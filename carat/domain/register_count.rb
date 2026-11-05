module Carat
  module Domain
    # The "[x] [count]" argument of a line command such as :d: the register
    # named ("" for none), the count (-1 for none), and the error that
    # refused it ("" when none). A register is a character that is not a
    # digit and that a delete may write: a letter, '"', "-", or "_";
    # blanks may follow it, then the count, then only blanks. A Data
    # value.
    class RegisterCount < Data.define(:register, :count, :error)
      # @rbs @register: String
      # @rbs @count: Integer
      # @rbs @error: String

      # A count is read up to this, which no buffer reaches.
      MAX_COUNT = 1_000_000_000

      #: () -> bool
      def ok?
        error.empty?
      end

      #: (String) -> RegisterCount
      def self.refused(message)
        RegisterCount.new(register: "", count: -1, error: message)
      end

      #: (String) -> RegisterCount
      def self.parse(text)
        n = text.bytesize
        i = 0
        register = ""
        if n > 0 && !digit?(text.getbyte(0).to_i)
          return trailing(text, 0) unless writable?(text.getbyte(0).to_i)
          register = text.byteslice(0, 1).to_s
          i = blanks_end(text, 1)
        end
        count = -1
        if i < n && digit?(text.getbyte(i).to_i)
          count = 0
          while i < n && digit?(text.getbyte(i).to_i)
            count = count * 10 + text.getbyte(i).to_i - 48 if count < MAX_COUNT
            i += 1
          end
          return refused("E939: Positive count required") if count == 0
          i = blanks_end(text, i)
        end
        return trailing(text, i) if i < n
        RegisterCount.new(register: register, count: count, error: "")
      end

      # E488 for what is left of text from byte i.
      #: (String, Integer) -> RegisterCount
      def self.trailing(text, i)
        refused("E488: Trailing characters: #{text.byteslice(i, text.bytesize - i)}")
      end

      # The first byte at or after i that is not a blank.
      #: (String, Integer) -> Integer
      def self.blanks_end(text, i)
        j = i
        j += 1 while j < text.bytesize && (text.getbyte(j) == 32 || text.getbyte(j) == 9)
        j
      end

      #: (Integer) -> bool
      def self.digit?(byte)
        byte >= 48 && byte <= 57
      end

      #: (Integer) -> bool
      def self.writable?(byte)
        (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122) || byte == 34 || byte == 45 || byte == 95
      end
    end
  end
end
