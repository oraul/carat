require_relative "../../domain/editor_state"
require_relative "../../domain/ex_range"
require_relative "../../domain/substitute_args"
require_relative "../search/substitute_lines"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :[range]s[ubstitute]/pattern/string/[flags] [count], and
    # :[range]& with flags and a count, which repeats the last substitute
    # (":&&" keeps its flags), through SubstituteLines on the range, the
    # cursor line without one. A bad range reports what ExRange gives, a
    # bang E477.
    class SubstituteCommandHandler < ExHandler
      attr_reader :substitute_lines #: SubstituteLines

      # @rbs @allow_pattern: bool

      #: (spec: String, substitute_lines: SubstituteLines, allow_pattern: bool) -> void
      def initialize(spec:, substitute_lines:, allow_pattern:)
        super(spec: spec)
        @substitute_lines = substitute_lines
        @allow_pattern = allow_pattern
      end

      # True: the range is the lines to substitute.
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
        args = Domain::SubstituteArgs.parse(command.args, @allow_pattern)
        @substitute_lines.call(state, lines.first, lines.last, args)
      end

      # Registers :substitute and :& after :nohlsearch, in the order of
      # docs/compatibility.md; no other command shares their spellings.
      #: (ExTable, substitute_lines: SubstituteLines) -> void
      def self.register(table, substitute_lines:)
        table.register(SubstituteCommandHandler.new(spec: "s[ubstitute]", substitute_lines: substitute_lines, allow_pattern: true))
        table.register(SubstituteCommandHandler.new(spec: "&", substitute_lines: substitute_lines, allow_pattern: false))
      end
    end
  end
end
