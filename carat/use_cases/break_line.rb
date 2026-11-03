require_relative "../domain/editor_state"
require_relative "../domain/last_change"
require_relative "outcome"

module Carat
  module UseCases
    # Enter in insert mode: the line broken at the cursor, the new line
    # taking the indent of the old one when autoindent is on, and the
    # cursor after that indent; noted in the last change.
    class BreakLine
      attr_reader :last_change #: Domain::LastChange

      #: (last_change: Domain::LastChange) -> void
      def initialize(last_change:)
        @last_change = last_change
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        @last_change.add_action("insert.newline", "\n", false)
        cursor = state.cursor
        indent = state.options.autoindent ? state.buffer.indent_of(cursor.row) : ""
        state.buffer.insert(cursor.position, "\n" + indent)
        cursor.move_to(cursor.row + 1, indent.length)
        Outcome.none
      end
    end
  end
end
