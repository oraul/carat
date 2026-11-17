require_relative "../../domain/editor_state"
require_relative "../../domain/register_count"
require_relative "../delete_lines"
require_relative "../outcome"
require_relative "line_command_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :[range]d[elete] [x] [count] through DeleteLines on the range, the
    # cursor line without one; a count deletes count lines from the
    # range's last line, stopping at the buffer's last line. A bad range
    # reports what ExRange gives, a bad argument what RegisterCount gives,
    # a bang E477.
    class DeleteCommandHandler < LineCommandHandler
      attr_reader :delete_lines #: DeleteLines

      #: (spec: String, delete_lines: DeleteLines) -> void
      def initialize(spec:, delete_lines:)
        super(spec: spec)
        @delete_lines = delete_lines
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        lines = lines_of(state, command)
        return Outcome.failure(lines.error) unless lines.ok?
        args = Domain::RegisterCount.parse(command.args)
        return Outcome.failure(args.error) unless args.ok?
        lines = lines.counted(args.count, state.buffer.line_count) if args.count > 0
        @delete_lines.call(state, lines.first, lines.last, args.register)
      end

      # Registers :delete after the global commands, in the order of
      # docs/compatibility.md; no core command shares its abbreviation.
      #: (ExTable, delete_lines: DeleteLines) -> void
      def self.register(table, delete_lines:)
        table.register(DeleteCommandHandler.new(spec: "d[elete]", delete_lines: delete_lines), "Delete lines")
      end
    end
  end
end
