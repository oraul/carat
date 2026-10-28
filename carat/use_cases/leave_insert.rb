require_relative "../domain/editor_state"

module Carat
  module UseCases
    # Returns to normal mode, moving the cursor onto the last inserted
    # character as Vim does.
    class LeaveInsert
      #: (Domain::EditorState) -> void
      def call(state)
        cursor = state.cursor
        state.mode = Domain::Mode::NORMAL
        cursor.move_to(cursor.row, cursor.col - 1) if cursor.col > 0
      end
    end
  end
end
