require_relative "../domain/editor_state"
require_relative "../domain/last_change"
require_relative "outcome"

module Carat
  module UseCases
    # Tab in insert mode: a tab character, or with expandtab the spaces to
    # the next tab stop, inserted at the cursor; noted in the last change.
    class InsertTab
      attr_reader :last_change #: Domain::LastChange

      #: (last_change: Domain::LastChange) -> void
      def initialize(last_change:)
        @last_change = last_change
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        options = state.options
        text = "\t"
        if options.expandtab
          width = options.tabstop > 0 ? options.tabstop : 8
          text = " " * (width - (state.cursor.col % width))
        end
        @last_change.add_action("insert.tab", text, false)
        cursor = state.cursor
        state.buffer.insert(cursor.position, text)
        cursor.move_to(cursor.row, cursor.col + text.length)
        Outcome.none
      end
    end
  end
end
