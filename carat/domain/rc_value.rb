module Carat
  module Domain
    # The four kinds of value a setting takes, read from a line's words:
    # "bool" (true or false), "integer" (one to nine digits), "string"
    # (one word), and "list" (any number of words, none being the empty
    # list). Options, plugin options, and manifest defaults share these
    # rules, their messages, and the text a plugin receives.
    module RcValue
      KINDS = ["bool", "integer", "string", "list"]
      ZERO = 48
      NINE = 57

      # Whether the words are a value of the kind.
      #: (Array[String], String) -> bool
      def self.valid?(words, kind)
        case kind
        when "bool" then words.length == 1 && (words[0] == "true" || words[0] == "false")
        when "integer" then words.length == 1 && number?(words[0].to_s)
        when "string" then words.length == 1
        when "list" then true
        else false
        end
      end

      # What a setting of the kind takes, for a problem: "takes a number".
      # Written with guard returns: on the pinned compiler, a case whose
      # branches are string literals, called with a literal kind, answered
      # the kind itself.
      #: (String) -> String
      def self.expectation(kind)
        return "takes true or false" if kind == "bool"
        return "takes a number" if kind == "integer"
        return "takes one word" if kind == "string"
        "takes a list of words"
      end

      # The value as a plugin reads it: the word, or a list's words
      # joined by newlines. The first word goes through a local: on the
      # pinned compiler, words.empty? ? "" : words[0].to_s answered the
      # kind.
      #: (Array[String], String) -> String
      def self.text(words, kind)
        return words.join("\n") if kind == "list"
        return "" if words.length == 0
        first = words[0]
        first
      end

      # Whether the word is one to nine digits, a count that fits.
      #: (String) -> bool
      def self.number?(word)
        n = word.bytesize
        return false if n == 0 || n > 9
        i = 0
        while i < n
          b = word.getbyte(i).to_i
          return false if b < ZERO || b > NINE
          i += 1
        end
        true
      end
    end
  end
end
