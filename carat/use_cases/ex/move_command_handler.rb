require_relative "../../domain/editor_state"
require_relative "../../domain/messages"
require_relative "../outcome"
require_relative "line_command_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :[range]m[ove] {address}: moves the lines of the range, the cursor
    # line without one, below the line the address names (0 for above the
    # first), as Neovim's do_move does: a target inside the range is
    # E134, one just above or below it changes nothing. The cursor goes
    # to the last moved line at the wanted column; above two lines the
    # message is "N lines moved". One undo step: the edits join the
    # caller's transaction or open their own. A bad range or address
    # reports what ExRange gives, a bang E477.
    class MoveCommandHandler < LineCommandHandler
      INTO_ITSELF = "E134: Cannot move a range of lines into itself"
      private_constant :INTO_ITSELF

      #: (spec: String) -> void
      def initialize(spec:)
        super(spec: spec)
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        lines = lines_of(state, command)
        return Outcome.failure(lines.error) unless lines.ok?
        target = target_of(state, command)
        return Outcome.failure(target.error) unless target.ok?
        buffer = state.buffer
        first = lines.first
        last = lines.last
        at = target.first
        return Outcome.failure(INTO_ITSELF) if at > first && at <= last
        count = last - first + 1
        moving = at != first && at != last + 1
        opened = moving && buffer.begin_transaction(state.cursor.position)
        move(buffer, first, last, at > last ? at - count : at) if moving
        place_cursor(state, at > last ? at - 1 : at + count - 1)
        buffer.commit_transaction(state.cursor.position) if opened
        return Outcome.success("#{count} lines moved") if moving && count > Domain::Messages::REPORT
        Outcome.none
      end

      # Registers :move in the order of docs/compatibility.md, which is
      # its precedence; no core command shares its abbreviation.
      #: (ExTable) -> void
      def self.register(table)
        table.register(MoveCommandHandler.new(spec: "m[ove]"), "Move lines")
      end

      private

      # Deletes the rows first to last and inserts them at row at of what
      # is left: two splices, so the global marks of the lines between
      # shift and those of the other lines stay.
      #: (Domain::Buffer, Integer, Integer, Integer) -> void
      def move(buffer, first, last, at)
        moved = buffer.lines_of(first, last)
        buffer.set_lines(first, last + 1, [])
        buffer.set_lines(at, at, moved)
      end
    end
  end
end
