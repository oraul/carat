require_relative "../../domain/editor_state"
require_relative "../../domain/ex_command"
require_relative "../../domain/ex_name"
require_relative "../outcome"

module Carat
  module UseCases
    # The input port of an ex command: the handler carries its name in
    # Vim's notation name[suffix] and runs the parsed command line. The
    # ExTable offers a typed name to each handler in registration order
    # and runs the first that matches.
    class ExHandler
      attr_reader :name #: Domain::ExName

      #: (spec: String) -> void
      def initialize(spec:)
        @name = Domain::ExName.parse(spec)
      end

      # Whether the typed name names this command.
      # @rbs typed: String
      def matches?(typed)
        @name.match?(typed)
      end

      # Runs the command and returns the Outcome to report.
      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        raise NotImplementedError, "ExHandler#call"
      end
    end
  end
end
