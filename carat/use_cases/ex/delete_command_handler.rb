require_relative "../../domain/editor_state"
require_relative "../../domain/ex_range"
require_relative "../../domain/register_count"
require_relative "../delete_lines"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :[range]d[elete] [x] [count] through DeleteLines on the range, the
    # cursor line without one; a count deletes count lines from the
    # range's last line, stopping at the buffer's last line. A bad range
    # reports what ExRange gives, a bad argument what RegisterCount gives,
    # a bang E477.
    class DeleteCommandHandler < ExHandler
      attr_reader :delete_lines #: DeleteLines

      #: (spec: String, delete_lines: DeleteLines) -> void
      def initialize(spec:, delete_lines:)
        super(spec: spec)
        @delete_lines = delete_lines
      end

      # True: the range is the lines to delete.
      # @rbs skip
      def ranged?
        true
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        return Outcome.failure("E477: No ! allowed") if command.bang
        lines = Domain::ExRange.resolve(command.range, state.cursor.row, state.buffer.line_count, state.window.last_selection)
        return Outcome.failure(lines.error) unless lines.ok?
        args = Domain::RegisterCount.parse(command.args)
        return Outcome.failure(args.error) unless args.ok?
        first = lines.first
        last = lines.last
        if args.count > 0
          first = last
          last += args.count - 1
          last = state.buffer.line_count - 1 if last > state.buffer.line_count - 1
        end
        @delete_lines.call(state, first, last, args.register)
      end

      # Registers :delete after the global commands, in the order of
      # docs/compatibility.md; no core command shares its abbreviation.
      #: (ExTable, delete_lines: DeleteLines) -> void
      def self.register(table, delete_lines:)
        table.register(DeleteCommandHandler.new(spec: "d[elete]", delete_lines: delete_lines))
      end
    end
  end
end
