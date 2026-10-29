require_relative "../../domain/editor_state"
require_relative "../outcome"

module Carat
  module UseCases
    # Closes the current tab page, or every other one. A modified buffer
    # shown only in a closed tab page stays listed, hidden.
    class CloseTab
      E784 = "E784: Cannot close last tab page"
      ONLY_ONE = "Already only one tab page"

      #: (Domain::EditorState) -> Outcome
      def close(state)
        return Outcome.failure(E784) if state.tab_count <= 1
        remove(state, state.tab_index)
        Outcome.success("")
      end

      #: (Domain::EditorState) -> Outcome
      def only(state)
        return Outcome.success(ONLY_ONE) if state.tab_count <= 1
        remove(state, state.tab_index == 0 ? 1 : 0) while state.tab_count > 1
        Outcome.success("")
      end

      private

      # Removes one tab page and releases the buffers its windows showed.
      #: (Domain::EditorState, Integer) -> void
      def remove(state, index)
        layout = state.tab_at(index).layout
        ids = layout.leaves
        held = []
        i = 0
        while i < ids.length
          held << layout.window_at(ids[i]).buffer
          i += 1
        end
        state.remove_tab(index)
        i = 0
        while i < held.length
          state.release(held[i])
          i += 1
        end
      end
    end
  end
end
