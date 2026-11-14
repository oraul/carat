module Carat
  module Domain
    # Where and how a floating window shows: the anchor its offset counts
    # from ("editor" for the screen's top-left cell, "cursor" for the
    # cursor cell of the layout's current window), the row and column
    # offset of the box's top-left corner, the size of its text area in
    # rows and columns, whether a one-cell border surrounds it, the title
    # on the border's top edge, and its z order, higher drawn on top. A
    # Data value.
    class FloatSpec < Data.define(:anchor, :row, :col, :height, :width, :border, :title, :z)
      ANCHORS = ["editor", "cursor"].freeze
      Z_MAX = 1000
      # The largest offset a row or a column may have either way, far past
      # any screen and far from the integer limits the anchor is added to.
      OFFSET_MAX = 10_000

      # @rbs @anchor: String
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @height: Integer
      # @rbs @width: Integer
      # @rbs @border: bool
      # @rbs @title: String
      # @rbs @z: Integer

      # The cells the border takes on each side, 0 or 1.
      #: () -> Integer
      def edge
        border ? 1 : 0
      end

      #: () -> bool
      def cursor_anchored?
        anchor == "cursor"
      end

      # The same spec at another offset.
      #: (Integer, Integer) -> FloatSpec
      def moved(to_row, to_col)
        FloatSpec.new(anchor: anchor, row: to_row, col: to_col, height: height, width: width, border: border, title: title, z: z)
      end

      # Why the values cannot make a float, "" when they can.
      #: (String, Integer, Integer, Integer, Integer, Integer) -> String
      def self.refusal(anchor, row, col, height, width, z)
        return "No anchor #{anchor}: editor or cursor" unless ANCHORS.include?(anchor)
        offset = offset_refusal(row, col)
        return offset unless offset.empty?
        return "A float needs at least one row and one column" if height < 1 || width < 1
        return "No z order #{z}: 0 to #{Z_MAX}" if z < 0 || z > Z_MAX
        ""
      end

      # Why a row and column offset cannot place a float, "" when they
      # can: each lies within OFFSET_MAX either way, the row checked first.
      #: (Integer, Integer) -> String
      def self.offset_refusal(row, col)
        bad = row
        bad = col if row.abs <= OFFSET_MAX
        return "" if bad.abs <= OFFSET_MAX
        "No offset #{bad}: -#{OFFSET_MAX} to #{OFFSET_MAX}"
      end
    end
  end
end
