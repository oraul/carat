require_relative "../../domain/editor_state"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :mes[sages] shows the message history: one entry on the message row,
    # several as a listing with the hit-enter prompt, none as nothing; the
    # output itself is not kept. :messages clear empties the history, and
    # any other argument is refused as Vim refuses it.
    class MessagesCommandHandler < ExHandler
      #: (spec: String) -> void
      def initialize(spec:)
        super(spec: spec)
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        args = command.args.strip
        history = state.history
        if args == "clear"
          history.clear
          return Outcome.none
        end
        return Outcome.failure("E474: Invalid argument") unless args.empty?
        state.show_output(history.to_s) if history.count > 0
        Outcome.none
      end

      # Registers :messages after the language server commands.
      #: (ExTable) -> void
      def self.register(table)
        table.register(MessagesCommandHandler.new(spec: "mes[sages]"))
      end
    end
  end
end
