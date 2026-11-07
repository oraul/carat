module Carat
  module Domain
    # Text from outside the editor (a language server's name or message)
    # made safe for the screen: C0 controls, DEL, and C1 controls are
    # dropped, so no escape sequence reaches the terminal, a byte outside a
    # well-formed UTF-8 sequence becomes U+FFFD, and the result is cut at a
    # character boundary at most a limit of bytes long. Walks bytes with
    # Utf8, since Spinel's character methods group illegal bytes.
    module ControlText
      REPLACEMENT = "\u{FFFD}"

      # The text without control characters, at most limit bytes.
      #: (String, Integer) -> String
      def self.strip(text, limit)
        cleaned(text, limit, false)
      end

      # The text as one line: each line feed, carriage return, or tab is a
      # space, every other control dropped, at most limit bytes.
      #: (String, Integer) -> String
      def self.line(text, limit)
        cleaned(text, limit, true)
      end

      # The most bytes of raw text plain reads, so a hostile megabyte costs
      # no more than this.
      RAW_LIMIT = 4096

      # Text a program wrote for a terminal (a completion's label) as one
      # line: whole escape sequences dropped first, so no parameter of one
      # is left as text, then as line. A sequence is ESC [ with parameter
      # bytes and a final byte; ESC ], P, X, ^, or _ up to BEL, ESC \, or
      # the C1 ST; ESC and one character; U+009B and U+009D read as ESC [
      # and ESC ]. An unterminated string drops the rest of the text.
      #: (String, Integer) -> String
      def self.plain(text, limit)
        raw = text.bytesize > RAW_LIMIT ? text.byteslice(0, RAW_LIMIT).to_s : text
        line(without_sequences(raw), limit)
      end

      # The text with its escape sequences taken out.
      #: (String) -> String
      def self.without_sequences(text)
        out = +""
        len = text.bytesize
        start = 0
        i = 0
        while i < len
          b = text.getbyte(i).to_i
          if b == 0x1B || (b == 0xC2 && (text.getbyte(i + 1).to_i == 0x9B || text.getbyte(i + 1).to_i == 0x9D))
            out << text.byteslice(start, i - start).to_s
            i = sequence_end(text, i, len)
            start = i
          else
            i += 1
          end
        end
        out << text.byteslice(start, len - start).to_s
        out
      end

      # The byte after the escape sequence that starts at i.
      #: (String, Integer, Integer) -> Integer
      def self.sequence_end(text, i, len)
        kind = text.getbyte(i + 1).to_i
        kind = 0x5B if text.getbyte(i).to_i == 0xC2 && kind == 0x9B
        kind = 0x5D if text.getbyte(i).to_i == 0xC2 && kind == 0x9D
        j = i + 2
        return len if j > len
        if kind == 0x5B
          j += 1 while j < len && text.getbyte(j).to_i >= 0x20 && text.getbyte(j).to_i <= 0x3F
          j += 1 if j < len && text.getbyte(j).to_i >= 0x40 && text.getbyte(j).to_i <= 0x7E
          return j
        end
        return string_end(text, j, len) if kind == 0x5D || kind == 0x50 || kind == 0x58 || kind == 0x5E || kind == 0x5F
        kind >= 0x20 && kind < 0x7F ? j : i + 1
      end

      # The byte after the terminator of a string sequence from j: BEL,
      # ESC \, or the C1 ST; the text's end when there is none.
      #: (String, Integer, Integer) -> Integer
      def self.string_end(text, j, len)
        while j < len
          b = text.getbyte(j).to_i
          return j + 1 if b == 0x07
          return j + 2 if b == 0x1B && text.getbyte(j + 1).to_i == 0x5C
          return j + 2 if b == 0xC2 && text.getbyte(j + 1).to_i == 0x9C
          j += 1
        end
        len
      end

      # The kept characters up to limit bytes, a break or tab as a space
      # when spaces is true.
      #: (String, Integer, bool) -> String
      def self.cleaned(text, limit, spaces)
        out = +""
        len = text.bytesize
        i = 0
        while i < len
          b = text.getbyte(i).to_i
          size = b < 0x80 ? 1 : Utf8.size_at(text, i, len)
          piece = spaces && (b == 0x0A || b == 0x0D || b == 0x09) ? " " : piece_at(text, i, b, size)
          break if out.bytesize + piece.bytesize > limit
          out << piece
          i += size
        end
        out
      end

      # The bytes kept for the character at i: none for a control, U+FFFD
      # for an illegal byte, else the character.
      #: (String, Integer, Integer, Integer) -> String
      def self.piece_at(text, i, b, size)
        return "" if b < 0x20 || b == 0x7F
        return REPLACEMENT if size == 1 && b >= 0x80
        return "" if b == 0xC2 && text.getbyte(i + 1).to_i <= 0x9F
        text.byteslice(i, size).to_s
      end
    end
  end
end
