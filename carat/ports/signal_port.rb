module Carat
  module Ports
    # The signals the main loop polls: a request to end the editor (INT or
    # TERM from outside) and a change of the terminal's size. A driver's
    # handlers only set flags, which the loop reads between reads.
    class SignalPort
      # Installs the handlers; called before any thread starts.
      #: () -> void
      def install
        raise NotImplementedError, "SignalPort#install"
      end

      # Returns whether a signal asked the editor to end.
      # @rbs skip
      def terminated?
        raise NotImplementedError, "SignalPort#terminated?"
      end

      # Returns whether the terminal was resized since the last
      # acknowledge_resize.
      # @rbs skip
      def resized?
        raise NotImplementedError, "SignalPort#resized?"
      end

      # The loop redrew at the new size: clears the resize flag.
      #: () -> void
      def acknowledge_resize
        raise NotImplementedError, "SignalPort#acknowledge_resize"
      end
    end
  end
end
