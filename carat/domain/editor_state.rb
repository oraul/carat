module Carat
  module Domain
    # Everything a use case reads or changes: the buffer, the window, the
    # cursor, the mode, the options, the command line, the message, the keys
    # pending in the keymap, the quit flag, the registers, the command
    # grammar with the keys of the command being typed, and the last f/t
    # motion for ";" and ",". A Struct record: mutable, with a reader and a
    # writer per member.
    class EditorState < Struct.new(:buffer, :window, :cursor, :mode, :options, :timeoutlen, :cmdline, :message, :message_error, :pending_keys, :quit, :registers, :grammar, :last_find)
      # @rbs @buffer: Buffer
      # @rbs @window: Window
      # @rbs @cursor: Cursor
      # @rbs @mode: Symbol
      # @rbs @options: Options
      # @rbs @timeoutlen: Integer
      # @rbs @cmdline: String
      # @rbs @message: String
      # @rbs @message_error: bool
      # @rbs @pending_keys: Array[Integer]
      # @rbs @quit: bool
      # @rbs @registers: Registers
      # @rbs @grammar: CommandGrammar
      # @rbs @last_find: Find?

      #: (Buffer, Options, Integer) -> void
      def initialize(buffer, options, timeoutlen)
        super(buffer, Window.new, Cursor.new(0, 0), Mode::NORMAL, options, timeoutlen, "", "", false, [], false, Registers.new, CommandGrammar.new, nil)
      end

      # The keys of the command being typed, for the pending-keys display:
      # what the grammar has taken plus what the keymap is still waiting on.
      #: () -> String
      def showcmd
        text = grammar.typed
        keys = pending_keys
        i = 0
        while i < keys.length
          text = text + CommandGrammar.display(keys[i])
          i += 1
        end
        text
      end

      #: (String, bool) -> void
      def show(text, error)
        self.message = text
        self.message_error = error
      end

      #: () -> void
      def clear_message
        self.message = ""
        self.message_error = false
      end

      #: () -> String
      def current_line
        buffer.line(cursor.row)
      end

      # The largest column the cursor may occupy on a row in the current
      # mode: past the last character in insert mode, on it otherwise.
      #: (Integer) -> Integer
      def max_col(row)
        len = buffer.line(row).length
        return len if mode == Mode::INSERT
        len > 0 ? len - 1 : 0
      end

      # Replaces the buffer and resets the cursor and the window to its start.
      #: (Buffer) -> void
      def load(buffer)
        self.buffer = buffer
        self.cursor = Cursor.new(0, 0)
        self.window = Window.new
      end
    end
  end
end
