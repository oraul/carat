require_relative "jump_list"

module Carat
  module Domain
    # A viewport over one buffer: the buffer it shows, its own cursor, the
    # first visible row and display column, the rectangle the layout gave
    # it at the last render (row, col, height in text rows, width in
    # columns including the gutter; all 0 before the first render, when the
    # screen motions H, M, and L treat the whole buffer as visible), and
    # whether its width is fixed, as Neovim's winfixwidth, so resizes and
    # equalizing leave it alone, and whether its height is, as
    # winfixheight, for the bottom panel. The window owns its visual
    # selection: the anchor where it started (the cursor is the other
    # end, the mode its kind), and the last selection it left, which "gv"
    # restores. id is the stable number the editor gives the window when
    # it enters a tab page (0 until then), never given to another window.
    # jumps is the window's own jump list, which a new window copies, and
    # alternate the number of the buffer it showed before the current one
    # (0 for none), Neovim's alternate file, copied with the list.
    # A Struct record: mutable, with a reader and a writer per member.
    class Window < Struct.new(:buffer, :cursor, :top, :left, :row, :col, :height, :width, :fixed_width, :fixed_height, :anchor, :last_selection, :id, :jumps, :alternate, keyword_init: true)
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
      # @rbs @fixed_height: bool
      # @rbs @anchor: Position
      # @rbs @last_selection: Selection
      # @rbs @id: Integer
      # @rbs @jumps: JumpList
      # @rbs @alternate: Integer

      #: (buffer: Buffer) -> void
      def initialize(buffer:)
        super(buffer: buffer, cursor: Cursor.new(row: 0, col: 0), top: 0, left: 0, row: 0, col: 0, height: 0, width: 0, fixed_width: false, fixed_height: false, anchor: Position.new(row: 0, col: 0), last_selection: Selection.none, id: 0, jumps: JumpList.new, alternate: 0)
      end

      # Shows another buffer from its start, forgetting the last selection,
      # which belonged to the buffer shown before.
      #: (Buffer) -> void
      def show(buffer)
        self.buffer = buffer
        self.cursor = Cursor.new(row: 0, col: 0)
        self.top = 0
        self.left = 0
        self.last_selection = Selection.none
      end

      # Lets the window's width and height change again, as a plugin's
      # side window that takes a file does.
      #: () -> void
      def unfix_size
        self.fixed_width = false
        self.fixed_height = false
      end

      # Records the cursor's position in the jump list before a jump
      # motion moves it, as Neovim's setpcmark; nothing for the startup
      # buffer, whose number 0 no walk finds.
      #: () -> void
      def record_jump
        id = buffer.id
        jumps.push(id, cursor.row, cursor.col) unless id == 0
      end

      # Takes the buffer, cursor, scroll position, a copy of the jump list,
      # and the alternate buffer of other, as a split gives the new window
      # the same view.
      #: (Window) -> void
      def copy_from(other)
        self.buffer = other.buffer
        self.cursor = Cursor.new(row: other.cursor.row, col: other.cursor.col)
        cursor.want_col = other.cursor.want_col
        self.top = other.top
        self.left = other.left
        self.last_selection = other.last_selection
        jumps.restore_from(other.jumps)
        self.alternate = other.alternate
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
        digits = 1
        rest = buffer.line_count
        while rest >= 10
          rest /= 10
          digits += 1
        end
        digits = 3 if digits < 3
        signs + digits + 1
      end

      # Scrolls so that row is visible with scrolloff rows of context where
      # the buffer allows, in the window's height of text rows.
      #: (Integer, Integer, Integer) -> void
      def scroll_to_row(row, line_count, scrolloff)
        return if height <= 0
        off = margin(scrolloff)
        self.top = row - off if row - off < top
        self.top = row + off - height + 1 if row + off >= top + height
        scroll_top_to(top, line_count)
      end

      # Makes row the first shown line, clamped between the first line and
      # max_top, as every scroll of the window clamps it.
      #: (Integer, Integer) -> void
      def scroll_top_to(row, line_count)
        last = max_top(line_count)
        row = last if row > last
        row = 0 if row < 0
        self.top = row
      end

      # The last first-shown line: the one that fills the window to the
      # last of line_count lines, 0 when they all fit.
      #: (Integer) -> Integer
      def max_top(line_count)
        last = line_count - height
        last < 0 ? 0 : last
      end

      # scrolloff, capped at half the window as Neovim caps it.
      #: (Integer) -> Integer
      def margin(scrolloff)
        half = (height - 1) / 2
        scrolloff > half ? half : scrolloff
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
