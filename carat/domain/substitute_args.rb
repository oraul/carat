require_relative "delimited_pattern"

module Carat
  module Domain
    # The argument of :s or :&, parsed as Vim reads it: whether a pattern
    # and a string were typed (fresh), the pattern ("" for the last one),
    # the replacement string as typed, the flags as typed, the count (-1
    # for none), and the error that refused it ("" when none). A fresh
    # argument starts with its delimiter, any ASCII character but a letter,
    # a digit, a blank, "\", '"', or "|"; the pattern ends at the next
    # delimiter that no backslash escapes and no collection holds, the
    # string at the next unescaped one, and a missing delimiter ends either
    # at the end. A Data value.
    class SubstituteArgs < Data.define(:fresh, :pattern, :replacement, :flags, :count, :error)
      # @rbs @fresh: bool
      # @rbs @pattern: String
      # @rbs @replacement: String
      # @rbs @flags: String
      # @rbs @count: Integer
      # @rbs @error: String

      # The flags Vim reads after the string, "&" only first.
      FLAG_CHARS = "cegriIpn#l"
      # The characters after :s that are flags or a count, not a delimiter.
      NOT_DELIMITERS = "0123456789cegriIp|\""
      # A count is read up to this, which no buffer reaches.
      MAX_COUNT = 1_000_000_000

      #: () -> bool
      def ok?
        error.empty?
      end

      #: (String) -> SubstituteArgs
      def self.refused(message)
        SubstituteArgs.new(fresh: false, pattern: "", replacement: "", flags: "", count: -1, error: message)
      end

      # Parses text, the argument after the name; a pattern is read only
      # when allow_pattern is true (:s, not :&).
      #: (String, bool) -> SubstituteArgs
      def self.parse(text, allow_pattern)
        size = text.bytesize
        first = size > 0 ? text.getbyte(0).to_i : 0
        return tail(false, "", "", text) unless allow_pattern && size > 0 && first != 32 && first != 9 && !listed?(NOT_DELIMITERS, first)
        delimited = DelimitedPattern.parse(text, ":s")
        return refused(delimited.error) unless delimited.ok?
        after = delimited.rest
        cut = string_end(after, first)
        replacement = after.byteslice(0, cut).to_s
        flags = cut < after.bytesize ? after.byteslice(cut + 1, after.bytesize - cut - 1).to_s : ""
        tail(true, delimited.pattern, replacement, flags)
      end

      # The byte where the string ends: the first delimiter no backslash
      # escapes, or the end.
      #: (String, Integer) -> Integer
      def self.string_end(text, delimiter)
        n = text.bytesize
        i = 0
        while i < n
          byte = text.getbyte(i).to_i
          return i if byte == delimiter
          i += byte == 92 && i + 1 < n ? 2 : 1
        end
        n
      end

      # The flags and the count of text, then nothing but blanks or a
      # comment.
      #: (bool, String, String, String) -> SubstituteArgs
      def self.tail(fresh, pattern, replacement, text)
        n = text.bytesize
        i = 0
        i += 1 if n > 0 && text.getbyte(0) == 38
        i += 1 while i < n && listed?(FLAG_CHARS, text.getbyte(i).to_i)
        flags = text.byteslice(0, i).to_s
        i += 1 while i < n && (text.getbyte(i) == 32 || text.getbyte(i) == 9)
        count = -1
        if i < n && digit?(text.getbyte(i).to_i)
          count = 0
          while i < n && digit?(text.getbyte(i).to_i)
            count = count * 10 + (text.getbyte(i).to_i - 48) if count < MAX_COUNT
            i += 1
          end
        end
        i += 1 while i < n && (text.getbyte(i) == 32 || text.getbyte(i) == 9)
        if i < n && text.getbyte(i) != 34
          return refused("E488: Trailing characters: #{text.byteslice(i, n - i)}")
        end
        SubstituteArgs.new(fresh: fresh, pattern: pattern, replacement: replacement, flags: flags, count: count, error: "")
      end

      # Whether an ASCII byte is one of the characters of list.
      #: (String, Integer) -> bool
      def self.listed?(list, byte)
        byte < 128 && list.include?(byte.chr)
      end

      #: (Integer) -> bool
      def self.digit?(byte)
        byte >= 48 && byte <= 57
      end
    end
  end
end
