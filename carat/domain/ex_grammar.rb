module Carat
  module Domain
    # Parses a command line into an ExCommand: leading colons and blanks are
    # skipped, the range is the run of address characters before the name
    # (ExRange resolves it), the name is a run of letters or a single "&",
    # "!" directly after it sets bang, and the rest, trimmed, is the
    # argument.
    module ExGrammar
      #: (String) -> ExCommand
      def self.parse(text)
        s = text.strip
        i = 0
        i += 1 while i < s.length && (s[i, 1] == ":" || s[i, 1] == " ")
        s = s[i, s.length - i]
        stop = range_end(s)
        range = s[0, stop].strip
        s = s[stop, s.length - stop]
        j = 0
        if s.start_with?("&")
          j = 1
        else
          j += 1 while j < s.length && letter?(s[j, 1])
        end
        name = s[0, j]
        rest = s[j, s.length - j]
        bang = rest.start_with?("!")
        rest = rest[1, rest.length - 1] if bang
        ExCommand.new(range: range, name: name, bang: bang, args: rest.strip)
      end

      # Where the range at the start of s ends: digits, ". $ % , ; + -",
      # blanks, and a mark "'" with the character after it.
      #: (String) -> Integer
      def self.range_end(s)
        i = 0
        while i < s.length
          ch = s[i, 1]
          if ch == "'"
            break if i + 1 >= s.length
            i += 2
          elsif address_char?(ch)
            i += 1
          else
            break
          end
        end
        i
      end

      #: (String) -> bool
      def self.address_char?(ch)
        code = ch.ord
        (code >= 48 && code <= 57) || ".$%,;+- ".include?(ch)
      end

      #: (String) -> bool
      def self.letter?(ch)
        code = ch.ord
        (code >= 97 && code <= 122) || (code >= 65 && code <= 90)
      end
    end
  end
end
