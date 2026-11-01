require_relative "../edit_command_line"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # ":" and the command-line keys bound to actions, through
    # EditCommandLine; executing returns the ex command's outcome.
    class CommandLineHandler < ActionHandler
      # @rbs @command_line: EditCommandLine
      # @rbs @variant: Symbol

      #: (command_line: EditCommandLine, variant: Symbol) -> void
      def initialize(command_line:, variant:)
        super(kind: :action, repeat: false)
        @command_line = command_line
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        case @variant
        when :start then @command_line.start(state)
        when :execute then @command_line.execute(state)
        else @command_line.backspace(state)
        end
      end

      #: (ActionTable, command_line: EditCommandLine) -> void
      def self.register(table, command_line:)
        table.register("mode.cmdline", CommandLineHandler.new(command_line: command_line, variant: :start))
        table.register("cmdline.execute", CommandLineHandler.new(command_line: command_line, variant: :execute))
        table.register("cmdline.backspace", CommandLineHandler.new(command_line: command_line, variant: :backspace))
      end
    end
  end
end
