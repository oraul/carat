require_relative "../../domain/editor_state"
require_relative "../outcome"

module Carat
  module UseCases
    # U: the line saved before the latest run of changes on it is put
    # back, as a change of its own; the replaced text becomes the saved
    # one, so U undoes U. Nothing when no line is saved.
    class RestoreLine
      #: (Domain::EditorState) -> Outcome
      def call(state)
        buffer = state.buffer
        tree = buffer.undo
        row = tree.line_row
        return Outcome.none if row < 0 || row >= buffer.line_count
        cursor = state.cursor
        old = buffer.line(row)
        col = tree.line_col
        buffer.set_lines(row, row + 1, [tree.line_text])
        tree.line_text = old
        tree.line_col = cursor.col if cursor.row == row
        cursor.move_to(row, state.clamp_col(row, col))
        Outcome.none
      end
    end
  end
end
