require_relative "editor_state"
require_relative "selection"
require_relative "operators"
require_relative "register_entry"

module Carat
  module Domain
    # Deletes a visual selection and returns what it held, as the visual
    # delete, change, and put do before they write a register or put text
    # in its place. The cursor goes to the start of a charwise selection,
    # the first non-blank of the top row of a linewise one, and a block's
    # top-left.
    module SelectionCut
      #: (EditorState, Selection) -> RegisterEntry
      def self.call(state, selection)
        buffer = state.buffer
        cursor = state.cursor
        if selection.kind == :linewise
          range = selection.line_range
          entry = Operators.extract(buffer, range)
          Operators.delete(buffer, range)
          row = selection.top
          row = buffer.line_count - 1 if row > buffer.line_count - 1
          cursor.move_to(row, buffer.first_nonblank(row))
          return entry
        end
        if selection.kind == :blockwise
          tabstop = state.options.tab_width
          block = selection.block(buffer, tabstop)
          col = block.span(buffer.line(block.top), tabstop).from
          entry = Operators.extract_block(buffer, block, tabstop)
          Operators.delete_block(buffer, block, tabstop)
          cursor.move_to(block.top, state.clamp_col(block.top, col))
          return entry
        end
        range = selection.char_range(buffer)
        entry = Operators.extract(buffer, range)
        Operators.delete(buffer, range)
        from = range.from
        cursor.move_to(from.row, state.clamp_col(from.row, from.col))
        entry
      end
    end
  end
end
