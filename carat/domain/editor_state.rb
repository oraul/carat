module Carat
  module Domain
    # Everything a use case reads or changes: the buffer, the window, the
    # cursor, the mode, the options, the command line, the message, the keys
    # pending in the keymap, and the quit flag.
    class EditorState
      attr_accessor :buffer #: Buffer
      attr_accessor :window #: Window
      attr_accessor :cursor #: Cursor
      attr_accessor :mode #: Symbol
      attr_accessor :options #: Options
      attr_accessor :timeoutlen #: Integer
      attr_accessor :cmdline #: String
      attr_accessor :message #: String
      attr_accessor :message_error #: bool
      attr_accessor :pending_keys #: Array[Integer]
      attr_accessor :quit #: bool

      #: (Buffer, Options, Integer) -> void
      def initialize(buffer, options, timeoutlen)
        @buffer = buffer
        @window = Window.new
        @cursor = Cursor.new(0, 0)
        @mode = Mode::NORMAL
        @options = options
        @timeoutlen = timeoutlen
        @cmdline = ""
        @message = ""
        @message_error = false
        @pending_keys = []
        @quit = false
      end

      #: (String, bool) -> void
      def show(text, error)
        @message = text
        @message_error = error
      end

      #: () -> void
      def clear_message
        @message = ""
        @message_error = false
      end

      #: () -> String
      def current_line
        @buffer.line(@cursor.row)
      end

      # The largest column the cursor may occupy on a row in the current
      # mode: past the last character in insert mode, on it otherwise.
      #: (Integer) -> Integer
      def max_col(row)
        len = @buffer.line(row).length
        return len if @mode == Mode::INSERT
        len > 0 ? len - 1 : 0
      end

      # Replaces the buffer and resets the cursor and the window to its start.
      #: (Buffer) -> void
      def load(buffer)
        @buffer = buffer
        @cursor = Cursor.new(0, 0)
        @window = Window.new
      end
    end
  end
end
