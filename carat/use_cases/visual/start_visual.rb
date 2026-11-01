require_relative "../../domain/editor_state"
require_relative "../../domain/mode"
require_relative "../../domain/position"
require_relative "../../domain/selection"
require_relative "../outcome"

module Carat
  module UseCases
    # Enters, switches, leaves, and reselects the visual modes. "v", "V",
    # and "<C-v>" set the anchor at the cursor from normal mode, leave
    # when pressed in their own mode, and switch the kind otherwise; "gv"
    # restores the window's last selection.
    class StartVisual
      # The key of a visual mode: enters it from normal mode, leaves it
      # when it is the current one, and switches to it from another
      # visual mode keeping the anchor and the cursor.
      #: (Domain::EditorState, Symbol) -> Outcome
      def toggle(state, mode)
        if state.mode == mode
          leave(state)
        elsif Domain::Mode.visual?(state.mode)
          state.mode = mode
        else
          state.window.anchor = state.cursor.position
          state.mode = mode
        end
        Outcome.none
      end

      # Escape and Ctrl-C: back to normal mode, keeping the selection for
      # "gv".
      #: (Domain::EditorState) -> Outcome
      def leave(state)
        state.end_visual
        Outcome.none
      end

      # "gv": the window's last selection again, clamped to the buffer. In
      # a visual mode the current selection takes its place as the last
      # one. Nothing happens when the window has none.
      #: (Domain::EditorState) -> Outcome
      def reselect(state)
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
        Domain::Position.new(row, pos.col > len ? len : pos.col)
      end
    end
  end
end
