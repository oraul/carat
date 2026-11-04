require_relative "../domain/editor_state"
require_relative "search/preview_search"
require_relative "outcome"

module Carat
  module UseCases
    # Command-line mode: a typed character, or a key that inserts itself,
    # appended to the command line; a search prompt previews the pattern
    # through PreviewSearch. Entering, erasing, cancelling, and executing
    # are EnterCommandLine, EraseCommandLine, CancelCommandLine, and
    # ExecuteCommandLine.
    class EditCommandLine
      attr_reader :preview_search #: PreviewSearch

      #: (preview_search: PreviewSearch) -> void
      def initialize(preview_search:)
        @preview_search = preview_search
      end

      #: (Domain::EditorState, String) -> Outcome
      def call(state, text)
        state.cmdline = state.cmdline + text
        @preview_search.call(state)
      end
    end
  end
end
