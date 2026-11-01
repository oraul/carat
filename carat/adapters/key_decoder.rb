require_relative "../domain/key"

module Carat
  module Adapters
    # Turns terminal bytes into key codes. An incomplete escape or UTF-8
    # sequence stays pending until more bytes arrive or flush is called,
    # which is how a lone Escape is told apart from a sequence.
    class KeyDecoder
      # What is pending when nothing is: one string kept for that, since
      # most reads decode whole.
      NOTHING = "".b

      # @rbs @pending: String

      #: () -> void
      def initialize
        @pending = "".b
      end

      #: () -> bool
      def pending?
        !@pending.empty?
      end

      # Decodes as many keys as the bytes so far allow.
      #: (String) -> Array[Integer]
      def feed(bytes)
        @pending = @pending.empty? ? bytes.b : @pending + bytes.b
        decode
      end

      # Resolves what is pending after the escape timeout: a leading Escape
      # byte is the Escape key; an incomplete character is dropped.
      #: () -> Array[Integer]
      def flush
        return [] if @pending.empty?
        codes = []
        if @pending.getbyte(0) == 27
          codes << Domain::Key::ESC
          @pending = @pending.byteslice(1, @pending.bytesize - 1)
        else
          @pending = "".b
        end
        codes.concat(decode)
        codes
      end

      # The bytes a terminal sends for a key: the inverse of feed, used by
      # FakeTerminal so tests type keys in Vim notation.
      #: (Integer) -> String
      def self.encode(code)
        return "\e" + encode(Domain::Key.base(code)) if Domain::Key.alt?(code)
        case code
        when Domain::Key::UP then "\e[A"
        when Domain::Key::DOWN then "\e[B"
        when Domain::Key::RIGHT then "\e[C"
        when Domain::Key::LEFT then "\e[D"
        when Domain::Key::HOME then "\e[H"
        when Domain::Key::END_KEY then "\e[F"
        when Domain::Key::INSERT then "\e[2~"
        when Domain::Key::DELETE then "\e[3~"
        when Domain::Key::PAGE_UP then "\e[5~"
        when Domain::Key::PAGE_DOWN then "\e[6~"
        when Domain::Key::F1 then "\eOP"
        when Domain::Key::F2 then "\eOQ"
        when Domain::Key::F3 then "\eOR"
        when Domain::Key::F4 then "\eOS"
        when Domain::Key::F5 then "\e[15~"
        when Domain::Key::F6 then "\e[17~"
        when Domain::Key::F7 then "\e[18~"
        when Domain::Key::F8 then "\e[19~"
        when Domain::Key::F9 then "\e[20~"
        when Domain::Key::F10 then "\e[21~"
        when Domain::Key::F11 then "\e[23~"
        when Domain::Key::F12 then "\e[24~"
        else Domain::Key.char(code)
        end
      end

      private

      #: () -> Array[Integer]
      def decode
        codes = []
        loop do
          break if @pending.empty?
          b = @pending.getbyte(0)
          if b == 27
            break unless decode_escape(codes)
          elsif b < 128
            codes << b
            consume(1)
          else
            break unless decode_utf8(0, codes, 0)
          end
        end
        codes
      end

      # Handles a leading Escape. Returns false when more bytes are needed.
      #: (Array[Integer]) -> bool
      def decode_escape(codes)
        return false if @pending.bytesize < 2
        n = @pending.getbyte(1)
        if n == 91
          decode_csi(codes)
        elsif n == 79
          return false if @pending.bytesize < 3
          codes << ss3_key(@pending.getbyte(2))
          consume(3)
          true
        elsif n == 27
          codes << Domain::Key::ESC
          consume(1)
          true
        else
          decode_utf8(1, codes, Domain::Key::ALT)
        end
      end

      # ESC [ params final. Returns false when the final byte is not here
      # yet.
      #: (Array[Integer]) -> bool
      def decode_csi(codes)
        i = 2
        size = @pending.bytesize
        while i < size
          b = @pending.getbyte(i)
          break if b >= 0x40 && b <= 0x7E
          i += 1
        end
        return false if i >= size
        final = @pending.getbyte(i)
        params = @pending.byteslice(2, i - 2)
        first = params.split(";")[0]
        number = first.nil? ? 0 : first.to_i
        codes << csi_key(final, number)
        consume(i + 1)
        true
      end

      #: (Integer, Integer) -> Integer
      def csi_key(final, number)
        case final
        when 65 then Domain::Key::UP
        when 66 then Domain::Key::DOWN
        when 67 then Domain::Key::RIGHT
        when 68 then Domain::Key::LEFT
        when 72 then Domain::Key::HOME
        when 70 then Domain::Key::END_KEY
        when 80 then Domain::Key::F1
        when 81 then Domain::Key::F2
        when 82 then Domain::Key::F3
        when 83 then Domain::Key::F4
        when 126 then tilde_key(number)
        else Domain::Key::UNKNOWN
        end
      end

      #: (Integer) -> Integer
      def tilde_key(number)
        case number
        when 1, 7 then Domain::Key::HOME
        when 2 then Domain::Key::INSERT
        when 3 then Domain::Key::DELETE
        when 4, 8 then Domain::Key::END_KEY
        when 5 then Domain::Key::PAGE_UP
        when 6 then Domain::Key::PAGE_DOWN
        when 11 then Domain::Key::F1
        when 12 then Domain::Key::F2
        when 13 then Domain::Key::F3
        when 14 then Domain::Key::F4
        when 15 then Domain::Key::F5
        when 17 then Domain::Key::F6
        when 18 then Domain::Key::F7
        when 19 then Domain::Key::F8
        when 20 then Domain::Key::F9
        when 21 then Domain::Key::F10
        when 23 then Domain::Key::F11
        when 24 then Domain::Key::F12
        else Domain::Key::UNKNOWN
        end
      end

      #: (Integer) -> Integer
      def ss3_key(final)
        case final
        when 65 then Domain::Key::UP
        when 66 then Domain::Key::DOWN
        when 67 then Domain::Key::RIGHT
        when 68 then Domain::Key::LEFT
        when 72 then Domain::Key::HOME
        when 70 then Domain::Key::END_KEY
        when 80 then Domain::Key::F1
        when 81 then Domain::Key::F2
        when 82 then Domain::Key::F3
        when 83 then Domain::Key::F4
        else Domain::Key::UNKNOWN
        end
      end

      # Decodes one UTF-8 character at offset, or-ing flag into its code.
      # Returns false when the character is incomplete.
      #: (Integer, Array[Integer], Integer) -> bool
      def decode_utf8(offset, codes, flag)
        lead = @pending.getbyte(offset)
        length = utf8_length(lead)
        if length == 0
          codes << (0xFFFD | flag)
          consume(offset + 1)
          return true
        end
        return false if @pending.bytesize < offset + length
        text = @pending.byteslice(offset, length).force_encoding("UTF-8")
        codes << ((text.valid_encoding? ? text.ord : 0xFFFD) | flag)
        consume(offset + length)
        true
      end

      #: (Integer) -> Integer
      def utf8_length(lead)
        return 1 if lead < 0x80
        return 2 if lead >= 0xC2 && lead <= 0xDF
        return 3 if lead >= 0xE0 && lead <= 0xEF
        return 4 if lead >= 0xF0 && lead <= 0xF4
        0
      end

      #: (Integer) -> void
      def consume(count)
        rest = @pending.bytesize - count
        @pending = rest > 0 ? @pending.byteslice(count, rest) : NOTHING
      end
    end
  end
end
