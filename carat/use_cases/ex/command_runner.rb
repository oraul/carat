require_relative "../../domain/editor_state"
require_relative "../outcome"

module Carat
  module UseCases
    # Runs a command line as ex commands: the interface the command line
    # and the plugin host's run_ex request depend on, so the plugin host
    # receives the runner already built and never needs it attached
    # later. ExecuteEx implements it.
    class CommandRunner
      # Runs the text and returns the Outcome to report.
      # @rbs state: Domain::EditorState
      # @rbs text: String
      def call(state, text)
        raise NotImplementedError, "CommandRunner#call"
      end
    end
  end
end
