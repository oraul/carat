require_relative "../ports/language_service_port"

module Carat
  module Doubles
    # Language services with no server, for a test that builds a use case
    # by hand: polls change nothing and the writes reported are recorded.
    class FakeLanguageServices < Ports::LanguageServicePort
      # @rbs @saves: Array[Integer]

      attr_reader :saves #: Array[Integer]

      #: () -> void
      def initialize
        @saves = []
      end

      # Answers false: nothing changes.
      # @rbs state: Domain::EditorState
      def poll(state)
        false
      end

      # Answers that no server is configured.
      # @rbs state: Domain::EditorState
      def start(state)
        "No language server for this buffer"
      end

      # Answers that no server is configured.
      # @rbs state: Domain::EditorState
      def restart(state)
        "No language server for this buffer"
      end

      #: (Domain::Buffer) -> void
      def saved(buffer)
        @saves << buffer.id
      end

      # Answers false: nothing waits.
      # @rbs skip
      def waiting?
        false
      end

      #: () -> void
      def stop
      end
    end
  end
end
