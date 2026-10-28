require_relative "../ports/clock_port"

module Carat
  module Drivers
    # The process's monotonic clock.
    class MonotonicClock < Ports::ClockPort
      # Returns seconds from an arbitrary start as a Float.
      # @rbs skip
      def now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      #: (Float) -> void
      def sleep(seconds)
        Kernel.sleep(seconds) if seconds > 0.0
      end
    end
  end
end
