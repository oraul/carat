require_relative "../domain/highlight"
require_relative "../domain/theme"
require_relative "../domain/color_depth"

module Carat
  module Adapters
    # The SGR sequence that starts a cell of each highlight group, and of
    # each group on the cursor line (Highlight::CURSOR_LINE_LAYER), built
    # once from the theme for the terminal's color depth: 24-bit colors as
    # 38;2 and 48;2, 256 colors as 38;5 and 48;5 with each 24-bit color
    # mapped to the nearest of the 6x6x6 cube and the gray ramp, and the
    # 16 basic colors as 30-37, 90-97, 40-47, and 100-107 from the theme's
    # own 16-color values with its 16-color attributes. A palette may give
    # its own 256-color index where the nearest would lose contrast. Every
    # sequence resets first (0), so a group never inherits the attributes
    # of the one before; Normal is the bare reset, which leaves the
    # terminal's own colors, unless the theme paints the background.
    class SgrTable
      CUBE = [0, 95, 135, 175, 215, 255]

      attr_reader :codes #: Array[String]

      #: (codes: Array[String]) -> void
      def initialize(codes:)
        @codes = codes
      end

      #: (Domain::Theme, Integer) -> SgrTable
      def self.from_theme(theme, colors)
        codes = []
        id = 0
        while id < Domain::Highlight::LIMIT
          codes << sequence(theme, id, colors)
          id += 1
        end
        new(codes: codes)
      end

      # The sequence of a group, the Normal one for an id out of range.
      #: (Integer) -> String
      def at(id)
        return @codes[0] if id < 0 || id >= @codes.length
        @codes[id]
      end

      # The sequence of one group at a color depth: at 16 colors the
      # group's 16-color attributes and basic colors.
      #: (Domain::Theme, Integer, Integer) -> String
      def self.sequence(theme, id, colors)
        out = +"\e[0"
        basic16 = colors == Domain::ColorDepth::COLORS_16
        attr = basic16 ? theme.attr16(id) : theme.attr(id)
        out << ";1" if attr & Domain::Theme::BOLD != 0
        out << ";3" if attr & Domain::Theme::ITALIC != 0
        out << ";4" if attr & Domain::Theme::UNDERLINE != 0
        out << ";7" if attr & Domain::Theme::REVERSE != 0
        if basic16
          basic(out, theme.fg16(id), 30, 90)
          basic(out, theme.bg16(id), 40, 100)
        else
          color(out, theme.fg(id), theme.fg256(id), "38", colors)
          color(out, theme.bg(id), theme.bg256(id), "48", colors)
        end
        out << "m"
        out
      end

      # Appends a basic color, 0 to 7 from low and 8 to 15 from high.
      #: (String, Integer, Integer, Integer) -> void
      def self.basic(out, index, low, high)
        return if index < 0
        out << ";"
        out << (index < 8 ? low + index : high + index - 8).to_s
      end

      # Appends a 24-bit color as 2;r;g;b, or as 5;n at 256 colors, the
      # palette's own index when it gives one (index 0 or more) and the
      # nearest otherwise, after the selector, 38 for the foreground and
      # 48 for the background.
      #: (String, Integer, Integer, String, Integer) -> void
      def self.color(out, rgb, index, selector, colors)
        return if rgb < 0
        out << ";" << selector
        if colors == Domain::ColorDepth::TRUECOLOR
          out << ";2;" << ((rgb >> 16) & 255).to_s << ";" << ((rgb >> 8) & 255).to_s << ";" << (rgb & 255).to_s
        else
          out << ";5;" << (index < 0 ? index_256(rgb) : index).to_s
        end
      end

      # The nearest color of the 256-color palette above the basic 16: a
      # cube color or a gray of the ramp, whichever is closer.
      #: (Integer) -> Integer
      def self.index_256(rgb)
        r = (rgb >> 16) & 255
        g = (rgb >> 8) & 255
        b = rgb & 255
        ri = level(r)
        gi = level(g)
        bi = level(b)
        cube = 16 + 36 * ri + 6 * gi + bi
        cube_distance = distance(r, g, b, CUBE[ri], CUBE[gi], CUBE[bi])
        average = (r + g + b) / 3
        step = average < 8 ? 0 : (average - 8 + 5) / 10
        step = 23 if step > 23
        gray = 8 + 10 * step
        gray_distance = distance(r, g, b, gray, gray, gray)
        gray_distance < cube_distance ? 232 + step : cube
      end

      # The index of the cube level nearest to a component.
      #: (Integer) -> Integer
      def self.level(value)
        best = 0
        i = 1
        while i < CUBE.length
          best = i if (CUBE[i] - value).abs < (CUBE[best] - value).abs
          i += 1
        end
        best
      end

      #: (Integer, Integer, Integer, Integer, Integer, Integer) -> Integer
      def self.distance(r, g, b, r2, g2, b2)
        (r - r2) * (r - r2) + (g - g2) * (g - g2) + (b - b2) * (b - b2)
      end
    end
  end
end
