require_relative "../domain/editor_state"
require_relative "../domain/command"
require_relative "../domain/operators"
require_relative "outcome"

module Carat
  module UseCases
    # ~: the case of count characters from the cursor switched, as many as
    # remain, and the cursor past them, stopping on the last character.
    class ToggleCase
      #: (Domain::EditorState, Domain::Command) -> Outcome
      def call(state, command)
        cursor = state.cursor
        line = state.current_line
        col = cursor.col
        return Outcome.none if col >= line.length
        count = command.count_or(1)
        count = line.length - col if col + count > line.length
        fresh = line[0, col] + Domain::Operators.recase(line[col, count], :toggle, "") + line[col + count, line.length - col - count]
        state.buffer.set_lines(cursor.row, cursor.row + 1, [fresh])
        cursor.move_to(cursor.row, state.clamp_col(cursor.row, col + count))
        Outcome.none
      end
    end
  end
end
