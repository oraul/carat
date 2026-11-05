require_relative "../../domain/editor_state"
require_relative "../../domain/mode"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # i a I A o O: enter insert mode at the positions Vim uses, before the
    # cursor, after it, at the first non-blank, at the end of the line, or
    # on a new line below or above that takes the line's indent when
    # autoindent is on.
    class InsertModeHandler < ActionHandler
      # @rbs @where: Symbol

      #: (where: Symbol) -> void
      def initialize(where:)
        super(kind: :action, repeat: true)
        @where = where
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        cursor = state.cursor
        buffer = state.buffer
        case @where
        when :after
          cursor.move_to(cursor.row, cursor.col + 1) if cursor.col < state.current_line.length
        when :line_start
          cursor.move_to(cursor.row, buffer.first_nonblank(cursor.row))
        when :line_end
          cursor.move_to(cursor.row, state.current_line.length)
        when :open_below
          indent = state.options.autoindent ? buffer.indent_of(cursor.row) : ""
          buffer.set_lines(cursor.row + 1, cursor.row + 1, [indent])
          cursor.move_to(cursor.row + 1, indent.length)
        when :open_above
          indent = state.options.autoindent ? buffer.indent_of(cursor.row) : ""
          buffer.set_lines(cursor.row, cursor.row, [indent])
          cursor.move_to(cursor.row, indent.length)
        end
        state.mode = Domain::Mode::INSERT
        Outcome.none
      end

      #: (ActionTable) -> void
      def self.register(table)
        table.register("mode.insert", InsertModeHandler.new(where: :before), "Insert before cursor")
        table.register("mode.insert_after", InsertModeHandler.new(where: :after), "Insert after cursor")
        table.register("mode.insert_line_start", InsertModeHandler.new(where: :line_start), "Insert at line start")
        table.register("mode.insert_line_end", InsertModeHandler.new(where: :line_end), "Insert at line end")
        table.register("mode.insert_open_below", InsertModeHandler.new(where: :open_below), "Open line below")
        table.register("mode.insert_open_above", InsertModeHandler.new(where: :open_above), "Open line above")
      end
    end
  end
end
