require_relative "utf8"

module Carat
  # A small JSON reader and writer. Spinel bundles no json library, so this is
  # the only JSON code in the project. It handles the full JSON grammar except
  # that numbers are parsed as Integer when they have no fraction or exponent
  # and as Float otherwise, and \u escapes are decoded into UTF-8.
  #
  # Values map to Hash (string keys), Array, String, Integer, Float, true,
  # false and nil. Errors raise Carat::Json::Error with a byte offset.
  #
  # Text from a language server is untrusted: arrays and objects nest at
  # most MAX_DEPTH deep, so a hostile body cannot exhaust the stack, and a
  # byte outside a well-formed UTF-8 sequence reads and writes as U+FFFD,
  # walked with Domain::Utf8 since Spinel's each_char and index group such bytes.
  module Json
    MAX_DEPTH = 64
    REPLACEMENT = "\u{FFFD}"

    class Error < StandardError
    end

    #: (String) -> untyped
    def self.parse(text)
      Parser.new(text: text).parse
    end

    #: (untyped) -> String
    def self.generate(value)
      out = +""
      Writer.new(out: out, pretty: false).write(value, 0)
      out
    end

    #: (untyped) -> String
    def self.pretty_generate(value)
      out = +""
      Writer.new(out: out, pretty: true).write(value, 0)
      out
    end

    class Parser
      # @rbs @text: String
      # @rbs @pos: Integer
      # @rbs @len: Integer
      # @rbs @depth: Integer

      #: (text: String) -> void
      def initialize(text:)
        @text = text
        @pos = 0
        @len = text.bytesize
        @depth = 0
      end

      #: () -> untyped
      def parse
        skip_whitespace
        value = parse_value
        skip_whitespace
        error("trailing characters") if @pos < @len
        value
      end

      private

      #: (String) -> void
      def error(message)
        raise Error, "#{message} at byte #{@pos}"
      end

      #: () -> Integer
      def peek
        @pos < @len ? @text.getbyte(@pos) : -1
      end

      #: () -> void
      def skip_whitespace
        while @pos < @len
          b = @text.getbyte(@pos)
          break unless b == 32 || b == 9 || b == 10 || b == 13
          @pos += 1
        end
      end

      #: () -> untyped
      def parse_value
        b = peek
        if b == 123 # {
          parse_object
        elsif b == 91 # [
          parse_array
        elsif b == 34 # "
          parse_string
        elsif b == 116 # t
          expect_word("true")
          true
        elsif b == 102 # f
          expect_word("false")
          false
        elsif b == 110 # n
          expect_word("null")
          nil
        elsif b == 45 || (b >= 48 && b <= 57) # - or digit
          parse_number
        else
          error("unexpected character")
        end
      end

      #: (String) -> void
      def expect_word(word)
        if @text.byteslice(@pos, word.bytesize) == word
          @pos += word.bytesize
        else
          error("expected #{word}")
        end
      end

      #: () -> void
      def descend
        @depth += 1
        error("nesting too deep") if @depth > MAX_DEPTH
      end

      #: () -> Hash[String, untyped]
      def parse_object
        @pos += 1
        descend
        result = {}
        skip_whitespace
        if peek == 125 # }
          @pos += 1
          @depth -= 1
          return result
        end
        while true
          skip_whitespace
          error("expected string key") unless peek == 34
          key = parse_string
          skip_whitespace
          error("expected colon") unless peek == 58
          @pos += 1
          skip_whitespace
          result[key] = parse_value
          skip_whitespace
          b = peek
          if b == 44 # ,
            @pos += 1
          elsif b == 125 # }
            @pos += 1
            @depth -= 1
            return result
          else
            error("expected comma or closing brace")
          end
        end
      end

      #: () -> Array[untyped]
      def parse_array
        @pos += 1
        descend
        result = []
        skip_whitespace
        if peek == 93 # ]
          @pos += 1
          @depth -= 1
          return result
        end
        while true
          skip_whitespace
          result << parse_value
          skip_whitespace
          b = peek
          if b == 44 # ,
            @pos += 1
          elsif b == 93 # ]
            @pos += 1
            @depth -= 1
            return result
          else
            error("expected comma or closing bracket")
          end
        end
      end

      #: () -> String
      def parse_string
        @pos += 1
        out = +""
        while true
          error("unterminated string") if @pos >= @len
          b = @text.getbyte(@pos)
          if b == 34 # "
            @pos += 1
            return out
          elsif b == 92 # backslash
            @pos += 1
            error("unterminated escape") if @pos >= @len
            e = @text.getbyte(@pos)
            @pos += 1
            if e == 34 then out << "\""
            elsif e == 92 then out << "\\"
            elsif e == 47 then out << "/"
            elsif e == 98 then out << "\b"
            elsif e == 102 then out << "\f"
            elsif e == 110 then out << "\n"
            elsif e == 114 then out << "\r"
            elsif e == 116 then out << "\t"
            elsif e == 117 then out << parse_unicode_escape
            else error("bad escape")
            end
          elsif b >= 0x80
            size = Domain::Utf8.size_at(@text, @pos, @len)
            if size == 1
              out << REPLACEMENT
            else
              out << @text.byteslice(@pos, size).to_s
            end
            @pos += size
          else
            error("control character in string") if b < 32
            start = @pos
            @pos += 1
            @pos += 1 while @pos < @len && ascii_text?(@text.getbyte(@pos).to_i)
            out << @text.byteslice(start, @pos - start)
          end
        end
      end

      # Whether a byte continues a run of plain ASCII string text.
      #: (Integer) -> bool
      def ascii_text?(b)
        b >= 32 && b < 0x80 && b != 34 && b != 92
      end

      #: () -> String
      def parse_unicode_escape
        code = read_hex4
        if code >= 0xD800 && code <= 0xDBFF
          # High surrogate: a low surrogate must follow as \uXXXX.
          error("missing low surrogate") unless @text.byteslice(@pos, 2) == "\\u"
          @pos += 2
          low = read_hex4
          error("bad low surrogate") unless low >= 0xDC00 && low <= 0xDFFF
          code = 0x10000 + ((code - 0xD800) << 10) + (low - 0xDC00)
        end
        return REPLACEMENT unless Domain::Utf8.scalar?(code)
        [code].pack("U")
      end

      #: () -> Integer
      def read_hex4
        error("short unicode escape") if @pos + 4 > @len
        value = 0
        4.times do
          b = @text.getbyte(@pos)
          digit = if b >= 48 && b <= 57 then b - 48
                  elsif b >= 97 && b <= 102 then b - 87
                  elsif b >= 65 && b <= 70 then b - 55
                  else error("bad hex digit")
                  end
          value = value * 16 + digit
          @pos += 1
        end
        value
      end

      #: () -> (Integer | Float)
      def parse_number
        start = @pos
        @pos += 1 if peek == 45
        error("expected digit") unless digit?(peek)
        if peek == 48
          @pos += 1
        else
          @pos += 1 while digit?(peek)
        end
        float = false
        if peek == 46 # .
          float = true
          @pos += 1
          error("expected digit after point") unless digit?(peek)
          @pos += 1 while digit?(peek)
        end
        if peek == 101 || peek == 69 # e E
          float = true
          @pos += 1
          @pos += 1 if peek == 43 || peek == 45
          error("expected digit in exponent") unless digit?(peek)
          @pos += 1 while digit?(peek)
        end
        text = @text.byteslice(start, @pos - start)
        float ? text.to_f : text.to_i
      end

      #: (Integer) -> bool
      def digit?(b)
        b >= 48 && b <= 57
      end
    end

    class Writer
      # @rbs @out: String
      # @rbs @pretty: bool

      #: (out: String, pretty: bool) -> void
      def initialize(out:, pretty:)
        @out = out
        @pretty = pretty
      end

      #: (untyped, Integer) -> void
      def write(value, depth)
        if value.nil?
          @out << "null"
        elsif value == true
          @out << "true"
        elsif value == false
          @out << "false"
        elsif value.is_a?(Integer) || value.is_a?(Float)
          @out << value.to_s
        elsif value.is_a?(String)
          write_string(value)
        elsif value.is_a?(Array)
          write_array(value, depth)
        elsif value.is_a?(Hash)
          write_object(value, depth)
        else
          raise Error, "cannot write #{value.class}"
        end
      end

      private

      #: (Integer) -> void
      def newline(depth)
        return unless @pretty
        @out << "\n"
        @out << ("  " * depth)
      end

      #: (Array[untyped], Integer) -> void
      def write_array(value, depth)
        if value.empty?
          @out << "[]"
          return
        end
        @out << "["
        i = 0
        while i < value.length
          @out << "," if i > 0
          newline(depth + 1)
          write(value[i], depth + 1)
          i += 1
        end
        newline(depth)
        @out << "]"
      end

      #: (Hash[untyped, untyped], Integer) -> void
      def write_object(value, depth)
        if value.empty?
          @out << "{}"
          return
        end
        @out << "{"
        first = true
        value.each do |k, v|
          @out << "," unless first
          first = false
          newline(depth + 1)
          write_string(k.to_s)
          @out << (@pretty ? ": " : ":")
          write(v, depth + 1)
        end
        newline(depth)
        @out << "}"
      end

      # Walks the bytes: a run of plain ASCII is copied at once, a
      # well-formed UTF-8 sequence as it is, and any other byte as U+FFFD.
      #: (String) -> void
      def write_string(s)
        @out << "\""
        len = s.bytesize
        i = 0
        while i < len
          b = s.getbyte(i).to_i
          if b >= 32 && b < 0x80 && b != 34 && b != 92
            start = i
            i += 1
            i += 1 while i < len && plain?(s.getbyte(i).to_i)
            @out << s.byteslice(start, i - start).to_s
          elsif b >= 0x80
            size = Domain::Utf8.size_at(s, i, len)
            if size == 1
              @out << REPLACEMENT
            else
              @out << s.byteslice(i, size).to_s
            end
            i += size
          else
            write_escape(b)
            i += 1
          end
        end
        @out << "\""
      end

      # Whether a byte is plain ASCII string text, copied as it is.
      #: (Integer) -> bool
      def plain?(b)
        b >= 32 && b < 0x80 && b != 34 && b != 92
      end

      # Writes the escape of a quote, a backslash, or a control byte.
      #: (Integer) -> void
      def write_escape(b)
        if b == 34 then @out << "\\\""
        elsif b == 92 then @out << "\\\\"
        elsif b == 10 then @out << "\\n"
        elsif b == 13 then @out << "\\r"
        elsif b == 9 then @out << "\\t"
        elsif b == 8 then @out << "\\b"
        elsif b == 12 then @out << "\\f"
        else @out << format("\\u%04x", b)
        end
      end
    end
  end
end
