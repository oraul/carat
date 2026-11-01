require_relative "display_width"

module Carat
  module Domain
    # A blockwise selection in display columns: the rows from top to bottom
    # and the display columns from left to right, both inclusive, or to the
    # end of every row when to_end is set by "$". A Data value.
    class Block < Data.define(:top, :bottom, :left, :right, :to_end)
      # @rbs @top: Integer
      # @rbs @bottom: Integer
      # @rbs @left: Integer
      # @rbs @right: Integer
      # @rbs @to_end: bool

      # The characters of line whose cells meet the block's columns, taken
      # whole, so a tab or a wide character on the edge is included; the
      # line break counts when the cell after the last character lies in
      # the block or the block runs to the end of the line.
      #: (String, Integer) -> Span
      def span(line, tabstop)
        from = -1
        to = line.length
        dcol = 0
        i = 0
        while i < line.length
          w = DisplayWidth.cell(line[i, 1], dcol, tabstop)
          if !to_end && dcol > right
            to = i
            break
          end
          from = i if from < 0 && dcol + w > left
          dcol += w
          i += 1
        end
        from = line.length if from < 0
        to = from if to < from
        width = DisplayWidth.column(line, line.length, tabstop)
        Span.new(from, to, to_end || (width >= left && width <= right))
      end

      # Whether line ends before the block's first column, as Vim's
      # is_short: block insert leaves such a row alone.
      #: (String, Integer) -> bool
      def short?(line, tabstop)
        DisplayWidth.column(line, line.length, tabstop) < left
      end
    end
  end
end
