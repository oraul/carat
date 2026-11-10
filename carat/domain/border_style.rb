module Carat
  module Domain
    # The border styles of option.winborder, Neovim's names, and the code
    # points each draws: the top-left, top-right, bottom-left, and
    # bottom-right corners, the horizontal edge, and the vertical side.
    # "none" draws no edge around a float; its set is the blank one,
    # used by the boxes that keep their edge, the notifications'. The
    # ASCII form replaces the line characters of the three styles that
    # have them. Each set is a frozen constant, so a lookup allocates
    # nothing.
    module BorderStyle
      STYLES = ["none", "single", "double", "rounded", "solid"].freeze
      DEFAULT = "rounded"

      SINGLE = [0x250C, 0x2510, 0x2514, 0x2518, 0x2500, 0x2502].freeze
      DOUBLE = [0x2554, 0x2557, 0x255A, 0x255D, 0x2550, 0x2551].freeze
      ROUNDED = [0x256D, 0x256E, 0x2570, 0x256F, 0x2500, 0x2502].freeze
      BLANK = [0x20, 0x20, 0x20, 0x20, 0x20, 0x20].freeze
      ASCII = [0x2B, 0x2B, 0x2B, 0x2B, 0x2D, 0x7C].freeze

      # The index of each code point in a set.
      TOP_LEFT = 0
      TOP_RIGHT = 1
      BOTTOM_LEFT = 2
      BOTTOM_RIGHT = 3
      HORIZONTAL = 4
      VERTICAL = 5

      #: (String) -> bool
      def self.style?(name)
        STYLES.include?(name)
      end

      # Whether a style draws an edge around a float.
      #: (String) -> bool
      def self.edged?(name)
        name != "none"
      end

      # The code points of a style, its ASCII form when ascii.
      #: (String, bool) -> Array[Integer]
      def self.glyphs(name, ascii)
        return BLANK if name == "none" || name == "solid"
        return ASCII if ascii
        return SINGLE if name == "single"
        return DOUBLE if name == "double"
        ROUNDED
      end
    end
  end
end
