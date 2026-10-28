module Carat
  module Domain
    # One cell of a frame: a code point, its display width, and a highlight
    # group id. The character is held as an integer code, not a string, so a
    # cell never shares string storage with a buffer line. A width-0 cell is
    # the continuation half of a wide character and carries code 0.
    class Cell
      attr_accessor :code #: Integer
      attr_accessor :width #: Integer
      attr_accessor :hl #: Integer

      #: (Integer, Integer, Integer) -> void
      def initialize(code, width, hl)
        @code = code
        @width = width
        @hl = hl
      end

      # The character this cell shows, or "" for a continuation cell.
      #: () -> String
      def char
        @code == 0 ? "" : [@code].pack("U")
      end

      #: (Cell) -> bool
      def same?(other)
        @code == other.code && @width == other.width && @hl == other.hl
      end
    end
  end
end
