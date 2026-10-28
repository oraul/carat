require_relative "../ports/clock_port"

module Carat
  module Doubles
    # A clock that moves only when told to.
    class ManualClock < Ports::ClockPort
      # @rbs @now: Float

      #: () -> void
      def initialize
        @now = 0.0
      end

      # Returns the current time in seconds.
      # @rbs skip
      def now
        @now
      end

      #: (Float) -> void
      def advance(seconds)
        @now += seconds
      end

      #: (Float) -> void
      def sleep(seconds)
        advance(seconds)
      end
    end
  end
end
