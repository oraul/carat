require_relative "../../domain/editor_state"
require_relative "../../domain/ex_range"
require_relative "../search/global_command"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :[range]g[lobal]/{pattern}/[cmd], :g! (inverted), and
    # :[range]v[global]/{pattern}/[cmd] through GlobalCommand on the
    # range, every line without one. A bad range reports what ExRange
    # gives, :v! E477.
    class GlobalCommandHandler < ExHandler
      attr_reader :global_command #: GlobalCommand

      # @rbs @invert: bool

      #: (spec: String, global_command: GlobalCommand, invert: bool) -> void
      def initialize(spec:, global_command:, invert:)
        super(spec: spec)
        @global_command = global_command
        @invert = invert
      end

      # True: the range is the lines to mark.
      # @rbs skip
      def ranged?
        true
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        return Outcome.failure("E477: No ! allowed") if command.bang && @invert
        count = state.buffer.line_count
        range = command.range.empty? ? "%" : command.range
        lines = Domain::ExRange.resolve(range, state.cursor.row, count, state.window.last_selection)
        return Outcome.failure(lines.error) unless lines.ok?
        @global_command.call(state, lines.first, lines.last, command.args, @invert || command.bang)
      end

      # Registers :global and :vglobal after :&, in the order of
      # docs/compatibility.md; no core command shares their abbreviations
      # (:vs[plit] and :vne[w] need two letters).
      #: (ExTable, global_command: GlobalCommand) -> void
      def self.register(table, global_command:)
        table.register(GlobalCommandHandler.new(spec: "g[lobal]", global_command: global_command, invert: false))
        table.register(GlobalCommandHandler.new(spec: "v[global]", global_command: global_command, invert: true))
      end
    end
  end
end
