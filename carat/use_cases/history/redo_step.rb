require_relative "../../domain/editor_state"
require_relative "../outcome"
require_relative "walk_history"

module Carat
  module UseCases
    # Ctrl-R and :redo: count states forward along the current branch of
    # the current buffer's undo tree, following each state's head.
    class RedoStep
      attr_reader :walk_history #: WalkHistory

      #: (walk_history: WalkHistory) -> void
      def initialize(walk_history:)
        @walk_history = walk_history
      end

      #: (Domain::EditorState, Integer) -> Outcome
      def call(state, count)
        @walk_history.call(state, state.buffer.undo.redo_path(count), false, false)
      end
    end
  end
end
