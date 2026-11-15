require_relative "../domain/display_width"
require_relative "../domain/editor_state"
require_relative "../domain/last_change"
require_relative "outcome"

module Carat
  module UseCases
    # Tab in insert mode: a tab character, or with expandtab the spaces to
    # the next tab stop, counted in screen cells from the display column of
    # the cursor, inserted at the cursor; noted in the last change.
    class InsertTab
      attr_reader :last_change #: Domain::LastChange

      #: (last_change: Domain::LastChange) -> void
      def initialize(last_change:)
        @last_change = last_change
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        options = state.options
        cursor = state.cursor
        text = "\t"
        if options.expandtab
          width = options.tabstop > 0 ? options.tabstop : 8
          column = Domain::DisplayWidth.column(state.buffer.line(cursor.row), cursor.col, width)
          text = " " * (width - (column % width))
        end
        @last_change.add_action("insert.tab", text, false)
        state.buffer.insert(cursor.position, text)
        cursor.move_to(cursor.row, cursor.col + text.length)
        Outcome.none
      end
    end
  end
end
