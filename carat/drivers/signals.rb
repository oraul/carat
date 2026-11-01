require_relative "../ports/signal_port"

module Carat
  module Drivers
    # The process's signals: INT and TERM end the editor, restoring the
    # terminal, and WINCH reports a resize. Raw mode delivers Ctrl-C as a
    # key, so INT only comes from outside. The handlers only assign the
    # instance's flags; the main loop polls them.
    class Signals < Ports::SignalPort
      # @rbs @terminated: bool
      # @rbs @resized: bool

      #: () -> void
      def initialize
        @terminated = false
        @resized = false
      end

      # Called before any thread starts.
      #: () -> void
      def install
        Signal.trap("INT") { @terminated = true }
        Signal.trap("TERM") { @terminated = true }
        Signal.trap("WINCH") { @resized = true }
        nil
      end

      # Returns the terminate flag.
      # @rbs skip
      def terminated?
        @terminated
      end

      # Returns the resize flag.
      # @rbs skip
      def resized?
        @resized
      end

      #: () -> void
      def acknowledge_resize
        @resized = false
      end
    end
  end
end
