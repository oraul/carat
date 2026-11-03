require_relative "../../domain/editor_state"
require_relative "../../domain/mode"
require_relative "../../domain/position"
require_relative "../../domain/display_width"
require_relative "../outcome"

module Carat
  module UseCases
    # "o" (corner false): the anchor and the cursor change places. "O"
    # (corner true): in a block, the cursor goes to the other corner on
    # its row and the anchor to the opposite column on its own, as
    # Neovim's v_swap_corners; in the other kinds, as "o".
    class SwapVisualEnds
      #: (Domain::EditorState, bool) -> Outcome
      def call(state, corner)
        if corner && state.mode == Domain::Mode::VISUAL_BLOCK
          swap_corner(state)
        else
          window = state.window
          cursor = state.cursor
          anchor = window.anchor
          window.anchor = cursor.position
          cursor.move_to(anchor.row, anchor.col)
        end
        Outcome.none
      end

      private

      #: (Domain::EditorState) -> void
      def swap_corner(state)
        tabstop = state.options.tab_width
        buffer = state.buffer
        window = state.window
        cursor = state.cursor
        anchor = window.anchor
        block = state.selection.block(buffer, tabstop)
        anchor_line = buffer.line(anchor.row)
        cursor_line = buffer.line(cursor.row)
        anchor_col = Domain::DisplayWidth.col_at(anchor_line, block.left, tabstop)
        cursor_col = Domain::DisplayWidth.col_at(cursor_line, block.right, tabstop)
        if cursor_col == cursor.col
          anchor_col = Domain::DisplayWidth.col_at(anchor_line, block.right, tabstop)
          cursor_col = Domain::DisplayWidth.col_at(cursor_line, block.left, tabstop)
        end
        window.anchor = Domain::Position.new(row: anchor.row, col: anchor_col)
        cursor.move_to(cursor.row, cursor_col)
      end
    end
  end
end
