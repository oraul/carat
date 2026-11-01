require_relative "../domain/editor_state"
require_relative "move"
require_relative "outcome"

module Carat
  module UseCases
    # Enters insert mode at the positions Vim uses for i a I A o O.
    class EnterInsert
      # @rbs @move: Move

      #: (move: Move) -> void
      def initialize(move:)
        @move = move
      end

      #: (Domain::EditorState, Symbol) -> Outcome
      def call(state, where)
        cursor = state.cursor
        buffer = state.buffer
        line = state.current_line
        case where
        when :after
          cursor.move_to(cursor.row, cursor.col + 1) if cursor.col < line.length
        when :line_start
          cursor.move_to(cursor.row, @move.first_nonblank(line))
        when :line_end
          cursor.move_to(cursor.row, line.length)
        when :open_below
          indent = indent_of(state, line)
          buffer.set_lines(cursor.row + 1, cursor.row + 1, [indent])
          cursor.move_to(cursor.row + 1, indent.length)
        when :open_above
          indent = indent_of(state, line)
          buffer.set_lines(cursor.row, cursor.row, [indent])
          cursor.move_to(cursor.row, indent.length)
        end
        state.mode = Domain::Mode::INSERT
        Outcome.none
      end

      # The leading blanks of line when autoindent is on, else "".
      #: (Domain::EditorState, String) -> String
      def indent_of(state, line)
        return "" unless state.options.autoindent
        i = 0
        i += 1 while i < line.length && (line[i, 1] == " " || line[i, 1] == "\t")
        line[0, i]
      end
    end
  end
end
