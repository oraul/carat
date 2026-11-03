require_relative "../../domain/editor_state"
require_relative "../outcome"
require_relative "walk_history"

module Carat
  module UseCases
    # u: count states back along the current branch of the current
    # buffer's undo tree, fewer when the original text comes first.
    class UndoStep
      attr_reader :walk_history #: WalkHistory

      #: (walk_history: WalkHistory) -> void
      def initialize(walk_history:)
        @walk_history = walk_history
      end

      #: (Domain::EditorState, Integer) -> Outcome
      def call(state, count)
        @walk_history.call(state, state.buffer.undo.undo_path(count), true, false)
      end
    end
  end
end
