require_relative "../domain/editor_state"
require_relative "../domain/command"
require_relative "../domain/mode"
require_relative "../domain/position"
require_relative "../domain/display_width"
require_relative "../domain/last_change"
require_relative "outcome"
require_relative "insert_text"
require_relative "leave_insert"
require_relative "actions/action_table"

module Carat
  module UseCases
    # The dot command: runs the last change again at the cursor. A typed
    # count replaces the change's count, for this and later repeats, and a
    # numbered register "1 to "8 the change named becomes the next one. A
    # visual change is run on a selection of the same size from the
    # cursor: the same lines, and the same characters on one line, end
    # column on several, or display columns for a block. When the change
    # opened an insert session, its steps are typed again and the session
    # is left, a block insert repeated on its rows as the first time. The
    # whole repeat runs in the dispatcher's transaction for the key, one
    # undo state.
    class RepeatLast
      attr_reader :last_change #: Domain::LastChange
      attr_reader :insert_text #: InsertText
      attr_reader :leave_insert #: LeaveInsert

      # @rbs @actions: ActionTable

      #: (last_change: Domain::LastChange, actions: ActionTable, insert_text: InsertText, leave_insert: LeaveInsert) -> void
      def initialize(last_change:, actions:, insert_text:, leave_insert:)
        @last_change = last_change
        @actions = actions
        @insert_text = insert_text
        @leave_insert = leave_insert
      end

      #: (Domain::EditorState, Domain::Command) -> Outcome
      def call(state, command)
        last = @last_change
        recorded = last.command
        return Outcome.none if recorded.nil?
        count = command.count > 0 ? command.count : recorded.count
        replay = Domain::Command.new(next_register(recorded.register), count, recorded.operator, recorded.action, recorded.char, recorded.linewise, recorded.keys)
        last.command = replay
        handler = @actions.find(replay.operator? ? replay.operator : replay.action)
        return Outcome.none if handler.nil?
        select(state, last) unless last.visual == :none
        last.replaying = true
        outcome = handler.call(state, replay)
        if state.mode == Domain::Mode::INSERT
          type(state, last)
          @leave_insert.call(state)
        end
        last.replaying = false
        outcome
      end

      private

      # "1 to "8 step to the next numbered register, as Vim's redo does.
      #: (String) -> String
      def next_register(name)
        return name unless name.length == 1
        code = name.ord
        return name unless code >= 49 && code <= 56
        (code + 1).chr
      end

      # The steps of the recorded insert session, typed again.
      #: (Domain::EditorState, Domain::LastChange) -> void
      def type(state, last)
        i = 0
        while i < last.steps.length
          name = last.step_at(i)
          if name.empty?
            @insert_text.call(state, last.text_at(i))
          else
            handler = @actions.find(name)
            handler.call(state, Domain::Command.plain(name)) unless handler.nil?
          end
          i += 1
        end
      end

      # A selection of the recorded size from the cursor, in the recorded
      # visual mode.
      #: (Domain::EditorState, Domain::LastChange) -> void
      def select(state, last)
        buffer = state.buffer
        cursor = state.cursor
        row = cursor.row
        col = cursor.col
        last_row = buffer.line_count - 1
        end_row = row + last.rows
        end_row = last_row if end_row > last_row
        state.window.anchor = Domain::Position.new(row, col)
        kind = last.visual
        if kind == :linewise
          state.mode = Domain::Mode::VISUAL_LINE
          cursor.move_to(end_row, clamp(state, end_row, col))
        elsif kind == :blockwise
          state.mode = Domain::Mode::VISUAL_BLOCK
          tabstop = state.options.tabstop > 0 ? state.options.tabstop : 8
          vcol = Domain::DisplayWidth.column(buffer.line(row), col, tabstop) + last.cols
          cursor.move_to(end_row, clamp(state, end_row, Domain::DisplayWidth.col_at(buffer.line(end_row), vcol, tabstop)))
          cursor.want_col = -1 if last.to_end
        else
          state.mode = Domain::Mode::VISUAL
          end_col = last.rows == 0 ? col + last.cols : last.cols
          cursor.move_to(end_row, clamp(state, end_row, end_col))
        end
      end

      #: (Domain::EditorState, Integer, Integer) -> Integer
      def clamp(state, row, col)
        max = state.max_col(row)
        col > max ? max : col
      end
    end
  end
end
