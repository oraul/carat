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
    end
  end
end
