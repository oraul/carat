require_relative "../domain/editor_state"
require_relative "../domain/registers"
require_relative "../domain/register_entry"
require_relative "outcome"

module Carat
  module UseCases
    # :[range]d[elete] [x] [count]: deletes the rows first to last into the
    # register named ("" for the unnamed one), shifting the numbered
    # registers as a linewise delete does, and puts the cursor on the first
    # non-blank of the row that took the first deleted row's place, the
    # last row when none did. Inside the dispatcher's transaction, so one
    # undo state.
    class DeleteLines
      attr_reader :registers #: Domain::Registers

      #: (registers: Domain::Registers) -> void
      def initialize(registers:)
        @registers = registers
      end

      #: (Domain::EditorState, Integer, Integer, String) -> Outcome
      def call(state, first, last, register)
        buffer = state.buffer
        entry = Domain::RegisterEntry.lines(buffer.lines_of(first, last))
        buffer.set_lines(first, last + 1, [])
        @registers.delete(register, entry, true)
        row = first
        row = buffer.line_count - 1 if row > buffer.line_count - 1
        state.cursor.move_to(row, buffer.first_nonblank(row))
        Outcome.none
      end
    end
  end
end
