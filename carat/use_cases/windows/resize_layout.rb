require_relative "../../domain/editor_state"

module Carat
  module UseCases
    # Changes window sizes: Ctrl-W = makes the windows of every split the
    # same size, leaving fixed-width windows alone.
    class ResizeLayout
      #: (Domain::EditorState) -> void
      def equalize(state)
        state.tab.layout.equalize
      end
    end
  end
end
