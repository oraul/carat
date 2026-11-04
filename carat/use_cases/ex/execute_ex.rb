require_relative "../../domain/editor_state"
require_relative "../../domain/ex_grammar"
require_relative "../../domain/ex_range"
require_relative "../../domain/motions"
require_relative "../outcome"
require_relative "ex_table"
require_relative "command_runner"

module Carat
  module UseCases
    # Parses a command line and runs the ex command it names: the first
    # handler of the ex table, in registration order, whose name the typed
    # name matches from its abbreviation to its full name. The core
    # commands come first and the plugin commands after them; a name no
    # handler takes is E492, and a range before a command that takes none
    # E481. A range with no command moves the cursor to its last line,
    # keeping the wanted column as G does. It knows no command name: each
    # feature registers its handlers in the table, which may still be filled
    # after the runner is built: the plugin host receives the runner first
    # and the plugin command handler, registered last, the host.
    class ExecuteEx < CommandRunner
      attr_reader :commands #: ExTable

      #: (commands: ExTable) -> void
      def initialize(commands:)
        @commands = commands
      end

      # Returns the handler's outcome, E492, or E481.
      # @rbs state: Domain::EditorState
      # @rbs text: String
      def call(state, text)
        command = Domain::ExGrammar.parse(text)
        if command.name.empty?
          return unknown(text) unless command.args.empty?
          return command.range.empty? ? Outcome.none : go_to(state, command.range)
        end
        handler = @commands.find(command.name)
        return unknown(text) if handler.nil?
        return Outcome.failure("E481: No range allowed") unless command.range.empty? || handler.ranged?
        handler.call(state, command)
      end

      private

      # A range alone: the cursor to its last line.
      #: (Domain::EditorState, String) -> Outcome
      def go_to(state, range)
        cursor = state.cursor
        lines = Domain::ExRange.resolve(range, cursor.row, state.buffer.line_count, state.window.last_selection)
        return Outcome.failure(lines.error) unless lines.ok?
        cursor.row = lines.last
        cursor.col = Domain::Motions.wanted_col(state, lines.last)
        Outcome.none
      end

      #: (String) -> Outcome
      def unknown(text)
        shown = text.strip
        shown = shown[1, shown.length - 1] while shown.start_with?(":")
        Outcome.failure("E492: Not an editor command: #{shown}")
      end
    end
  end
end
