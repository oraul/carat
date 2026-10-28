module Carat
  module Ports
    # The terminal as the editor core sees it: a size, raw key bytes with a
    # timeout, and a byte sink. Drivers and doubles subclass it. Return types
    # of overridden methods are described in prose because the compiler
    # applies only the parameter types of a method a subclass overrides.
    class TerminalPort
      # Returns [rows, cols].
      # @rbs skip
      def size
        raise NotImplementedError, "TerminalPort#size"
      end

      # Returns the bytes of one read, or nil when timeout seconds pass
      # with nothing to read.
      # @rbs timeout: Float
      def read_key(timeout)
        raise NotImplementedError, "TerminalPort#read_key"
      end

      #: (String) -> void
      def write(bytes)
        raise NotImplementedError, "TerminalPort#write"
      end

      #: () -> void
      def enter
        raise NotImplementedError, "TerminalPort#enter"
      end

      #: () -> void
      def leave
        raise NotImplementedError, "TerminalPort#leave"
      end
    end
  end
end
