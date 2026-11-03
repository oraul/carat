require_relative "../enter_command_line"
require_relative "../execute_command_line"
require_relative "../erase_command_line"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # ":" through EnterCommandLine, Enter through ExecuteCommandLine, whose
    # outcome is the ex command's, and Backspace through
    # EraseCommandLine.
    class CommandLineHandler < ActionHandler
      # @rbs @enter_command_line: EnterCommandLine
      # @rbs @execute_command_line: ExecuteCommandLine
      # @rbs @erase_command_line: EraseCommandLine
      # @rbs @variant: Symbol

      #: (enter_command_line: EnterCommandLine, execute_command_line: ExecuteCommandLine, erase_command_line: EraseCommandLine, variant: Symbol) -> void
      def initialize(enter_command_line:, execute_command_line:, erase_command_line:, variant:)
        super(kind: :action, repeat: false)
        @enter_command_line = enter_command_line
        @execute_command_line = execute_command_line
        @erase_command_line = erase_command_line
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        case @variant
        when :start then @enter_command_line.call(state)
        when :execute then @execute_command_line.call(state)
        else @erase_command_line.call(state)
        end
      end

      #: (ActionTable, enter_command_line: EnterCommandLine, execute_command_line: ExecuteCommandLine, erase_command_line: EraseCommandLine) -> void
      def self.register(table, enter_command_line:, execute_command_line:, erase_command_line:)
        names = ["mode.cmdline", "cmdline.execute", "cmdline.backspace"]
        variants = [:start, :execute, :backspace]
        i = 0
        while i < names.length
          table.register(names[i], CommandLineHandler.new(enter_command_line: enter_command_line, execute_command_line: execute_command_line, erase_command_line: erase_command_line, variant: variants[i]))
          i += 1
        end
      end
    end
  end
end
