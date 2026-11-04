require_relative "../../domain/editor_state"
require_relative "../../domain/mode"
require_relative "../../domain/history"
require_relative "../../domain/search_prompt"
require_relative "../outcome"

module Carat
  module UseCases
    # "/" and "?" once the grammar wants their pattern: the command line
    # opens with the search prompt, which keeps the direction, the mode to
    # return to (a visual mode stays, operator-pending and normal return
    # to normal), and the cursor and view it started from; a recall of the
    # search history starts again.
    class OpenSearchPrompt
      attr_reader :search_prompt #: Domain::SearchPrompt
      attr_reader :search_history #: Domain::History

      #: (search_prompt: Domain::SearchPrompt, search_history: Domain::History) -> void
      def initialize(search_prompt:, search_history:)
        @search_prompt = search_prompt
        @search_history = search_history
      end

      # action is the search action the grammar holds.
      #: (Domain::EditorState, String) -> Outcome
      def call(state, action)
        mode = state.mode
        back = Domain::Mode.visual?(mode) ? mode : Domain::Mode::NORMAL
        window = state.window
        cursor = window.cursor
        @search_prompt.open(action != "search.backward", back, cursor.row, cursor.col, window.top, window.left)
        @search_history.restart
        state.mode = Domain::Mode::CMDLINE
        state.cmdline = ""
        Outcome.none
      end
    end
  end
end
