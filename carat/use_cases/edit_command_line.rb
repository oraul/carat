require_relative "../domain/editor_state"
require_relative "outcome"

module Carat
  module UseCases
    # Command-line mode: a typed character, or a key that inserts itself,
    # appended to the command line. Entering, erasing, cancelling, and
    # executing are EnterCommandLine, EraseCommandLine,
    # CancelCommandLine, and ExecuteCommandLine.
    class EditCommandLine
      #: (Domain::EditorState, String) -> Outcome
      def call(state, text)
        state.cmdline = state.cmdline + text
        Outcome.none
      end
    end
  end
end
