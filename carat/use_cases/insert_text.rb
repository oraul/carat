require_relative "../domain/editor_state"
require_relative "../domain/range"
require_relative "../domain/last_change"
require_relative "enter_insert"
require_relative "outcome"

module Carat
  module UseCases
    # Insert-mode editing: typed text, newline, backspace, delete, and tab.
    # Each is noted in the last change, for the dot command to type again
    # and for the "." register.
    class InsertText
      attr_reader :last_change #: Domain::LastChange

      # @rbs @enter_insert: EnterInsert

      #: (enter_insert: EnterInsert, last_change: Domain::LastChange) -> void
      def initialize(enter_insert:, last_change:)
        @enter_insert = enter_insert
        @last_change = last_change
      end

      # Inserts text without newlines at the cursor and moves past it.
      #: (Domain::EditorState, String) -> Outcome
      def call(state, text)
        put(state, text)
        @last_change.add_text(text)
        Outcome.none
      end

      #: (Domain::EditorState) -> Outcome
      def newline(state)
        @last_change.add_action("insert.newline", "\n", false)
        cursor = state.cursor
        indent = @enter_insert.indent_of(state, state.current_line)
        state.buffer.insert(cursor.position, "\n" + indent)
        cursor.move_to(cursor.row + 1, indent.length)
        Outcome.none
      end

      #: (Domain::EditorState) -> Outcome
      def backspace(state)
        @last_change.add_action("insert.backspace", "", true)
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
        Outcome.none
      end

      #: (Domain::EditorState) -> Outcome
      def delete(state)
        @last_change.add_action("insert.delete", "", false)
        cursor = state.cursor
        line = state.current_line
        if cursor.col < line.length
          to = Domain::Position.new(cursor.row, cursor.col + 1)
          state.buffer.delete(Domain::Range.charwise(cursor.position, to))
        elsif cursor.row < state.buffer.line_count - 1
          to = Domain::Position.new(cursor.row + 1, 0)
          state.buffer.delete(Domain::Range.charwise(cursor.position, to))
        end
        Outcome.none
      end

      #: (Domain::EditorState) -> Outcome
      def tab(state)
        options = state.options
        text = "\t"
        if options.expandtab
          width = options.tabstop > 0 ? options.tabstop : 8
          text = " " * (width - (state.cursor.col % width))
        end
        @last_change.add_action("insert.tab", text, false)
        put(state, text)
        Outcome.none
      end

      private

      #: (Domain::EditorState, String) -> void
      def put(state, text)
        cursor = state.cursor
        state.buffer.insert(cursor.position, text)
        cursor.move_to(cursor.row, cursor.col + text.length)
      end
    end
  end
end
