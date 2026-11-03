require_relative "../../domain/editor_state"
require_relative "../outcome"
require_relative "walk_history"

module Carat
  module UseCases
    # :undo N: the text after state number N, 0 for the original text, or
    # E830 when no such state is kept.
    class UndoToState
      attr_reader :walk_history #: WalkHistory

      #: (walk_history: WalkHistory) -> void
      def initialize(walk_history:)
        @walk_history = walk_history
      end

      #: (Domain::EditorState, Integer) -> Outcome
      def call(state, number)
        tree = state.buffer.undo
        unless number == 0 || (number <= tree.last && tree.live?(number))
          return Outcome.failure("E830: Undo number #{number} not found")
        end
        @walk_history.call(state, tree.path_to(number == 0 ? tree.root : number), true, true)
      end
    end
  end
end
