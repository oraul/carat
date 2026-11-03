require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../../domain/operators"
require_relative "../outcome"

module Carat
  module UseCases
    # Visual > (direction 1) and < (direction -1): leaves visual mode and
    # shifts the selected rows, or the block's text, count steps of
    # shiftwidth.
    class ShiftSelection
      #: (Domain::EditorState, Domain::Command, Integer) -> Outcome
      def call(state, command, direction)
        selection = state.end_visual
        amount = command.count_or(1) * direction
        options = state.options
        buffer = state.buffer
        cursor = state.cursor
        if selection.kind == :blockwise
          tabstop = options.tab_width
          block = selection.block(buffer, tabstop)
          col = block.span(buffer.line(block.top), tabstop).from
          Domain::Operators.shift_block(buffer, block, amount, options.shiftwidth, tabstop)
          cursor.move_to(block.top, state.clamp_col(block.top, col))
          return Outcome.none
        end
        top = selection.top
        Domain::Operators.shift(buffer, top, selection.bottom, amount, options.shiftwidth, options.tabstop, options.expandtab)
        cursor.move_to(top, buffer.first_nonblank(top))
        Outcome.none
      end
    end
  end
end
