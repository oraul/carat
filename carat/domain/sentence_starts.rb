require_relative "position"

module Carat
  module Domain
    # Where sentences start, in buffer order, as parallel row and column
    # arrays: Spinel pins Array[Integer] but not an array of positions, and
    # an untyped position would make every comparison a dynamic call. A
    # Struct record built by Motions.sentence_starts.
    class SentenceStarts < Struct.new(:rows, :cols)
      # @rbs @rows: Array[Integer]
      # @rbs @cols: Array[Integer]

      #: () -> void
      def initialize
        super([], [])
      end

      # Adds a start unless it is not after the last one, which keeps the
      # list ordered and without duplicates.
      #: (Integer, Integer) -> void
      def add(row, col)
        last = rows.length - 1
        return if last >= 0 && (rows[last] > row || (rows[last] == row && cols[last] >= col))
        rows << row
        cols << col
      end

      #: () -> Integer
      def length
        rows.length
      end

      # The readers go through methods with a return signature: an indexed
      # element is nullable to the compiler, and passing it straight to
      # Position.new would widen the position's members.
      #: (Integer) -> Integer
      def row(i)
        rows[i]
      end

      #: (Integer) -> Integer
      def col(i)
        cols[i]
      end

      #: (Integer) -> Position
      def position(i)
        Position.new(row(i), col(i))
      end

      # Whether start i comes after pos.
      #: (Integer, Position) -> bool
      def after?(i, pos)
        row(i) > pos.row || (row(i) == pos.row && col(i) > pos.col)
      end

      # Whether start i comes before pos.
      #: (Integer, Position) -> bool
      def before?(i, pos)
        row(i) < pos.row || (row(i) == pos.row && col(i) < pos.col)
      end

      # The index of the last start at or before pos, or 0.
      #: (Position) -> Integer
      def index_at(pos)
        i = 0
        i += 1 while i + 1 < rows.length && !after?(i + 1, pos)
        i
      end
    end
  end
end
