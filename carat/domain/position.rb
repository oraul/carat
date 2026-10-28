module Carat
  module Domain
    # A (row, col) pair. Columns count code points; display width is a
    # presenter concern.
    class Position
      attr_reader :row #: Integer
      attr_reader :col #: Integer

      #: (Integer, Integer) -> void
      def initialize(row, col)
        @row = row
        @col = col
      end

      #: (Position) -> bool
      def ==(other)
        @row == other.row && @col == other.col
      end

      #: (Position) -> bool
      def before?(other)
        @row < other.row || (@row == other.row && @col < other.col)
      end

      #: () -> Array[Integer]
      def to_a
        [@row, @col]
      end
    end
  end
end
