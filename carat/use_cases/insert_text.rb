require_relative "../domain/editor_state"
require_relative "../domain/range"
require_relative "enter_insert"

module Carat
  module UseCases
    # Insert-mode editing: typed text, newline, backspace, delete, and tab.
    class InsertText
      # @rbs @enter_insert: EnterInsert

      #: (EnterInsert) -> void
      def initialize(enter_insert)
        @enter_insert = enter_insert
      end

      # Inserts text without newlines at the cursor and moves past it.
      #: (Domain::EditorState, String) -> void
      def call(state, text)
        cursor = state.cursor
        state.buffer.insert(cursor.position, text)
        cursor.move_to(cursor.row, cursor.col + text.length)
      end

      #: (Domain::EditorState) -> void
      def newline(state)
        cursor = state.cursor
        indent = @enter_insert.indent_of(state, state.current_line)
        state.buffer.insert(cursor.position, "\n" + indent)
        cursor.move_to(cursor.row + 1, indent.length)
      end

      #: (Domain::EditorState) -> void
      def backspace(state)
        cursor = state.cursor
        if cursor.col > 0
          from = Domain::Position.new(cursor.row, cursor.col - 1)
          state.buffer.delete(Domain::Range.charwise(from, cursor.position))
          cursor.move_to(cursor.row, cursor.col - 1)
        elsif cursor.row > 0
          prev_len = state.buffer.line(cursor.row - 1).length
          from = Domain::Position.new(cursor.row - 1, prev_len)
          state.buffer.delete(Domain::Range.charwise(from, cursor.position))
          cursor.move_to(cursor.row - 1, prev_len)
        end
      end

      #: (Domain::EditorState) -> void
      def delete(state)
        cursor = state.cursor
        line = state.current_line
        if cursor.col < line.length
          to = Domain::Position.new(cursor.row, cursor.col + 1)
          state.buffer.delete(Domain::Range.charwise(cursor.position, to))
        elsif cursor.row < state.buffer.line_count - 1
          to = Domain::Position.new(cursor.row + 1, 0)
          state.buffer.delete(Domain::Range.charwise(cursor.position, to))
        end
      end

      #: (Domain::EditorState) -> void
      def tab(state)
        options = state.options
        if options.expandtab
          width = options.tabstop > 0 ? options.tabstop : 8
          count = width - (state.cursor.col % width)
          call(state, " " * count)
        else
          call(state, "\t")
        end
      end
    end
  end
end
