require_relative "../ports/terminal_port"
require_relative "../ports/clock_port"
require_relative "../ports/file_port"
require_relative "../ports/config_port"
require_relative "../domain/editor_state"
require_relative "../domain/buffer_list"
require_relative "../domain/tab_list"
require_relative "../domain/input_state"
require_relative "../domain/last_find"
require_relative "../domain/plugin_ui"
require_relative "../domain/registers"
require_relative "../domain/last_change"
require_relative "../domain/keymap"
require_relative "../domain/options"
require_relative "../domain/line_cache"
require_relative "../domain/themes"
require_relative "../use_cases/outcome"
require_relative "../use_cases/concerns/reporting"
require_relative "../use_cases/move"
require_relative "../use_cases/operate"
require_relative "../use_cases/replace_chars"
require_relative "../use_cases/toggle_case"
require_relative "../use_cases/put_register"
require_relative "../use_cases/join_lines"
require_relative "../use_cases/insert_text"
require_relative "../use_cases/break_line"
require_relative "../use_cases/erase_character"
require_relative "../use_cases/insert_tab"
require_relative "../use_cases/leave_insert"
require_relative "../use_cases/history/walk_history"
require_relative "../use_cases/history/undo_step"
require_relative "../use_cases/history/redo_step"
require_relative "../use_cases/history/undo_to_state"
require_relative "../use_cases/history/travel_history"
require_relative "../use_cases/history/restore_line"
require_relative "../use_cases/history/list_undo"
require_relative "../use_cases/repeat_last"
require_relative "../use_cases/files/open_file"
require_relative "../use_cases/files/save_file"
require_relative "../use_cases/files/save_all"
require_relative "../use_cases/files/quit"
require_relative "../use_cases/files/quit_all"
require_relative "../use_cases/windows/split_window"
require_relative "../use_cases/windows/open_side_window"
require_relative "../use_cases/windows/close_window"
require_relative "../use_cases/windows/close_other_windows"
require_relative "../use_cases/windows/focus_window"
require_relative "../use_cases/windows/open_tab"
require_relative "../use_cases/windows/close_tab"
require_relative "../use_cases/windows/close_other_tabs"
require_relative "../use_cases/windows/switch_tab"
require_relative "../use_cases/plugins/plugin_host"
require_relative "../use_cases/visual/start_visual"
require_relative "../use_cases/visual/reselect_visual"
require_relative "../use_cases/visual/extend_visual"
require_relative "../use_cases/visual/swap_visual_ends"
require_relative "../use_cases/visual/delete_selection"
require_relative "../use_cases/visual/yank_selection"
require_relative "../use_cases/visual/change_selection"
require_relative "../use_cases/visual/shift_selection"
require_relative "../use_cases/visual/join_selection"
require_relative "../use_cases/visual/recase_selection"
require_relative "../use_cases/visual/insert_at_selection"
require_relative "../use_cases/visual/put_over_selection"
require_relative "../use_cases/enter_command_line"
require_relative "../use_cases/edit_command_line"
require_relative "../use_cases/erase_command_line"
require_relative "../use_cases/cancel_command_line"
require_relative "../use_cases/execute_command_line"
require_relative "../use_cases/ex/ex_table"
require_relative "../use_cases/ex/command_runner"
require_relative "../use_cases/ex/execute_ex"
require_relative "../use_cases/ex/file_command_handler"
require_relative "../use_cases/ex/window_command_handler"
require_relative "../use_cases/ex/tab_command_handler"
require_relative "../use_cases/ex/history_command_handler"
require_relative "../use_cases/ex/register_command_handler"
require_relative "../use_cases/ex/syntax_command_handler"
require_relative "../use_cases/ex/set_command_handler"
require_relative "../use_cases/ex/plugin_command_handler"
require_relative "../use_cases/actions/action_table"
require_relative "../use_cases/actions/motion_handler"
require_relative "../use_cases/actions/operator_handler"
require_relative "../use_cases/actions/edit_handler"
require_relative "../use_cases/actions/text_object_handler"
require_relative "../use_cases/actions/insert_mode_handler"
require_relative "../use_cases/actions/insert_text_handler"
require_relative "../use_cases/actions/normal_mode_handler"
require_relative "../use_cases/actions/visual_mode_handler"
require_relative "../use_cases/actions/selection_handler"
require_relative "../use_cases/actions/command_line_handler"
require_relative "../use_cases/actions/window_handler"
require_relative "../use_cases/actions/tab_handler"
require_relative "../use_cases/actions/message_handler"
require_relative "../use_cases/actions/history_handler"
require_relative "../use_cases/actions/scroll_handler"
require_relative "../use_cases/actions/plugin_action_handler"
require_relative "../use_cases/dispatcher"
require_relative "../use_cases/handle_key"
require_relative "../use_cases/arrange_view"
require_relative "../use_cases/syntax/highlight_view"
require_relative "key_decoder"
require_relative "input_controller"
require_relative "frame_presenter"
require_relative "screen_presenter"

