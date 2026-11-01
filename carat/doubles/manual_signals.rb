require_relative "../ports/signal_port"

module Carat
  module Doubles
    # Signals a test trips by hand: resize and terminate set the flags at
    # once, resize_after(n) sets the resize flag at the n-th poll of
    # terminated?, as a WINCH arriving while the loop runs, and
    # terminate_after(n) ends the main loop at its n-th poll, so a loop
    # over a terminal with no input stops. It counts the installs, the
    # polls, and the resizes the loop acknowledged.
    class ManualSignals < Ports::SignalPort
      attr_reader :installs #: Integer
      attr_reader :polls #: Integer
      attr_reader :acknowledged #: Integer

      # @rbs @terminated: bool
      # @rbs @resized: bool
      # @rbs @limit: Integer
      # @rbs @resize_at: Integer

      #: () -> void
      def initialize
        @installs = 0
        @polls = 0
        @acknowledged = 0
        @terminated = false
        @resized = false
        @limit = -1
        @resize_at = -1
      end

      #: () -> void
      def resize
        @resized = true
      end

      #: () -> void
      def terminate
        @terminated = true
      end

      # Sets the resize flag when terminated? is asked the polls-th time.
      #: (Integer) -> void
      def resize_after(polls)
        @resize_at = polls
      end

      # Ends the loop when terminated? has been asked polls times.
      #: (Integer) -> void
      def terminate_after(polls)
        @limit = polls
      end

      #: () -> void
      def install
        @installs += 1
      end

      # Returns the terminate flag, set by terminate or by reaching the
      # poll limit.
      # @rbs skip
      def terminated?
        @polls += 1
        @resized = true if @polls == @resize_at
        @terminated = true if @limit >= 0 && @polls >= @limit
        @terminated
      end

      # Returns the resize flag.
      # @rbs skip
      def resized?
        @resized
      end

      #: () -> void
      def acknowledge_resize
        @acknowledged += 1 if @resized
        @resized = false
      end
    end
  end
end
