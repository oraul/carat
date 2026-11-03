require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../../domain/mode"
require_relative "../../domain/registers"
require_relative "../../domain/operators"
require_relative "../../domain/selection_cut"
require_relative "../../domain/messages"
require_relative "../outcome"

module Carat
  module UseCases
    # Visual c and s (shape :selected), S and R (:lines), and C (:to_end):
    # leaves visual mode, deletes what was selected into the register the
    # command names, and enters insert mode: at the start, on one line
    # keeping the top row's indent with autoindent, or at the block's
    # top-left with the text to be repeated on the rows that reach the
    # block. S and R change whole lines in every kind; C changes a block
    # to the end of every row and whole lines otherwise. Naming a
    # read-only register refuses the command with E354.
    class ChangeSelection
      attr_reader :registers #: Domain::Registers

      #: (registers: Domain::Registers) -> void
      def initialize(registers:)
        @registers = registers
      end

      #: (Domain::EditorState, Domain::Command, Symbol) -> Outcome
      def call(state, command, shape)
        selection = state.end_visual
        register = command.register
        return Outcome.failure(Domain::Messages.read_only_register(register)) if Domain::Registers.read_only?(register)
        if shape == :to_end && selection.kind == :blockwise
          selection = selection.as(:blockwise, true)
        elsif shape != :selected
          selection = selection.as(:linewise, false)
        end
        buffer = state.buffer
        cursor = state.cursor
        if selection.kind == :linewise
          top = selection.top
          @registers.delete(register, Domain::Operators.extract(buffer, selection.line_range), true)
          indent = state.options.autoindent ? buffer.indent_of(top) : ""
          buffer.set_lines(top, selection.bottom + 1, [indent])
          state.mode = Domain::Mode::INSERT
          cursor.move_to(top, indent.length)
          return Outcome.none
        end
        if selection.kind == :blockwise
          tabstop = state.options.tab_width
          block = selection.block(buffer, tabstop)
          rows = block.reaching_rows(buffer, tabstop)
          col = block.span(buffer.line(block.top), tabstop).from
          @registers.delete(register, Domain::SelectionCut.call(state, selection), selection.numbered_delete?)
          line = buffer.line(block.top)
          state.mode = Domain::Mode::INSERT
          col = line.length if col > line.length
          cursor.move_to(block.top, col)
          state.block_insert.start(:change, block.top, col, line.length, buffer.line_count, rows, block.left, -1)
          return Outcome.none
        end
        range = selection.char_range(buffer)
        @registers.delete(register, Domain::Operators.extract(buffer, range), selection.numbered_delete?)
        Domain::Operators.delete(buffer, range)
        state.mode = Domain::Mode::INSERT
        cursor.move_to(range.from.row, range.from.col)
        Outcome.none
      end
    end
  end
end
