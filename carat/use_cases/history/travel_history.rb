require_relative "../../domain/editor_state"
require_relative "../outcome"
require_relative "walk_history"

module Carat
  module UseCases
    # g-, g+, :earlier, and :later: steps states back (negative) or
    # forward in the order they were made, across branches of the
    # current buffer's undo tree.
    class TravelHistory
      attr_reader :walk_history #: WalkHistory

      #: (walk_history: WalkHistory) -> void
      def initialize(walk_history:)
        @walk_history = walk_history
      end

      #: (Domain::EditorState, Integer) -> Outcome
      def call(state, steps)
        tree = state.buffer.undo
        back = steps < 0
        if back
          return @walk_history.call(state, [], true, false) if tree.current == tree.root
          target = tree.nearest(tree.current + steps, true)
        else
          return @walk_history.call(state, [], false, false) if tree.current >= tree.last
          wanted = tree.current + steps
          wanted = tree.last if wanted > tree.last
          target = tree.nearest(wanted, false)
          return @walk_history.call(state, [], false, false) if target < 0
        end
        path = tree.path_to(target)
        return Outcome.none if path.empty?
        @walk_history.call(state, path, back, false)
      end
    end
  end
end
