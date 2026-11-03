require_relative "highlight"

module Carat
  module Domain
    # How each highlight group looks: per group id, a 24-bit foreground
    # and background (-1 for the terminal's own), a foreground and
    # background among the 16 basic colors for terminals that have only
    # those (-1 for the terminal's own), and attribute bits. The 16-color
    # values are given by hand, as Vim themes give ctermfg, because the
    # nearest basic color to most theme colors is white. A Data value.
    class Theme < Data.define(:name, :fgs, :bgs, :fgs16, :bgs16, :attrs)
      BOLD = 1
      ITALIC = 2
      UNDERLINE = 4
      REVERSE = 8

      # @rbs @name: String
      # @rbs @fgs: Array[Integer]
      # @rbs @bgs: Array[Integer]
      # @rbs @fgs16: Array[Integer]
      # @rbs @bgs16: Array[Integer]
      # @rbs @attrs: Array[Integer]

      # Builds a theme from rows of six integers, flat: group id,
      # foreground, background, 16-color foreground, 16-color background,
      # and attributes. A group no row names keeps the terminal's colors.
      #: (String, Array[Integer]) -> Theme
      def self.from_rows(name, rows)
        fgs = Array.new(Highlight::COUNT, -1)
        bgs = Array.new(Highlight::COUNT, -1)
        fgs16 = Array.new(Highlight::COUNT, -1)
        bgs16 = Array.new(Highlight::COUNT, -1)
        attrs = Array.new(Highlight::COUNT, 0)
        i = 0
        while i + 5 < rows.length
          id = rows[i]
          fgs[id] = rows[i + 1]
          bgs[id] = rows[i + 2]
          fgs16[id] = rows[i + 3]
          bgs16[id] = rows[i + 4]
          attrs[id] = rows[i + 5]
          i += 6
        end
        new(name: name, fgs: fgs, bgs: bgs, fgs16: fgs16, bgs16: bgs16, attrs: attrs)
      end

      #: (Integer) -> Integer
      def fg(id)
        fgs[id]
      end

      #: (Integer) -> Integer
      def bg(id)
        bgs[id]
      end

      #: (Integer) -> Integer
      def fg16(id)
        fgs16[id]
      end

      #: (Integer) -> Integer
      def bg16(id)
        bgs16[id]
      end

      #: (Integer) -> Integer
      def attr(id)
        attrs[id]
      end
    end
  end
end
