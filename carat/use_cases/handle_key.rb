require_relative "../domain/editor_state"
require_relative "../domain/keymap"
require_relative "../domain/key"
require_relative "../domain/key_notation"
require_relative "dispatcher"
require_relative "insert_text"
require_relative "edit_command_line"

module Carat
  module UseCases
    # The central use case: feeds one key through the current mode's keymap
    # and dispatches the action when a sequence completes. Returns :handled
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
          insert_literal(state, keys)
        else
          dispatch(state, value, queue)
        end
        step(state, queue.shift, queue) until queue.empty?
        :handled
      end

      private

      # Handles one key; a remap it triggers is pushed to the front of queue.
      #: (Domain::EditorState, Integer, Array[Integer]) -> Symbol
      def step(state, code, queue)
        state.clear_message
        state.pending_keys << code
        match = @keymap.lookup(state.mode, state.pending_keys)
        case match.kind
        when :match
          state.pending_keys = []
          dispatch(state, match.value, queue)
          :handled
        when :prefix, :match_prefix
          :pending
        else
          keys = state.pending_keys
          state.pending_keys = []
          insert_literal(state, keys)
          :handled
        end
      end

      #: (Domain::EditorState, String?, Array[Integer]) -> void
      def dispatch(state, value, queue)
        return if value.nil?
        if action_name?(value)
          @dispatcher.call(state, value)
        else
          replay(state, value, queue)
        end
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
