require_relative "vim_pattern"

module Carat
  module Domain
    # The argument of :g, :g!, and :v, parsed as Vim reads it: the pattern
    # ("" for the last search pattern), the command to run on each marked
    # line ("" to list them), and the error that refused it ("" when none).
    # The delimiter is the first character, any ASCII character but a
    # letter; the pattern ends at the next delimiter that no backslash
    # escapes and no collection holds, and the command is the rest. A Data
    # value.
    class GlobalArgs < Data.define(:pattern, :command, :error)
      # @rbs @pattern: String
      # @rbs @command: String
      # @rbs @error: String

      MISSING = "E148: Regular expression missing from :global"

      #: () -> bool
      def ok?
        error.empty?
      end

      #: (String) -> GlobalArgs
      def self.refused(message)
        GlobalArgs.new(pattern: "", command: "", error: message)
      end

      # Parses text, the argument after the name.
      #: (String) -> GlobalArgs
      def self.parse(text)
        size = text.bytesize
        return refused(MISSING) if size == 0
        first = text.getbyte(0).to_i
        letter = (first >= 65 && first <= 90) || (first >= 97 && first <= 122)
        return refused("E146: Regular expressions can't be delimited by letters") if letter
        return refused("Not implemented: \\ as the delimiter of :g") if first == 92
        return refused("Not implemented: a delimiter that is not ASCII") if first >= 128
        rest = text.byteslice(1, size - 1).to_s
        stop = VimPattern.pattern_end(rest, first)
        pattern = rest.byteslice(0, stop).to_s
        return GlobalArgs.new(pattern: pattern, command: "", error: "") if stop >= rest.bytesize
        command = rest.byteslice(stop + 1, rest.bytesize - stop - 1).to_s
        GlobalArgs.new(pattern: pattern, command: command, error: "")
      end
    end
  end
end
