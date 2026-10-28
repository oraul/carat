require_relative "../ports/terminal_port"
require_relative "manual_clock"

module Carat
  module Doubles
    # A terminal with a scripted queue of key bytes and captured output. A
    # read from an empty queue is a timeout, which also advances the manual
    # clock by the timeout, so waits resolve deterministically.
    class FakeTerminal < Ports::TerminalPort
      attr_reader :output #: String
      attr_accessor :rows #: Integer
      attr_accessor :cols #: Integer
      attr_reader :entered #: Integer
      attr_reader :left #: Integer

      # @rbs @queue: Array[String]
      # @rbs @clock: ManualClock
      # @rbs @writes: Array[String]

      #: (ManualClock, Integer, Integer) -> void
      def initialize(clock, rows, cols)
        @clock = clock
        @rows = rows
        @cols = cols
        @queue = []
        @output = +""
        @writes = []
        @entered = 0
        @left = 0
      end

      #: (String) -> void
      def push(bytes)
        @queue << bytes
      end

      #: () -> bool
      def input?
        !@queue.empty?
      end

      # The bytes of every write, in order.
      #: () -> Array[String]
      def writes
        @writes
      end

      #: () -> String
      def last_write
        @writes.empty? ? "" : @writes[@writes.length - 1]
      end

      # Returns [rows, cols].
      # @rbs skip
      def size
        [@rows, @cols]
      end

      # Returns the next scripted read, or nil after advancing the clock by
      # timeout when nothing is scripted.
      # @rbs timeout: Float
      def read_key(timeout)
        if @queue.empty?
          @clock.advance(timeout)
          return nil
        end
        @queue.shift
      end

      #: (String) -> void
      def write(bytes)
        @output << bytes
        @writes << bytes
      end

      #: () -> void
      def enter
        @entered += 1
      end

      #: () -> void
      def leave
        @left += 1
      end
    end
  end
end
