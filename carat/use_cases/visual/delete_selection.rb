require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../../domain/registers"
require_relative "../../domain/selection_cut"
require_relative "../../domain/messages"
require_relative "../outcome"

module Carat
  module UseCases
    # Visual d, x, and <Del> (shape :selected), X (:lines), and D
    # (:to_end): leaves visual mode, which keeps the selection for "gv",
    # and deletes what was selected into the register the command names,
    # by Vim's delete rules (register 1 for whole lines or more than one
    # line). X and D act on whole lines, except in a block, where X keeps
    # the block and D reaches the end of every row. Naming a read-only
    # register refuses the command with E354.
    class DeleteSelection
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
        selection = selection.lines_or_block(shape == :to_end) unless shape == :selected
        @registers.delete(register, Domain::SelectionCut.call(state, selection), selection.numbered_delete?)
        Outcome.none
      end
    end
  end
end
