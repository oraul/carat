require_relative "../domain/editor_state"
require_relative "../domain/position"
require_relative "../domain/range"
require_relative "../domain/last_change"
require_relative "outcome"

module Carat
  module UseCases
    # Backspace (forward false) and Delete (forward true) in insert mode:
    # the character before or under the cursor removed, joining the line
    # with the one before or after at a line's edge; noted in the last
    # change.
    class EraseCharacter
      attr_reader :last_change #: Domain::LastChange

      #: (last_change: Domain::LastChange) -> void
      def initialize(last_change:)
        @last_change = last_change
      end

      #: (Domain::EditorState, bool) -> Outcome
      def call(state, forward)
        if forward
          @last_change.add_action("insert.delete", "", false)
          erase_forward(state)
        else
          @last_change.add_action("insert.backspace", "", true)
          erase_backward(state)
        end
        Outcome.none
      end

      private

      #: (Domain::EditorState) -> void
      def erase_backward(state)
        cursor = state.cursor
        if cursor.col > 0
          from = Domain::Position.new(row: cursor.row, col: cursor.col - 1)
          state.buffer.delete(Domain::Range.charwise(from, cursor.position))
          cursor.move_to(cursor.row, cursor.col - 1)
        elsif cursor.row > 0
          prev_len = state.buffer.line(cursor.row - 1).length
          from = Domain::Position.new(row: cursor.row - 1, col: prev_len)
          state.buffer.delete(Domain::Range.charwise(from, cursor.position))
          cursor.move_to(cursor.row - 1, prev_len)
        end
      end

      #: (Domain::EditorState) -> void
      def erase_forward(state)
        cursor = state.cursor
        line = state.current_line
        if cursor.col < line.length
          to = Domain::Position.new(row: cursor.row, col: cursor.col + 1)
          state.buffer.delete(Domain::Range.charwise(cursor.position, to))
        elsif cursor.row < state.buffer.line_count - 1
          to = Domain::Position.new(row: cursor.row + 1, col: 0)
          state.buffer.delete(Domain::Range.charwise(cursor.position, to))
        end
      end
    end
  end
end
