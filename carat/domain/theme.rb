require_relative "highlight"

module Carat
  module Domain
    # How each highlight group looks: per group id, a 24-bit foreground
    # and background (-1 for the terminal's own), a 256-color index for
    # each (-1 to take the nearest one of the 24-bit color), a foreground
    # and background among the 16 basic colors for terminals that have
    # only those (-1 for none), and attribute bits at 24-bit and 256
    # colors and at 16 colors, where an attribute such as reverse video
    # stands in for a color the basic set lacks. Built by Themes. A Data
    # value.
    class Theme < Data.define(:name, :fgs, :bgs, :fgs256, :bgs256, :fgs16, :bgs16, :attrs, :attrs16)
      BOLD = 1
      ITALIC = 2
      UNDERLINE = 4
      REVERSE = 8

      # @rbs @name: String
      # @rbs @fgs: Array[Integer]
      # @rbs @bgs: Array[Integer]
      # @rbs @fgs256: Array[Integer]
      # @rbs @bgs256: Array[Integer]
      # @rbs @fgs16: Array[Integer]
      # @rbs @bgs16: Array[Integer]
      # @rbs @attrs: Array[Integer]
      # @rbs @attrs16: Array[Integer]

      #: (Integer) -> Integer
      def fg(id)
        fgs[id]
      end

      #: (Integer) -> Integer
      def bg(id)
        bgs[id]
      end

      #: (Integer) -> Integer
      def fg256(id)
        fgs256[id]
      end

      #: (Integer) -> Integer
      def bg256(id)
        bgs256[id]
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

      #: (Integer) -> Integer
      def attr16(id)
        attrs16[id]
      end

      # Whether the theme paints the background: Normal has a color of its
      # own instead of the terminal's.
      #: () -> bool
      def paints_background?
        bgs[Highlight::NORMAL] >= 0
      end
    end
  end
end
