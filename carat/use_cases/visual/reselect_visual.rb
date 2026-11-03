require_relative "../../domain/editor_state"
require_relative "../../domain/mode"
require_relative "../../domain/position"
require_relative "../../domain/selection"
require_relative "../outcome"

module Carat
  module UseCases
    # "gv": the window's last selection again, clamped to the buffer. In a
    # visual mode the current selection takes its place as the last one.
    # Nothing happens when the window has none.
    class ReselectVisual
      #: (Domain::EditorState) -> Outcome
      def call(state)
        window = state.window
        last = window.last_selection
        return Outcome.none unless last.active?
        current = state.selection
        state.mode = Domain::Mode.for_kind(last.kind)
        window.anchor = clamp(state, last.anchor)
        head = clamp(state, last.head)
        cursor = state.cursor
        cursor.move_to(head.row, head.col)
        cursor.want_col = -1 if last.to_end
        window.last_selection = current if current.active?
        Outcome.none
      end

      private

      # pos moved inside the buffer, where visual mode lets a column rest
      # on the end of the line.
      #: (Domain::EditorState, Domain::Position) -> Domain::Position
      def clamp(state, pos)
        buffer = state.buffer
        row = pos.row
        row = buffer.line_count - 1 if row > buffer.line_count - 1
        len = buffer.line(row).length
        Domain::Position.new(row: row, col: pos.col > len ? len : pos.col)
      end
    end
  end
end
