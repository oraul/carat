require_relative "../domain/editor_state"
require_relative "../domain/command"
require_relative "../domain/command_grammar"
require_relative "move"
require_relative "operate"
require_relative "enter_insert"
require_relative "insert_text"
require_relative "leave_insert"
require_relative "edit_command_line"

module Carat
  module UseCases
    # Maps a command from the grammar to the use case that performs it: an
    # operator command goes to Operate, a motion to Move, and every other
    # action is a case over its name. The names are listed in
    # docs/actions.md. An action a later roadmap item owns shows a "Not
    # implemented" message.
    class Dispatcher
      QUIT_HINT = "Type  :q!  and press <Enter> to abandon all changes and exit Carat"

      # @rbs @move: Move
      # @rbs @operate: Operate
      # @rbs @enter_insert: EnterInsert
      # @rbs @insert_text: InsertText
      # @rbs @leave_insert: LeaveInsert
      # @rbs @command_line: EditCommandLine

      #: (Move, Operate, EnterInsert, InsertText, LeaveInsert, EditCommandLine) -> void
      def initialize(move, operate, enter_insert, insert_text, leave_insert, command_line)
        @move = move
        @operate = operate
        @enter_insert = enter_insert
        @insert_text = insert_text
        @leave_insert = leave_insert
        @command_line = command_line
      end

      #: (Domain::EditorState, Domain::Command) -> void
      def call(state, command)
        if command.operator?
          @operate.call(state, command)
          return
        end
        action = command.action
        if Domain::CommandGrammar.motion?(action)
          @move.call(state, command)
          return
        end
        case action
        when "operator.delete_char" then @operate.fixed(state, command, Operate::DELETE, "cursor.right", false)
        when "operator.substitute_char" then @operate.fixed(state, command, Operate::CHANGE, "cursor.right", false)
        when "operator.substitute_line" then @operate.fixed(state, command, Operate::CHANGE, "", true)
        when "operator.change_to_end" then @operate.fixed(state, command, Operate::CHANGE, "cursor.line_end", false)
        when "operator.delete_to_end" then @operate.fixed(state, command, Operate::DELETE, "cursor.line_end", false)
        when "operator.yank_to_end" then @operate.fixed(state, command, Operate::YANK, "cursor.line_end", false)
        when "operator.join" then @operate.join(state, command)
        when "operator.put_after" then @operate.put(state, command, true)
        when "operator.put_before" then @operate.put(state, command, false)
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
