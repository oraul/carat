module Carat
  module Domain
    # The signs one plugin placed in one buffer: the plugin's name, its
    # priority (its registration position; the lowest number shows when
    # two plugins mark a row), the glyphs it used, each with the highlight
    # group it is drawn in, and one mark per line of the buffer, 0 for none
    # and k for the k-th glyph and group. The buffer moves the
    # marks with its lines. A Struct record.
    class SignLayer < Struct.new(:owner, :priority, :glyphs, :groups, :marks, keyword_init: true)
      # @rbs @owner: String
      # @rbs @priority: Integer
      # @rbs @glyphs: Array[String]
      # @rbs @groups: Array[Integer]
      # @rbs @marks: Array[Integer]

      # The glyph and group lists are stored through the writers, so the
      # empty literals take the pinned types; marks starts with a 0 per line.
      #: (owner: String, priority: Integer, line_count: Integer) -> void
      def initialize(owner:, priority:, line_count:)
        super()
        self.owner = owner
        self.priority = priority
        self.glyphs = []
        self.groups = []
        marks = []
        i = 0
        while i < line_count
          marks << 0
          i += 1
        end
        self.marks = marks
      end

      # Puts the glyph, drawn in the group, on the row, replacing this
      # layer's own mark there.
      #: (Integer, String, Integer) -> void
      def place(row, glyph, group)
        index = index_of(glyph, group)
        if index < 0
          glyphs << glyph
          groups << group
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

      # The group of the glyph on the row, Highlight::SIGN_COLUMN for none.
      #: (Integer) -> Integer
      def group_at(row)
        mark = marks[row]
        return Highlight::SIGN_COLUMN if mark.nil? || mark == 0
        groups[mark - 1]
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

      private

      # The index of the glyph drawn in the group, -1 when the layer has
      # not used that pair.
      #: (String, Integer) -> Integer
      def index_of(glyph, group)
        i = 0
        while i < glyphs.length
          return i if glyphs[i] == glyph && groups[i] == group
          i += 1
        end
        -1
      end
    end
  end
end
