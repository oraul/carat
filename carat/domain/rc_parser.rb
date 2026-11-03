require_relative "rc_parse"

module Carat
  module Domain
    # Reads one line of a .caratrc file: a dotted key, then the value's
    # words separated by spaces and tabs. A word that starts with a double
    # quote runs to the next unescaped one, keeping its spaces, with \" and
    # \\ as escapes; a double quote inside any other word is an ordinary
    # character. A # at the start of a word starts a comment, and a key
    # is never quoted. The parser walks bytes and cuts words with
    # byteslice, so it makes no one-character strings, and it refuses
    # control characters other than tab, so no escape sequence from a file
    # reaches the screen. It knows no scope: what a value must be is the
    # setting's to say.
    module RcParser
      TAB = 9
      NEWLINE = 10
      RETURN = 13
      SPACE = 32
      QUOTE = 34
      HASH = 35
      DOT = 46
      ZERO = 48
      NINE = 57
      BACKSLASH = 92
      UNDERSCORE = 95
      LOWER_A = 97
      LOWER_Z = 122
      DELETE = 127

      # Parses a whole line.
      #: (String) -> RcParse
      def self.parse(text)
        parse_range(text, 0, text.bytesize)
      end

      # Parses the bytes of text from from up to to, a line without its
      # newline; a carriage return before the end is dropped. One pass
      # reads the key, the words, and the control characters; the key is
      # checked on its bytes, so no pattern runs per line.
      #: (String, Integer, Integer) -> RcParse
      def self.parse_range(text, from, to)
        stop = to
        stop -= 1 if stop > from && text.getbyte(stop - 1).to_i == RETURN
        words = no_words
        key = ""
        i = from
        while i < stop
          b = text.getbyte(i).to_i
          if b == SPACE || b == TAB
            i += 1
          elsif b < SPACE || b == DELETE
            return failure("control character")
          elsif b == HASH
            return failure("control character") if control?(text, i, stop)
            i = stop
          elsif b == QUOTE
            return failure("invalid key") if key.empty?
            close = closing_quote(text, i + 1, stop)
            return failure("unterminated quote") if close < 0
            return failure("control character") if control?(text, i + 1, close)
            after = close + 1
            if after < stop
              c = text.getbyte(after).to_i
              return failure("text after a closing quote") unless c == SPACE || c == TAB
            end
            words << unquote(text, i + 1, close)
            i = after
          else
            start = i
            i += 1
            while i < stop
              c = text.getbyte(i).to_i
              break if c == SPACE || c == TAB
              return failure("control character") if c < SPACE || c == DELETE
              i += 1
            end
            if key.empty?
              return failure("invalid key") unless key?(text, start, i)
              key = text.byteslice(start, i - start).to_s
            else
              words << text.byteslice(start, i - start).to_s
            end
          end
        end
        RcParse.new(key: key, words: words, error: "")
      end

      # Whether the bytes from from up to to are a key: two or more
      # segments of lowercase letters, digits, and underscores joined by
      # dots.
      #: (String, Integer, Integer) -> bool
      def self.key?(text, from, to)
        dots = 0
        previous = DOT
        i = from
        while i < to
          b = text.getbyte(i).to_i
          if b == DOT
            return false if previous == DOT
            dots += 1
          else
            return false unless (b >= LOWER_A && b <= LOWER_Z) || (b >= ZERO && b <= NINE) || b == UNDERSCORE
          end
          previous = b
          i += 1
        end
        dots > 0 && previous != DOT
      end

      # Whether a byte from from up to to is a control character other
      # than tab.
      #: (String, Integer, Integer) -> bool
      def self.control?(text, from, to)
        i = from
        while i < to
          b = text.getbyte(i).to_i
          return true if (b < SPACE && b != TAB) || b == DELETE
          i += 1
        end
        false
      end

      # The byte of the double quote that closes a quoted word whose text
      # starts at from, skipping escaped ones, or -1 when none does.
      #: (String, Integer, Integer) -> Integer
      def self.closing_quote(text, from, to)
        i = from
        while i < to
          b = text.getbyte(i).to_i
          return i if b == QUOTE
          i += b == BACKSLASH && i + 1 < to ? 2 : 1
        end
        -1
      end

      # The text of a quoted word between its quotes, with \" and \\
      # replaced by the character they stand for; any other backslash
      # stays.
      #: (String, Integer, Integer) -> String
      def self.unquote(text, from, to)
        out = +""
        start = from
        i = from
        while i < to
          b = text.getbyte(i).to_i
          if b == BACKSLASH && i + 1 < to
            c = text.getbyte(i + 1).to_i
            if c == QUOTE || c == BACKSLASH
              out << text.byteslice(start, i - start).to_s
              out << (c == QUOTE ? "\"" : "\\")
              i += 2
              start = i
              next
            end
          end
          i += 1
        end
        out << text.byteslice(start, to - start).to_s
        out
      end

      #: (String) -> RcParse
      def self.failure(error)
        RcParse.new(key: "", words: no_words, error: error)
      end

      # An empty word list typed as the words are.
      #: () -> Array[String]
      def self.no_words
        words = [""]
        words.clear
        words
      end
    end
  end
end
