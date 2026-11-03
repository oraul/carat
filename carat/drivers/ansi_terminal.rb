require "io/console"
require_relative "../ports/terminal_port"
require_relative "../domain/color_depth"

module Carat
  module Drivers
    # The real terminal: window size through io/console, byte reads with
    # IO.select and readpartial so no bytes hide in a stdio buffer, and
    # flushed writes. Raw mode is entered by bin/carat.rb around the loop.
    # The color depth comes from COLORTERM and TERM, read once here: the
    # drivers are the only place the environment is read.
    class AnsiTerminal < Ports::TerminalPort
      # @rbs @input: IO
      # @rbs @output: IO
      # @rbs @colors: Integer

      #: (input: IO, output: IO) -> void
      def initialize(input:, output:)
        @input = input
        @output = output
        @colors = Domain::ColorDepth.detect(environment("COLORTERM"), environment("TERM"))
      end

      # Returns the color depth decided when the driver was made.
      # @rbs skip
      def colors
        @colors
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

      # Returns the bytes of one read, or nil on timeout or end of input.
      # @rbs timeout: Float
      def read_key(timeout)
        ready = IO.select([@input], nil, nil, timeout)
        return nil if ready.nil?
        begin
          @input.readpartial(4096)
        rescue EOFError
          nil
        end
      end

      #: (String) -> void
      def write(bytes)
        @output.write(bytes)
        @output.flush
      end

      #: () -> void
      def enter
        @output.flush
      end

      #: () -> void
      def leave
        @output.flush
      end

      private

      # The value of an environment variable, "" when it is unset.
      #: (String) -> String
      def environment(name)
        value = ENV[name]
        value.nil? ? "" : value
      end
    end
  end
end
