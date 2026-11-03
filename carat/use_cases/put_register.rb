require_relative "../domain/editor_state"
require_relative "../domain/command"
require_relative "../domain/operators"
require_relative "../domain/registers"
require_relative "../domain/register_entry"
require_relative "../domain/display_width"
require_relative "../domain/messages"
require_relative "outcome"

module Carat
  module UseCases
    # p (after) and P: the register the command names put count times
    # after or before the cursor, as lines below or above, as text after
    # or at the cursor, or as a block from the cursor's display column;
    # E353 when the register is empty.
    class PutRegister
      attr_reader :registers #: Domain::Registers

      #: (registers: Domain::Registers) -> void
      def initialize(registers:)
        @registers = registers
      end

      #: (Domain::EditorState, Domain::Command, bool) -> Outcome
      def call(state, command, after)
        entry = @registers.read_with_file(command.register, state.buffer.path_text)
        return Outcome.failure(Domain::Messages.nothing_in_register(command.register)) if entry.nil?
        if entry.blockwise?
          put_block(state, entry, command.count_or(1), after)
          return Outcome.none
        end
        pos = Domain::Operators.put(state.buffer, state.cursor.position, entry, command.count_or(1), after)
        state.cursor.move_to(pos.row, pos.col)
        Outcome.none
      end

      private

      # A blockwise register put as a block from the display column of the
      # cursor's character, or the one after it for "p".
      #: (Domain::EditorState, Domain::RegisterEntry, Integer, bool) -> void
      def put_block(state, entry, count, after)
        buffer = state.buffer
        cursor = state.cursor
        tabstop = state.options.tab_width
        line = buffer.line(cursor.row)
        vcol = Domain::DisplayWidth.column(line, cursor.col, tabstop)
        vcol += Domain::DisplayWidth.cell(line[cursor.col, 1], vcol, tabstop) if after && cursor.col < line.length
        pos = Domain::Operators.put_block(buffer, cursor.row, vcol, entry, count, tabstop)
        cursor.move_to(pos.row, state.clamp_col(pos.row, pos.col))
      end
    end
  end
end
