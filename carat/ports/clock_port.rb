module Carat
  module Ports
    # A monotonic clock in seconds.
    class ClockPort
      # Returns the current time as a Float of seconds.
      # @rbs skip
      def now
        raise NotImplementedError, "ClockPort#now"
      end

      #: (Float) -> void
      def sleep(seconds)
        raise NotImplementedError, "ClockPort#sleep"
      end
    end
  end
end
