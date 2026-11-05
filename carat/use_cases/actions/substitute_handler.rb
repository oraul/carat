require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../../domain/ex_range"
require_relative "../../domain/substitute_args"
require_relative "../search/substitute_lines"
require_relative "../outcome"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # "&" (substitute.repeat): the last substitute again on the cursor line
    # without its flags, as ":s" does, on count lines with a count (E16
    # past the last line); "g&" (substitute.repeat_all): ":%s//~/&", the
    # last search pattern replaced by the last string on every line with
    # the last flags. Neither is a change "." repeats, as in Vim.
    class SubstituteHandler < ActionHandler
      attr_reader :substitute_lines #: SubstituteLines

      # @rbs @variant: Symbol

      #: (substitute_lines: SubstituteLines, variant: Symbol) -> void
      def initialize(substitute_lines:, variant:)
        super(kind: :action, repeat: false)
        @substitute_lines = substitute_lines
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        last = state.buffer.line_count - 1
        return @substitute_lines.call(state, 0, last, Domain::SubstituteArgs.parse("//~/&", true)) if @variant == :all
        row = state.cursor.row
        to = row + command.count_or(1) - 1
        return Outcome.failure(Domain::ExRange::INVALID) if to > last
        @substitute_lines.call(state, row, to, Domain::SubstituteArgs.parse("", false))
      end

      #: (ActionTable, substitute_lines: SubstituteLines) -> void
      def self.register(table, substitute_lines:)
        table.register("substitute.repeat", SubstituteHandler.new(substitute_lines: substitute_lines, variant: :line), "Repeat substitute on line")
        table.register("substitute.repeat_all", SubstituteHandler.new(substitute_lines: substitute_lines, variant: :all), "Repeat substitute everywhere")
      end
    end
  end
end
