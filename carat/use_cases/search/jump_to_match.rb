require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../outcome"
require_relative "find_match"

module Carat
  module UseCases
    # A search command outside an operator: the cursor moves to the start
    # of the match FindMatch found, a match at the end of a line resting
    # on its last character outside the visual modes, and the hit's
    # message is shown, as an error when there was no match. The echo of
    # the pattern is output the message history does not keep; the wrap
    # message and an error are kept. A match
    # found records the position left in the jump list. In a visual
    # mode the moved cursor extends the selection.
    class JumpToMatch
      attr_reader :find_match #: FindMatch

      #: (find_match: FindMatch) -> void
      def initialize(find_match:)
        @find_match = find_match
      end

      #: (Domain::EditorState, Domain::Command) -> Outcome
      def call(state, command)
        hit = @find_match.call(state, command)
        return Outcome.failure(hit.message) unless hit.found?
        state.window.record_jump
        state.cursor.move_to(hit.row, state.clamp_col(hit.row, hit.col))
        return Outcome.success(hit.message) if hit.wrapped
        state.show_output(hit.message)
        Outcome.none
      end
    end
  end
end
