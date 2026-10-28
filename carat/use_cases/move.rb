require_relative "../domain/editor_state"

module Carat
  module UseCases
    # The foundation cursor motions. Horizontal motions set the wanted
    # column; vertical motions aim for it and clamp to the line.
    class Move
      #: (Domain::EditorState, Symbol) -> void
      def call(state, direction)
        cursor = state.cursor
        case direction
        when :left
          cursor.move_to(cursor.row, cursor.col - 1) if cursor.col > 0
        when :right
          cursor.move_to(cursor.row, cursor.col + 1) if cursor.col < state.max_col(cursor.row)
        when :up
          vertical(state, cursor.row - 1) if cursor.row > 0
        when :down
          vertical(state, cursor.row + 1) if cursor.row < state.buffer.line_count - 1
        when :line_start
          cursor.move_to(cursor.row, 0)
        when :first_nonblank
          cursor.move_to(cursor.row, first_nonblank(state.current_line))
        when :line_end
          cursor.move_to(cursor.row, state.max_col(cursor.row))
          cursor.want_col = -1
        when :buffer_start
          vertical(state, 0)
        when :buffer_end
          vertical(state, state.buffer.line_count - 1)
        end
      end

      # The column of the first character that is not a space or a tab, or
      # the last column when the line is blank.
      #: (String) -> Integer
      def first_nonblank(line)
        i = 0
        i += 1 while i < line.length && (line[i, 1] == " " || line[i, 1] == "\t")
        i >= line.length ? (line.length > 0 ? line.length - 1 : 0) : i
      end

      private

      #: (Domain::EditorState, Integer) -> void
      def vertical(state, row)
        cursor = state.cursor
        max = state.max_col(row)
        want = cursor.want_col
        col = want < 0 ? max : want
        col = max if col > max
        cursor.row = row
        cursor.col = col
      end
    end
  end
end
