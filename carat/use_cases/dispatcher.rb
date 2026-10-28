require_relative "../domain/editor_state"
require_relative "move"
require_relative "enter_insert"
require_relative "insert_text"
require_relative "leave_insert"
require_relative "edit_command_line"

module Carat
  module UseCases
    # Maps an action name from the keymap to the use case that performs it.
    # The names are listed in docs/actions.md. An action a later roadmap
    # item owns shows a "Not implemented" message.
    class Dispatcher
      QUIT_HINT = "Type  :q!  and press <Enter> to abandon all changes and exit Carat"

      # @rbs @move: Move
      # @rbs @enter_insert: EnterInsert
      # @rbs @insert_text: InsertText
      # @rbs @leave_insert: LeaveInsert
      # @rbs @command_line: EditCommandLine

      #: (Move, EnterInsert, InsertText, LeaveInsert, EditCommandLine) -> void
      def initialize(move, enter_insert, insert_text, leave_insert, command_line)
        @move = move
        @enter_insert = enter_insert
        @insert_text = insert_text
        @leave_insert = leave_insert
        @command_line = command_line
      end

      #: (Domain::EditorState, String) -> void
      def call(state, action)
        case action
        when "cursor.left" then @move.call(state, :left)
        when "cursor.right" then @move.call(state, :right)
        when "cursor.up" then @move.call(state, :up)
        when "cursor.down" then @move.call(state, :down)
        when "cursor.line_start" then @move.call(state, :line_start)
        when "cursor.first_nonblank" then @move.call(state, :first_nonblank)
        when "cursor.line_end" then @move.call(state, :line_end)
        when "cursor.buffer_start" then @move.call(state, :buffer_start)
        when "cursor.buffer_end" then @move.call(state, :buffer_end)
        when "mode.insert" then @enter_insert.call(state, :before)
        when "mode.insert_after" then @enter_insert.call(state, :after)
        when "mode.insert_line_start" then @enter_insert.call(state, :line_start)
        when "mode.insert_line_end" then @enter_insert.call(state, :line_end)
        when "mode.insert_open_below" then @enter_insert.call(state, :open_below)
        when "mode.insert_open_above" then @enter_insert.call(state, :open_above)
        when "mode.normal" then normal(state)
        when "mode.cmdline" then @command_line.start(state)
        when "insert.newline" then @insert_text.newline(state)
        when "insert.backspace" then @insert_text.backspace(state)
        when "insert.delete" then @insert_text.delete(state)
        when "insert.tab" then @insert_text.tab(state)
        when "cmdline.execute" then @command_line.execute(state)
        when "cmdline.backspace" then @command_line.backspace(state)
        when "message.quit_hint" then state.show(QUIT_HINT, false)
        else state.show("Not implemented: #{action}", false)
        end
      end

      private

      #: (Domain::EditorState) -> void
      def normal(state)
        case state.mode
        when Domain::Mode::INSERT then @leave_insert.call(state)
        when Domain::Mode::CMDLINE then @command_line.cancel(state)
        else state.mode = Domain::Mode::NORMAL
        end
      end
    end
  end
end
