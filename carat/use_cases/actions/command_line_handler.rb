require_relative "../enter_command_line"
require_relative "../execute_command_line"
require_relative "../erase_command_line"
require_relative "../recall_history"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # ":" through EnterCommandLine, Enter through ExecuteCommandLine, whose
    # outcome is the ex command's, Backspace through EraseCommandLine, and
    # <Up> and <Down> through RecallHistory.
    class CommandLineHandler < ActionHandler
      # @rbs @enter_command_line: EnterCommandLine
      # @rbs @execute_command_line: ExecuteCommandLine
      # @rbs @erase_command_line: EraseCommandLine
      # @rbs @recall_history: RecallHistory
      # @rbs @variant: Symbol

      #: (enter_command_line: EnterCommandLine, execute_command_line: ExecuteCommandLine, erase_command_line: EraseCommandLine, recall_history: RecallHistory, variant: Symbol) -> void
      def initialize(enter_command_line:, execute_command_line:, erase_command_line:, recall_history:, variant:)
        super(kind: :action, repeat: false)
        @enter_command_line = enter_command_line
        @execute_command_line = execute_command_line
        @erase_command_line = erase_command_line
        @recall_history = recall_history
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        case @variant
        when :start then @enter_command_line.call(state)
        when :execute then @execute_command_line.call(state)
        when :older then @recall_history.call(state, true)
        when :newer then @recall_history.call(state, false)
        else @erase_command_line.call(state)
        end
      end

      #: (ActionTable, enter_command_line: EnterCommandLine, execute_command_line: ExecuteCommandLine, erase_command_line: EraseCommandLine, recall_history: RecallHistory) -> void
      def self.register(table, enter_command_line:, execute_command_line:, erase_command_line:, recall_history:)
        names = ["mode.cmdline", "cmdline.execute", "cmdline.backspace", "cmdline.history_older", "cmdline.history_newer"]
        variants = [:start, :execute, :backspace, :older, :newer]
        descriptions = ["Command line", "Run command line", "Erase character", "Older history entry", "Newer history entry"]
        i = 0
        while i < names.length
          table.register(names[i], CommandLineHandler.new(enter_command_line: enter_command_line, execute_command_line: execute_command_line, erase_command_line: erase_command_line, recall_history: recall_history, variant: variants[i]), descriptions[i])
          i += 1
        end
      end
    end
  end
end
