require_relative "../../domain/editor_state"
require_relative "../../domain/mode"
require_relative "../../domain/selection"
require_relative "../../domain/display_width"
require_relative "../outcome"

module Carat
  module UseCases
    # Visual I (append false) and A (append true): leaves visual mode and
    # enters insert mode before the start or after the end of the
    # selection; in a block, on the top row before the block, after it
    # (padding a short top row), or at the row's end after "$", with the
    # repetition recorded so the typed text goes on the other rows when
    # insert mode is left.
    class InsertAtSelection
      #: (Domain::EditorState, bool) -> Outcome
      def call(state, append)
        selection = state.end_visual
        if selection.kind == :blockwise
          insert_block(state, selection, append)
          return Outcome.none
        end
        buffer = state.buffer
        row = selection.bottom
        col = buffer.line(row).length
        unless append
          start = selection.line_start
          row = start.row
          col = start.col
        end
        state.mode = Domain::Mode::INSERT
        len = buffer.line(row).length
        state.cursor.move_to(row, col > len ? len : col)
        Outcome.none
      end

      private

      #: (Domain::EditorState, Domain::Selection, bool) -> void
      def insert_block(state, selection, append)
        buffer = state.buffer
        tabstop = state.options.tab_width
        block = selection.block(buffer, tabstop)
        top = block.top
        line = buffer.line(top)
        home = block.span(line, tabstop).from
        kind = :insert
        vcol = block.left
        rows = block.reaching_rows(buffer, tabstop)
        col = Domain::DisplayWidth.col_at(line, vcol, tabstop)
        if append
          rows = []
          row = top + 1
          while row <= block.bottom
            rows << row
            row += 1
          end
          if block.to_end
            kind = :append_end
            col = line.length
          else
            kind = :append
            vcol = block.right + 1
            width = Domain::DisplayWidth.column(line, line.length, tabstop)
            if width < vcol
              line = line + (" " * (vcol - width))
              buffer.set_lines(top, top + 1, [line])
            end
            col = Domain::DisplayWidth.col_at(line, vcol, tabstop)
          end
        end
        state.mode = Domain::Mode::INSERT
        state.cursor.move_to(top, col)
        state.block_insert.start(kind, top, col, line.length, buffer.line_count, rows, vcol, home)
      end
    end
  end
end
