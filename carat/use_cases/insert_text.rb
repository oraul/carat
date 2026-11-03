require_relative "../domain/editor_state"
require_relative "../domain/last_change"
require_relative "outcome"

module Carat
  module UseCases
    # Insert mode: typed text without newlines inserted at the cursor, the
    # cursor moving past it, and the text noted in the last change, for
    # the dot command to type again and for the "." register. Enter,
    # Backspace, Delete, and Tab are BreakLine, EraseCharacter, and
    # InsertTab.
    class InsertText
      attr_reader :last_change #: Domain::LastChange

      #: (last_change: Domain::LastChange) -> void
      def initialize(last_change:)
        @last_change = last_change
      end

      #: (Domain::EditorState, String) -> Outcome
      def call(state, text)
        cursor = state.cursor
        state.buffer.insert(cursor.position, text)
        cursor.move_to(cursor.row, cursor.col + text.length)
        @last_change.add_text(text)
        Outcome.none
      end
    end
  end
end
