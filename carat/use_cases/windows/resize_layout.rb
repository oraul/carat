require_relative "../../domain/editor_state"
require_relative "../outcome"

module Carat
  module UseCases
    # Changes window sizes: Ctrl-W = makes the windows of every split the
    # same size, leaving fixed-width windows alone.
    class ResizeLayout
      #: (Domain::EditorState) -> Outcome
      def equalize(state)
        state.tab.layout.equalize
        Outcome.none
      end
    end
  end
end
