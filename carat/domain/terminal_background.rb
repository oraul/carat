module Carat
  module Domain
    # The terminal's background color, from its answer to the OSC 11 query
    # the terminal driver writes at start. The answer is untrusted input
    # read from the key bytes: `reply_size` finds where it ends in one
    # scan, and `parse` reads at most LIMIT bytes of it, by bytes only, so
    # a byte that is not UTF-8 cannot raise. Light when the luma of the
    # color is over half; anything malformed is unknown.
    module TerminalBackground
      # The query: OSC 11 with "?", ended by ST.
      QUERY = "\e]11;?\e\\"
      # How every answer starts.
      INTRODUCER = "\e]11;"
      # The most bytes of an answer, introducer and terminator included,
      # that are held across reads or parsed; "rgba:" with four channels
      # of four digits and ST takes 31.
      LIMIT = 48
      # The luma weights of red, green, and blue; alpha weighs nothing.
      LUMA_WEIGHTS = [299, 587, 114, 0].freeze
      DARK = "dark"
      LIGHT = "light"
      UNKNOWN = ""

      BEL = 7
      ESC = 27
      BACKSLASH = 92
      SLASH = 47

      # The size of the answer at the start of text, which starts with
      # INTRODUCER: through its terminator (BEL or ESC \); up to an ESC
      # followed by another byte or a control byte, which begin the keys
      # after an answer cut short; 0 when it has not ended and is shorter
      # than LIMIT, so the caller holds it for the next read; else the
      # whole text, an answer too long.
      #: (String) -> Integer
      def self.reply_size(text)
        size = text.bytesize
        i = INTRODUCER.bytesize
        while i < size
          b = text.getbyte(i).to_i
          return i + 1 if b == BEL
          if b == ESC
            break if i + 1 >= size
            return i + 2 if text.getbyte(i + 1).to_i == BACKSLASH
            return i
          end
          return i if b < 32 || b == 127
          i += 1
        end
        return 0 if size < LIMIT
        size
      end

      # DARK or LIGHT for a whole answer ("rgb:" or "rgba:" and one to
      # four hex digits per channel, then BEL or ESC \), else UNKNOWN.
      #: (String) -> String
      def self.parse(reply)
        size = reply.bytesize
        return UNKNOWN if size > LIMIT || size <= INTRODUCER.bytesize
        return UNKNOWN unless reply.start_with?(INTRODUCER)
        finish = body_end(reply)
        return UNKNOWN if finish < 0
        at = INTRODUCER.bytesize
        count = 3
        if prefix?(reply, at, "rgba:")
          at += 5
          count = 4
        elsif prefix?(reply, at, "rgb:")
          at += 4
        else
          return UNKNOWN
        end
        luma = 0
        n = 0
        while n < count
          digits = 0
          value = 0
          while at < finish && digits < 5
            v = hex_value(reply.getbyte(at).to_i)
            break if v < 0
            value = value * 16 + v
            digits += 1
            at += 1
          end
          return UNKNOWN if digits == 0 || digits > 4
          luma += LUMA_WEIGHTS[n] * (value * 65_535 / (16**digits - 1))
          n += 1
          if n < count
            return UNKNOWN if at >= finish || reply.getbyte(at).to_i != SLASH
            at += 1
          end
        end
        return UNKNOWN if at != finish
        return LIGHT if luma > 500 * 65_535
        DARK
      end

      # Where the body of a whole answer ends: before its BEL or ESC \,
      # -1 when it has neither at its end.
      #: (String) -> Integer
      def self.body_end(reply)
        size = reply.bytesize
        return size - 1 if reply.getbyte(size - 1).to_i == BEL
        return size - 2 if size >= 2 && reply.getbyte(size - 1).to_i == BACKSLASH && reply.getbyte(size - 2).to_i == ESC
        -1
      end

      # True when text holds word at byte offset at.
      #: (String, Integer, String) -> bool
      def self.prefix?(text, at, word)
        text.byteslice(at, word.bytesize).to_s == word
      end

      # The value of one hex digit's byte, -1 for any other byte.
      #: (Integer) -> Integer
      def self.hex_value(b)
        return b - 48 if b >= 48 && b <= 57
        return b - 87 if b >= 97 && b <= 102
        return b - 55 if b >= 65 && b <= 70
        -1
      end

      # Names reply_size and parse in every program that requires this
      # file, which already have them public: Spinel drops a method that
      # nothing in the program names (docs/spinel-notes.md).
      public_class_method :reply_size, :parse
    end
  end
end
