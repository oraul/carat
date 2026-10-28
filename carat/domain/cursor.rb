module Carat
  module Domain
    # The current position plus want_col, the column aimed for when moving
    # vertically through shorter lines (Vim's curswant). A want_col of -1
    # means "the end of the line", set by $. A Struct record: mutable, with
    # a reader and a writer per member.
    class Cursor < Struct.new(:row, :col, :want_col)
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @want_col: Integer

      #: (Integer, Integer) -> void
      def initialize(row, col)
        super(row, col, col)
      end

      #: () -> Position
      def position
        Position.new(row, col)
      end

      # Moves horizontally: the new column becomes the wanted one.
      #: (Integer, Integer) -> void
      def move_to(row, col)
        self.row = row
        self.col = col
        self.want_col = col
      end

      # The position as a pair, without want_col.
      #: () -> Array[Integer]
      def to_a
        [row, col]
      end
    end
  end
end
