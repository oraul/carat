require_relative "utf8"
require_relative "operators"

module Carat
  module Domain
    # The replacement string of a substitute, read as Vim's magic mode
    # reads it: "&" and "\0" are the match, "\1" to "\9" its groups, "\u"
    # and "\l" recase the next character and "\U" and "\L" the following
    # ones until "\e" or "\E", "\r" and a carriage return break the line,
    # "\t" is a tab, "\b" a backspace, and a backslash before any other
    # character gives that character. A line break is written as "\n",
    # which no buffer line holds, so a carriage return in the match stays
    # a character. Columns are code points, as the match gives them; the
    # text is cut from the line itself, so a byte that is not UTF-8 is
    # kept.
    module Replacement
      BREAK = "\n"

      # "~" replaced by the previous string (nothing when there is none),
      # as Vim's regtilde does; an escaped character is kept with its
      # backslash, so "\~" stays a literal "~" for expand.
      #: (String, String, bool) -> String
      def self.tilde(raw, previous, has_previous)
        return raw unless raw.include?("~")
        out = +""
        n = raw.bytesize
        i = 0
        while i < n
          byte = raw.getbyte(i).to_i
          if byte == 126
            out << previous if has_previous
            i += 1
          elsif byte == 92 && i + 1 < n
            size = Utf8.size_at(raw, i + 1, n)
            out << raw.byteslice(i, size + 1).to_s
            i += size + 1
          else
            size = Utf8.size_at(raw, i, n)
            out << raw.byteslice(i, size).to_s
            i += size
          end
        end
        out
      end

      # The message refusing what Carat does not expand, "" when none:
      # an expression (a leading "\=") and "\n", which Vim makes a NUL.
      #: (String) -> String
      def self.check(text)
        return "Not implemented: \\= in a substitute string" if text.start_with?("\\=")
        n = text.bytesize
        i = 0
        while i < n
          if text.getbyte(i) == 92 && i + 1 < n
            return "Not implemented: \\n in a substitute string" if text.getbyte(i + 1) == 110
            i += 2
          else
            i += 1
          end
        end
        ""
      end

      # The text that replaces the match found in line.
      #: (String, String, MatchData) -> String
      def self.expand(text, line, found)
        out = +""
        one = 0
        all = 0
        n = text.bytesize
        i = 0
        while i < n
          byte = text.getbyte(i).to_i
          if byte == 92 && i + 1 < n
            code = text.getbyte(i + 1).to_i
            if code >= 48 && code <= 57
              group = group_text(line, found, code - 48)
              if one == 0 && all == 0
                out << group
              else
                out << recase(group, one, all)
                one = 0 unless group.empty?
              end
              i += 2
              next
            end
            case code
            when 117 then one = 1
            when 108 then one = 2
            when 85 then all = 1
            when 76 then all = 2
            when 101, 69 then all = 0
            when 114 then out << BREAK
            when 116 then out << "\t"
            when 98 then out << "\b"
            else
              size = Utf8.size_at(text, i + 1, n)
              out << cased(text.byteslice(i + 1, size).to_s, one, all)
              one = 0
              i += size + 1
              next
            end
            i += 2
          elsif byte == 38
            group = group_text(line, found, 0)
            if one == 0 && all == 0
              out << group
            else
              out << recase(group, one, all)
              one = 0 unless group.empty?
            end
            i += 1
          elsif byte == 13
            out << BREAK
            i += 1
          else
            size = Utf8.size_at(text, i, n)
            out << cased(text.byteslice(i, size).to_s, one, all)
            one = 0
            i += size
          end
        end
        out
      end

      # The text of group k of the match in line, "" when the pattern has
      # no such group or it did not take part.
      #: (String, MatchData, Integer) -> String
      def self.group_text(line, found, k)
        return "" if k >= found.size
        return "" if found[k].nil?
        from = found.begin(k).to_i
        line[from, found.end(k).to_i - from].to_s
      end

      # text with its first character recased by one and every character
      # by all (0 none, 1 upper, 2 lower), one first.
      #: (String, Integer, Integer) -> String
      def self.recase(text, one, all)
        out = +""
        n = text.bytesize
        i = 0
        first = true
        while i < n
          size = Utf8.size_at(text, i, n)
          out << cased(text.byteslice(i, size).to_s, first ? one : 0, all)
          first = false
          i += size
        end
        out
      end

      # One character recased by one, else by all.
      #: (String, Integer, Integer) -> String
      def self.cased(char, one, all)
        how = one != 0 ? one : all
        return char if how == 0
        Operators.recase(char, how == 1 ? :upper : :lower, "")
      end
    end
  end
end
