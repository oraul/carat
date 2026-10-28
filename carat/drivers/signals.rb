module Carat
  module Drivers
    # Flags set by signal handlers and polled by the main loop. The handlers
    # only assign; nothing else runs inside them.
    module Signals
      @resized = false
      @terminated = false

      #: () -> bool
      def self.resized
        @resized
      end

      #: (bool) -> void
      def self.resized=(value)
        @resized = value
      end

      #: () -> bool
      def self.terminated
        @terminated
      end

      #: (bool) -> void
      def self.terminated=(value)
        @terminated = value
      end

      # Installs the handlers. Called before any thread starts. Raw mode
      # delivers Ctrl-C as a key, so INT only comes from outside and ends
      # the editor as TERM does, restoring the terminal.
      #: () -> void
      def self.install
        Signal.trap("INT") { @terminated = true }
        Signal.trap("TERM") { @terminated = true }
        Signal.trap("WINCH") { @resized = true }
      end
    end
  end
end
