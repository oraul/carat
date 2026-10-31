module Carat
  module Domain
    # The signs one plugin placed in one buffer: the plugin's name, its
    # priority (its registration position; the lowest number shows when
    # two plugins mark a row), the glyphs it used, and one mark per line of
    # the buffer, 0 for none and k for the k-th glyph. The buffer moves the
    # marks with its lines. A Struct record.
    class SignLayer < Struct.new(:owner, :priority, :glyphs, :marks)
      # @rbs @owner: String
      # @rbs @priority: Integer
      # @rbs @glyphs: Array[String]
      # @rbs @marks: Array[Integer]

      # The glyph list is stored through the writer, so the empty literal
      # takes the pinned type; marks starts with a 0 per line.
      #: (String, Integer, Integer) -> void
      def initialize(owner, priority, line_count)
        super()
        self.owner = owner
        self.priority = priority
        self.glyphs = []
        marks = []
        i = 0
        while i < line_count
          marks << 0
          i += 1
        end
        self.marks = marks
      end

      # Puts the glyph on the row, replacing this layer's own mark there.
      #: (Integer, String) -> void
      def place(row, glyph)
        index = glyphs.index(glyph)
        if index.nil?
          glyphs << glyph
          index = glyphs.length - 1
        end
        marks[row] = index + 1
        nil
      end

      # The glyph on the row, "" for none.
      #: (Integer) -> String
      def glyph_at(row)
        mark = marks[row]
        return "" if mark.nil? || mark == 0
        glyphs[mark - 1]
      end

      # How many rows carry a mark.
      #: () -> Integer
      def count
        n = 0
        i = 0
        while i < marks.length
          n += 1 if marks[i] != 0
          i += 1
        end
        n
      end
    end
  end
end
