module Carat
  module Domain
    # The view model: a grid of cells plus the cursor position and shape. It
    # contains no terminal knowledge; presenters and tests both reason about
    # it. Cells hold integer code points, so the frame never aliases a
    # buffer line's string storage. A Struct record: mutable, and repainted
    # in place across renders rather than allocated anew.
    class Frame < Struct.new(:rows, :cols, :cursor_row, :cursor_col, :cursor_shape, :cells)
      SPACE = 32

      # @rbs @rows: Integer
      # @rbs @cols: Integer
      # @rbs @cursor_row: Integer
      # @rbs @cursor_col: Integer
      # @rbs @cursor_shape: Symbol
      # @rbs @cells: Array[Array[Cell]]

      #: (Integer, Integer) -> void
      def initialize(rows, cols)
        grid = []
        r = 0
        while r < rows
          row = []
          c = 0
          while c < cols
            row << Cell.new(SPACE, 1, Highlight::NORMAL)
            c += 1
          end
          grid << row
          r += 1
        end
        super(rows, cols, 0, 0, :block, grid)
      end

      #: (Integer, Integer) -> Cell
      def cell(row, col)
        cells[row][col]
      end

      # Resets every cell to a blank and the cursor to the origin, so one
      # frame can be repainted instead of allocated anew each render.
      #: () -> void
      def clear
        r = 0
        while r < rows
          row = cells[r]
          c = 0
          while c < cols
            current = row[c]
            current.code = SPACE
            current.width = 1
            current.hl = Highlight::NORMAL
            c += 1
          end
          r += 1
        end
        self.cursor_row = 0
        self.cursor_col = 0
        self.cursor_shape = :block
      end

      # Writes text from (row, col), honoring display width and stopping at
      # the right edge. Returns the column after the last cell written.
      #: (Integer, Integer, String, Integer) -> Integer
      def put(row, col, text, hl)
        return col if row < 0 || row >= rows
        text.each_codepoint do |code|
          width = DisplayWidth.of(code)
          next if width == 0
          break if col + width > cols
          target = cell(row, col)
          target.code = code
          target.width = width
          target.hl = hl
          if width == 2
            follower = cell(row, col + 1)
            follower.code = 0
            follower.width = 0
            follower.hl = hl
          end
          col += width
        end
        col
      end

      # Sets the highlight of every cell in [from, to) of a row.
      #: (Integer, Integer, Integer, Integer) -> void
      def fill(row, from, to, hl)
        return if row < 0 || row >= rows
        c = from
        while c < to && c < cols
          cell(row, c).hl = hl
          c += 1
        end
      end

      # The characters of a row joined, trailing blanks removed. The code
      # points are packed in one call rather than one per cell.
      #: (Integer) -> String
      def row_text(row)
        codes = []
        c = 0
        while c < cols
          current = cell(row, c)
          codes << current.code if current.width > 0
          c += 1
        end
        codes.pack("U*").rstrip
      end

      #: () -> Array[String]
      def text_rows
        out = []
        r = 0
        while r < rows
          out << row_text(r)
          r += 1
        end
        out
      end

      # Copies every cell and the cursor from other into this frame, which
      # must be the same size. Lets a presenter keep a reusable snapshot of
      # the last frame it drew without allocating one each time.
      #: (Frame) -> void
      def sync_from(other)
        r = 0
        while r < rows
          c = 0
          while c < cols
            mine = cell(r, c)
            theirs = other.cell(r, c)
            mine.code = theirs.code
            mine.width = theirs.width
            mine.hl = theirs.hl
            c += 1
          end
          r += 1
        end
        self.cursor_row = other.cursor_row
        self.cursor_col = other.cursor_col
        self.cursor_shape = other.cursor_shape
      end

      #: (Frame, Integer) -> bool
      def row_same?(other, row)
        return false unless other.cols == cols
        c = 0
        while c < cols
          return false unless cell(row, c).same?(other.cell(row, c))
          c += 1
        end
        true
      end
    end
  end
end
