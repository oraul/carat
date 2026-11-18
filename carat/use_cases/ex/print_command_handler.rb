require_relative "../../domain/editor_state"
require_relative "../../domain/register_count"
require_relative "../outcome"
require_relative "line_command_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :[range]p[rint] [count]: shows the lines of the range, the cursor
    # line without one, or count lines from the range's last line, one per
    # line of the message, as Neovim's ex_print does without flags. The
    # position left is recorded in the jump list and the cursor goes to
    # the last line shown at the wanted column. The message is
    # Outcome.from_print, so a global shows the lines of every :p together.
    # E749 on an empty buffer, E477 for a bang; a bad range reports what
    # ExRange gives, a bad count or a flag what RegisterCount gives.
    class PrintCommandHandler < LineCommandHandler
      EMPTY_BUFFER = "E749: Empty buffer"
      private_constant :EMPTY_BUFFER

      #: (spec: String) -> void
      def initialize(spec:)
        super(spec: spec)
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        lines = lines_of(state, command)
        return Outcome.failure(lines.error) unless lines.ok?
        args = Domain::RegisterCount.parse_count(command.args)
        return Outcome.failure(args.error) unless args.ok?
        buffer = state.buffer
        return Outcome.failure(EMPTY_BUFFER) if buffer.line_count == 1 && buffer.line(0).empty?
        lines = lines.counted(args.count, buffer.line_count) if args.count > 0
        out = +""
        row = lines.first
        while row <= lines.last
          out << "\n" if row > lines.first
          out << buffer.line(row)
          row += 1
        end
        state.window.record_jump
        place_cursor(state, lines.last)
        Outcome.from_print(out)
      end

      # Registers :print after :normal, in the order of
      # docs/compatibility.md, which is its precedence; no core command
      # shares its abbreviation, which is Vim's.
      #: (ExTable) -> void
      def self.register(table)
        table.register(PrintCommandHandler.new(spec: "p[rint]"), "Print lines")
      end
    end
  end
end
