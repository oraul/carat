require_relative "../domain/editor_state"
require_relative "../domain/command"
require_relative "../domain/operators"
require_relative "outcome"

module Carat
  module UseCases
    # J: count lines from the cursor's, at least two, joined with spaces;
    # nothing on the last line.
    class JoinLines
      #: (Domain::EditorState, Domain::Command) -> Outcome
      def call(state, command)
        cursor = state.cursor
        last = state.buffer.line_count - 1
        return Outcome.none if cursor.row >= last
        count = command.count_or(2)
        count = 2 if count < 2
        count = last - cursor.row + 1 if cursor.row + count - 1 > last
        col = Domain::Operators.join(state.buffer, cursor.row, count, true)
        cursor.move_to(cursor.row, state.clamp_col(cursor.row, col))
        Outcome.none
      end
    end
  end
end
