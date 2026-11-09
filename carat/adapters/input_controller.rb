require_relative "../ports/terminal_port"
require_relative "../ports/clock_port"
require_relative "../domain/editor_state"
require_relative "../domain/input_state"
require_relative "../domain/key"
require_relative "../domain/start_screen"
require_relative "../use_cases/handle_key"
require_relative "../use_cases/completion/show_completion"
require_relative "../use_cases/docs/show_hover"
require_relative "../use_cases/docs/show_signature"
require_relative "../use_cases/discovery/show_key_hints"
require_relative "../domain/signature_request"
require_relative "key_decoder"

module Carat
  module Adapters
    # Owns the key-to-use-case path: reads bytes from the terminal with a
    # timeout, decodes them, feeds each key through HandleKey, and resolves
    # the escape and timeoutlen waits with the clock. Keys HandleKey keeps
    # :pending get a deadline of timeoutlen; keys it keeps :waiting get
    # none and wait for the next key however long it takes. While the
    # start screen animates, a read waits no longer than its next frame,
    # and a read that times out advances it; any key read dismisses it and
    # is handled as usual. While the language services wait (a wanted
    # completion or a request in flight) a read waits at most
    # SERVICE_TIMEOUT, so an answer arriving between two keys is read and
    # shown before the next one; so is a signature answer, in its float.
    # Keys HandleKey keeps :waiting arm the key hints: once
    # keyhints.delay passes with the keys still pending, a read that times
    # out shows them through ShowKeyHints. Keys kept :pending get none, as
    # timeoutlen resolves them. The clock is read for the hints only after
    # a :waiting key, as for timeoutlen after a :pending one.
    class InputController
      ESCAPE_TIMEOUT = 0.05
      IDLE_TIMEOUT = 0.25
      SERVICE_TIMEOUT = 0.02

      attr_reader :terminal #: Ports::TerminalPort
      attr_reader :clock #: Ports::ClockPort
      attr_reader :handle_key #: UseCases::HandleKey
      attr_reader :input #: Domain::InputState
      attr_reader :start_screen #: Domain::StartScreen
      attr_reader :services #: Ports::LanguageServicePort
      attr_reader :show_completion #: UseCases::ShowCompletion
      attr_reader :show_hover #: UseCases::ShowHover
      attr_reader :show_signature #: UseCases::ShowSignature
      attr_reader :signature #: Domain::SignatureRequest
      attr_reader :show_key_hints #: UseCases::ShowKeyHints

      # @rbs @decoder: KeyDecoder
      # @rbs @wait_until: Float
      # @rbs @deadline: bool
      # @rbs @hint_at: Float
      # @rbs @hinting: bool

      #: (terminal: Ports::TerminalPort, clock: Ports::ClockPort, decoder: KeyDecoder, handle_key: UseCases::HandleKey, input: Domain::InputState, start_screen: Domain::StartScreen, services: Ports::LanguageServicePort, show_completion: UseCases::ShowCompletion, show_hover: UseCases::ShowHover, show_signature: UseCases::ShowSignature, signature: Domain::SignatureRequest, show_key_hints: UseCases::ShowKeyHints) -> void
      def initialize(terminal:, clock:, decoder:, handle_key:, input:, start_screen:, services:, show_completion:, show_hover:, show_signature:, signature:, show_key_hints:)
        @show_key_hints = show_key_hints
        @show_signature = show_signature
        @signature = signature
        @services = services
        @show_hover = show_hover
        @show_completion = show_completion
        @terminal = terminal
        @clock = clock
        @decoder = decoder
        @handle_key = handle_key
        @input = input
        @start_screen = start_screen
        @wait_until = 0.0
        @deadline = false
        @hint_at = 0.0
        @hinting = false
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
          if @deadline && @input.pending? && @clock.now >= @wait_until
            @handle_key.call(state, Domain::Key::TIMEOUT)
            return true
          end
          if @hinting && @input.pending? && @clock.now >= @hint_at
            @hinting = false
            @show_key_hints.call(state)
            return true
          end
          # Idle: the language services read and send here, never while a
          # key waits; a completion answer they kept fills the popup, and
          # resolved documentation the float beside it, and a hover answer
          # the documentation float.
          served = @services.poll(state)
          request = @show_completion.source.request
          if request.arrived || request.docs.arrived
            @show_completion.call(state, false)
            served = true
          end
          if @show_hover.hover.arrived
            @show_hover.call(state)
            served = true
          end
          if @signature.arrived
            @show_signature.call(state)
            served = true
          end
          return tick || served
        end
        start = @start_screen
        if start.showing
          start.dismiss
          handle(state, @decoder.feed(bytes))
          return true
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
        if (@deadline || @hinting) && @input.pending?
          remaining = (@deadline ? @wait_until : @hint_at) - @clock.now
          return remaining > 0.0 ? remaining : 0.0
        end
        if @start_screen.animating?
          frame = @start_screen.wait(@clock.now)
          return frame if frame < IDLE_TIMEOUT
        end
        return SERVICE_TIMEOUT if @services.waiting?
        IDLE_TIMEOUT
      end

      # Moves the start screen to the frame of the clock when its next one
      # is due; true when it moved and the screen should be redrawn.
      #: () -> bool
      def tick
        start = @start_screen
        return false unless start.animating?
        now = @clock.now
        return false unless start.due?(now)
        start.advance(now)
        true
      end

      #: (Domain::EditorState, Array[Integer]) -> bool
      def handle(state, codes)
        return false if codes.empty?
        i = 0
        while i < codes.length
          result = @handle_key.call(state, codes[i])
          @deadline = result == :pending
          @wait_until = @clock.now + state.options.timeoutlen / 1000.0 if @deadline
          @hinting = result == :waiting && state.options.keyhints_delay > 0
          @hint_at = @clock.now + state.options.keyhints_delay / 1000.0 if @hinting
          i += 1
        end
        true
      end
    end
  end
end
