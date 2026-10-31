require_relative "../domain/editor_state"
require_relative "../domain/command"
require_relative "../domain/command_grammar"
require_relative "move"
require_relative "operate"
require_relative "enter_insert"
require_relative "insert_text"
require_relative "leave_insert"
require_relative "edit_command_line"
require_relative "files/quit"
require_relative "windows/split_window"
require_relative "windows/close_window"
require_relative "windows/focus_window"
require_relative "windows/resize_layout"
require_relative "windows/switch_tab"
require_relative "plugins/plugin_host"
require_relative "visual/start_visual"
require_relative "visual/extend_visual"
require_relative "visual/operate_on_selection"

module Carat
  module UseCases
    # Maps a command from the grammar to the use case that performs it: in
    # a visual mode a text object goes to ExtendVisual and an operator or
    # a visual.* action to OperateOnSelection; otherwise an operator
    # command goes to Operate, a motion to Move, and every other action is
    # a case over its name. The names are listed in
    # docs/actions.md. A plugin.<name>.<action> action goes to the plugin
    # host; an action a later roadmap item owns shows a "Not implemented"
    # message.
    class Dispatcher
      QUIT_HINT = "Type  :q!  and press <Enter> to abandon all changes and exit Carat"

      # @rbs @move: Move
      # @rbs @operate: Operate
      # @rbs @enter_insert: EnterInsert
      # @rbs @insert_text: InsertText
      # @rbs @leave_insert: LeaveInsert
      # @rbs @command_line: EditCommandLine
      # @rbs @quit: Quit
      # @rbs @split_window: SplitWindow
      # @rbs @close_window: CloseWindow
      # @rbs @focus_window: FocusWindow
      # @rbs @resize_layout: ResizeLayout
      # @rbs @switch_tab: SwitchTab
      # @rbs @plugins: PluginHost
      # @rbs @start_visual: StartVisual
      # @rbs @extend_visual: ExtendVisual
      # @rbs @operate_on_selection: OperateOnSelection

      #: (Move, Operate, EnterInsert, InsertText, LeaveInsert, EditCommandLine, Quit, SplitWindow, CloseWindow, FocusWindow, ResizeLayout, SwitchTab, PluginHost, StartVisual, ExtendVisual, OperateOnSelection) -> void
      def initialize(move, operate, enter_insert, insert_text, leave_insert, command_line, quit, split_window, close_window, focus_window, resize_layout, switch_tab, plugins, start_visual, extend_visual, operate_on_selection)
        @move = move
        @operate = operate
        @enter_insert = enter_insert
        @insert_text = insert_text
        @leave_insert = leave_insert
        @command_line = command_line
        @quit = quit
        @split_window = split_window
        @close_window = close_window
        @focus_window = focus_window
        @resize_layout = resize_layout
        @switch_tab = switch_tab
        @plugins = plugins
        @start_visual = start_visual
        @extend_visual = extend_visual
        @operate_on_selection = operate_on_selection
      end

      #: (Domain::EditorState, Domain::Command) -> void
      def call(state, command)
        return if Domain::Mode.visual?(state.mode) && visual(state, command)
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
        when "mode.visual" then @start_visual.toggle(state, Domain::Mode::VISUAL)
        when "mode.visual_line" then @start_visual.toggle(state, Domain::Mode::VISUAL_LINE)
        when "mode.visual_block" then @start_visual.toggle(state, Domain::Mode::VISUAL_BLOCK)
        when "visual.reselect" then @start_visual.reselect(state)
        when "mode.cmdline" then @command_line.start(state)
        when "insert.newline" then @insert_text.newline(state)
        when "insert.backspace" then @insert_text.backspace(state)
        when "insert.delete" then @insert_text.delete(state)
        when "insert.tab" then @insert_text.tab(state)
        when "cmdline.execute" then @command_line.execute(state)
        when "cmdline.backspace" then @command_line.backspace(state)
        when "message.quit_hint" then state.show(QUIT_HINT, false)
        when "window.split" then report(state, @split_window.call(state, false, command.count, "", false))
        when "window.vsplit" then report(state, @split_window.call(state, true, command.count, "", false))
        when "window.left" then @focus_window.direction(state, :left, command.count)
        when "window.down" then @focus_window.direction(state, :down, command.count)
        when "window.up" then @focus_window.direction(state, :up, command.count)
        when "window.right" then @focus_window.direction(state, :right, command.count)
        when "window.next" then @focus_window.cycle(state, true, command.count)
        when "window.previous" then @focus_window.cycle(state, false, command.count)
        when "window.last_accessed" then @focus_window.previous(state)
        when "window.close" then report(state, @close_window.close(state, command.count))
        when "window.only" then report(state, @close_window.only(state))
        when "window.equalize" then @resize_layout.equalize(state)
        when "window.quit" then quit_window(state, command.count)
        when "tab.next" then @switch_tab.next(state, command.count)
        when "tab.previous" then @switch_tab.previous(state, command.count)
        else
          if action.start_with?("plugin.")
            @plugins.action(state, action, command)
          else
            state.show("Not implemented: #{action}", false)
          end
        end
      end

      private

      # The actions that act on the selection in a visual mode; returns
      # false for any other action, which then runs as in normal mode
      # (motions move the cursor end of the selection).
      #: (Domain::EditorState, Domain::Command) -> bool
      def visual(state, command)
        action = command.action
        if Domain::CommandGrammar.text_object?(action)
          @extend_visual.text_object(state, command)
          return true
        end
        selection = @operate_on_selection
        case action
        when "operator.delete" then selection.delete(state, command)
        when "operator.yank" then selection.yank(state, command)
        when "operator.change" then selection.change(state, command)
        when "operator.indent" then selection.shift(state, command, 1)
        when "operator.dedent" then selection.shift(state, command, -1)
        when "visual.join" then selection.join(state, command, true)
        when "visual.join_raw" then selection.join(state, command, false)
        when "visual.put" then selection.put(state, command, false)
        when "visual.put_keep" then selection.put(state, command, true)
        when "visual.replace" then selection.recase(state, command, :replace)
        when "visual.toggle_case" then selection.recase(state, command, :toggle)
        when "visual.lowercase" then selection.recase(state, command, :lower)
        when "visual.uppercase" then selection.recase(state, command, :upper)
        when "visual.delete_lines" then selection.delete_lines(state, command, false)
        when "visual.delete_to_end" then selection.delete_lines(state, command, true)
        when "visual.change_lines" then selection.change_lines(state, command, false)
        when "visual.change_to_end" then selection.change_lines(state, command, true)
        when "visual.yank_lines" then selection.yank_lines(state, command)
        when "visual.insert" then selection.insert(state, command, false)
        when "visual.append" then selection.insert(state, command, true)
        when "visual.swap_ends" then @extend_visual.swap_ends(state)
        when "visual.swap_corner" then @extend_visual.swap_corner(state)
        else return false
        end
        true
      end

      #: (Domain::EditorState) -> void
      def normal(state)
        case state.mode
        when Domain::Mode::INSERT then @leave_insert.call(state)
        when Domain::Mode::CMDLINE then @command_line.cancel(state)
        when Domain::Mode::VISUAL, Domain::Mode::VISUAL_LINE, Domain::Mode::VISUAL_BLOCK then @start_visual.leave(state)
        else state.mode = Domain::Mode::NORMAL
        end
      end

      # Shows an outcome's message as the command line would.
      #: (Domain::EditorState, Outcome) -> void
      def report(state, outcome)
        state.show(outcome.message, !outcome.ok) unless outcome.message.empty?
      end

      # Ctrl-W q: :q on the current window, or with a count on window n,
      # which closes it without moving the cursor as :{n}quit does.
      #: (Domain::EditorState, Integer) -> void
      def quit_window(state, n)
        if n > 0 && state.total_windows > 1
          report(state, @close_window.close(state, n))
        else
          report(state, @quit.call(state, false))
        end
      end
    end
  end
end
