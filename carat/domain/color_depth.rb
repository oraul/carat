module Carat
  module Domain
    # How many colors the terminal shows, from COLORTERM and TERM as the
    # terminal driver reads them once at start: 24-bit when COLORTERM says
    # truecolor or 24bit, the 16 basic colors when TERM names a terminal
    # that has only those, 256 otherwise.
    module ColorDepth
      TRUECOLOR = 16_777_216
      COLORS_256 = 256
      COLORS_16 = 16

      # TERM values of terminals with the 16 basic colors only; a name
      # ending in -16color is one too.
      BASIC_TERMS = ["linux", "ansi", "vt100", "vt102", "vt220", "cons25", "xterm-color"]

      # The depth for the two environment values, "" for an unset one.
      #: (String, String) -> Integer
      def self.detect(colorterm, term)
        return TRUECOLOR if colorterm == "truecolor" || colorterm == "24bit"
        return COLORS_16 if BASIC_TERMS.include?(term) || term.end_with?("-16color")
        COLORS_256
      end
    end
  end
end
