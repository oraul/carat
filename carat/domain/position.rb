module Carat
  module Domain
    # A (row, col) pair. Columns count code points; display width is a
    # presenter concern. A Data value: equal by value, frozen, usable as a
    # hash key.
    class Position < Data.define(:row, :col)
      # The position itself, typed as never nil: a nullable local keeps its
      # nullable type after a nil check, and reading its members would widen
      # whatever they are stored into.
      #: (Position?) -> Position
      def self.sure(pos)
        pos.nil? ? Position.new(0, 0) : pos
      end

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
