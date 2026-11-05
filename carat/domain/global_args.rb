require_relative "delimited_pattern"

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
        return refused(MISSING) if text.empty?
        delimited = DelimitedPattern.parse(text, ":g")
        return refused(delimited.error) unless delimited.ok?
        GlobalArgs.new(pattern: delimited.pattern, command: delimited.rest, error: "")
      end
    end
  end
end
