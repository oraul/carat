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
