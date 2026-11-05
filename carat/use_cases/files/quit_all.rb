require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/messages"
require_relative "../outcome"

module Carat
  module UseCases
    # :qa and :qa!: ends the editor at once, unless a listed file buffer
    # has unsaved changes and no bang was given: then the first of them in
    # Neovim's order is named with E37 and E162 and brought to the user,
    # its window focused or, when none shows it, shown in the current
    # window.
    class QuitAll
      attr_reader :buffers #: Domain::BufferList

      #: (buffers: Domain::BufferList) -> void
      def initialize(buffers:)
        @buffers = buffers
      end

      #: (Domain::EditorState, bool) -> Outcome
      def call(state, bang)
        unless bang
          unsaved = @buffers.first_unsaved(false)
          unless unsaved.nil?
            @buffers.bring(unsaved)
            return Outcome.failure(Domain::Messages.unsaved_buffer(unsaved.path_text))
          end
        end
        state.quit = true
        Outcome.success("")
      end
    end
  end
end
