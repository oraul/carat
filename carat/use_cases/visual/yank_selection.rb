require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../../domain/registers"
require_relative "../../domain/operators"
require_relative "../../domain/messages"
require_relative "../outcome"

module Carat
  module UseCases
    # Visual y, and Y (lines true), which yanks whole lines except in a
    # block, where it keeps the block: leaves visual mode and copies what
    # was selected into the register the command names, by Vim's yank
    # rules. The cursor goes to the start of a charwise selection, the
    # start of a linewise operand, or the block's top-left. Naming a
    # read-only register refuses the command with E354.
    class YankSelection
      attr_reader :registers #: Domain::Registers

      #: (registers: Domain::Registers) -> void
      def initialize(registers:)
        @registers = registers
      end

      #: (Domain::EditorState, Domain::Command, bool) -> Outcome
      def call(state, command, lines)
        selection = state.end_visual
        register = command.register
        return Outcome.failure(Domain::Messages.read_only_register(register)) if Domain::Registers.read_only?(register)
        selection = selection.lines_or_block(false) if lines
        buffer = state.buffer
        cursor = state.cursor
        if selection.kind == :linewise
          @registers.yank(register, Domain::Operators.extract(buffer, selection.line_range))
          start = selection.line_start
          cursor.move_to(start.row, state.clamp_col(start.row, start.col))
        elsif selection.kind == :blockwise
          tabstop = state.options.tab_width
          block = selection.block(buffer, tabstop)
          col = block.span(buffer.line(block.top), tabstop).from
          @registers.yank(register, Domain::Operators.extract_block(buffer, block, tabstop))
          cursor.move_to(block.top, state.clamp_col(block.top, col))
        else
          @registers.yank(register, Domain::Operators.extract(buffer, selection.char_range(buffer)))
          start = selection.start
          cursor.move_to(start.row, state.clamp_col(start.row, start.col))
        end
        Outcome.none
      end
    end
  end
end
