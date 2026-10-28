require_relative "../../domain/editor_state"
require_relative "../outcome"

module Carat
  module UseCases
    # Ends the editor unless the buffer has unsaved changes and no bang.
    class Quit
      E37 = "E37: No write since last change (add ! to override)"

      #: (Domain::EditorState, bool) -> Outcome
      def call(state, bang)
        return Outcome.failure(E37) if state.buffer.modified && !bang
        state.quit = true
        Outcome.success("")
      end
    end
  end
end
