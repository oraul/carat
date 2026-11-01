require_relative "position"
require_relative "range"
require_relative "buffer"
require_relative "display_width"
require_relative "span"
require_relative "block"

module Carat
  module Domain
    # A visual selection: the anchor, where it started, the head, the
    # cursor end, the kind (:charwise, :linewise, :blockwise, or :none for
    # no selection), and whether "$" made a block reach every row's end.
    # The selection is inclusive: both ends are selected, and an end on
    # the end of a line or on an empty line selects the line break. A
    # Data value.
    class Selection < Data.define(:anchor, :head, :kind, :to_end)
      # @rbs @anchor: Position
      # @rbs @head: Position
      # @rbs @kind: Symbol
      # @rbs @to_end: bool

      #: () -> Selection
      def self.none
        Selection.new(Position.new(0, 0), Position.new(0, 0), :none, false)
      end

      # The cells the character at col of line takes from display column
      # dcol; the end of the line counts as one cell.
      #: (String, Integer, Integer, Integer) -> Integer
      def self.cells(line, col, dcol, tabstop)
        col < line.length ? DisplayWidth.cell(line[col, 1], dcol, tabstop) : 1
      end

      #: () -> bool
      def active?
        kind != :none
      end

      # The earlier of the two ends.
      #: () -> Position
      def start
        head.before?(anchor) ? head : anchor
      end

      # The later of the two ends.
      #: () -> Position
      def finish
        head.before?(anchor) ? anchor : head
      end

      #: () -> Integer
      def top
        anchor.row < head.row ? anchor.row : head.row
      end

      #: () -> Integer
      def bottom
        anchor.row < head.row ? head.row : anchor.row
      end

      #: (Integer) -> bool
      def covers?(row)
        active? && row >= top && row <= bottom
      end

      # The same ends as another kind.
      #: (Symbol, bool) -> Selection
      def as(other_kind, other_to_end)
        Selection.new(anchor, head, other_kind, other_to_end)
      end

      # The charwise range an operator works on: inclusive of the later
      # end, or reaching the start of the next line when that end rests on
      # the end of its line, which selects the line break (on the last
      # line of the buffer there is none to select).
      #: (Buffer) -> Range
      def char_range(buffer)
        s = start
        f = finish
        len = buffer.line(f.row).length
        if f.col >= len
          return Range.new(s, Position.new(f.row + 1, 0), :charwise, false) if f.row < buffer.line_count - 1
          return Range.new(s, Position.new(f.row, len), :charwise, false)
        end
        Range.new(s, f, :charwise, true)
      end

      # The rows of the selection as a linewise range.
      #: () -> Range
      def line_range
        Range.new(Position.new(top, 0), Position.new(bottom, 0), :linewise, true)
      end

      # Where a linewise operand starts, as Neovim computes it: column 0 of
      # the top row when the anchor is on it, the cursor otherwise.
      #: () -> Position
      def line_start
        anchor.row <= head.row ? Position.new(anchor.row, 0) : head
      end

      # The block in display columns: from the leftmost to the rightmost
      # cell of the anchor's and the head's characters.
      #: (Buffer, Integer) -> Block
      def block(buffer, tabstop)
        a_line = buffer.line(anchor.row)
        h_line = buffer.line(head.row)
        a_start = DisplayWidth.column(a_line, anchor.col, tabstop)
        h_start = DisplayWidth.column(h_line, head.col, tabstop)
        a_end = a_start + Selection.cells(a_line, anchor.col, a_start, tabstop) - 1
        h_end = h_start + Selection.cells(h_line, head.col, h_start, tabstop) - 1
        left = a_start < h_start ? a_start : h_start
        right = a_end > h_end ? a_end : h_end
        Block.new(top, bottom, left, right, to_end)
      end

      # The columns of row the selection covers.
      #: (Buffer, Integer, Integer) -> Span
      def span(buffer, row, tabstop)
        return Span.empty unless covers?(row)
        line = buffer.line(row)
        len = line.length
        return Span.new(0, len, true) if kind == :linewise
        return block(buffer, tabstop).span(line, tabstop) if kind == :blockwise
        s = start
        f = finish
        from = row == s.row ? s.col : 0
        from = len if from > len
        to = len
        eol = true
        if row == f.row
          eol = f.col >= len
          to = f.col + 1 unless eol
        end
        Span.new(from, to, eol)
      end
    end
  end
end
