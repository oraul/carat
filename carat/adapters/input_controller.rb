require_relative "../ports/terminal_port"
require_relative "../ports/clock_port"
require_relative "../domain/editor_state"
require_relative "../use_cases/handle_key"
require_relative "key_decoder"

module Carat
  module Adapters
    # Owns the key-to-use-case path: reads bytes from the terminal with a
    # timeout, decodes them, feeds each key through HandleKey, and resolves
    # the escape and timeoutlen waits with the clock.
    class InputController
      ESCAPE_TIMEOUT = 0.05
      IDLE_TIMEOUT = 0.25

      attr_reader :terminal #: Ports::TerminalPort
      attr_reader :clock #: Ports::ClockPort
      attr_reader :handle_key #: UseCases::HandleKey

      # @rbs @decoder: KeyDecoder
      # @rbs @wait_until: Float

      #: (terminal: Ports::TerminalPort, clock: Ports::ClockPort, decoder: KeyDecoder, handle_key: UseCases::HandleKey) -> void
      def initialize(terminal:, clock:, decoder:, handle_key:)
        @terminal = terminal
        @clock = clock
        @decoder = decoder
        @handle_key = handle_key
        @wait_until = 0.0
      end

      # One read and everything it unlocks. Returns true when the state may
      # have changed and the screen should be redrawn.
      #: (Domain::EditorState) -> bool
      def pump(state)
        bytes = @terminal.read_key(next_timeout(state))
        if bytes.nil?
          if @decoder.pending?
            return handle(state, @decoder.flush)
          end
          if @handle_key.pending? && @clock.now >= @wait_until
            @handle_key.timeout(state)
            return true
          end
          return false
        end
        handle(state, @decoder.feed(bytes))
      end

      #: () -> KeyDecoder
      def decoder
        @decoder
      end

      private

      #: (Domain::EditorState) -> Float
      def next_timeout(state)
        return ESCAPE_TIMEOUT if @decoder.pending?
        if @handle_key.pending?
          remaining = @wait_until - @clock.now
          return remaining > 0.0 ? remaining : 0.0
        end
        IDLE_TIMEOUT
      end

      #: (Domain::EditorState, Array[Integer]) -> bool
      def handle(state, codes)
        return false if codes.empty?
        i = 0
        while i < codes.length
          result = @handle_key.call(state, codes[i])
          @wait_until = @clock.now + state.options.timeoutlen / 1000.0 if result == :pending
          i += 1
        end
        true
      end
    end
  end
end