module Carat
  module Adapters
    # Wires the entities, use cases, and adapters of one editor over the
    # given ports and the list of compiled plugins: the composition root
    # that bin/carat.rb and the editor harness share, so both run the same
    # graph. Every shared collaborator, the records of the state included,
    # is built once here and handed on by keyword, and kept with a reader
    # so a test can check that each is one object. The configuration is
    # read once through its port; a value it leaves out falls back to
    # Vim's default in the domain, never here. The ex table and its runner
    # are built before the plugin host, which receives the runner; the
    # handlers are registered afterwards, the core ex commands before the
    # plugin commands, which is their order of precedence. The plugins are
    # registered first, activated once every ex command is registered (so
    # a plugin may run ex commands in activate), and before the
    # configuration's bindings go into the keymap, so the configuration
    # always wins; a binding of an action neither the table nor a plugin
    # declares is reported with its file and line instead of added. Every
    # problem the options, the plugin host, and the keymap note on the
    # configuration is kept in file order in config_errors.
    class EditorAssembly
      include UseCases::Reporting

      attr_reader :terminal #: Ports::TerminalPort
      attr_reader :clock #: Ports::ClockPort
      attr_reader :files #: Ports::FilePort
      attr_reader :config #: Ports::ConfigPort
      attr_reader :tabs #: Domain::TabList
      attr_reader :buffers #: Domain::BufferList
      attr_reader :state #: Domain::EditorState
      attr_reader :keymap #: Domain::Keymap
      attr_reader :registers #: Domain::Registers
      attr_reader :last_change #: Domain::LastChange
      attr_reader :last_find #: Domain::LastFind
      attr_reader :input #: Domain::InputState
      attr_reader :plugin_ui #: Domain::PluginUi
      attr_reader :cache #: Domain::LineCache
      attr_reader :arrange_view #: UseCases::ArrangeView
      attr_reader :highlight_view #: UseCases::HighlightView
      attr_reader :actions #: UseCases::ActionTable
      attr_reader :commands #: UseCases::ExTable
      attr_reader :runner #: UseCases::CommandRunner
      attr_reader :move #: UseCases::Move
      attr_reader :operate #: UseCases::Operate
      attr_reader :put_register #: UseCases::PutRegister
      attr_reader :insert_text #: UseCases::InsertText
      attr_reader :break_line #: UseCases::BreakLine
      attr_reader :erase_character #: UseCases::EraseCharacter
      attr_reader :insert_tab #: UseCases::InsertTab
      attr_reader :leave_insert #: UseCases::LeaveInsert
      attr_reader :walk_history #: UseCases::WalkHistory
      attr_reader :undo_step #: UseCases::UndoStep
      attr_reader :redo_step #: UseCases::RedoStep
      attr_reader :undo_to_state #: UseCases::UndoToState
      attr_reader :travel_history #: UseCases::TravelHistory
      attr_reader :list_undo #: UseCases::ListUndo
      attr_reader :repeat_last #: UseCases::RepeatLast
      attr_reader :delete_selection #: UseCases::DeleteSelection
      attr_reader :yank_selection #: UseCases::YankSelection
      attr_reader :change_selection #: UseCases::ChangeSelection
      attr_reader :put_over_selection #: UseCases::PutOverSelection
      attr_reader :probe_path #: UseCases::ProbePath
      attr_reader :open_file #: UseCases::OpenFile
      attr_reader :save_file #: UseCases::SaveFile
      attr_reader :save_all #: UseCases::SaveAll
      attr_reader :quit #: UseCases::Quit
      attr_reader :quit_all #: UseCases::QuitAll
      attr_reader :close_window #: UseCases::CloseWindow
      attr_reader :close_other_windows #: UseCases::CloseOtherWindows
      attr_reader :split_window #: UseCases::SplitWindow
      attr_reader :open_side_window #: UseCases::OpenSideWindow
      attr_reader :open_tab #: UseCases::OpenTab
      attr_reader :close_tab #: UseCases::CloseTab
      attr_reader :close_other_tabs #: UseCases::CloseOtherTabs
      attr_reader :switch_tab #: UseCases::SwitchTab
      attr_reader :plugins #: UseCases::PluginHost
      attr_reader :enter_command_line #: UseCases::EnterCommandLine
      attr_reader :edit_command_line #: UseCases::EditCommandLine
      attr_reader :cancel_command_line #: UseCases::CancelCommandLine
      attr_reader :execute_command_line #: UseCases::ExecuteCommandLine
      attr_reader :dispatcher #: UseCases::Dispatcher
      attr_reader :handle_key #: UseCases::HandleKey
      attr_reader :controller #: InputController
      attr_reader :frame_presenter #: FramePresenter
      attr_reader :screen_presenter #: ScreenPresenter
      attr_reader :config_errors #: Array[String]

      #: (terminal: Ports::TerminalPort, clock: Ports::ClockPort, files: Ports::FilePort, config: Ports::ConfigPort, plugin_list: Array[untyped]) -> void
      def initialize(terminal:, clock:, files:, config:, plugin_list:)
        @terminal = terminal
        @clock = clock
        @files = files
        @config = config
        value = config.load
        leader = Domain::Keymap.leader_from(value)
        first = Domain::Buffer.from_text("", nil)
        @tabs = Domain::TabList.new(window: Domain::Window.new(buffer: first))
        @buffers = Domain::BufferList.new(tabs: @tabs)
        @buffers.add(first)
        @state = Domain::EditorState.new(tabs: @tabs, options: Domain::Options.from_config(value))
        @keymap = Domain::Keymap.new
        @registers = Domain::Registers.new
        @last_change = Domain::LastChange.new
        @buffers.feed.undolevels = @state.options.undolevels
        @last_find = Domain::LastFind.new
        @input = Domain::InputState.new
        @plugin_ui = Domain::PluginUi.new
        @cache = Domain::LineCache.new
        @arrange_view = UseCases::ArrangeView.new(cache: @cache)
        @actions = UseCases::ActionTable.new
        @commands = UseCases::ExTable.new
        @runner = UseCases::ExecuteEx.new(commands: @commands)
        @config_errors = []

        @move = UseCases::Move.new(last_find: @last_find)
        @operate = UseCases::Operate.new(registers: @registers, last_find: @last_find)
        @put_register = UseCases::PutRegister.new(registers: @registers)
        @insert_text = UseCases::InsertText.new(last_change: @last_change)
        @break_line = UseCases::BreakLine.new(last_change: @last_change)
        @erase_character = UseCases::EraseCharacter.new(last_change: @last_change)
        @insert_tab = UseCases::InsertTab.new(last_change: @last_change)
        @leave_insert = UseCases::LeaveInsert.new(last_change: @last_change, registers: @registers)
        @walk_history = UseCases::WalkHistory.new(clock: clock)
        @undo_step = UseCases::UndoStep.new(walk_history: @walk_history)
        @redo_step = UseCases::RedoStep.new(walk_history: @walk_history)
        @undo_to_state = UseCases::UndoToState.new(walk_history: @walk_history)
        @travel_history = UseCases::TravelHistory.new(walk_history: @walk_history)
        @list_undo = UseCases::ListUndo.new(clock: clock)
        @repeat_last = UseCases::RepeatLast.new(last_change: @last_change, actions: @actions, insert_text: @insert_text, leave_insert: @leave_insert)
        @delete_selection = UseCases::DeleteSelection.new(registers: @registers)
        @yank_selection = UseCases::YankSelection.new(registers: @registers)
        @change_selection = UseCases::ChangeSelection.new(registers: @registers)
        @put_over_selection = UseCases::PutOverSelection.new(registers: @registers)
        @probe_path = UseCases::ProbePath.new(files: files)
        @open_file = UseCases::OpenFile.new(files: files, buffers: @buffers, probe_path: @probe_path)
        @close_window = UseCases::CloseWindow.new(buffers: @buffers, tabs: @tabs)
        @close_other_windows = UseCases::CloseOtherWindows.new(buffers: @buffers)
        @split_window = UseCases::SplitWindow.new(open_file: @open_file, buffers: @buffers, tabs: @tabs)
        @open_side_window = UseCases::OpenSideWindow.new(buffers: @buffers, tabs: @tabs)
        @open_tab = UseCases::OpenTab.new(open_file: @open_file, buffers: @buffers, tabs: @tabs)
        @close_tab = UseCases::CloseTab.new(buffers: @buffers, tabs: @tabs)
        @close_other_tabs = UseCases::CloseOtherTabs.new(buffers: @buffers, tabs: @tabs)
        @switch_tab = UseCases::SwitchTab.new(tabs: @tabs)
        @quit = UseCases::Quit.new(buffers: @buffers, tabs: @tabs)
        @quit_all = UseCases::QuitAll.new(buffers: @buffers)
        focus_window = UseCases::FocusWindow.new
        scroll_window = UseCases::ScrollWindow.new
        @plugins = UseCases::PluginHost.new(state: @state, buffers: @buffers, tabs: @tabs, input: @input, plugin_ui: @plugin_ui, files: files, open_file: @open_file, probe_path: @probe_path, split_window: @split_window, open_side_window: @open_side_window, open_tab: @open_tab, keymap: @keymap, leader: leader, runner: @runner)
        i = 0
        while i < plugin_list.length
          @plugins.register(plugin_list[i])
          i += 1
        end
        @save_file = UseCases::SaveFile.new(files: files, plugins: @plugins)
        @save_all = UseCases::SaveAll.new(save_file: @save_file, buffers: @buffers)
        @highlight_view = UseCases::HighlightView.new(syntax: @plugins.syntax)

        UseCases::FileCommandHandler.register(@commands, save_file: @save_file, save_all: @save_all, quit: @quit, quit_all: @quit_all, open_file: @open_file)
        UseCases::WindowCommandHandler.register(@commands, split_window: @split_window, close_window: @close_window, close_other_windows: @close_other_windows)
        UseCases::TabCommandHandler.register(@commands, open_tab: @open_tab, close_tab: @close_tab, close_other_tabs: @close_other_tabs, switch_tab: @switch_tab)
        UseCases::HistoryCommandHandler.register(@commands, undo_step: @undo_step, redo_step: @redo_step, undo_to_state: @undo_to_state, travel_history: @travel_history, list_undo: @list_undo)
        UseCases::RegisterCommandHandler.register(@commands, registers: @registers)
        UseCases::SyntaxCommandHandler.register(@commands)
        UseCases::SetCommandHandler.register(@commands)
        UseCases::PluginCommandHandler.register(@commands, plugins: @plugins)
        @plugins.activate_all(value)

        @enter_command_line = UseCases::EnterCommandLine.new(plugin_ui: @plugin_ui)
        @edit_command_line = UseCases::EditCommandLine.new
        @cancel_command_line = UseCases::CancelCommandLine.new(plugins: @plugins, plugin_ui: @plugin_ui)
        @execute_command_line = UseCases::ExecuteCommandLine.new(runner: @runner, plugins: @plugins, plugin_ui: @plugin_ui, registers: @registers)
        erase_command_line = UseCases::EraseCommandLine.new(cancel_command_line: @cancel_command_line)
        start_visual = UseCases::StartVisual.new
        reselect_visual = UseCases::ReselectVisual.new
        extend_visual = UseCases::ExtendVisual.new
        swap_visual_ends = UseCases::SwapVisualEnds.new
        shift_selection = UseCases::ShiftSelection.new
        UseCases::MotionHandler.register(@actions, move: @move)
        UseCases::OperatorHandler.register(@actions, operate: @operate, delete_selection: @delete_selection, yank_selection: @yank_selection, change_selection: @change_selection, shift_selection: shift_selection)
        UseCases::EditHandler.register(@actions, operate: @operate, replace_chars: UseCases::ReplaceChars.new, toggle_case: UseCases::ToggleCase.new, put_register: @put_register, join_lines: UseCases::JoinLines.new)
        UseCases::TextObjectHandler.register(@actions, extend_visual: extend_visual)
        UseCases::InsertModeHandler.register(@actions)
        UseCases::NormalModeHandler.register(@actions, leave_insert: @leave_insert, cancel_command_line: @cancel_command_line)
        UseCases::VisualModeHandler.register(@actions, start_visual: start_visual, reselect_visual: reselect_visual)
        UseCases::SelectionHandler.register(@actions, delete_selection: @delete_selection, yank_selection: @yank_selection, change_selection: @change_selection, join_selection: UseCases::JoinSelection.new, recase_selection: UseCases::RecaseSelection.new, insert_at_selection: UseCases::InsertAtSelection.new, put_over_selection: @put_over_selection, swap_visual_ends: swap_visual_ends)
        UseCases::CommandLineHandler.register(@actions, enter_command_line: @enter_command_line, execute_command_line: @execute_command_line, erase_command_line: erase_command_line)
        UseCases::InsertTextHandler.register(@actions, break_line: @break_line, erase_character: @erase_character, insert_tab: @insert_tab)
        UseCases::MessageHandler.register(@actions)
        UseCases::HistoryHandler.register(@actions, undo_step: @undo_step, redo_step: @redo_step, restore_line: UseCases::RestoreLine.new, travel_history: @travel_history, repeat_last: @repeat_last)
        UseCases::WindowHandler.register(@actions, split_window: @split_window, close_window: @close_window, close_other_windows: @close_other_windows, focus_window: focus_window, quit: @quit, tabs: @tabs)
        UseCases::TabHandler.register(@actions, switch_tab: @switch_tab)
        UseCases::ScrollHandler.register(@actions, scroll_window: scroll_window)
        UseCases::PluginActionHandler.register(@actions, plugins: @plugins)

        @keymap.add_checked(value, known_actions)
        problems = value.report
        i = 0
        while i < problems.length
          @config_errors << problems[i]
          i += 1
        end

        @dispatcher = UseCases::Dispatcher.new(actions: @actions, last_change: @last_change, clock: clock, feed: @buffers.feed)
        @handle_key = UseCases::HandleKey.new(keymap: @keymap, input: @input, actions: @actions, dispatcher: @dispatcher, insert_text: @insert_text, command_line: @edit_command_line, plugins: @plugins, arrange_view: @arrange_view)
        @controller = InputController.new(terminal: terminal, clock: clock, decoder: KeyDecoder.new, handle_key: @handle_key, input: @input)
        @frame_presenter = FramePresenter.new(input: @input, plugin_ui: @plugin_ui, cache: @cache)
        @screen_presenter = ScreenPresenter.new(terminal: terminal, theme: Domain::Themes.find(@state.options.theme), colors: terminal.colors)
      end

      # Opens the file to edit, shows its message, lets the plugins see the
      # buffer open, lays out the windows, and then shows the first
      # configuration problem, if there is one, with the count of the
      # others.
      #: (String) -> void
      def open(path)
        report(@state, @open_file.call(@state, path))
        @plugins.observe
        @arrange_view.call(@state)
        return if @config_errors.empty?
        more = @config_errors.length - 1
        first = @config_errors[0]
        report(@state, UseCases::Outcome.failure(more > 0 ? "#{first} (and #{more} more)" : first))
      end

      # Renders the state at the given size and writes it to the terminal:
      # the size goes into the state, the plugins hear of a change first so
      # what they do about it is in this frame, ArrangeView lays the
      # windows out (so a state changed outside a key is arranged too),
      # HighlightView brings the syntax of the visible rows up to date, and
      # the frame presenter draws what the state holds.
      #: (Integer, Integer) -> Domain::Frame
      def render(rows, cols)
        @state.resize(rows, cols)
        @plugins.resized(rows, cols)
        @arrange_view.call(@state)
        @highlight_view.call(@state)
        frame = @frame_presenter.call(@state)
        @screen_presenter.present(frame)
        frame
      end

      private

      # The action names a binding may use: every name the action table
      # registered and every action a registered plugin declares.
      #: () -> Hash[String, bool]
      def known_actions
        known = {}
        names = @actions.names
        i = 0
        while i < names.length
          known[names[i]] = true
          i += 1
        end
        names = @plugins.action_names
        i = 0
        while i < names.length
          known[names[i]] = true
          i += 1
        end
        known
      end
    end
  end
end
