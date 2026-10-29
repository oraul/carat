module Carat
  module Domain
    # Display width of a code point in terminal cells: 2 for the wide ranges
    # (CJK, Hangul, fullwidth forms, the common emoji blocks), 0 for
    # combining marks, 1 otherwise. A complete East Asian width table is a
    # later change.
    module DisplayWidth
      #: (Integer) -> Integer
      def self.of(code)
        return 0 if code >= 0x0300 && code <= 0x036F
        return 2 if code >= 0x1100 && code <= 0x115F
        return 2 if code >= 0x2E80 && code <= 0xA4CF && code != 0x303F
        return 2 if code >= 0xAC00 && code <= 0xD7A3
        return 2 if code >= 0xF900 && code <= 0xFAFF
        return 2 if code >= 0xFE30 && code <= 0xFE4F
        return 2 if code >= 0xFF00 && code <= 0xFF60
        return 2 if code >= 0xFFE0 && code <= 0xFFE6
        return 2 if code >= 0x1F300 && code <= 0x1F64F
        return 2 if code >= 0x1F900 && code <= 0x1F9FF
        return 2 if code >= 0x20000 && code <= 0x3FFFD
        1
      end

      #: (String) -> Integer
      def self.of_char(ch)
        of(ch.ord)
      end

      # True for the code points no cell may hold raw: the C0 controls
      # below 32, delete (U+007F), and the C1 controls U+0080 to U+009F,
      # whose UTF-8 forms some terminals read as escape introducers.
      #: (Integer) -> bool
      def self.control?(code)
        return true if code < 32
        code >= 0x7F && code <= 0x9F
      end
    end
  end
end
