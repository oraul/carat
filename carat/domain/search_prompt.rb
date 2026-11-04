require_relative "mode"
require_relative "window"

module Carat
  module Domain
    # The search prompt "/" or "?" while it holds the command line: its
    # direction, the mode it returns to, and where the cursor and the
    # window's view stood when it opened, which Escape restores and Enter
    # searches from; then, once Enter closed it, the text entered, which
    # HandleKey hands to the command grammar as the search's argument.
    # A Struct record: mutable, with a reader and a writer per member.
    class SearchPrompt < Struct.new(:active, :forward, :return_mode, :origin_row, :origin_col, :origin_top, :origin_left, :entered, :text, keyword_init: true)
      # @rbs @active: bool
      # @rbs @forward: bool
      # @rbs @return_mode: Symbol
      # @rbs @origin_row: Integer
      # @rbs @origin_col: Integer
      # @rbs @origin_top: Integer
      # @rbs @origin_left: Integer
      # @rbs @entered: bool
      # @rbs @text: String

      #: () -> void
      def initialize
        super(active: false, forward: true, return_mode: Mode::NORMAL, origin_row: 0, origin_col: 0, origin_top: 0, origin_left: 0, entered: false, text: "")
      end

      #: (bool, Symbol, Integer, Integer, Integer, Integer) -> void
      def open(forward, return_mode, row, col, top, left)
        self.active = true
        self.forward = forward
        self.return_mode = return_mode
        self.origin_row = row
        self.origin_col = col
        self.origin_top = top
        self.origin_left = left
        self.entered = false
        self.text = ""
      end

      # Puts the window's cursor and view back where the prompt opened,
      # keeping the wanted column, inside the buffer should a plugin have
      # shortened it meanwhile.
      #: (Window) -> void
      def restore(window)
        cursor = window.cursor
        buffer = window.buffer
        row = origin_row
        last = buffer.line_count - 1
        row = last if row > last
        length = buffer.line(row).length
        cursor.row = row
        cursor.col = origin_col > length ? length : origin_col
        window.top = origin_top
        window.left = origin_left
      end

      # The prompt character, "/" or "?".
      #: () -> String
      def prefix
        forward ? "/" : "?"
      end

      # Closes the prompt with the text Enter submitted.
      #: (String) -> void
      def enter(line)
        self.active = false
        self.entered = true
        self.text = line
      end

      #: () -> void
      def close
        self.active = false
      end

      # The text entered, which is forgotten.
      #: () -> String
      def take_text
        self.entered = false
        line = text
        self.text = ""
        line
      end
    end
  end
end
