require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../../domain/position"
require_relative "../../domain/operators"
require_relative "../outcome"

module Carat
  module UseCases
    # Visual ~ (:toggle), u (:lower), U (:upper), and r{char} (:replace):
    # leaves visual mode and changes every selected character; the cursor
    # goes to the start.
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
        lines = []
        row = top
        while row <= selection.bottom
          line = buffer.line(row)
          span = selection.span(buffer, row, tabstop)
          lines << line[0, span.from] + Domain::Operators.recase(line[span.from, span.to - span.from], how, command.char) + line[span.to, line.length - span.to]
          row += 1
        end
        buffer.set_lines(top, selection.bottom + 1, lines)
        state.cursor.move_to(home.row, state.clamp_col(home.row, home.col))
        Outcome.none
      end
    end
  end
end
