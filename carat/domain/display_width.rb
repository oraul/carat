require_relative "utf8"

module Carat
  module Domain
    # Display width of a code point in terminal cells: 2 for the wide ranges
    # (CJK, Hangul, fullwidth forms, the common emoji blocks), 0 for
    # combining marks, 1 otherwise, including the private use areas where
    # Nerd Font glyphs live, which a terminal draws in one cell. A complete
    # East Asian width table is a later change and must keep that.
    module DisplayWidth
      #: (Integer) -> Integer
      def self.of(code)
        return 0 if code >= 0x0300 && code <= 0x036F
        return 1 if private_use?(code)
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

      # The private use areas: U+E000 to U+F8FF in the basic plane and the
      # supplementary plane U+F0000 to U+FFFFD.
      #: (Integer) -> bool
      def self.private_use?(code)
        return true if code >= 0xE000 && code <= 0xF8FF
        code >= 0xF0000 && code <= 0xFFFFD
      end

      # The cells one character takes when it starts at display column
      # dcol: a tab reaches the next tabstop, a C0 control takes two as ^X,
      # delete and the C1 controls take four as <xx>, a format code point
      # six as <xxxx>, and every other code point its display width.
      #: (String, Integer, Integer) -> Integer
      def self.cell(ch, dcol, tabstop)
        code_cells(Utf8.code_of(ch), dcol, tabstop)
      end

      # cell for a code point rather than a one-character string.
      #: (Integer, Integer, Integer) -> Integer
      def self.code_cells(code, dcol, tabstop)
        if code == 9
          ts = tabstop > 0 ? tabstop : 8
          return ts - (dcol % ts)
        end
        return 2 if code < 32
        return 4 if control?(code)
        return 6 if format_char?(code)
        of(code)
      end

      # The display column where code point column col of line starts; a
      # column past the end gives the width of the whole line. The line is
      # walked by bytes, so a long UTF-8 line costs no more than an ASCII
      # one.
      #: (String, Integer, Integer) -> Integer
      def self.column(line, col, tabstop)
        bytes = line.bytesize
        dcol = 0
        i = 0
        k = 0
        while k < col && i < bytes
          code = line.getbyte(i).to_i
          if code < 0x80
            i += 1
          else
            size = Utf8.size_at(line, i, bytes)
            code = Utf8.code_at(line, i, size)
            i += size
          end
          dcol += code_cells(code, dcol, tabstop)
          k += 1
        end
        dcol
      end

      # The code point column of the character whose cells cover display
      # column vcol, or the line length when the line ends before it.
      #: (String, Integer, Integer) -> Integer
      def self.col_at(line, vcol, tabstop)
        bytes = line.bytesize
        dcol = 0
        i = 0
        k = 0
        while i < bytes
          code = line.getbyte(i).to_i
          if code < 0x80
            i += 1
          else
            size = Utf8.size_at(line, i, bytes)
            code = Utf8.code_at(line, i, size)
            i += size
          end
          w = code_cells(code, dcol, tabstop)
          return k if dcol + w > vcol
          dcol += w
          k += 1
        end
        line.length
      end

      # The cells text takes from byte from to its end as Frame#put writes
      # it: each code point its width, a control one cell, as the
      # replacement character it becomes. Walked by bytes, so nothing is
      # allocated.
      #: (String, Integer) -> Integer
      def self.text_width(text, from)
        bytes = text.bytesize
        i = from < 0 ? 0 : from
        total = 0
        while i < bytes
          code = text.getbyte(i).to_i
          if code < 0x80
            i += 1
          else
            size = Utf8.size_at(text, i, bytes)
            code = Utf8.code_at(text, i, size)
            i += size
          end
          total += control?(code) ? 1 : of(code)
        end
        total
      end

      # The byte length of the longest prefix of text that takes at most
      # width cells as text_width measures it: it stops before the first
      # character that would pass the width, so a combining mark stays
      # with the character before it. A negative width answers 0.
      #: (String, Integer) -> Integer
      def self.bytes_within(text, width)
        bytes = text.bytesize
        i = 0
        total = 0
        while i < bytes
          code = text.getbyte(i).to_i
          size = 1
          if code >= 0x80
            size = Utf8.size_at(text, i, bytes)
            code = Utf8.code_at(text, i, size)
          end
          total += control?(code) ? 1 : of(code)
          break if total > width
          i += size
        end
        i
      end

      # The text cut at a character boundary to at most width cells; the
      # text itself when it fits.
      #: (String, Integer) -> String
      def self.cut(text, width)
        size = bytes_within(text, width)
        out = text
        out = text.byteslice(0, size).to_s if size < text.bytesize
        out
      end

      # A new string of the text cut to width cells and padded with
      # spaces to exactly width, never a negative pad.
      #: (String, Integer) -> String
      def self.fit(text, width)
        out = +""
        out << cut(text, width)
        used = text_width(out, 0)
        out << " " * (width - used) if used < width
        out
      end

      # True for the code points no cell may hold raw: the C0 controls
      # below 32, delete (U+007F), and the C1 controls U+0080 to U+009F,
      # whose UTF-8 forms some terminals read as escape introducers.
      #: (Integer) -> bool
      def self.control?(code)
        return true if code < 32
        code >= 0x7F && code <= 0x9F
      end

      # True for the code points a terminal draws in no cell or uses to
      # reorder a row, which the line painter shows as <xxxx>: U+061C,
      # U+200B to U+200F (zero-width and directional marks), U+2028 to
      # U+202E (separators, embeddings, and overrides), U+2060 to U+206F
      # (word joiner, isolates, invisible operators), and U+FEFF.
      #: (Integer) -> bool
      def self.format_char?(code)
        return false if code < 0x061C
        return true if code == 0x061C || code == 0xFEFF
        return true if code >= 0x200B && code <= 0x200F
        return true if code >= 0x2028 && code <= 0x202E
        code >= 0x2060 && code <= 0x206F
      end
    end
  end
end
