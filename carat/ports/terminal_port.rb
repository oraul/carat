module Carat
  module Ports
    # The terminal as the editor core sees it: a size, raw key bytes with a
    # timeout, a byte sink, how many colors it shows, whether color is
    # unwanted, and the background it reported. Drivers and doubles
    # subclass it. Return types of overridden methods are described in
    # prose because the compiler applies only the parameter types of a
    # method a subclass overrides.
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

      # Returns how many colors the terminal shows, one of
      # Domain::ColorDepth's TRUECOLOR, COLORS_256, and COLORS_16, decided
      # once when the driver is made.
      # @rbs skip
      def colors
        raise NotImplementedError, "TerminalPort#colors"
      end

      # Returns true when the user asked for no color (NO_COLOR set and
      # not empty), decided once when the driver is made.
      # @rbs skip
      def no_color?
        raise NotImplementedError, "TerminalPort#no_color?"
      end

      # Returns the background the terminal reported in answer to the query
      # written on enter: Domain::TerminalBackground's DARK ("dark") or
      # LIGHT ("light"), or UNKNOWN ("") before an answer, with none, or
      # with a malformed one. Reading it never waits for the answer.
      # @rbs skip
      def background
        raise NotImplementedError, "TerminalPort#background"
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
