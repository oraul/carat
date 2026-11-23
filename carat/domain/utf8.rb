module Carat
  module Domain
    # Decodes UTF-8 one character at a time by walking a string's bytes, so
    # a loop over a line's characters slices no one-character strings,
    # which Spinel resolves from the start of the line, and allocates
    # nothing. A character is a well-formed sequence of one to four bytes;
    # any other byte is a character of its own that decodes to U+FFFD, the
    # way String#length counts it.
    module Utf8
      REPLACEMENT = 0xFFFD

      # The number of bytes of the character at byte i of text, whose
      # length in bytes is bytesize: the length of a well-formed sequence
      # per RFC 3629, 1 for a byte that does not start one. The second
      # byte's range depends on the lead byte, so no overlong form, no
      # surrogate (U+D800 to U+DFFF), and nothing above U+10FFFF is a
      # character; each of their bytes is one, as String#length counts.
      #: (String, Integer, Integer) -> Integer
      def self.size_at(text, i, bytesize)
        b = text.getbyte(i).to_i
        return 1 if b < 0x80
        n = 0
        low = 0x80
        high = 0xBF
        if b >= 0xF0
          n = 4 if b <= 0xF4
          low = 0x90 if b == 0xF0
          high = 0x8F if b == 0xF4
        elsif b >= 0xE0
          n = 3
          low = 0xA0 if b == 0xE0
          high = 0x9F if b == 0xED
        elsif b >= 0xC2
          n = 2
        end
        return 1 if n == 0 || i + n > bytesize
        second = text.getbyte(i + 1).to_i
        return 1 if second < low || second > high
        k = 2
        while k < n
          return 1 if (text.getbyte(i + k).to_i & 0xC0) != 0x80
          k += 1
        end
        n
      end

      # The first byte at or after i of text that String#byteindex takes as
      # an offset: past the continuation bytes (0x80 to 0xBF) at i, which
      # it refuses with an IndexError as inside a character since Spinel
      # 84aa303b1, as CRuby does, even in text that is not UTF-8. A search
      # for an ASCII needle from there finds what it would from i, since
      # no continuation byte is ASCII.
      #: (String, Integer) -> Integer
      def self.boundary(text, i)
        size = text.bytesize
        at = i
        at += 1 while at < size && (text.getbyte(at).to_i & 0xC0) == 0x80
        at
      end

      # Whether code is a Unicode scalar value: 0 to U+10FFFF outside the
      # surrogates, the only codes that have a UTF-8 form.
      #: (Integer) -> bool
      def self.scalar?(code)
        return false if code < 0 || code > 0x10FFFF
        code < 0xD800 || code > 0xDFFF
      end

      # The code point of the character of size bytes at byte i of text,
      # U+FFFD for a byte that starts no well-formed sequence.
      #: (String, Integer, Integer) -> Integer
      def self.code_at(text, i, size)
        b = text.getbyte(i).to_i
        if size == 1
          return b < 0x80 ? b : REPLACEMENT
        end
        if size == 2
          return ((b & 0x1F) << 6) | (text.getbyte(i + 1).to_i & 0x3F)
        end
        if size == 3
          return ((b & 0x0F) << 12) | ((text.getbyte(i + 1).to_i & 0x3F) << 6) | (text.getbyte(i + 2).to_i & 0x3F)
        end
        ((b & 0x07) << 18) | ((text.getbyte(i + 1).to_i & 0x3F) << 12) | ((text.getbyte(i + 2).to_i & 0x3F) << 6) | (text.getbyte(i + 3).to_i & 0x3F)
      end

      # The code point of the first character of ch, decoded as the screen
      # decodes it: U+FFFD for a byte outside a well-formed sequence, where
      # String#ord would answer the byte.
      #: (String) -> Integer
      def self.code_of(ch)
        code_at(ch, 0, size_at(ch, 0, ch.bytesize))
      end

      # The code points of text, exactly text.length of them.
      #: (String) -> Array[Integer]
      def self.codes(text)
        n = text.length
        out = Array.new(n, REPLACEMENT)
        bytes = text.bytesize
        i = 0
        k = 0
        while k < n && i < bytes
          code = text.getbyte(i).to_i
          if code < 0x80
            i += 1
          else
            size = size_at(text, i, bytes)
            code = code_at(text, i, size)
            i += size
          end
          out[k] = code
          k += 1
        end
        out
      end

      # The UTF-16 code units of text, which language server positions
      # count: two for a four-byte character, outside the basic plane, and
      # one for any other character, a byte that starts no well-formed
      # sequence included, as it decodes to U+FFFD.
      #: (String) -> Integer
      def self.utf16_length(text)
        bytes = text.bytesize
        count = 0
        i = 0
        while i < bytes
          size = text.getbyte(i).to_i < 0x80 ? 1 : size_at(text, i, bytes)
          count += size == 4 ? 2 : 1
          i += size
        end
        count
      end

      # Names boundary and scalar? in every program that requires this
      # file, which already have them public. Spinel drops a method that
      # nothing in the program names, unless it is the last statement of
      # its module, and then warns that its signature is not applied:
      # carat-gen-config calls only size_at (docs/spinel-notes.md).
      public_class_method :boundary, :scalar?
    end
  end
end
