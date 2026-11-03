require_relative "../domain/editor_state"
require_relative "../domain/command"
require_relative "outcome"

module Carat
  module UseCases
    # r{char}: count characters from the cursor replaced by the character,
    # the cursor on the last one; nothing when fewer remain.
    class ReplaceChars
      #: (Domain::EditorState, Domain::Command) -> Outcome
      def call(state, command)
        cursor = state.cursor
        line = state.current_line
        count = command.count_or(1)
        col = cursor.col
        return Outcome.none if command.char.empty? || col + count > line.length
        fresh = line[0, col] + (command.char * count) + line[col + count, line.length - col - count]
        state.buffer.set_lines(cursor.row, cursor.row + 1, [fresh])
        cursor.move_to(cursor.row, col + count - 1)
        Outcome.none
      end
    end
  end
end
