require_relative "../../domain/mode"
require_relative "../leave_insert"
require_relative "../edit_command_line"
require_relative "../visual/start_visual"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # Escape: back to normal mode from whatever mode is current, leaving
    # insert mode, cancelling the command line, or leaving a visual mode
    # with its selection kept for "gv".
    class NormalModeHandler < ActionHandler
      # @rbs @leave_insert: LeaveInsert
      # @rbs @command_line: EditCommandLine
      # @rbs @start_visual: StartVisual

      #: (leave_insert: LeaveInsert, command_line: EditCommandLine, start_visual: StartVisual) -> void
      def initialize(leave_insert:, command_line:, start_visual:)
        super(kind: :action, repeat: false)
        @leave_insert = leave_insert
        @command_line = command_line
        @start_visual = start_visual
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        mode = state.mode
        return @leave_insert.call(state) if mode == Domain::Mode::INSERT
        return @command_line.cancel(state) if mode == Domain::Mode::CMDLINE
        return @start_visual.leave(state) if Domain::Mode.visual?(mode)
        state.mode = Domain::Mode::NORMAL
        Outcome.none
      end

      #: (ActionTable, leave_insert: LeaveInsert, command_line: EditCommandLine, start_visual: StartVisual) -> void
      def self.register(table, leave_insert:, command_line:, start_visual:)
        table.register("mode.normal", NormalModeHandler.new(leave_insert: leave_insert, command_line: command_line, start_visual: start_visual))
      end
    end
  end
end
