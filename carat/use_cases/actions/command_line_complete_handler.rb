require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../complete_command_line"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # <Tab> and <S-Tab> on the command line: cmdline.complete_next and
    # cmdline.complete_previous complete the word before the cursor at the
    # `:` prompt and step through the matches, through
    # CompleteCommandLine with the step 1 or -1.
    class CommandLineCompleteHandler < ActionHandler
      # @rbs @complete_command_line: CompleteCommandLine
      # @rbs @step: Integer

      #: (complete_command_line: CompleteCommandLine, step: Integer) -> void
      def initialize(complete_command_line:, step:)
        super(kind: :action, repeat: false)
        @complete_command_line = complete_command_line
        @step = step
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        @complete_command_line.call(state, @step)
      end

      #: (ActionTable, complete_command_line: CompleteCommandLine) -> void
      def self.register(table, complete_command_line:)
        table.register("cmdline.complete_next", CommandLineCompleteHandler.new(complete_command_line: complete_command_line, step: 1), "Complete the next match")
        table.register("cmdline.complete_previous", CommandLineCompleteHandler.new(complete_command_line: complete_command_line, step: -1), "Complete the previous match")
      end
    end
  end
end
