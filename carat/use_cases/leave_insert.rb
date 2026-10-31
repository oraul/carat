require_relative "../domain/editor_state"
require_relative "../domain/block_insert"
require_relative "../domain/display_width"

module Carat
  module UseCases
    # Returns to normal mode, moving the cursor onto the last inserted
    # character as Vim does. After a blockwise "I", "A", or "c", the text
    # typed on the block's top row is inserted on the block's other rows
    # first, when the cursor is still on that row and no line was added;
    # after "I" and "A" the cursor then goes to the block's top-left.
    # Leaving insert mode ends the insert session: the transaction the
    # command that entered insert mode opened is closed here, after the
    # block repeat, with the cursor where it comes to rest.
    class LeaveInsert
      #: (Domain::EditorState) -> void
      def call(state)
        leave(state)
        state.buffer.commit_transaction(state.cursor.position)
      end

      private

      #: (Domain::EditorState) -> void
      def leave(state)
        cursor = state.cursor
        state.mode = Domain::Mode::NORMAL
        pending = state.block_insert
        if pending.active
          home = repeat(state, pending)
          pending.clear
          if home >= 0
            cursor.move_to(cursor.row, home)
            return
          end
        end
        cursor.move_to(cursor.row, cursor.col - 1) if cursor.col > 0
      end

      # Inserts the text typed on the top row on every recorded row and
      # returns the column the cursor goes to, or -1 for the usual one
      # column left.
      #: (Domain::EditorState, Domain::BlockInsert) -> Integer
      def repeat(state, pending)
        buffer = state.buffer
        return -1 unless buffer.line_count == pending.line_count && state.cursor.row == pending.row
        line = buffer.line(pending.row)
        added = line.length - pending.length
        return -1 if added <= 0 || pending.col + added > line.length
        text = line[pending.col, added]
        tabstop = state.options.tabstop > 0 ? state.options.tabstop : 8
        i = 0
        while i < pending.rows.length
          row = pending.row_at(i)
          current = buffer.line(row)
          col = current.length
          unless pending.kind == :append_end
            width = Domain::DisplayWidth.column(current, current.length, tabstop)
            current = current + (" " * (pending.vcol - width)) if pending.kind == :append && width < pending.vcol
            col = Domain::DisplayWidth.col_at(current, pending.vcol, tabstop)
          end
          buffer.set_lines(row, row + 1, [current[0, col] + text + current[col, current.length - col]])
          i += 1
        end
        pending.kind == :change ? -1 : pending.home
      end
    end
  end
end
