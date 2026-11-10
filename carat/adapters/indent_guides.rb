require_relative "../domain/buffer"
require_relative "../domain/frame"
require_relative "../domain/highlight"
require_relative "../domain/options"

module Carat
  module Adapters
    # The indent guides of one file window, measured by the frame
    # presenter before it paints the window's rows: a guide at every
    # multiple of the level width (shiftwidth, or tabstop when shiftwidth
    # is 0) inside a row's leading whitespace, a space one column and a
    # tab running to the next multiple of tabstop. A blank or
    # whitespace-only row carries the smaller of the indents of the
    # nearest non-blank rows above and below it, searched for at most
    # NEIGHBOR_LIMIT rows past the window's edges, none counting as no
    # indent. In the current window the cursor's block is the run of
    # rows around the cursor indented past the deepest level below the
    # cursor row's indent; its guide at that level is drawn in IblScope,
    # every other guide in IblIndent. Each row's guides reduce to a key,
    # an input of its repaint beside its line. The indents are kept in
    # arrays that grow only when a taller window appears, so measuring
    # and painting allocate nothing.
    class IndentGuides
      NEIGHBOR_LIMIT = 1000
      # Indents at or past this are capped in a row's key; the key is
      # the indent times SCOPE_SHIFT plus the row's scope column plus 1.
      INDENT_CAP = 1 << 20
      SCOPE_SHIFT = 1 << 21

      # @rbs @indents: Array[Integer]
      # @rbs @above: Array[Integer]
      # @rbs @rows: Integer
      # @rbs @width: Integer
      # @rbs @tabstop: Integer
      # @rbs @code: Integer
      # @rbs @scope: Integer
      # @rbs @scope_from: Integer
      # @rbs @scope_to: Integer

      #: () -> void
      def initialize
        @indents = Array.new(64, 0)
        @above = Array.new(64, 0)
        @rows = 0
        @width = 8
        @tabstop = 8
        @code = 0
        @scope = -1
        @scope_from = 0
        @scope_to = -1
      end

      # Takes a frame's options and returns the stamp of the settings
      # every row's guides depend on, 0 with the guides off, so a frame
      # with other settings paints every row again.
      #: (Domain::Options) -> Integer
      def configure(options)
        @tabstop = options.tab_width
        @width = options.shiftwidth > 0 ? options.shiftwidth : @tabstop
        @code = options.indentguides ? options.guide_code : 0
        return 0 if @code == 0
        (@code * 16_384 + @width) * 16_384 + @tabstop
      end

      # Whether the options of the frame draw guides.
      #: () -> bool
      def on?
        @code > 0
      end

      # Measures the rows of a window from top for height rows: their
      # indents, the blank rows' carried ones, and, in the current window,
      # the cursor's block.
      #: (Domain::Buffer, Integer, Integer, Integer, bool) -> void
      def measure(buffer, top, height, cursor_row, current)
        grow(height)
        count = buffer.line_count
        rows = count - top
        rows = height if rows > height
        rows = 0 if rows < 0
        @rows = rows
        i = 0
        while i < rows
          @indents[i] = indent_of(buffer.line(top + i))
          i += 1
        end
        carry(buffer, top, rows)
        find_scope(cursor_row - top, rows, current)
      end

      # The key of visible row i's guides: 0 for none.
      #: (Integer) -> Integer
      def key(i)
        return 0 if @code == 0 || i >= @rows
        indent = @indents[i]
        return 0 if indent <= 0
        indent = INDENT_CAP - 1 if indent >= INDENT_CAP
        scope = i >= @scope_from && i <= @scope_to ? @scope + 1 : 0
        indent * SCOPE_SHIFT + scope
      end

      # Paints visible row i's guides on a frame row whose text starts at
      # column col, width cells wide, scrolled left columns.
      #: (Domain::Frame, Integer, Integer, Integer, Integer, Integer) -> void
      def paint(frame, frame_row, i, col, width, left)
        return if @code == 0 || i >= @rows
        indent = @indents[i]
        limit = left + width
        limit = indent if indent < limit
        level = left > 0 ? ((left + @width - 1) / @width) * @width : 0
        scoped = i >= @scope_from && i <= @scope_to
        while level < limit
          hl = scoped && level == @scope ? Domain::Highlight::INDENT_GUIDE_SCOPE : Domain::Highlight::INDENT_GUIDE
          frame.put_code(frame_row, col + level - left, @code, 1, hl)
          level += @width
        end
      end

      private

      #: (Integer) -> void
      def grow(height)
        while @indents.length < height
          @indents << 0
          @above << 0
        end
      end

      # The display width of a line's leading whitespace, -1 for a line
      # of whitespace only.
      #: (String) -> Integer
      def indent_of(line)
        n = line.bytesize
        k = 0
        col = 0
        while k < n
          b = line.getbyte(k).to_i
          if b == 32
            col += 1
          elsif b == 9
            col += @tabstop - col % @tabstop
          else
            return col
          end
          k += 1
        end
        -1
      end

      # Gives each blank row of the rows measured the smaller of its
      # nearest non-blank neighbors' indents.
      #: (Domain::Buffer, Integer, Integer) -> void
      def carry(buffer, top, rows)
        return if rows == 0
        above = @indents[0] < 0 ? neighbor(buffer, top - 1, -1) : 0
        i = 0
        while i < rows
          value = @indents[i]
          above = value if value >= 0
          @above[i] = above
          i += 1
        end
        below = @indents[rows - 1] < 0 ? neighbor(buffer, top + rows, 1) : 0
        i = rows - 1
        while i >= 0
          value = @indents[i]
          if value >= 0
            below = value
          else
            up = @above[i]
            @indents[i] = up < below ? up : below
          end
          i -= 1
        end
      end

      # The indent of the nearest non-blank line from row on in the
      # direction step, 0 when none lies within NEIGHBOR_LIMIT lines.
      #: (Domain::Buffer, Integer, Integer) -> Integer
      def neighbor(buffer, row, step)
        count = buffer.line_count
        n = 0
        at = row
        while n < NEIGHBOR_LIMIT && at >= 0 && at < count
          value = indent_of(buffer.line(at))
          return value if value >= 0
          at += step
          n += 1
        end
        0
      end

      # The cursor's block among the rows measured: its guide's column
      # and its first and last visible rows, none outside the current
      # window or on a row of no indent.
      #: (Integer, Integer, bool) -> void
      def find_scope(cursor, rows, current)
        @scope = -1
        @scope_from = 0
        @scope_to = -1
        return unless current && cursor >= 0 && cursor < rows
        indent = @indents[cursor]
        return if indent <= 0
        scope = ((indent - 1) / @width) * @width
        from = cursor
        while from > 0 && @indents[from - 1] > scope
          from -= 1
        end
        to = cursor
        while to + 1 < rows && @indents[to + 1] > scope
          to += 1
        end
        @scope = scope
        @scope_from = from
        @scope_to = to
      end
    end
  end
end
