require_relative "utf8"
require_relative "display_width"
require_relative "highlight"
require_relative "cell"

module Carat
  module Domain
    # The view model: a grid of cells plus the cursor position and shape,
    # with no terminal knowledge; presenters and tests both reason about
    # it. The cells are three flat integer arrays indexed row * cols + col:
    # the code point, its display width (2 for the first cell of a wide
    # character, 0 for the continuation cell after it, which holds code
    # 0), and the highlight group id. Integers only, so a frame never
    # aliases a buffer line's storage and Spinel reads every cell unboxed.
    #
    # A frame also says how it differs from the frame it was drawn after,
    # its base, for the screen presenter: dirty is 1 for a row whose cells
    # may differ from the base's, sources gives for each row the base row
    # whose content the terminal shows there once the frame's scrolls are
    # applied (-1 for a row that came into view), and scrolls holds three
    # integers per scroll of a region: first row, last row, and the rows
    # it moved up (negative for down). serial numbers the paint, and
    # base_serial is the serial of the base, -1 for none. layout is the
    # key of the geometry the frame was painted with. A fresh frame is
    # blank with every row dirty and no base. A Struct record, repainted
    # in place and reallocated only when the size changes.
    class Frame < Struct.new(:rows, :cols, :cursor_row, :cursor_col, :cursor_shape, :codes, :widths, :hls, :dirty, :sources, :scrolls, :serial, :base_serial, :layout)
      SPACE = 32
      REPLACEMENT = 0xFFFD

      # @rbs @rows: Integer
      # @rbs @cols: Integer
      # @rbs @cursor_row: Integer
      # @rbs @cursor_col: Integer
      # @rbs @cursor_shape: Symbol
      # @rbs @codes: Array[Integer]
      # @rbs @widths: Array[Integer]
      # @rbs @hls: Array[Integer]
      # @rbs @dirty: Array[Integer]
      # @rbs @sources: Array[Integer]
      # @rbs @scrolls: Array[Integer]
      # @rbs @serial: Integer
      # @rbs @base_serial: Integer
      # @rbs @layout: Array[Integer]

      #: (Integer, Integer) -> void
      def initialize(rows, cols)
        n = rows * cols
        super(rows, cols, 0, 0, :block, Array.new(n, SPACE), Array.new(n, 1), Array.new(n, Highlight::NORMAL), Array.new(rows, 1), Array.new(rows, 0), [], 0, -1, [])
        reset_sources
      end

      #: (Integer, Integer) -> Integer
      def index(row, col)
        row * cols + col
      end

      #: (Integer, Integer) -> Integer
      def code_at(row, col)
        codes[row * cols + col]
      end

      #: (Integer, Integer) -> Integer
      def width_at(row, col)
        widths[row * cols + col]
      end

      #: (Integer, Integer) -> Integer
      def hl_at(row, col)
        hls[row * cols + col]
      end

      # A value view of one cell, built on demand, for tests.
      #: (Integer, Integer) -> Cell
      def cell(row, col)
        i = row * cols + col
        Cell.new(codes[i], widths[i], hls[i])
      end

      # Sets the highlight of the cell, the way the presenter keeps the
      # cell under the cursor out of a selection.
      #: (Integer, Integer, Integer) -> void
      def set_hl(row, col, hl)
        hls[row * cols + col] = hl
      end

      # Blanks the cells [from, to) of a row: a space of width 1 in the
      # normal highlight.
      #: (Integer, Integer, Integer) -> void
      def blank(row, from, to)
        return if row < 0 || row >= rows
        stop = to < cols ? to : cols
        c = from < 0 ? 0 : from
        i = row * cols + c
        last = row * cols + stop
        while i < last
          codes[i] = SPACE
          widths[i] = 1
          hls[i] = Highlight::NORMAL
          i += 1
        end
      end

      # Blanks every cell and puts the cursor at the origin.
      #: () -> void
      def clear
        r = 0
        while r < rows
          blank(r, 0, cols)
          r += 1
        end
        self.cursor_row = 0
        self.cursor_col = 0
        self.cursor_shape = :block
      end

      # Writes one character of the given width at (row, col), with its
      # continuation cell after a wide one. The caller has checked that it
      # fits and that the code point is printable. Returns the column
      # after it.
      #: (Integer, Integer, Integer, Integer, Integer) -> Integer
      def put_code(row, col, code, width, hl)
        i = row * cols + col
        codes[i] = code
        widths[i] = width
        hls[i] = hl
        if width == 2
          codes[i + 1] = 0
          widths[i + 1] = 0
          hls[i + 1] = hl
        end
        col + width
      end

      # Writes text from (row, col), honoring display width and stopping at
      # the right edge. Returns the column after the last cell written. A
      # control code point is stored as the replacement character, so no
      # cell ever holds one and the terminal never receives it raw; the
      # presenter turns the ones it meets in a line into markers before
      # they get here. The text is walked by bytes, so nothing is
      # allocated.
      #: (Integer, Integer, String, Integer) -> Integer
      def put(row, col, text, hl)
        put_within(row, col, text, hl, cols)
      end

      # put, stopping at column limit instead of the right edge when it
      # comes first.
      #: (Integer, Integer, String, Integer, Integer) -> Integer
      def put_within(row, col, text, hl, limit)
        return col if row < 0 || row >= rows
        limit = cols if limit > cols
        bytes = text.bytesize
        i = 0
        while i < bytes
          raw = text.getbyte(i).to_i
          if raw < 0x80
            i += 1
          else
            size = Utf8.size_at(text, i, bytes)
            raw = Utf8.code_at(text, i, size)
            i += size
          end
          code = DisplayWidth.control?(raw) ? REPLACEMENT : raw
          width = DisplayWidth.of(code)
          next if width == 0
          break if col + width > limit
          put_code(row, col, code, width, hl)
          col += width
        end
        col
      end

      # The number of decimal digits of a number of zero or more.
      #: (Integer) -> Integer
      def self.digits(number)
        count = 1
        rest = number
        while rest >= 10
          rest /= 10
          count += 1
        end
        count
      end

      # Writes the decimal digits of a number of zero or more from (row,
      # col), stopping at the right edge. Returns the column after them.
      #: (Integer, Integer, Integer, Integer) -> Integer
      def put_digits(row, col, number, hl)
        count = Frame.digits(number)
        k = count - 1
        rest = number
        while k >= 0
          put_code(row, col + k, 48 + rest % 10, 1, hl) if col + k < cols
          rest /= 10
          k -= 1
        end
        col + count
      end

      # Writes number right-aligned in field cells followed by one space,
      # as a line number gutter shows it, keeping only the first visible
      # cells of those field + 1 and stopping at the right edge.
      #: (Integer, Integer, Integer, Integer, Integer, Integer) -> void
      def put_number(row, col, field, number, visible, hl)
        digits = Frame.digits(number)
        pad = field - digits
        pad = 0 if pad < 0
        total = pad + digits + 1
        total = visible if visible < total
        k = 0
        while k < total && col + k < cols
          put_code(row, col + k, SPACE, 1, hl)
          k += 1
        end
        k = pad + digits - 1
        rest = number
        while k >= pad
          put_code(row, col + k, 48 + rest % 10, 1, hl) if k < total && col + k < cols
          rest /= 10
          k -= 1
        end
      end

      # Sets the highlight of every cell in [from, to) of a row.
      #: (Integer, Integer, Integer, Integer) -> void
      def fill(row, from, to, hl)
        return if row < 0 || row >= rows
        c = from < 0 ? 0 : from
        while c < to && c < cols
          hls[row * cols + c] = hl
          c += 1
        end
      end

      # The characters of a row joined, trailing blanks removed.
      #: (Integer) -> String
      def row_text(row)
        out = +""
        i = row * cols
        last = i + cols
        while i < last
          out << codes[i] if widths[i] > 0
          i += 1
        end
        out.rstrip
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

      # Whether row of this frame and other_row of other, a frame of the
      # same width, hold the same cells.
      #: (Integer, Frame, Integer) -> bool
      def same_row?(row, other, other_row)
        return false unless other.cols == cols
        i = row * cols
        j = other_row * cols
        last = i + cols
        their_codes = other.codes
        their_widths = other.widths
        their_hls = other.hls
        while i < last
          return false if codes[i] != their_codes[j] || widths[i] != their_widths[j] || hls[i] != their_hls[j]
          i += 1
          j += 1
        end
        true
      end

      #: (Integer) -> bool
      def dirty?(row)
        dirty[row] != 0
      end

      # The dirty rows in order.
      #: () -> Array[Integer]
      def dirty_rows
        out = []
        r = 0
        while r < rows
          out << r if dirty[r] != 0
          r += 1
        end
        out
      end

      # Every row clean, sourced from itself, with no scroll: the state a
      # paint starts from.
      #: () -> void
      def reset_rows
        r = 0
        while r < rows
          dirty[r] = 0
          r += 1
        end
        reset_sources
        scrolls.clear
      end

      #: () -> void
      def mark_all_dirty
        r = 0
        while r < rows
          dirty[r] = 1
          r += 1
        end
        reset_sources
        scrolls.clear
      end

      # Records that rows first to last moved up by delta rows (down when
      # negative) from the base.
      #: (Integer, Integer, Integer) -> void
      def add_scroll(first, last, delta)
        scrolls << first
        scrolls << last
        scrolls << delta
      end

      #: () -> Integer
      def scroll_count
        scrolls.length / 3
      end

      private

      #: () -> void
      def reset_sources
        r = 0
        while r < rows
          sources[r] = r
          r += 1
        end
      end
    end
  end
end
