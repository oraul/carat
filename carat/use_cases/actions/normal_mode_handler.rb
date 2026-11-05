require_relative "../../domain/mode"
require_relative "../leave_insert"
require_relative "../cancel_command_line"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # Escape: back to normal mode from whatever mode is current, leaving
    # insert mode through LeaveInsert, cancelling the command line through
    # CancelCommandLine, or leaving a visual mode with its selection kept
    # for "gv".
    class NormalModeHandler < ActionHandler
      # @rbs @leave_insert: LeaveInsert
      # @rbs @cancel_command_line: CancelCommandLine

      #: (leave_insert: LeaveInsert, cancel_command_line: CancelCommandLine) -> void
      def initialize(leave_insert:, cancel_command_line:)
        super(kind: :action, repeat: false)
        @leave_insert = leave_insert
        @cancel_command_line = cancel_command_line
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        mode = state.mode
        return @leave_insert.call(state) if mode == Domain::Mode::INSERT
        return @cancel_command_line.call(state) if mode == Domain::Mode::CMDLINE
        if Domain::Mode.visual?(mode)
          state.end_visual
          return Outcome.none
        end
        state.mode = Domain::Mode::NORMAL
        Outcome.none
      end

      #: (ActionTable, leave_insert: LeaveInsert, cancel_command_line: CancelCommandLine) -> void
      def self.register(table, leave_insert:, cancel_command_line:)
        table.register("mode.normal", NormalModeHandler.new(leave_insert: leave_insert, cancel_command_line: cancel_command_line), "Normal mode")
      end
    end
  end
end
