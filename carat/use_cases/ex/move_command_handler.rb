require_relative "../../domain/editor_state"
require_relative "../../domain/ex_range"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :[range]m[ove] {address}: moves the lines of the range, the cursor
    # line without one, below the line the address names (0 for above the
    # first), as Neovim's do_move does: a target inside the range is
    # E134, one just above or below it changes nothing. The cursor goes
    # to the last moved line at the wanted column, as Neovim's
    # beginline(BL_SOL | BL_FIX) does under nostartofline; above two
    # lines the message is "N lines moved". One undo step: the edits join
    # the caller's transaction or open their own. A bad range or address
    # reports what ExRange gives, a bang E477.
    class MoveCommandHandler < ExHandler
      INTO_ITSELF = "E134: Cannot move a range of lines into itself"
      # Neovim's 'report': more lines than this give a message.
      REPORT = 2
      private_constant :INTO_ITSELF, :REPORT

      #: (spec: String) -> void
      def initialize(spec:)
        super(spec: spec)
      end

      # True: the range is the lines to move.
      # @rbs skip
      def ranged?
        true
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        return Outcome.failure("E477: No ! allowed") if command.bang
        buffer = state.buffer
        selection = state.window.last_selection
        lines = Domain::ExRange.resolve(command.range, state.cursor.row, buffer.line_count, selection)
        return Outcome.failure(lines.error) unless lines.ok?
        target = Domain::ExRange.target(command.args, state.cursor.row, buffer.line_count, selection)
        return Outcome.failure(target.error) unless target.ok?
        line1 = lines.first + 1
        line2 = lines.last + 1
        dest = target.first
        return Outcome.failure(INTO_ITSELF) if dest >= line1 && dest < line2
        count = line2 - line1 + 1
        moving = dest != line1 - 1 && dest != line2
        opened = moving && buffer.begin_transaction(state.cursor.position)
        move(buffer, lines.first, lines.last, dest >= line1 ? dest - count : dest) if moving
        place_cursor(state, dest >= line1 ? dest - 1 : dest + count - 1)
        buffer.commit_transaction(state.cursor.position) if opened
        return Outcome.success("#{count} lines moved") if moving && count > REPORT
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

      # The cursor on row at the wanted column, clamped as in normal mode,
      # the wanted column kept.
      #: (Domain::EditorState, Integer) -> void
      def place_cursor(state, row)
        cursor = state.cursor
        length = state.buffer.line(row).length
        max = length > 0 ? length - 1 : 0
        want = cursor.want_col
        col = want < 0 || want > max ? max : want
        cursor.row = row
        cursor.col = col
      end
    end
  end
end
