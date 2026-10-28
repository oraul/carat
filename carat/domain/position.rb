module Carat
  module Domain
    # A (row, col) pair. Columns count code points; display width is a
    # presenter concern. A Data value: equal by value, frozen, usable as a
    # hash key.
    class Position < Data.define(:row, :col)
      #: (Position) -> bool
      def before?(other)
        row < other.row || (row == other.row && col < other.col)
      end

      #: () -> Array[Integer]
      def to_a
        [row, col]
      end
    end
  end
end
