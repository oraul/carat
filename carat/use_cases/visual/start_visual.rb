require_relative "../../domain/editor_state"
require_relative "../../domain/mode"
require_relative "../outcome"

module Carat
  module UseCases
    # The key of a visual mode, "v", "V", or "<C-v>": enters it from normal
    # mode with the anchor at the cursor, leaves it when it is the current
    # one, keeping the selection for "gv", and switches to it from another
    # visual mode keeping the anchor and the cursor.
    class StartVisual
      #: (Domain::EditorState, Symbol) -> Outcome
      def call(state, mode)
        if state.mode == mode
          state.end_visual
        elsif Domain::Mode.visual?(state.mode)
          state.mode = mode
        else
          state.window.anchor = state.cursor.position
          state.mode = mode
        end
        Outcome.none
      end
    end
  end
end
