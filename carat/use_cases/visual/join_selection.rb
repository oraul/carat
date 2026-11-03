require_relative "../../domain/editor_state"
require_relative "../../domain/operators"
require_relative "../outcome"

module Carat
  module UseCases
    # Visual J (spaces true) and gJ (spaces false): leaves visual mode and
    # joins the selected rows, at least two.
    class JoinSelection
      #: (Domain::EditorState, bool) -> Outcome
      def call(state, spaces)
        selection = state.end_visual
        buffer = state.buffer
        top = selection.top
        return Outcome.none if top >= buffer.line_count - 1
        count = selection.bottom - top + 1
        count = 2 if count < 2
        col = Domain::Operators.join(buffer, top, count, spaces)
        state.cursor.move_to(top, state.clamp_col(top, col))
        Outcome.none
      end
    end
  end
end
