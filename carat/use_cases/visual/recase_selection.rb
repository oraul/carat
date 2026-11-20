require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../../domain/position"
require_relative "../../domain/operators"
require_relative "../outcome"

module Carat
  module UseCases
    # Visual ~ (:toggle), u (:lower), U (:upper), and r{char} (:replace):
    # leaves visual mode and changes every selected character; the cursor
    # goes to the start. A case change of a selection that changes no
    # character leaves the buffer and its undo history as they were.
    class RecaseSelection
      #: (Domain::EditorState, Domain::Command, Symbol) -> Outcome
      def call(state, command, how)
        selection = state.end_visual
        buffer = state.buffer
        tabstop = state.options.tab_width
        top = selection.top
        home = selection.start
        if selection.kind == :linewise
          home = selection.line_start
        elsif selection.kind == :blockwise
          home = Domain::Position.new(row: top, col: selection.span(buffer, top, tabstop).from)
        end
        firsts = []
        lasts = []
        row = top
        while row <= selection.bottom
          span = selection.span(buffer, row, tabstop)
          firsts << span.from
          lasts << span.to
          row += 1
        end
        Domain::Operators.recase_rows(buffer, top, firsts, lasts, how, command.char)
        state.cursor.move_to(home.row, state.clamp_col(home.row, home.col))
        Outcome.none
      end
    end
  end
end
