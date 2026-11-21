require_relative "../../domain/editor_state"
require_relative "../../domain/comments"
require_relative "../outcome"

module Carat
  module UseCases
    # Visual gc in visual, visual_line, and visual_block: leaves visual
    # mode and toggles the comment of every line the selection touches,
    # by the marker of the buffer's filetype, the cursor on the first
    # non-blank of the selection's first line.
    class CommentSelection
      #: (Domain::EditorState) -> Outcome
      def call(state)
        selection = state.end_visual
        buffer = state.buffer
        top = selection.top
        Domain::Comments.toggle(buffer, top, selection.bottom, Domain::Comments.marker_for(buffer.filetype))
        state.cursor.move_to(top, buffer.first_nonblank(top))
        Outcome.none
      end
    end
  end
end
