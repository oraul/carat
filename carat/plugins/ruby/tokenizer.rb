require_relative "groups"
require_relative "keywords"
require_relative "line_state"

module Carat
  module Plugins
    module Ruby
      # Tokenizes one line of Ruby 4 source from the state at its start and
      # returns the state at its end (LineState). It scans bytes, keeps the
      # open string frames of the line in a small stack, and appends tokens
      # as (start, length, id) triples in code point columns, converting
      # byte offsets through a map only for a line with non-ASCII bytes. No
      # string is made per token: keywords are found by Keywords, and
      # heredoc terminators are compared in place against a table of the
      # terminators met so far, which only grows. ids maps a Groups index
      # to the editor's group id, -1 for one not resolved, which is then
      # not emitted.
      #
      # The heuristics are vim-ruby's: a slash, a percent sign, a question
      # mark, or << opens a literal at the start of an expression (after an
      # operator, a keyword, an opening bracket, or a comma) and after a
      # method name followed by a space and then no space; after a value
      # they are operators.
      class Tokenizer
        KIND_STRING = 0
        KIND_SYMBOL = 1
        KIND_REGEX = 2
        STACK = 8
        QUEUE = 4
        # The characters that may follow $ as a special global variable.
        GLOBAL_SPECIALS = "!@&~`'+*$?:\"<>,./\\;=_0"

        attr_reader :keywords #: Keywords
        attr_reader :terminators #: Array[String]
        attr_accessor :ids #: Array[Integer]

        # @rbs @text: String
        # @rbs @size: Integer
        # @rbs @out: Array[Integer]
        # @rbs @ascii: bool
        # @rbs @map: Array[Integer]
        # @rbs @mode: Integer
        # @rbs @closes: Array[Integer]
        # @rbs @interps: Array[Integer]
        # @rbs @kinds: Array[Integer]
        # @rbs @depths: Array[Integer]
        # @rbs @codes: Array[Integer]
        # @rbs @braces: Array[Integer]
        # @rbs @starts: Array[Integer]
        # @rbs @top: Integer
        # @rbs @terms: Array[Integer]
        # @rbs @indents: Array[Integer]
        # @rbs @raws: Array[Integer]
        # @rbs @pending: Integer
        # @rbs @operand: bool
        # @rbs @word: bool
        # @rbs @spaced: bool
        # @rbs @dot: bool

        #: (keywords: Keywords) -> void
        def initialize(keywords:)
          @keywords = keywords
          @terminators = []
          @ids = Array.new(Groups::NAMES.length, -1)
          @text = ""
          @size = 0
          @out = []
          @ascii = true
          @map = Array.new(0, 0)
          @mode = LineState::CODE
          @closes = Array.new(STACK, 0)
          @interps = Array.new(STACK, 0)
          @kinds = Array.new(STACK, 0)
          @depths = Array.new(STACK, 0)
          @codes = Array.new(STACK, 0)
          @braces = Array.new(STACK, 0)
          @starts = Array.new(STACK, -1)
          @top = 0
          @terms = Array.new(QUEUE, 0)
          @indents = Array.new(QUEUE, 0)
          @raws = Array.new(QUEUE, 0)
          @pending = 0
          @operand = false
          @word = false
          @spaced = false
          @dot = false
        end

        # Tokenizes text from state into tokens and returns the end state.
        #: (String, Integer, Array[Integer]) -> Integer
        def call(text, state, tokens)
          @text = text
          @size = text.bytesize
          @out = tokens
          prepare_columns
          decode(state)
          @operand = false
          @word = false
          @spaced = false
          @dot = false
          if @mode == LineState::EMBDOC
            @mode = LineState::CODE if starts_with_word?("=end")
            comment(0)
          elsif @mode == LineState::DATA
            comment(0)
          elsif @pending > 0
            heredoc_line
          elsif @top == 0 && starts_with_word?("=begin")
            @mode = LineState::EMBDOC
            comment(0)
          elsif @top == 0 && end_marker?
            @mode = LineState::DATA
            comment(0)
          else
            scan(0)
          end
          encode
        end

        private

        # ------------------------------------------------------------ state

        #: (Integer) -> void
        def decode(state)
          @mode = LineState.mode(state)
          @pending = LineState.heredoc_count(state)
          i = 0
          while i < @pending
            bits = LineState.heredoc(state, i)
            @terms[i] = LineState.term_of(bits)
            @indents[i] = LineState.indent_of(bits)
            @raws[i] = LineState.raw_of(bits)
            i += 1
          end
          @top = LineState.frame_count(state)
          i = 0
          while i < @top
            bits = LineState.frame(state, i)
            @closes[i] = LineState.close_of(bits)
            @interps[i] = LineState.interp_of(bits)
            @kinds[i] = LineState.kind_of(bits)
            @depths[i] = LineState.depth_of(bits)
            @codes[i] = LineState.code_of(bits)
            @braces[i] = LineState.braces_of(bits)
            @starts[i] = -1
            i += 1
          end
        end

        # Packs what is still open, the outermost two frames and the first
        # two heredocs.
        #: () -> Integer
        def encode
          heredocs = @pending > LineState::MAX_HEREDOCS ? LineState::MAX_HEREDOCS : @pending
          first_heredoc = heredocs > 0 ? LineState.pack_heredoc(@terms[0], @indents[0], @raws[0]) : 0
          second_heredoc = heredocs > 1 ? LineState.pack_heredoc(@terms[1], @indents[1], @raws[1]) : 0
          frames = @top > LineState::MAX_FRAMES ? LineState::MAX_FRAMES : @top
          first_frame = frames > 0 ? frame_bits(0) : 0
          second_frame = frames > 1 ? frame_bits(1) : 0
          LineState.pack(@mode, heredocs, first_heredoc, second_heredoc, frames, first_frame, second_frame)
        end

        #: (Integer) -> Integer
        def frame_bits(i)
          LineState.pack_frame(@closes[i], @interps[i], @kinds[i], @depths[i], @codes[i], @braces[i])
        end

        # ---------------------------------------------------------- columns

        # Fills the byte to code point map for a line with non-ASCII bytes.
        #: () -> void
        def prepare_columns
          text = @text
          size = @size
          i = 0
          while i < size
            break if text.getbyte(i).to_i >= 0x80
            i += 1
          end
          @ascii = i == size
          return if @ascii
          map = @map
          map.clear
          col = -1
          i = 0
          while i < size
            b = text.getbyte(i).to_i
            col += 1 unless b >= 0x80 && b < 0xC0
            map << col
            i += 1
          end
          map << col + 1
        end

        # Appends a token for the bytes [from, to) in a group, joined to the
        # token before when it is the same group and adjacent.
        #: (Integer, Integer, Integer) -> void
        def emit(from, to, group)
          return if to <= from
          id = @ids[group]
          return if id < 0
          start = from
          length = to - from
          unless @ascii
            start = @map[from]
            length = @map[to] - start
          end
          return if length <= 0
          out = @out
          last = out.length
          if last >= 3 && out[last - 1] == id && out[last - 3] + out[last - 2] == start
            out[last - 2] = out[last - 2] + length
            return
          end
          out << start
          out << length
          out << id
        end

        # ------------------------------------------------------------ bytes

        #: (Integer) -> Integer
        def byte(i)
          i < @size ? @text.getbyte(i).to_i : 0
        end

        #: (Integer) -> bool
        def word_byte?(b)
          (b >= 97 && b <= 122) || (b >= 65 && b <= 90) || (b >= 48 && b <= 57) || b == 95 || b >= 0x80
        end

        #: (Integer) -> bool
        def word_start?(b)
          (b >= 97 && b <= 122) || (b >= 65 && b <= 90) || b == 95 || b >= 0x80
        end

        #: (Integer) -> bool
        def digit?(b)
          b >= 48 && b <= 57
        end

        #: (Integer) -> bool
        def space?(b)
          b == 32 || b == 9 || b == 13 || b == 12 || b == 11
        end

        # The end of the identifier that starts at pos.
        #: (Integer) -> Integer
        def word_end(pos)
          i = pos
          i += 1 while i < @size && word_byte?(@text.getbyte(i).to_i)
          i
        end

        # The position after the character at pos.
        #: (Integer) -> Integer
        def next_char(pos)
          i = pos + 1
          while i < @size
            b = @text.getbyte(i).to_i
            break unless b >= 0x80 && b < 0xC0
            i += 1
          end
          i
        end

        # Whether the line starts with the word: followed by its end or a
        # blank.
        #: (String) -> bool
        def starts_with_word?(word)
          length = word.bytesize
          return false if @size < length
          i = 0
          while i < length
            return false unless @text.getbyte(i) == word.getbyte(i)
            i += 1
          end
          @size == length || space?(byte(length))
        end

        # Whether the line is __END__, a carriage return allowed after it.
        #: () -> bool
        def end_marker?
          return false unless @size == 7 || (@size == 8 && byte(7) == 13)
          starts_with_word?("__END__") || (@size == 8 && @text.start_with?("__END__"))
        end

        # ---------------------------------------------------------- comment

        # A comment from pos to the end of the line, with Todo words.
        #: (Integer) -> void
        def comment(pos)
          size = @size
          text = @text
          from = pos
          i = pos
          while i < size
            b = text.getbyte(i).to_i
            if b >= 65 && b <= 90 && (i == 0 || !word_byte?(text.getbyte(i - 1).to_i))
              stop = word_end(i)
              at = @keywords.find(text, i, stop)
              if at >= 0 && @keywords.kind(at) == Groups::TODO
                emit(from, i, Groups::COMMENT)
                emit(i, stop, Groups::TODO)
                from = stop
              end
              i = stop
            else
              i += 1
            end
          end
          emit(from, size, Groups::COMMENT)
        end

        # ---------------------------------------------------------- heredoc

        # A line of the first pending heredoc's body: its terminator, which
        # ends it, or text with interpolation unless it is raw.
        #: () -> void
        def heredoc_line
          start = 0
          start += 1 while @indents[0] == 1 && start < @size && space?(@text.getbyte(start).to_i)
          if terminator_at?(start)
            emit(start, @size, Groups::DELIMITER)
            i = 1
            while i < @pending
              @terms[i - 1] = @terms[i]
              @indents[i - 1] = @indents[i]
              @raws[i - 1] = @raws[i]
              i += 1
            end
            @pending -= 1
            return
          end
          base = @top
          push(0, @raws[0] == 1 ? 0 : 1, KIND_STRING, 0)
          scan(0)
          @top = base
        end

        # Whether the line from pos is the first heredoc's terminator.
        #: (Integer) -> bool
        def terminator_at?(pos)
          term = @terms[0]
          return false if term < 1 || term > @terminators.length
          word = @terminators[term - 1]
          length = word.bytesize
          stop = @size
          stop -= 1 if stop > pos && byte(stop - 1) == 13
          return false unless stop - pos == length
          i = 0
          while i < length
            return false unless word.getbyte(i) == @text.getbyte(pos + i)
            i += 1
          end
          true
        end

        # The number of the terminator in the table, adding it when it is
        # new; 0 when the table is full.
        #: (Integer, Integer) -> Integer
        def terminator(from, to)
          length = to - from
          i = 0
          while i < @terminators.length
            word = @terminators[i]
            if word.bytesize == length
              k = 0
              k += 1 while k < length && word.getbyte(k) == @text.getbyte(from + k)
              return i + 1 if k == length
            end
            i += 1
          end
          return 0 if @terminators.length >= LineState::MAX_TERMINATORS
          @terminators << @text.byteslice(from, length).to_s
          @terminators.length
        end

        # ------------------------------------------------------------ frames

        # Opens a string frame; the literal's text starts at start.
        #: (Integer, Integer, Integer, Integer) -> void
        def push(close, interp, kind, start)
          if @top >= STACK
            @top = STACK - 1
          end
          i = @top
          @closes[i] = close
          @interps[i] = interp
          @kinds[i] = kind
          @depths[i] = 0
          @codes[i] = 0
          @braces[i] = 0
          @starts[i] = start
          @top = i + 1
        end

        # The group of a frame's text.
        #: (Integer) -> Integer
        def frame_group(i)
          @kinds[i] == KIND_SYMBOL ? Groups::CONSTANT : Groups::STRING
        end

        # The opening delimiter paired with a closing one, 0 for none.
        #: (Integer) -> Integer
        def opener_of(close)
          return 40 if close == 41
          return 91 if close == 93
          return 123 if close == 125
          return 60 if close == 62
          0
        end

        # The closing delimiter for an opening one.
        #: (Integer) -> Integer
        def closer_of(open)
          return 41 if open == 40
          return 93 if open == 91
          return 125 if open == 123
          return 62 if open == 60
          open
        end

        # -------------------------------------------------------------- scan

        #: (Integer) -> void
        def scan(pos)
          i = pos
          while i < @size
            i = @top > 0 && @codes[@top - 1] == 0 ? string_part(i) : code_part(i)
          end
          close_line
        end

        # At the end of the line a frame keeps its place; its text starts
        # again at the next line's start.
        #: () -> void
        def close_line
          i = 0
          while i < @top
            @starts[i] = -1
            i += 1
          end
        end

        # The text of the top frame from pos: to its closing delimiter, an
        # interpolation, or the end of the line.
        #: (Integer) -> Integer
        def string_part(pos)
          f = @top - 1
          group = frame_group(f)
          close = @closes[f]
          open = opener_of(close)
          interp = @interps[f] == 1
          regex = @kinds[f] == KIND_REGEX
          from = @starts[f] >= 0 ? @starts[f] : pos
          @starts[f] = -1
          i = pos
          size = @size
          text = @text
          while i < size
            b = text.getbyte(i).to_i
            if b == 92
              stop = escape_end(i, interp)
              special = interp || regex || byte(i + 1) == 92 || byte(i + 1) == close || (open > 0 && byte(i + 1) == open)
              if special
                emit(from, i, group)
                emit(i, stop, Groups::SPECIAL_CHAR)
                from = stop
              end
              i = stop
            elsif b == 35 && interp && byte(i + 1) == 123
              emit(from, i, group)
              emit(i, i + 2, Groups::DELIMITER)
              @codes[f] = 1
              @braces[f] = 0
              @operand = false
              @word = false
              @dot = false
              return i + 2
            elsif b == 35 && interp && (byte(i + 1) == 64 || byte(i + 1) == 36) && variable_end(i + 1) > i + 2
              stop = variable_end(i + 1)
              emit(from, i, group)
              emit(i, stop, Groups::IDENTIFIER)
              from = stop
              i = stop
            elsif open > 0 && b == open
              @depths[f] += 1 if @depths[f] < LineState::MAX_DEPTH
              i += 1
            elsif b == close && close != 0
              if @depths[f] > 0
                @depths[f] -= 1
                i += 1
              else
                @top = f
                @operand = true
                @word = false
                @spaced = false
                if regex
                  emit(from, i, group)
                  stop = i + 1
                  stop += 1 while stop < size && regex_flag?(text.getbyte(stop).to_i)
                  emit(i, stop, Groups::DELIMITER)
                  return stop
                end
                emit(from, i + 1, group)
                return i + 1
              end
            else
              i = next_char(i)
            end
          end
          emit(from, size, group)
          size
        end

        #: (Integer) -> bool
        def regex_flag?(b)
          b == 105 || b == 109 || b == 120 || b == 111 || b == 117 || b == 110 || b == 101 || b == 115
        end

        # The end of the escape at pos: \u{...}, \uXXXX, \xHH, octal
        # digits, \C-x and \M-x in an interpolating literal, otherwise the
        # backslash and one character.
        #: (Integer, bool) -> Integer
        def escape_end(pos, interp)
          c = byte(pos + 1)
          return pos + 1 if pos + 1 >= @size
          if interp
            if c == 117
              if byte(pos + 2) == 123
                i = pos + 3
                i += 1 while i < @size && byte(i) != 125
                return i < @size ? i + 1 : i
              end
              return hex_end(pos + 2, 4)
            end
            return hex_end(pos + 2, 2) if c == 120
            if c >= 48 && c <= 55
              i = pos + 2
              i += 1 while i < pos + 4 && byte(i) >= 48 && byte(i) <= 55
              return i
            end
            return next_char(pos + 3) if (c == 67 || c == 77) && byte(pos + 2) == 45 && pos + 3 < @size
          end
          next_char(pos + 1)
        end

        #: (Integer, Integer) -> Integer
        def hex_end(pos, count)
          i = pos
          while i < pos + count && i < @size
            b = byte(i)
            break unless digit?(b) || (b >= 97 && b <= 102) || (b >= 65 && b <= 70)
            i += 1
          end
          i
        end

        # The end of the variable whose sigil is at pos: @name, @@name,
        # $name, or $ and one special character; pos when there is none.
        #: (Integer) -> Integer
        def variable_end(pos)
          b = byte(pos)
          if b == 64
            i = byte(pos + 1) == 64 ? pos + 2 : pos + 1
            return word_start?(byte(i)) ? word_end(i) : pos
          end
          return pos unless b == 36
          c = byte(pos + 1)
          return word_end(pos + 1) if word_start?(c)
          if c == 45
            return word_byte?(byte(pos + 2)) ? pos + 3 : pos
          end
          return word_end(pos + 1) if digit?(c)
          specials = GLOBAL_SPECIALS
          i = 0
          while i < specials.bytesize
            return pos + 2 if specials.getbyte(i) == c
            i += 1
          end
          pos
        end

        # --------------------------------------------------------------- code

        # Whether a literal may start here: at the start of an expression,
        # or after a method name with a space before and none after.
        #: (Integer) -> bool
        def literal_allowed?(after)
          return true unless @operand
          @word && @spaced && after < @size && !space?(byte(after)) && byte(after) != 61
        end

        # One token of code at pos; returns the position after it.
        #: (Integer) -> Integer
        def code_part(pos)
          b = @text.getbyte(pos).to_i
          if space?(b)
            i = pos + 1
            i += 1 while i < @size && space?(@text.getbyte(i).to_i)
            @spaced = true
            return i
          end
          stop = code_token(pos, b)
          @spaced = false
          stop
        end

        #: (Integer, Integer) -> Integer
        def code_token(pos, b)
          f = @top - 1
          if b == 35
            comment(pos)
            return @size
          end
          if b == 125 && f >= 0
            if @braces[f] == 0
              emit(pos, pos + 1, Groups::DELIMITER)
              @codes[f] = 0
              @starts[f] = pos + 1
              return pos + 1
            end
            @braces[f] -= 1
            value
            return pos + 1
          end
          if b == 123
            @braces[f] += 1 if f >= 0 && @braces[f] < LineState::MAX_BRACES
            operator
            return pos + 1
          end
          return word(pos) if word_start?(b)
          return number(pos) if digit?(b)
          case b
          when 34 then return open_string(pos, 34, 1, KIND_STRING, pos + 1)
          when 39 then return open_string(pos, 39, 0, KIND_STRING, pos + 1)
          when 96 then return open_string(pos, 96, 1, KIND_STRING, pos + 1)
          when 64, 36
            stop = variable_end(pos)
            if stop > pos
              emit(pos, stop, Groups::IDENTIFIER)
              value
              return stop
            end
          when 58 then return colon(pos)
          when 47
            if literal_allowed?(pos + 1)
              emit(pos, pos + 1, Groups::DELIMITER)
              push(47, 1, KIND_REGEX, pos + 1)
              return pos + 1
            end
          when 37
            stop = percent(pos)
            return stop if stop > pos
          when 63
            stop = character(pos)
            return stop if stop > pos
          when 60
            stop = heredoc(pos)
            return stop if stop > pos
          when 41, 93
            value
            return pos + 1
          when 46
            if byte(pos + 1) == 46
              operator
              return byte(pos + 2) == 46 ? pos + 3 : pos + 2
            end
            operator
            @dot = true
            return pos + 1
          end
          operator
          next_char(pos)
        end

        # After a value: a slash divides.
        #: () -> void
        def value
          @operand = true
          @word = false
          @dot = false
        end

        # After an operator or an opening bracket: a slash starts a
        # regular expression.
        #: () -> void
        def operator
          @operand = false
          @word = false
          @dot = false
        end

        # Opens a quoted literal whose text, the opening quote included,
        # starts at start.
        #: (Integer, Integer, Integer, Integer, Integer) -> Integer
        def open_string(pos, close, interp, kind, after)
          push(close, interp, kind, pos)
          after
        end

        # A word: a label, a method name after a dot, a keyword, a
        # constant, or a name.
        #: (Integer) -> Integer
        def word(pos)
          stop = word_end(pos)
          b = byte(stop)
          if (b == 63 || b == 33) && (byte(stop + 1) != 61 || byte(stop + 2) == 61)
            stop += 1
          end
          last = byte(stop - 1)
          if byte(stop) == 58 && byte(stop + 1) != 58 && last != 63 && !@dot
            emit(pos, stop + 1, Groups::CONSTANT)
            operator
            return stop + 1
          end
          if @dot
            value
            @word = true
            return stop
          end
          at = @keywords.find(@text, pos, stop)
          if at >= 0 && @keywords.kind(at) != Groups::TODO
            kind = @keywords.kind(at)
            emit(pos, stop, kind)
            if @keywords.value?(at)
              value
            else
              operator
            end
            word_text = Keywords::WORDS[at]
            return definition(stop) if word_text == "def"
            return class_name(stop) if word_text == "class" || word_text == "module"
            return stop
          end
          first = @text.getbyte(pos).to_i
          if first >= 65 && first <= 90
            emit(pos, stop, Groups::TYPE)
            value
            return stop
          end
          value
          @word = true
          stop
        end

        # After def: an optional receiver (self, a constant, or a name)
        # and a dot, then the method name, a name with ?, !, or = or an
        # operator, as Function.
        #: (Integer) -> Integer
        def definition(pos)
          i = pos
          i += 1 while i < @size && space?(byte(i))
          if word_start?(byte(i))
            stop = word_end(i)
            if byte(stop) == 46 && byte(stop + 1) != 46
              at = @keywords.find(@text, i, stop)
              if at >= 0 && Keywords::WORDS[at] == "self"
                emit(i, stop, Groups::CONSTANT)
              elsif byte(i) >= 65 && byte(i) <= 90
                emit(i, stop, Groups::TYPE)
              end
              i = stop + 1
            end
          end
          if word_start?(byte(i))
            stop = word_end(i)
            b = byte(stop)
            stop += 1 if b == 63 || b == 33 || (b == 61 && byte(stop + 1) != 61 && byte(stop + 1) != 126 && byte(stop + 1) != 62)
            emit(i, stop, Groups::FUNCTION)
            operator
            return stop
          end
          stop = operator_name(i)
          emit(i, stop, Groups::FUNCTION) if stop > i
          operator
          stop > i ? stop : pos
        end

        OPERATOR_NAMES = ["[]=", "[]", "<=>", "===", "==", "=~", "!=", "!~", "**", "+@", "-@", "<<", ">>", "<=", ">=", "<", ">", "+", "-", "*", "/", "%", "&", "|", "^", "~", "!", "`"]

        # The end of an operator method name at pos, pos for none.
        #: (Integer) -> Integer
        def operator_name(pos)
          i = 0
          while i < OPERATOR_NAMES.length
            name = OPERATOR_NAMES[i]
            length = name.bytesize
            k = 0
            k += 1 while k < length && byte(pos + k) == name.getbyte(k)
            return pos + length if k == length
            i += 1
          end
          pos
        end

        # After class or module: the constant path as one Type token; a
        # singleton class (class << self) is left to the operator.
        #: (Integer) -> Integer
        def class_name(pos)
          i = pos
          i += 1 while i < @size && space?(byte(i))
          start = i
          stop = i
          while true
            i += 2 if byte(i) == 58 && byte(i + 1) == 58
            break unless byte(i) >= 65 && byte(i) <= 90
            i = word_end(i)
            stop = i
            break unless byte(i) == 58 && byte(i + 1) == 58
          end
          i = stop
          return pos if i == start
          emit(start, i, Groups::TYPE)
          value
          i
        end

        # A number: hexadecimal, binary, octal, or decimal with underscores,
        # a fraction and an exponent making it a Float, and the rational and
        # imaginary suffixes.
        #: (Integer) -> Integer
        def number(pos)
          i = pos
          float = false
          c = byte(pos + 1)
          if byte(pos) == 48 && (c == 120 || c == 88)
            i += 2
            i += 1 while i < @size && (digit?(byte(i)) || (byte(i) >= 97 && byte(i) <= 102) || (byte(i) >= 65 && byte(i) <= 70) || byte(i) == 95)
          elsif byte(pos) == 48 && (c == 98 || c == 66)
            i += 2
            i += 1 while i < @size && (byte(i) == 48 || byte(i) == 49 || byte(i) == 95)
          elsif byte(pos) == 48 && (c == 111 || c == 79 || c == 100 || c == 68)
            i += 2
            i += 1 while i < @size && (digit?(byte(i)) || byte(i) == 95)
          else
            i += 1 while i < @size && (digit?(byte(i)) || byte(i) == 95)
            if byte(i) == 46 && digit?(byte(i + 1))
              float = true
              i += 1
              i += 1 while i < @size && (digit?(byte(i)) || byte(i) == 95)
            end
            e = byte(i)
            if e == 101 || e == 69
              s = byte(i + 1)
              if digit?(s) || ((s == 43 || s == 45) && digit?(byte(i + 2)))
                float = true
                i += 2
                i += 1 while i < @size && (digit?(byte(i)) || byte(i) == 95)
              end
            end
          end
          if byte(i) == 114 && !word_byte?(byte(i + 1))
            i += 1
          elsif byte(i) == 114 && byte(i + 1) == 105 && !word_byte?(byte(i + 2))
            i += 2
          end
          i += 1 if byte(i) == 105 && !word_byte?(byte(i + 1))
          emit(pos, i, float ? Groups::FLOAT : Groups::NUMBER)
          value
          i
        end

        # A colon: ::, a quoted symbol, a symbol, or a ternary colon.
        #: (Integer) -> Integer
        def colon(pos)
          c = byte(pos + 1)
          if c == 58
            operator
            return pos + 2
          end
          return open_string(pos, 34, 1, KIND_SYMBOL, pos + 2) if c == 34
          return open_string(pos, 39, 0, KIND_SYMBOL, pos + 2) if c == 39
          if word_start?(c)
            stop = word_end(pos + 1)
            b = byte(stop)
            stop += 1 if b == 63 || b == 33 || (b == 61 && byte(stop + 1) != 61 && byte(stop + 1) != 62 && byte(stop + 1) != 126)
            emit(pos, stop, Groups::CONSTANT)
            value
            return stop
          end
          if c == 64 || c == 36
            stop = variable_end(pos + 1)
            if stop > pos + 1
              emit(pos, stop, Groups::CONSTANT)
              value
              return stop
            end
          end
          if !@operand || @spaced
            stop = operator_name(pos + 1)
            if stop > pos + 1
              emit(pos, stop, Groups::CONSTANT)
              value
              return stop
            end
          end
          operator
          pos + 1
        end

        # A percent literal at pos, its end; pos when it is the operator.
        #: (Integer) -> Integer
        def percent(pos)
          return pos unless literal_allowed?(pos + 1)
          c = byte(pos + 1)
          type = 0
          open = c
          if c == 119 || c == 87 || c == 105 || c == 73 || c == 113 || c == 81 || c == 114 || c == 115 || c == 120
            type = c
            open = byte(pos + 2)
          end
          return pos unless delimiter?(open)
          after = type == 0 ? pos + 2 : pos + 3
          interp = type == 0 || type == 87 || type == 73 || type == 81 || type == 114 || type == 120 ? 1 : 0
          kind = KIND_STRING
          kind = KIND_SYMBOL if type == 105 || type == 73 || type == 115
          if type == 114
            emit(pos, after, Groups::DELIMITER)
            push(closer_of(open), 1, KIND_REGEX, after)
            return after
          end
          open_string(pos, closer_of(open), interp, kind, after)
        end

        # Whether a byte may delimit a percent literal: printable ASCII
        # punctuation.
        #: (Integer) -> bool
        def delimiter?(b)
          b > 32 && b < 127 && !word_byte?(b)
        end

        # A character literal (?a, ?\n) at pos, its end; pos for a ternary
        # question mark.
        #: (Integer) -> Integer
        def character(pos)
          return pos unless literal_allowed?(pos + 1)
          c = byte(pos + 1)
          return pos if pos + 1 >= @size || space?(c)
          stop = c == 92 ? escape_end(pos + 1, true) : next_char(pos + 1)
          return pos if c != 92 && word_byte?(byte(stop))
          emit(pos, stop, Groups::CHARACTER)
          value
          stop
        end

        # A heredoc opener at pos (<<ID, <<-ID, <<~ID, the identifier bare
        # or quoted), queued for the next lines; pos when it is <<.
        #: (Integer) -> Integer
        def heredoc(pos)
          return pos unless byte(pos + 1) == 60
          i = pos + 2
          indent = 0
          if byte(i) == 126 || byte(i) == 45
            indent = 1
            i += 1
          end
          quote = byte(i)
          raw = 0
          from = i
          stop = i
          after = i
          if quote == 34 || quote == 39 || quote == 96
            from = i + 1
            stop = from
            stop += 1 while stop < @size && byte(stop) != quote
            return pos if stop >= @size || stop == from
            after = stop + 1
            raw = quote == 39 ? 1 : 0
          elsif word_start?(quote)
            stop = word_end(i)
            after = stop
          else
            return pos
          end
          return pos unless !@operand || (@word && @spaced)
          emit(pos, after, Groups::DELIMITER)
          term = terminator(from, stop)
          if term > 0 && @pending < QUEUE
            @terms[@pending] = term
            @indents[@pending] = indent
            @raws[@pending] = raw
            @pending += 1
          end
          value
          after
        end
      end
    end
  end
end
