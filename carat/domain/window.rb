module Carat
  module Domain
    # A viewport over one buffer: the buffer it shows, its own cursor, the
    # first visible row and display column, the rectangle the layout gave
    # it at the last render (row, col, height in text rows, width in
    # columns including the gutter; all 0 before the first render, when the
    # screen motions H, M, and L treat the whole buffer as visible), and
    # whether its width is fixed, as Neovim's winfixwidth, so resizes and
    # equalizing leave it alone. The window owns its visual selection: the
    # anchor where it started (the cursor is the other end, the mode its
    # kind), and the last selection it left, which "gv" restores. id is the
    # stable number the editor gives the window when it enters a tab page
    # (0 until then), never given to another window. A Struct record:
    # mutable, with a reader and a writer per member.
    class Window < Struct.new(:buffer, :cursor, :top, :left, :row, :col, :height, :width, :fixed_width, :anchor, :last_selection, :id)
      SIGN_WIDTH = 2

      # @rbs @buffer: Buffer
      # @rbs @cursor: Cursor
      # @rbs @top: Integer
      # @rbs @left: Integer
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @height: Integer
      # @rbs @width: Integer
      # @rbs @fixed_width: bool
      # @rbs @anchor: Position
      # @rbs @last_selection: Selection
      # @rbs @id: Integer

      #: (Buffer) -> void
      def initialize(buffer)
        super(buffer, Cursor.new(0, 0), 0, 0, 0, 0, 0, 0, false, Position.new(0, 0), Selection.none, 0)
      end

      # Shows another buffer from its start, forgetting the last selection,
      # which belonged to the buffer shown before.
      #: (Buffer) -> void
      def show(buffer)
        self.buffer = buffer
        self.cursor = Cursor.new(0, 0)
        self.top = 0
        self.left = 0
        self.last_selection = Selection.none
      end

      # Takes the buffer, cursor, and scroll position of other, as a split
      # gives the new window the same view.
      #: (Window) -> void
      def copy_from(other)
        self.buffer = other.buffer
        self.cursor = Cursor.new(other.cursor.row, other.cursor.col)
        cursor.want_col = other.cursor.want_col
        self.top = other.top
        self.left = other.left
        self.last_selection = other.last_selection
      end

      # The gutter is the sign column, two cells while the buffer has
      # signs, plus max(3, digits of the line count) and one space when
      # numbers are shown. A plugin's scratch buffer shows no numbers, as
      # Neovim's tree plugins set nonumber in their windows.
      #: (Options) -> Integer
      def gutter_width(options)
        signs = buffer.signs? ? SIGN_WIDTH : 0
        return signs if buffer.scratch?
        return signs unless options.number || options.relativenumber
        digits = buffer.line_count.to_s.length
        digits = 3 if digits < 3
        signs + digits + 1
      end

      # Scrolls so that row is visible with scrolloff rows of context where
      # the buffer allows, in a window of height rows.
      #: (Integer, Integer, Integer, Integer) -> void
      def scroll_to_row(row, line_count, height, scrolloff)
        return if height <= 0
        off = scrolloff
        half = (height - 1) / 2
        off = half if off > half
        self.top = row - off if row - off < top
        self.top = row + off - height + 1 if row + off >= top + height
        max_top = line_count - height
        max_top = 0 if max_top < 0
        self.top = max_top if top > max_top
        self.top = 0 if top < 0
      end

      # Scrolls horizontally so that display column col is visible in a text
      # area of width columns.
      #: (Integer, Integer) -> void
      def scroll_to_col(col, width)
        return if width <= 0
        self.left = col if col < left
        self.left = col - width + 1 if col >= left + width
        self.left = 0 if left < 0
      end
    end
  end
end
