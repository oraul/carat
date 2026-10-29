require_relative "../../domain/editor_state"
require_relative "../outcome"
require_relative "../windows/close_window"

module Carat
  module UseCases
    # The :q rule: closes the current window when another exists in any tab
    # page, and ends the editor otherwise unless a listed buffer has unsaved
    # changes and no bang was given. :qa ends the editor at once under the
    # same check.
    class Quit
      E37 = "E37: No write since last change (add ! to override)"

      # @rbs @close_window: CloseWindow

      #: (CloseWindow) -> void
      def initialize(close_window)
        @close_window = close_window
      end

      # With the bang on the last window, a modified hidden buffer is shown
      # in the window instead of ending the editor, as Neovim does, so :qa!
      # is the only way to lose it.
      #: (Domain::EditorState, bool) -> Outcome
      def call(state, bang)
        return close_window(state) if state.total_windows > 1
        if bang
          hidden = state.hidden_modified
          if hidden.nil?
            state.quit = true
          else
            state.load(hidden)
          end
          return Outcome.success("")
        end
        return Outcome.failure(E37) if state.any_modified?
        state.quit = true
        Outcome.success("")
      end

      # After a write: closes the window, or ends the editor unless another
      # buffer is modified; the buffer just written is not checked, since a
      # write to another path leaves it modified on purpose.
      #: (Domain::EditorState) -> Outcome
      def leave(state)
        return close_window(state) if state.total_windows > 1
        return Outcome.failure(E37) unless state.hidden_modified.nil?
        state.quit = true
        Outcome.success("")
      end

      # :qa and :qa!.
      #: (Domain::EditorState, bool) -> Outcome
      def all(state, bang)
        return Outcome.failure(E37) if !bang && state.any_modified?
        state.quit = true
        Outcome.success("")
      end

      private

      #: (Domain::EditorState) -> Outcome
      def close_window(state)
        @close_window.remove(state, state.tab.current)
        Outcome.success("")
      end
    end
  end
end
