module Carat
  module Domain
    # Splits a language server's output into JSON-RPC bodies, framed as in
    # the Language Server Protocol: headers of "Name: value" lines ending
    # in a blank line, then Content-Length bytes of body. The output is
    # untrusted, so a header section over HEADER_LIMIT bytes, a missing or
    # malformed Content-Length, or a body over BODY_LIMIT bytes refuses the
    # stream: nothing more is read from it. Fed and read by one thread.
    class RpcFramer
      HEADER_LIMIT = 1024
      BODY_LIMIT = 8 * 1024 * 1024
      SEPARATOR = "\r\n\r\n"
      LENGTH_NAME = "content-length"

      # @rbs @buffer: String
      # @rbs @start: Integer
      # @rbs @length: Integer
      # @rbs @refused: bool

      #: () -> void
      def initialize
        @buffer = +""
        @start = 0
        @length = -1
        @refused = false
      end

      # The frame of a body, ready to write to a server.
      #: (String) -> String
      def self.frame(body)
        "Content-Length: #{body.bytesize}\r\n\r\n#{body}"
      end

      # Whether the stream broke a limit; no body is answered after it.
      #: () -> bool
      def refused?
        @refused
      end

      # Appends bytes read from the server.
      #: (String) -> void
      def feed(bytes)
        @buffer << bytes unless @refused
      end

      # The next complete body, or nil until one is complete or after the
      # stream was refused.
      #: () -> String?
      def next_body
        return nil if @refused
        return nil if @length < 0 && !read_header
        return nil if @buffer.bytesize - @start < @length
        body = @buffer.byteslice(@start, @length).to_s
        @start += @length
        @length = -1
        compact
        body
      end

      private

      # Reads one header section into @length; false while it is not
      # complete or when it was refused.
      #: () -> bool
      def read_header
        stop = @buffer.byteindex(SEPARATOR, @start)
        if stop.nil?
          refuse if @buffer.bytesize - @start > HEADER_LIMIT
          return false
        end
        return refuse if stop - @start > HEADER_LIMIT
        length = content_length(@buffer.byteslice(@start, stop - @start).to_s)
        return refuse if length < 0 || length > BODY_LIMIT
        @length = length
        @start = stop + SEPARATOR.bytesize
        true
      end

      #: () -> bool
      def refuse
        @refused = true
        @buffer = +""
        @start = 0
        false
      end

      # Drops the bytes already read once they are all read or many.
      #: () -> void
      def compact
        return if @start == 0
        return unless @start >= @buffer.bytesize || @start > HEADER_LIMIT * 64
        @buffer = @buffer.byteslice(@start, @buffer.bytesize - @start).to_s
        @start = 0
      end

      # The Content-Length of a header section, or -1 when no line gives
      # one in digits.
      #: (String) -> Integer
      def content_length(header)
        length = -1
        from = 0
        size = header.bytesize
        while from <= size
          stop = header.byteindex("\r\n", from) || size
          length = line_length(header.byteslice(from, stop - from).to_s, length)
          from = stop + 2
        end
        length
      end

      # The length a header line gives, or the one found before.
      #: (String, Integer) -> Integer
      def line_length(line, found)
        colon = line.byteindex(":")
        return found if colon.nil? || !length_name?(line, colon)
        digits(line, colon + 1)
      end

      # Whether the line's name before the colon is Content-Length, in any
      # case of ASCII letters.
      #: (String, Integer) -> bool
      def length_name?(line, colon)
        return false unless colon == LENGTH_NAME.bytesize
        i = 0
        while i < colon
          b = line.getbyte(i).to_i
          b += 32 if b >= 65 && b <= 90
          return false unless b == LENGTH_NAME.getbyte(i).to_i
          i += 1
        end
        true
      end

      # The number after the colon, spaces around it allowed, or -1 for
      # anything else or more than nine digits.
      #: (String, Integer) -> Integer
      def digits(line, from)
        i = from
        size = line.bytesize
        i += 1 while i < size && line.getbyte(i) == 32
        value = 0
        count = 0
        while i < size
          b = line.getbyte(i).to_i
          break unless b >= 48 && b <= 57
          value = value * 10 + (b - 48)
          count += 1
          i += 1
        end
        i += 1 while i < size && line.getbyte(i) == 32
        return -1 if count == 0 || count > 9 || i < size
        value
      end
    end
  end
end
