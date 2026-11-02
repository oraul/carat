require_relative "../../domain/editor_state"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :sy[ntax] on, :syntax enable, and :syntax off switch highlighting
    # for every buffer; the switch is in the options. :syntax alone would
    # list the syntax items, which Carat does not have, and any other
    # argument is refused as Vim refuses an unknown subcommand.
    class SyntaxCommandHandler < ExHandler
      #: (spec: String) -> void
      def initialize(spec:)
        super(spec: spec)
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        args = command.args.strip
        case args
        when "on", "enable"
          state.options.syntax_on = true
          Outcome.none
        when "off"
          state.options.syntax_on = false
          Outcome.none
        when ""
          Outcome.success("Not implemented: :syntax list")
        else
          Outcome.failure("E410: Invalid :syntax subcommand: #{args}")
        end
      end

      # Registers :syntax after the register commands.
      #: (ExTable) -> void
      def self.register(table)
        table.register(SyntaxCommandHandler.new(spec: "sy[ntax]"))
      end
    end
  end
end
