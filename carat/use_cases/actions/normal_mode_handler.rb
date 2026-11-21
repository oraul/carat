require_relative "../../domain/mode"
require_relative "../leave_insert"
require_relative "../cancel_command_line"
require_relative "../close_cmdline_menu"
require_relative "../../domain/cmdline_menu"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # Escape: back to normal mode from whatever mode is current, leaving
    # insert mode through LeaveInsert, cancelling the command line through
    # CancelCommandLine, or leaving a visual mode with its selection kept
    # for "gv". On the command line a showing completion menu is closed
    # first, through CloseCmdlineMenu, and the line stays.
    class NormalModeHandler < ActionHandler
      # @rbs @leave_insert: LeaveInsert
      # @rbs @cancel_command_line: CancelCommandLine
      # @rbs @cmdline_menu: Domain::CmdlineMenu
      # @rbs @close_cmdline_menu: CloseCmdlineMenu

      #: (leave_insert: LeaveInsert, cancel_command_line: CancelCommandLine, cmdline_menu: Domain::CmdlineMenu, close_cmdline_menu: CloseCmdlineMenu) -> void
      def initialize(leave_insert:, cancel_command_line:, cmdline_menu:, close_cmdline_menu:)
        super(kind: :action, repeat: false)
        @leave_insert = leave_insert
        @cancel_command_line = cancel_command_line
        @cmdline_menu = cmdline_menu
        @close_cmdline_menu = close_cmdline_menu
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        mode = state.mode
        return @leave_insert.call(state) if mode == Domain::Mode::INSERT
        if mode == Domain::Mode::CMDLINE
          return @cancel_command_line.call(state) unless @cmdline_menu.showing?
          @close_cmdline_menu.call(state)
          return Outcome.none
        end
        if Domain::Mode.visual?(mode)
          state.end_visual
          return Outcome.none
        end
        state.mode = Domain::Mode::NORMAL
        Outcome.none
      end

      #: (ActionTable, leave_insert: LeaveInsert, cancel_command_line: CancelCommandLine, cmdline_menu: Domain::CmdlineMenu, close_cmdline_menu: CloseCmdlineMenu) -> void
      def self.register(table, leave_insert:, cancel_command_line:, cmdline_menu:, close_cmdline_menu:)
        table.register("mode.normal", NormalModeHandler.new(leave_insert: leave_insert, cancel_command_line: cancel_command_line, cmdline_menu: cmdline_menu, close_cmdline_menu: close_cmdline_menu), "Normal mode")
      end
    end
  end
end
