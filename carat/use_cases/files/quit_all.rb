require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/messages"
require_relative "../outcome"

module Carat
  module UseCases
    # :qa and :qa!: ends the editor at once, unless a listed buffer has
    # unsaved changes and no bang was given.
    class QuitAll
      attr_reader :buffers #: Domain::BufferList

      #: (buffers: Domain::BufferList) -> void
      def initialize(buffers:)
        @buffers = buffers
      end

      #: (Domain::EditorState, bool) -> Outcome
      def call(state, bang)
        return Outcome.failure(Domain::Messages::E37) if !bang && @buffers.any_modified?
        state.quit = true
        Outcome.success("")
      end
    end
  end
end
