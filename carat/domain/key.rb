module Carat
  module Domain
    # Key codes. Printable code points are themselves, control characters are
    # their byte, special keys are codes above the Unicode range, and Alt is
    # a flag bit.
    module Key
      NUL = 0
      TAB = 9
      NL = 10
      CR = 13
      ESC = 27
      SPACE = 32
      BS = 127
      CTRL_H = 8

      SPECIAL = 0x110000
      UP = SPECIAL + 1
      DOWN = SPECIAL + 2
      LEFT = SPECIAL + 3
      RIGHT = SPECIAL + 4
      HOME = SPECIAL + 5
      END_KEY = SPECIAL + 6
      INSERT = SPECIAL + 7
      DELETE = SPECIAL + 8
      PAGE_UP = SPECIAL + 9
      PAGE_DOWN = SPECIAL + 10
      F1 = SPECIAL + 11
      F2 = SPECIAL + 12
      F3 = SPECIAL + 13
      F4 = SPECIAL + 14
      F5 = SPECIAL + 15
      F6 = SPECIAL + 16
      F7 = SPECIAL + 17
      F8 = SPECIAL + 18
      F9 = SPECIAL + 19
      F10 = SPECIAL + 20
      F11 = SPECIAL + 21
      F12 = SPECIAL + 22
      UNKNOWN = SPECIAL + 99

      ALT = 0x400000

      # A key that inserts itself as text: a code point at or above space
      # that is not a special key, not Alt-flagged, and not DEL.
      #: (Integer) -> bool
      def self.printable?(code)
        code >= SPACE && code < SPECIAL && code != BS
      end

      #: (Integer) -> bool
      def self.alt?(code)
        (code & ALT) != 0
      end

      #: (Integer) -> Integer
      def self.base(code)
        code & ~ALT
      end

      # The character a printable code stands for.
      #: (Integer) -> String
      def self.char(code)
        [code].pack("U")
      end
    end
  end
end
