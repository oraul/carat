require_relative "utf8"
require_relative "search_pattern"

module Carat
  module Domain
    # Translates a Vim search pattern into the regular expression syntax of
    # the engine Spinel bundles, in one pass over its code points, and
    # compiles it. The pattern is untrusted input, so the translation emits
    # only what that engine matches without backtracking: a group is
    # non-capturing, back references and look-around are refused, and
    # every character the engine reads specially is escaped. A byte that
    # is not UTF-8 becomes U+FFFD, which is how a searched line holds one.
    # The size of the compiled form is counted as it is written (an atom
    # is one state, a counted repetition multiplies its operand) and
    # capped at MAX_SIZE, which bounds compiling and the cost of every
    # character a search scans.
    #
    # Supported, in the four magic modes \v, \m (the default), \M, and \V:
    # literal characters, . * \+ \= \? \{n,m} \{-n,m}, ^ and $ where Vim
    # anchors them, [...] with ranges, negation, [:class:], and the
    # escapes \e \t \r \\ \] \^ \-, \( \) \%( \|, \< and \> (both a word
    # boundary), the class escapes s S d D w W a A l L u U x X h H o O k K,
    # \t \e \r, and \c \C. Everything else Vim has answers Not
    # implemented, and a malformed pattern Vim's error. A substitute's
    # pattern is translated the same way except that \( captures, at most
    # nine times as in Vim, for \1 to \9 of the replacement, and ~ matches
    # the previous replacement string. A plain class built once per
    # compile.
    class VimPattern
      MAX_SIZE = 2000
      MAX_BYTES = 4096
      TOO_BIG = "E363: pattern uses more memory than 'maxmempattern'"

      # Literal, a character with its special meaning, or a backslash and
      # a letter or digit.
      LITERAL = 0
      SPECIAL = 1
      LETTER = 2

      # @rbs @source: String
      # @rbs @bytes: Integer
      # @rbs @pos: Integer
      # @rbs @out: String
      # @rbs @level: Integer
      # @rbs @error: String
      # @rbs @case_flag: Integer
      # @rbs @upper: bool
      # @rbs @size: Integer
      # @rbs @last: Integer
      # @rbs @starts: Array[Integer]
      # @rbs @can_multi: bool
      # @rbs @after_multi: bool
      # @rbs @at_start: bool
      # @rbs @code: Integer
      # @rbs @kind: Integer
      # @rbs @capture: bool
      # @rbs @groups: Integer
      # @rbs @tilde: String
      # @rbs @tilde_known: bool

      #: (source: String, capture: bool, tilde: String, tilde_known: bool) -> void
      def initialize(source:, capture:, tilde:, tilde_known:)
        @source = source
        @capture = capture
        @groups = 0
        @tilde = tilde
        @tilde_known = tilde_known
        @bytes = source.bytesize
        @pos = 0
        @out = +""
        @level = 2
        @error = ""
        @case_flag = 0
        @upper = false
        @size = 0
        @last = 0
        @starts = [0]
        @starts.clear
        @can_multi = false
        @after_multi = false
        @at_start = true
        @code = 0
        @kind = LITERAL
      end

      # The pattern compiled for a search: case is ignored when \c is in
      # it, matched when \C is, and otherwise ignored when ignorecase is
      # on, unless smartcase is on and the pattern holds an uppercase
      # letter.
      #: (String, bool, bool) -> SearchPattern
      def self.compile(source, ignorecase, smartcase)
        VimPattern.new(source: source, capture: false, tilde: "", tilde_known: false).build(ignorecase, smartcase)
      end

      # The pattern of a substitute: as compile, with capturing groups and
      # ~ as previous, the last replacement string, when previous_kept.
      #: (String, bool, bool, String, bool) -> SearchPattern
      def self.compile_substitute(source, ignorecase, smartcase, previous, previous_kept)
        VimPattern.new(source: source, capture: true, tilde: previous, tilde_known: previous_kept).build(ignorecase, smartcase)
      end

      # The pattern that matches text literally, for "*" and "#": every
      # character the magic mode reads specially is escaped.
      #: (String) -> String
      def self.escape(text)
        out = +""
        i = 0
        n = text.bytesize
        while i < n
          byte = text.getbyte(i).to_i
          out << "\\" if byte == 92 || byte == 47 || byte == 46 || byte == 42 || byte == 36 || byte == 94 || byte == 126 || byte == 91 || byte == 93
          size = Utf8.size_at(text, i, n)
          out << text.byteslice(i, size).to_s
          i += size
        end
        out
      end

      # The byte where the pattern typed at a prompt ends: the first
      # delimiter ("/" or "?") that no backslash escapes and no collection
      # holds, or the end of the text. What follows it is an offset.
      #: (String, Integer) -> Integer
      def self.pattern_end(text, delimiter)
        n = text.bytesize
        i = 0
        while i < n
          byte = text.getbyte(i).to_i
          return i if byte == delimiter
          if byte == 92
            i += 2
          elsif byte == 91
            close = i + 2 < n ? text.byteindex("]", i + 2) : nil
            i = close.nil? ? i + 1 : close + 1
          else
            i += 1
          end
        end
        n
      end

      #: (bool, bool) -> SearchPattern
      def build(ignorecase, smartcase)
        return SearchPattern.refused(@source, TOO_BIG) if @bytes > MAX_BYTES
        translate
        return SearchPattern.refused(@source, @error) unless @error.empty?
        ignore = @case_flag == 1 || (@case_flag == 0 && ignorecase && !(smartcase && @upper))
        regexp(ignore)
      end

      private

      #: (bool) -> SearchPattern
      def regexp(ignore)
        compiled = ignore ? Regexp.new(@out, Regexp::IGNORECASE) : Regexp.new(@out)
        SearchPattern.new(source: @source, regexp: compiled, size: @size > 0 ? @size : 1, error: "")
      rescue RegexpError, ArgumentError
        SearchPattern.refused(@source, "E383: Invalid search string: #{@source}")
      end

      #: () -> void
      def translate
        while @error.empty? && @pos < @bytes
          read_token
          step
        end
        return unless @error.empty?
        refuse("E54: Unmatched \\(") unless @starts.empty?
      end

      #: (String) -> void
      def refuse(message)
        @error = message if @error.empty?
      end

      # Reads the next token into @code and @kind.
      #: () -> void
      def read_token
        code = next_code
        if code != 92 || @pos >= @bytes
          @code = code
          @kind = special_plain?(code) ? SPECIAL : LITERAL
          return
        end
        code = next_code
        @code = code
        if letter_or_digit?(code) || code == 95 || code == 38
          @kind = LETTER
        else
          @kind = special_escaped?(code) ? SPECIAL : LITERAL
        end
      end

      # The code point at @pos, which moves past it; U+FFFD for a byte
      # that starts no character.
      #: () -> Integer
      def next_code
        size = Utf8.size_at(@source, @pos, @bytes)
        code = Utf8.code_at(@source, @pos, size)
        @pos += size
        code
      end

      #: (Integer) -> bool
      def letter_or_digit?(code)
        (code >= 48 && code <= 57) || (code >= 65 && code <= 90) || (code >= 97 && code <= 122)
      end

      # . * [ ~
      #: (Integer) -> bool
      def magic_char?(code)
        code == 46 || code == 42 || code == 91 || code == 126
      end

      # ( ) | + ? = { @ % < >
      #: (Integer) -> bool
      def very_magic_char?(code)
        code == 40 || code == 41 || code == 124 || code == 43 || code == 63 || code == 61 || code == 123 || code == 64 || code == 37 || code == 60 || code == 62
      end

      # Whether an unescaped character is special in the current mode;
      # ^ and $ always are, where they stand decides.
      #: (Integer) -> bool
      def special_plain?(code)
        return true if code == 94 || code == 36
        return @level >= 2 if magic_char?(code)
        return @level == 3 if very_magic_char?(code)
        false
      end

      #: (Integer) -> bool
      def special_escaped?(code)
        return @level <= 1 if magic_char?(code)
        return @level != 3 if very_magic_char?(code)
        false
      end

      #: () -> void
      def step
        code = @code
        if @kind == LETTER
          letter(code)
        elsif @kind == LITERAL
          literal(code)
        else
          special(code)
        end
      end

      # The name of a special character as typed in the current mode, for
      # a message.
      #: (Integer) -> String
      def typed(code)
        bare = @level == 3 ? very_magic_char?(code) : magic_char?(code)
        bare ? code.chr : "\\#{code.chr}"
      end

      #: (Integer) -> void
      def special(code)
        case code
        when 94 then caret
        when 36 then dollar
        when 46 then atom(".", 1)
        when 42 then star
        when 91 then collection
        when 126 then tilde
        when 40 then open_group(@capture)
        when 41 then close_group
        when 124 then alternative
        when 43 then multi("+", code)
        when 61, 63 then multi("?", code)
        when 123 then count_multi
        when 60, 62 then boundary
        when 37 then percent
        else refuse("Not implemented: #{typed(code)} in a pattern")
        end
      end

      #: () -> void
      def caret
        unless @at_start
          literal(94)
          return
        end
        @out << "^"
        @can_multi = false
        @after_multi = false
      end

      # $ anchors at the end of the pattern and before \| or \).
      #: () -> void
      def dollar
        unless dollar_ends?
          literal(36)
          return
        end
        @out << "$"
        @can_multi = false
        @after_multi = false
        @at_start = false
      end

      #: () -> bool
      def dollar_ends?
        return true if @pos >= @bytes
        pos = @pos
        code = @code
        kind = @kind
        read_token
        ends = @kind == SPECIAL && (@code == 124 || @code == 41)
        @pos = pos
        @code = code
        @kind = kind
        ends
      end

      #: () -> void
      def star
        if @at_start
          literal(42)
          return
        end
        multi("*", 42)
      end

      # A multi after the last atom: "*", "+", or "?".
      #: (String, Integer) -> void
      def multi(text, code)
        return refuse(code == 42 ? "E61: Nested #{typed(code)}" : "E62: Nested #{typed(code)}") if @after_multi
        return refuse("E64: #{typed(code)} follows nothing") unless @can_multi
        @out << text
        @can_multi = false
        @after_multi = true
      end

      # \{n,m}, \{n}, \{n,}, \{,m}, \{}, and their lazy forms \{-...}.
      #: () -> void
      def count_multi
        return refuse("E62: Nested #{typed(123)}") if @after_multi
        return refuse("E64: #{typed(123)} follows nothing") unless @can_multi
        lazy = false
        if @pos < @bytes && @source.getbyte(@pos) == 45
          lazy = true
          @pos += 1
        end
        low = read_number
        high = low
        comma = false
        if @pos < @bytes && @source.getbyte(@pos) == 44
          comma = true
          @pos += 1
          high = read_number
        end
        @pos += 1 if @pos + 1 < @bytes && @source.getbyte(@pos) == 92 && @source.getbyte(@pos + 1) == 125
        return refuse("E554: Syntax error in #{typed(123)}...}") unless @pos < @bytes && @source.getbyte(@pos) == 125
        @pos += 1
        return refuse(TOO_BIG) if low > MAX_SIZE || high > MAX_SIZE
        if low >= 0 && high >= 0 && low > high
          swap = low
          low = high
          high = swap
        end
        factor = high >= 0 ? high : (low >= 0 ? low + 1 : 1)
        if low < 0 && high < 0
          @out << "*"
        elsif !comma
          @out << "{#{low}}"
        else
          @out << "{#{low < 0 ? 0 : low},#{high < 0 ? "" : high.to_s}}"
        end
        @out << "?" if lazy
        grow(@last * (factor > 1 ? factor - 1 : 0))
        @can_multi = false
        @after_multi = true
      end

      # The decimal number at @pos, -1 when there is none; a number past
      # MAX_SIZE reads as MAX_SIZE + 1.
      #: () -> Integer
      def read_number
        value = -1
        while @pos < @bytes
          byte = @source.getbyte(@pos).to_i
          break if byte < 48 || byte > 57
          value = value < 0 ? 0 : value
          value = value * 10 + (byte - 48)
          value = MAX_SIZE + 1 if value > MAX_SIZE
          @pos += 1
        end
        value
      end

      # ~: the previous replacement string, matched literally as one atom.
      #: () -> void
      def tilde
        return refuse("E33: No previous substitute regular expression") unless @capture && @tilde_known
        codes = Utf8.codes(@tilde)
        text = +"(?:"
        i = 0
        while i < codes.length
          text << literal_text(codes[i].to_i)
          i += 1
        end
        text << ")"
        atom(text, codes.length > 0 ? codes.length : 1)
      end

      # A group, capturing when capturing is true.
      #: (bool) -> void
      def open_group(capturing)
        if capturing
          @groups += 1
          return refuse("E51: Too many #{typed(40)}") if @groups > 9
          @out << "("
        else
          @out << "(?:"
        end
        @starts << @size
        @at_start = true
        @can_multi = false
        @after_multi = false
      end

      #: () -> void
      def close_group
        return refuse("E55: Unmatched #{typed(41)}") if @starts.empty?
        start = @starts.pop.to_i
        @out << ")"
        @last = @size - start
        @last = 1 if @last < 1
        @at_start = false
        @can_multi = true
        @after_multi = false
      end

      #: () -> void
      def alternative
        @out << "|"
        @at_start = true
        @can_multi = false
        @after_multi = false
      end

      # \< and \>: a word boundary, after which no multi may follow.
      #: () -> void
      def boundary
        @out << "\\b"
        @at_start = false
        @can_multi = false
        @after_multi = false
      end

      # \%( opens a group; every other \% item is not implemented.
      #: () -> void
      def percent
        if @pos < @bytes && @source.getbyte(@pos) == 40
          @pos += 1
          open_group(false)
          return
        end
        refuse("Not implemented: #{typed(37)} in a pattern")
      end

      # A backslash and a letter or digit.
      #: (Integer) -> void
      def letter(code)
        name = code.chr
        set = class_of(name)
        unless set.empty?
          atom(set, 1)
          return
        end
        case name
        when "c" then @case_flag = 1
        when "C" then @case_flag = 2 if @case_flag == 0
        when "v" then @level = 3
        when "m" then @level = 2
        when "M" then @level = 1
        when "V" then @level = 0
        when "t" then atom("\\t", 1)
        when "e" then atom("\\e", 1)
        when "r" then atom("\\r", 1)
        else refuse("Not implemented: \\#{name} in a pattern")
        end
      end

      # The bracket expression of a class escape, "" for another letter.
      #: (String) -> String
      def class_of(name)
        case name
        when "s" then "[ \\t]"
        when "S" then "[^ \\t]"
        when "d" then "[0-9]"
        when "D" then "[^0-9]"
        when "w" then "[0-9A-Za-z_]"
        when "W" then "[^0-9A-Za-z_]"
        when "a" then "[A-Za-z]"
        when "A" then "[^A-Za-z]"
        when "l" then "[a-z]"
        when "L" then "[^a-z]"
        when "u" then "[A-Z]"
        when "U" then "[^A-Z]"
        when "x" then "[0-9A-Fa-f]"
        when "X" then "[^0-9A-Fa-f]"
        when "h" then "[A-Za-z_]"
        when "H" then "[^A-Za-z_]"
        when "o" then "[0-7]"
        when "O" then "[^0-7]"
        when "k" then "[0-9A-Za-z_À-\u{10FFFF}]"
        when "K" then "[A-Za-z_À-\u{10FFFF}]"
        else ""
        end
      end

      #: (String, Integer) -> void
      def atom(text, size)
        @out << text
        grow(size)
        @last = size
        @at_start = false
        @can_multi = true
        @after_multi = false
      end

      #: (Integer) -> void
      def grow(size)
        @size += size
        refuse(TOO_BIG) if @size > MAX_SIZE
      end

      # A character that matches itself.
      #: (Integer) -> void
      def literal(code)
        @upper = true if code >= 65 && code <= 90
        atom(literal_text(code), 1)
      end

      # How a character that matches itself is written for the engine.
      #: (Integer) -> String
      def literal_text(code)
        return [code].pack("U") if code >= 128
        text = code.chr
        return "\\#{text}" if escaped_outside?(code)
        text
      end

      # \ ^ $ . | ? * + ( ) [ ] { }
      #: (Integer) -> bool
      def escaped_outside?(code)
        code == 92 || code == 94 || code == 36 || code == 46 || code == 124 || code == 63 || code == 42 || code == 43 ||
          code == 40 || code == 41 || code == 91 || code == 93 || code == 123 || code == 125
      end

      # [...]: a collection when a closing ] follows, the character [
      # otherwise, as in Vim.
      #: () -> void
      def collection
        stop = collection_end
        if stop < 0
          literal(91)
          return
        end
        out = +"["
        if @pos < stop && @source.getbyte(@pos) == 94
          out << "^"
          @pos += 1
        end
        first = true
        previous = -1
        while @error.empty? && @pos < stop
          byte = @source.getbyte(@pos).to_i
          if byte == 91 && posix_class_end(@pos) > 0
            finish = posix_class_end(@pos)
            out << @source.byteslice(@pos, finish - @pos).to_s
            @pos = finish
            previous = -1
            first = false
            next
          end
          if byte == 45 && !first && previous >= 0 && @pos + 1 < stop
            @pos += 1
            high = class_char
            return refuse("E944: Reverse range in character class") if high < previous
            out << "-" << class_text(high)
            previous = -1
            next
          end
          first = false
          code = class_char
          @upper = true if code >= 65 && code <= 90
          out << class_text(code)
          previous = code
        end
        return unless @error.empty?
        @pos = stop + 1
        out << "]"
        atom(out, 1)
      end

      # One character of a collection at @pos, which moves past it, with
      # the backslash escapes Vim reads there.
      #: () -> Integer
      def class_char
        if @source.getbyte(@pos) == 92 && @pos + 1 < @bytes
          following = @source.getbyte(@pos + 1).to_i
          case following
          when 101
            @pos += 2
            return 27
          when 116
            @pos += 2
            return 9
          when 114
            @pos += 2
            return 13
          when 92, 93, 94, 45
            @pos += 2
            return following
          when 110
            refuse("Not implemented: \\n in a pattern")
          end
        end
        next_code
      end

      # How one character of a collection is written for the engine.
      #: (Integer) -> String
      def class_text(code)
        return [code].pack("U") if code >= 128
        return "\\t" if code == 9
        return "\\r" if code == 13
        return "\\e" if code == 27
        return "\\x#{hex(code >> 4)}#{hex(code & 15)}" if code < 32 || code == 127
        letter_or_digit?(code) || code == 32 ? code.chr : "\\#{code.chr}"
      end

      #: (Integer) -> String
      def hex(digit)
        "0123456789ABCDEF"[digit, 1].to_s
      end

      # The byte after the ] that closes the collection opened before
      # @pos, -1 when none does; a ] first, after an optional ^, is a
      # member, and so is one after a backslash.
      #: () -> Integer
      def collection_end
        i = @pos
        i += 1 if i < @bytes && @source.getbyte(i) == 94
        i += 1 if i < @bytes && @source.getbyte(i) == 93
        while i < @bytes
          byte = @source.getbyte(i).to_i
          return i if byte == 93
          if byte == 92 && i + 1 < @bytes
            i += 2
          elsif byte == 91 && posix_class_end(i) > 0
            i = posix_class_end(i)
          else
            i += 1
          end
        end
        -1
      end

      # The byte after a [:name:] class at i, 0 when there is none there.
      #: (Integer) -> Integer
      def posix_class_end(i)
        return 0 unless i + 1 < @bytes && @source.getbyte(i + 1) == 58
        close = @source.byteindex(":]", i + 2)
        return 0 if close.nil?
        name = @source.byteslice(i + 2, close - i - 2).to_s
        return 0 unless POSIX.include?(name)
        close + 2
      end

      POSIX = ["alnum", "alpha", "blank", "cntrl", "digit", "graph", "lower", "print", "punct", "space", "upper", "xdigit"]
    end
  end
end
