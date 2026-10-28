module Carat
  module Domain
    # The current position plus want_col, the column aimed for when moving
    # vertically through shorter lines (Vim's curswant). A want_col of -1
    # means "the end of the line", set by $.
    class Cursor
      attr_accessor :row #: Integer
      attr_accessor :col #: Integer
      attr_accessor :want_col #: Integer

      #: (Integer, Integer) -> void
      def initialize(row, col)
        @row = row
        @col = col
        @want_col = col
      end

      #: () -> Position
      def position
        Position.new(@row, @col)
      end

      # Moves horizontally: the new column becomes the wanted one.
      #: (Integer, Integer) -> void
      def move_to(row, col)
        @row = row
        @col = col
        @want_col = col
      end

      #: () -> Array[Integer]
      def to_a
        [@row, @col]
      end
    end
  end
end
