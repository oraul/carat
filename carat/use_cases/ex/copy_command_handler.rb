require_relative "../../domain/editor_state"
require_relative "../../domain/ex_range"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :[range]co[py] {address} and its synonym :[range]t {address}: puts a
    # copy of the lines of the range, the cursor line without one, below
    # the line the address names (0 for above the first), as Neovim's
    # ex_copy does. The cursor goes to the last copied line at the wanted
    # column, as Neovim's beginline(BL_SOL | BL_FIX) does under
    # nostartofline; above two lines the message is "N more lines". One
    # undo step: the edit joins the caller's transaction or is its own. A
    # bad range or address reports what ExRange gives, a bang E477.
    class CopyCommandHandler < ExHandler
      # Neovim's 'report': more lines than this give a message.
      REPORT = 2
      private_constant :REPORT

      #: (spec: String) -> void
      def initialize(spec:)
        super(spec: spec)
      end

      # True: the range is the lines to copy.
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
        dest = target.first
        count = lines.last - lines.first + 1
        opened = buffer.begin_transaction(state.cursor.position)
        buffer.set_lines(dest, dest, buffer.lines_of(lines.first, lines.last))
        place_cursor(state, dest + count - 1)
        buffer.commit_transaction(state.cursor.position) if opened
        return Outcome.success("#{count} more lines") if count > REPORT
        Outcome.none
      end

      # Registers :copy and :t in the order of docs/compatibility.md,
      # which is their precedence; no core command shares their
      # abbreviations.
      #: (ExTable) -> void
      def self.register(table)
        table.register(CopyCommandHandler.new(spec: "co[py]"), "Copy lines")
        table.register(CopyCommandHandler.new(spec: "t"), "Copy lines")
      end

      private

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
