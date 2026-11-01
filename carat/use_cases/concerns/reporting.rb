require_relative "../../domain/editor_state"
require_relative "../outcome"

module Carat
  module UseCases
    # The one step that shows what a use case reported: a non-empty
    # message goes to the message row, as an error when the outcome
    # failed, and an empty one leaves the row as it is. Included by the
    # dispatcher for every action, by HandleKey for its remap errors, and
    # by the editor assembly for the startup open and the configuration
    # report.
    #
    # Readers the including class provides: none; the state and the
    # outcome are the arguments.
    module Reporting
      # Shows the outcome's message, if it has one.
      # @rbs skip
      def report(state, outcome)
        state.show(outcome.message, !outcome.ok) unless outcome.message.empty?
        nil
      end
    end
  end
end
