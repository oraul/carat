require_relative "../domain/editor_state"
require_relative "../domain/input_state"
require_relative "../domain/keymap"
require_relative "../domain/key"
require_relative "../domain/key_notation"
require_relative "../domain/command"
require_relative "../domain/command_grammar"
require_relative "outcome"
require_relative "concerns/reporting"
require_relative "actions/action_table"
require_relative "dispatcher"
require_relative "insert_text"
require_relative "edit_command_line"
require_relative "plugins/plugin_host"

module Carat
  module UseCases
    # The central use case: feeds one key through the current mode's keymap
    # and, in normal, operator-pending, and the visual modes, through the
    # command grammar, dispatching the command when it completes; in a
    # visual mode an operator completes at once and the mode stays until
    # the command ends it. Returns :handled
    # or :pending, the latter meaning the keymap is waiting for more keys.
    # A remap sequence is queued in front of the keys still to handle, so
    # replay is a loop, not a recursion; one key may cause at most
    # MAX_REPLAYS remaps before E223 stops it. A key is looked up first in
    # the keymap of a scratch buffer the current window shows, then in the
    # mode's keymap. The grammar reads each action with the kind of its
    # handler in the action table. After every key the plugin host
    # observes the state and delivers the events the key caused. It owns
    # the input state: the keys the keymap waits on and the grammar.
    class HandleKey
      include Reporting

      MAX_REPLAYS = 100

      attr_reader :keymap #: Domain::Keymap
      attr_reader :input #: Domain::InputState
      attr_reader :plugins #: PluginHost

      # @rbs @actions: ActionTable
      # @rbs @dispatcher: Dispatcher
      # @rbs @insert_text: InsertText
      # @rbs @command_line: EditCommandLine
      # @rbs @replays: Integer

      #: (keymap: Domain::Keymap, input: Domain::InputState, actions: ActionTable, dispatcher: Dispatcher, insert_text: InsertText, command_line: EditCommandLine, plugins: PluginHost) -> void
      def initialize(keymap:, input:, actions:, dispatcher:, insert_text:, command_line:, plugins:)
        @keymap = keymap
        @input = input
        @actions = actions
        @dispatcher = dispatcher
        @insert_text = insert_text
        @command_line = command_line
        @plugins = plugins
        @replays = 0
      end

      #: (Domain::EditorState, Integer) -> Symbol
      def call(state, code)
        @replays = 0
        queue = [code]
        result = :handled
        result = step(state, queue.shift, queue) until queue.empty?
        @plugins.observe
        result
      end

      # Whether the keymap is waiting for more keys of a binding.
      #: () -> bool
      def pending?
        @input.pending?
      end

      # Resolves pending keys after timeoutlen: the shorter binding fires if
      # there is one, otherwise the keys are dropped (or inserted as text).
      #: (Domain::EditorState) -> Symbol
      def timeout(state)
        input = @input
        keys = input.pending_keys
        return :idle if keys.empty?
        @replays = 0
        match = lookup(state, keys)
        input.pending_keys = []
        value = match.value
        queue = []
        if value.nil?
          cancel(state)
          insert_literal(state, keys)
        else
          dispatch(state, value, keys, queue)
        end
        step(state, queue.shift, queue) until queue.empty?
        @plugins.observe
        :handled
      end

      private

      # The scratch buffer's own keymap answers first; a key it neither
      # binds nor starts a binding with falls through to the mode's keymap.
      #: (Domain::EditorState, Array[Integer]) -> Domain::KeymapMatch
      def lookup(state, keys)
        local = state.buffer.keymap
        unless local.nil?
          match = local.lookup(state.mode, keys)
          return match unless match.kind == :none
        end
        @keymap.lookup(state.mode, keys)
      end

      # Whether the grammar reads keys in the current mode.
      #: (Domain::EditorState) -> bool
      def grammar_mode?(state)
        mode = state.mode
        mode == Domain::Mode::NORMAL || mode == Domain::Mode::OPERATOR_PENDING || Domain::Mode.visual?(mode)
      end

      # Handles one key; a remap it triggers is pushed to the front of queue.
      #: (Domain::EditorState, Integer, Array[Integer]) -> Symbol
      def step(state, code, queue)
        state.clear_message
        input = @input
        if grammar_mode?(state)
          grammar = input.grammar
          if grammar.wants_char?
            finish(state, grammar.char(code))
            return :handled
          end
          if input.pending_keys.empty? && grammar.digit?(code)
            grammar.digit(code)
            return :handled
          end
        end
        input.pending_keys << code
        match = lookup(state, input.pending_keys)
        case match.kind
        when :match
          keys = input.take_keys
          dispatch(state, match.value, keys, queue)
          :handled
        when :prefix, :match_prefix
          :pending
        else
          keys = input.take_keys
          cancel(state)
          insert_literal(state, keys)
          :handled
        end
      end

      #: (Domain::EditorState, String?, Array[Integer], Array[Integer]) -> void
      def dispatch(state, value, keys, queue)
        return if value.nil?
        unless Domain::Keymap.action_name?(value)
          replay(state, value, queue)
          return
        end
        if Domain::Mode.visual?(state.mode)
          finish(state, @input.grammar.accept_visual(value, @actions.kind_of(value), keys))
        elsif grammar_mode?(state)
          finish(state, @input.grammar.accept(value, @actions.kind_of(value), keys))
        else
          @dispatcher.call(state, Domain::Command.plain(value))
        end
      end

      # Acts on what the grammar said: an operator switches to
      # operator-pending mode, a complete command returns to normal mode
      # and is dispatched (the command itself may enter insert mode), a
      # cancel returns to normal mode, and pending waits. In a visual mode
      # the mode stays: the dispatched command decides what comes next.
      #: (Domain::EditorState, Symbol) -> void
      def finish(state, result)
        visual = Domain::Mode.visual?(state.mode)
        case result
        when :operator
          state.mode = Domain::Mode::OPERATOR_PENDING
        when :complete
          state.mode = Domain::Mode::NORMAL unless visual
          @dispatcher.call(state, @input.grammar.take)
        when :cancel
          state.mode = Domain::Mode::NORMAL unless visual
        end
      end

      # An unbound key drops whatever command was being typed; a visual
      # mode stays.
      #: (Domain::EditorState) -> void
      def cancel(state)
        return unless grammar_mode?(state)
        @input.grammar.reset
        state.mode = Domain::Mode::NORMAL unless Domain::Mode.visual?(state.mode)
      end

      #: (Domain::EditorState, String, Array[Integer]) -> void
      def replay(state, sequence, queue)
        @replays += 1
        if @replays > MAX_REPLAYS
          report(state, Outcome.failure("E223: Recursive mapping"))
          queue.clear
          return
        end
        parsed = Domain::KeyNotation.parse(sequence, "")
        unless parsed.ok?
          report(state, Outcome.failure("Bad mapping: #{sequence}"))
          return
        end
        codes = parsed.codes
        i = codes.length - 1
        while i >= 0
          queue.unshift(codes[i])
          i -= 1
        end
      end

      #: (Domain::EditorState, Array[Integer]) -> void
      def insert_literal(state, keys)
        mode = state.mode
        return unless mode == Domain::Mode::INSERT || mode == Domain::Mode::CMDLINE
        i = 0
        while i < keys.length
          code = keys[i]
          if Domain::Key.printable?(code)
            text = Domain::Key.char(code)
            if mode == Domain::Mode::INSERT
              report(state, @insert_text.call(state, text))
            else
              @command_line.append(state, text)
            end
          end
          i += 1
        end
      end
    end
  end
end
