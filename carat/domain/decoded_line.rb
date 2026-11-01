require_relative "utf8"
require_relative "display_width"

module Carat
  module Domain
    # A line decoded once for drawing and for measuring: its code points,
    # and for each the display column where it starts with the tabstop it
    # was decoded with, plus one more entry, the width of the whole line.
    # It has exactly as many code points as the line has characters, a
    # malformed byte decoding to U+FFFD, so a cursor column, a code point
    # index, indexes it directly. A plain line, printable ASCII only, keeps
    # no arrays: its code points are its bytes and its columns their
    # indexes. text is the line it was decoded from, which a cache compares
    # by identity. A Struct record, never changed after it is built.
    class DecodedLine < Struct.new(:text, :codes, :cols, :tabstop, :plain)
      NONE = Array.new(0, 0)

      # @rbs @text: String
      # @rbs @codes: Array[Integer]
      # @rbs @cols: Array[Integer]
      # @rbs @tabstop: Integer
      # @rbs @plain: bool

      #: (String, Integer) -> DecodedLine
      def self.decode(text, tabstop)
        return new(text, NONE, NONE, tabstop, true) if plain?(text)
        n = text.length
        codes = Array.new(n, 0)
        cols = Array.new(n + 1, 0)
        bytes = text.bytesize
        i = 0
        k = 0
        dcol = 0
        while k < n
          code = Utf8::REPLACEMENT
          if i < bytes
            code = text.getbyte(i).to_i
            if code < 0x80
              i += 1
            else
              size = Utf8.size_at(text, i, bytes)
              code = Utf8.code_at(text, i, size)
              i += size
            end
          end
          codes[k] = code
          cols[k] = dcol
          dcol += DisplayWidth.code_cells(code, dcol, tabstop)
          k += 1
        end
        cols[n] = dcol
        new(text, codes, cols, tabstop, false)
      end

      # Whether every byte of text is printable ASCII, a space to a tilde.
      #: (String) -> bool
      def self.plain?(text)
        bytes = text.bytesize
        i = 0
        while i < bytes
          b = text.getbyte(i).to_i
          return false if b < 32 || b > 126
          i += 1
        end
        true
      end

      # The number of code points.
      #: () -> Integer
      def size
        plain ? text.bytesize : codes.length
      end

      #: (Integer) -> Integer
      def code(i)
        plain ? text.getbyte(i).to_i : codes[i]
      end

      # The display column where code point i starts; i at or past the end
      # gives the width of the line.
      #: (Integer) -> Integer
      def col(i)
        n = size
        return width if i >= n
        return 0 if i < 0
        plain ? i : cols[i]
      end

      # The cells code point i takes.
      #: (Integer) -> Integer
      def cells(i)
        plain ? 1 : cols[i + 1] - cols[i]
      end

      #: () -> Integer
      def width
        plain ? text.bytesize : cols[codes.length]
      end

      # The code point whose cells cover display column vcol, or the
      # number of code points when the line ends before it, found by
      # halving because the columns only grow.
      #: (Integer) -> Integer
      def index_at(vcol)
        n = size
        return n if vcol >= width
        return vcol if plain
        low = 0
        high = n - 1
        while low < high
          mid = (low + high + 1) / 2
          if cols[mid] <= vcol
            low = mid
          else
            high = mid - 1
          end
        end
        low
      end
    end
  end
end
