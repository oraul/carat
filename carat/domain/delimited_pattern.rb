require_relative "vim_pattern"

module Carat
  module Domain
    # A pattern read after its delimiter as Vim reads :s, :g, and :v, or
    # as a "/" or "?" prompt submitted it (typed): the pattern, the text
    # after its closing delimiter ("" when none closes it; a search
    # offset at a prompt), and the error that refused the delimiter (""
    # when none). The delimiter of a command is its first character, any
    # ASCII character but a letter (a backslash is not implemented); the
    # pattern ends at the next delimiter that no backslash escapes and no
    # collection holds. The one reader of these rules, so the commands
    # and the prompt cannot drift. A Data value.
    class DelimitedPattern < Data.define(:pattern, :rest, :error)
      # @rbs @pattern: String
      # @rbs @rest: String
      # @rbs @error: String

      #: () -> bool
      def ok?
        error.empty?
      end

      # Reads text, which starts with the delimiter; name is the command
      # an error names (":s", ":g").
      #: (String, String) -> DelimitedPattern
      def self.parse(text, name)
        size = text.bytesize
        first = size > 0 ? text.getbyte(0).to_i : 0
        letter = (first >= 65 && first <= 90) || (first >= 97 && first <= 122)
        return refused("E146: Regular expressions can't be delimited by letters") if letter
        return refused("Not implemented: \\ as the delimiter of " + name) if first == 92
        return refused("Not implemented: a delimiter that is not ASCII") if first >= 128
        after = size > 0 ? text.byteslice(1, size - 1).to_s : ""
        cut(after, first)
      end

      # What a "/" or "?" prompt submitted: the pattern up to the first
      # delimiter of its direction, and the search offset after it as the
      # rest.
      #: (String, bool) -> DelimitedPattern
      def self.typed(text, forward)
        cut(text, forward ? 47 : 63)
      end

      # text cut at its first delimiter that no backslash escapes and no
      # collection holds.
      #: (String, Integer) -> DelimitedPattern
      def self.cut(text, delimiter)
        stop = VimPattern.pattern_end(text, delimiter)
        pattern = text.byteslice(0, stop).to_s
        return DelimitedPattern.new(pattern: pattern, rest: "", error: "") if stop >= text.bytesize
        rest = text.byteslice(stop + 1, text.bytesize - stop - 1).to_s
        DelimitedPattern.new(pattern: pattern, rest: rest, error: "")
      end

      #: (String) -> DelimitedPattern
      def self.refused(message)
        DelimitedPattern.new(pattern: "", rest: "", error: message)
      end
    end
  end
end
