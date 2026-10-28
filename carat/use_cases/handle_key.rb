require_relative "../domain/editor_state"
require_relative "../domain/keymap"
require_relative "../domain/key"
require_relative "../domain/key_notation"
require_relative "../domain/command"
require_relative "../domain/command_grammar"
require_relative "dispatcher"
require_relative "insert_text"
require_relative "edit_command_line"

module Carat
  module UseCases
    # The central use case: feeds one key through the current mode's keymap
    # and, in normal and operator-pending modes, through the command
    # grammar, dispatching the command when it completes. Returns :handled
    # or :pending, the latter meaning the keymap is waiting for more keys.
    # A remap sequence is queued in front of the keys still to handle, so
    # replay is a loop, not a recursion; one key may cause at most
    # MAX_REPLAYS remaps before E223 stops it.
    class HandleKey
      MAX_REPLAYS = 100

      # @rbs @keymap: Domain::Keymap
      # @rbs @dispatcher: Dispatcher
      # @rbs @insert_text: InsertText
      # @rbs @command_line: EditCommandLine
      # @rbs @replays: Integer

      #: (Domain::Keymap, Dispatcher, InsertText, EditCommandLine) -> void
      def initialize(keymap, dispatcher, insert_text, command_line)
        @keymap = keymap
        @dispatcher = dispatcher
        @insert_text = insert_text
        @command_line = command_line
        @replays = 0
      end

      #: (Domain::EditorState, Integer) -> Symbol
      def call(state, code)
        @replays = 0
        queue = [code]
        result = :handled
        result = step(state, queue.shift, queue) until queue.empty?
        result
      end

      # Resolves pending keys after timeoutlen: the shorter binding fires if
      # there is one, otherwise the keys are dropped (or inserted as text).
      #: (Domain::EditorState) -> Symbol
      def timeout(state)
        keys = state.pending_keys
        return :idle if keys.empty?
        @replays = 0
        match = @keymap.lookup(state.mode, keys)
        state.pending_keys = []
        value = match.value
        queue = []
        if value.nil?
          cancel(state)
          insert_literal(state, keys)
        else
          dispatch(state, value, keys, queue)
        end
        step(state, queue.shift, queue) until queue.empty?
        :handled
      end

      private

      # Whether the grammar reads keys in the current mode.
      #: (Domain::EditorState) -> bool
      def grammar_mode?(state)
        state.mode == Domain::Mode::NORMAL || state.mode == Domain::Mode::OPERATOR_PENDING
      end

      # Handles one key; a remap it triggers is pushed to the front of queue.
      #: (Domain::EditorState, Integer, Array[Integer]) -> Symbol
      def step(state, code, queue)
        state.clear_message
        if grammar_mode?(state)
          grammar = state.grammar
          if grammar.wants_char?
            finish(state, grammar.char(code))
            return :handled
          end
          if state.pending_keys.empty? && grammar.digit?(code)
            grammar.digit(code)
            return :handled
          end
        end
        state.pending_keys << code
        match = @keymap.lookup(state.mode, state.pending_keys)
        case match.kind
        when :match
          keys = state.pending_keys
          state.pending_keys = []
          dispatch(state, match.value, keys, queue)
          :handled
        when :prefix, :match_prefix
          :pending
        else
          keys = state.pending_keys
          state.pending_keys = []
          cancel(state)
          insert_literal(state, keys)
          :handled
        end
      end

      #: (Domain::EditorState, String?, Array[Integer], Array[Integer]) -> void
      def dispatch(state, value, keys, queue)
        return if value.nil?
        unless action_name?(value)
          replay(state, value, queue)
          return
        end
        if grammar_mode?(state)
          finish(state, state.grammar.accept(value, keys))
        else
          @dispatcher.call(state, Domain::Command.plain(value))
        end
      end

      # Acts on what the grammar said: an operator switches to
      # operator-pending mode, a complete command returns to normal mode
      # and is dispatched (the command itself may enter insert mode), a
      # cancel returns to normal mode, and pending waits.
      #: (Domain::EditorState, Symbol) -> void
      def finish(state, result)
        case result
        when :operator
          state.mode = Domain::Mode::OPERATOR_PENDING
        when :complete
          state.mode = Domain::Mode::NORMAL
          @dispatcher.call(state, state.grammar.take)
        when :cancel
          state.mode = Domain::Mode::NORMAL
        end
      end

      # An unbound key drops whatever command was being typed.
      #: (Domain::EditorState) -> void
      def cancel(state)
        return unless grammar_mode?(state)
        state.grammar.reset
        state.mode = Domain::Mode::NORMAL
      end

      # An action name is namespace.action in lowercase letters, digits, and
      # underscores; anything else is a key sequence to replay.
      #: (String) -> bool
      def action_name?(value)
        value.match?(/\A[a-z0-9_]+\.[a-z0-9_]+\z/)
      end

      #: (Domain::EditorState, String, Array[Integer]) -> void
      def replay(state, sequence, queue)
        @replays += 1
        if @replays > MAX_REPLAYS
          state.show("E223: Recursive mapping", true)
          queue.clear
          return
        end
        parsed = Domain::KeyNotation.parse(sequence, "")
        unless parsed.ok?
          state.show("Bad mapping: #{sequence}", true)
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
              @insert_text.call(state, text)
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
