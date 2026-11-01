module Carat
  module Domain
    # A value view of one cell of a frame, which Frame#cell builds on
    # demand for tests: a code point, its display width, and a highlight
    # group id. A frame keeps its cells in flat integer arrays and never
    # holds Cell values. A width-0 cell is the continuation half of a wide
    # character and carries code 0. A Struct record.
    class Cell < Struct.new(:code, :width, :hl)
      # @rbs @code: Integer
      # @rbs @width: Integer
      # @rbs @hl: Integer

      # The character this cell shows, or "" for a continuation cell.
      #: () -> String
      def char
        code == 0 ? "" : [code].pack("U")
      end

      #: (Cell) -> bool
      def same?(other)
        code == other.code && width == other.width && hl == other.hl
      end
    end
  end
end
