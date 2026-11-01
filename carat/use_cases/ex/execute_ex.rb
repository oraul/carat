require_relative "../../domain/editor_state"
require_relative "../../domain/ex_grammar"
require_relative "../outcome"
require_relative "ex_table"

module Carat
  module UseCases
    # Parses a command line and runs the ex command it names: the first
    # handler of the ex table, in registration order, whose name the typed
    # name matches from its abbreviation to its full name. The core
    # commands come first and the plugin commands after them; a name no
    # handler takes is E492. It knows no command name: each feature
    # registers its handlers in the table.
    class ExecuteEx
      # @rbs @commands: ExTable

      #: (commands: ExTable) -> void
      def initialize(commands:)
        @commands = commands
      end

      #: (Domain::EditorState, String) -> Outcome
      def call(state, text)
        command = Domain::ExGrammar.parse(text)
        if command.name.empty?
          return command.args.empty? ? Outcome.none : unknown(text)
        end
        handler = @commands.find(command.name)
        return unknown(text) if handler.nil?
        handler.call(state, command)
      end

      private

      #: (String) -> Outcome
      def unknown(text)
        shown = text.strip
        shown = shown[1, shown.length - 1] while shown.start_with?(":")
        Outcome.failure("E492: Not an editor command: #{shown}")
      end
    end
  end
end
