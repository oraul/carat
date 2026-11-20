require "io/console"
require_relative "../ports/terminal_port"
require_relative "../domain/color_depth"
require_relative "../domain/terminal_background"

module Carat
  module Drivers
    # The real terminal: window size through io/console, byte reads with
    # IO.select and readpartial so no bytes hide in a stdio buffer, and
    # flushed writes. Raw mode is entered by bin/carat.rb around the loop.
    # The color depth comes from COLORTERM and TERM and the wish for no
    # color from NO_COLOR, read once here: the drivers are the only place
    # the environment is read. Entering asks the terminal for its
    # background (OSC 11) and waits for no answer; the answer, untrusted
    # input, arrives among the key bytes, and the reads take it out
    # (Domain::TerminalBackground) until one has come.
    class AnsiTerminal < Ports::TerminalPort
      # @rbs @input: IO
      # @rbs @output: IO
      # @rbs @colors: Integer
      # @rbs @no_color: bool
      # @rbs @background: String
      # @rbs @awaiting: bool
      # @rbs @reply: String

      #: (input: IO, output: IO) -> void
      def initialize(input:, output:)
        @input = input
        @output = output
        @colors = Domain::ColorDepth.detect(environment("COLORTERM"), environment("TERM"))
        @no_color = !environment("NO_COLOR").empty?
        @background = Domain::TerminalBackground::UNKNOWN
        @awaiting = false
        @reply = ""
      end

      # Returns true when NO_COLOR was set and not empty when the driver
      # was made.
      # @rbs skip
      def no_color?
        @no_color
      end

      # Returns the color depth decided when the driver was made.
      # @rbs skip
      def colors
        @colors
      end

      # Returns "dark" or "light" once the terminal answered the query
      # with a color, "" before that, with no answer, or a malformed one.
      # @rbs skip
      def background
        @background
      end

      # Returns [rows, cols], falling back to 24 by 80 when the terminal
      # reports no size.
      # @rbs skip
      def size
        s = @output.winsize
        rows = s[0]
        cols = s[1]
        rows = 24 if rows <= 0
        cols = 80 if cols <= 0
        [rows, cols]
      end

      # Returns the key bytes of one read, or nil on timeout, at the end
      # of input, or when the read held only the terminal's answer. While
      # the answer is awaited a read that times out drops the held start
      # of an answer, cut short.
      # @rbs timeout: Float
      def read_key(timeout)
        bytes = read_bytes(timeout)
        return bytes unless @awaiting
        if bytes.nil?
          finish_reply(Domain::TerminalBackground::UNKNOWN) unless @reply.empty?
          return nil
        end
        data = @reply.empty? ? bytes : @reply + bytes
        @reply = ""
        keys = take_reply(data)
        return nil if keys.empty?
        keys
      end

      #: (String) -> void
      def write(bytes)
        @output.write(bytes)
        @output.flush
      end

      # Asks for the background and returns without reading.
      #: () -> void
      def enter
        @output.write(Domain::TerminalBackground::QUERY)
        @output.flush
        @awaiting = true
      end

      #: () -> void
      def leave
        @output.flush
      end

      private

      # The bytes of one read, nil on timeout or end of input.
      #: (Float) -> String?
      def read_bytes(timeout)
        ready = IO.select([@input], nil, nil, timeout)
        return nil if ready.nil?
        begin
          @input.readpartial(4096)
        rescue EOFError
          nil
        end
      end

      # The bytes of data without the answer in them. An answer not yet
      # ended is held for the next read; one found ends the awaiting.
      #: (String) -> String
      def take_reply(data)
        start = data.byteindex(Domain::TerminalBackground::INTRODUCER)
        return data if start.nil?
        before = data.byteslice(0, start).to_s
        rest = data.byteslice(start, data.bytesize - start).to_s
        taken = Domain::TerminalBackground.reply_size(rest)
        if taken == 0
          @reply = rest
          return before
        end
        finish_reply(Domain::TerminalBackground.parse(rest.byteslice(0, taken).to_s))
        before + rest.byteslice(taken, rest.bytesize - taken).to_s
      end

      # Records the background an answer named and stops awaiting one.
      #: (String) -> void
      def finish_reply(background)
        @background = background
        @awaiting = false
        @reply = ""
      end

      # The value of an environment variable, "" when it is unset.
      #: (String) -> String
      def environment(name)
        value = ENV[name]
        value.nil? ? "" : value
      end
    end
  end
end
