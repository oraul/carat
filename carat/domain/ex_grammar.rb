module Carat
  module Domain
    # Parses a command line into an ExCommand: leading colons and blanks are
    # skipped, the name is a run of letters, "!" directly after it sets bang,
    # and the rest, trimmed, is the argument.
    module ExGrammar
      #: (String) -> ExCommand
      def self.parse(text)
        s = text.strip
        i = 0
        i += 1 while i < s.length && (s[i, 1] == ":" || s[i, 1] == " ")
        s = s[i, s.length - i]
        j = 0
        j += 1 while j < s.length && letter?(s[j, 1])
        name = s[0, j]
        rest = s[j, s.length - j]
        bang = rest.start_with?("!")
        rest = rest[1, rest.length - 1] if bang
        ExCommand.new(name, bang, rest.strip)
      end

      #: (String) -> bool
      def self.letter?(ch)
        code = ch.ord
        (code >= 97 && code <= 122) || (code >= 65 && code <= 90)
      end
    end
  end
end
