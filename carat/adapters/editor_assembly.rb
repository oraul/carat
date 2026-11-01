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
require_relative "../domain/keymap"
require_relative "../domain/options"
require_relative "../use_cases/outcome"
require_relative "../use_cases/concerns/reporting"
require_relative "../use_cases/move"
require_relative "../use_cases/operate"
require_relative "../use_cases/enter_insert"
require_relative "../use_cases/insert_text"
require_relative "../use_cases/leave_insert"
require_relative "../use_cases/files/open_file"
require_relative "../use_cases/files/save_file"
require_relative "../use_cases/files/quit"
require_relative "../use_cases/windows/split_window"
require_relative "../use_cases/windows/close_window"
require_relative "../use_cases/windows/focus_window"
require_relative "../use_cases/windows/resize_layout"
require_relative "../use_cases/windows/open_tab"
require_relative "../use_cases/windows/close_tab"
require_relative "../use_cases/windows/switch_tab"
require_relative "../use_cases/plugins/plugin_host"
require_relative "../use_cases/visual/start_visual"
require_relative "../use_cases/visual/extend_visual"
require_relative "../use_cases/visual/operate_on_selection"
require_relative "../use_cases/ex/ex_table"
require_relative "../use_cases/ex/command_runner"
require_relative "../use_cases/ex/execute_ex"
require_relative "../use_cases/ex/file_command_handler"
require_relative "../use_cases/ex/window_command_handler"
require_relative "../use_cases/ex/tab_command_handler"
require_relative "../use_cases/ex/plugin_command_handler"
require_relative "../use_cases/edit_command_line"
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
require_relative "../use_cases/actions/plugin_action_handler"
require_relative "../use_cases/dispatcher"
require_relative "../use_cases/handle_key"
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
    # declares is reported with the configuration's file name instead of
    # added.
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
      attr_reader :last_find #: Domain::LastFind
      attr_reader :input #: Domain::InputState
      attr_reader :plugin_ui #: Domain::PluginUi
      attr_reader :actions #: UseCases::ActionTable
      attr_reader :commands #: UseCases::ExTable
      attr_reader :runner #: UseCases::CommandRunner
      attr_reader :move #: UseCases::Move
      attr_reader :operate #: UseCases::Operate
      attr_reader :selection #: UseCases::OperateOnSelection
      attr_reader :open_file #: UseCases::OpenFile
      attr_reader :save_file #: UseCases::SaveFile
      attr_reader :quit #: UseCases::Quit
      attr_reader :close_window #: UseCases::CloseWindow
      attr_reader :split_window #: UseCases::SplitWindow
      attr_reader :open_tab #: UseCases::OpenTab
      attr_reader :close_tab #: UseCases::CloseTab
      attr_reader :switch_tab #: UseCases::SwitchTab
      attr_reader :plugins #: UseCases::PluginHost
      attr_reader :command_line #: UseCases::EditCommandLine
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
        @tabs = Domain::TabList.new(Domain::Window.new(first))
        @buffers = Domain::BufferList.new(@tabs)
        @buffers.add(first)
        @state = Domain::EditorState.new(@tabs, Domain::Options.from_config(value))
        @keymap = Domain::Keymap.new
        @registers = Domain::Registers.new
        @last_find = Domain::LastFind.new
        @input = Domain::InputState.new
        @plugin_ui = Domain::PluginUi.new
        @actions = UseCases::ActionTable.new
        @commands = UseCases::ExTable.new
        @runner = UseCases::ExecuteEx.new(commands: @commands)
        @config_errors = []

        @move = UseCases::Move.new(last_find: @last_find)
        @operate = UseCases::Operate.new(registers: @registers, last_find: @last_find)
        @selection = UseCases::OperateOnSelection.new(registers: @registers)
        enter_insert = UseCases::EnterInsert.new(move: @move)
        insert_text = UseCases::InsertText.new(enter_insert: enter_insert)
        leave_insert = UseCases::LeaveInsert.new
        @open_file = UseCases::OpenFile.new(files: files, buffers: @buffers)
        @close_window = UseCases::CloseWindow.new(buffers: @buffers, tabs: @tabs)
        @split_window = UseCases::SplitWindow.new(open_file: @open_file, buffers: @buffers, tabs: @tabs)
        @open_tab = UseCases::OpenTab.new(open_file: @open_file, buffers: @buffers, tabs: @tabs)
        @close_tab = UseCases::CloseTab.new(buffers: @buffers, tabs: @tabs)
        @switch_tab = UseCases::SwitchTab.new(tabs: @tabs)
        @quit = UseCases::Quit.new(close_window: @close_window, buffers: @buffers, tabs: @tabs)
        focus_window = UseCases::FocusWindow.new
        resize_layout = UseCases::ResizeLayout.new
        @plugins = UseCases::PluginHost.new(state: @state, buffers: @buffers, tabs: @tabs, input: @input, plugin_ui: @plugin_ui, files: files, open_file: @open_file, close_window: @close_window, split_window: @split_window, open_tab: @open_tab, keymap: @keymap, leader: leader, runner: @runner)
        i = 0
        while i < plugin_list.length
          @plugins.register(plugin_list[i])
          i += 1
        end
        @save_file = UseCases::SaveFile.new(files: files, plugins: @plugins, buffers: @buffers)

        UseCases::FileCommandHandler.register(@commands, save_file: @save_file, quit: @quit, open_file: @open_file)
        UseCases::WindowCommandHandler.register(@commands, split_window: @split_window, close_window: @close_window)
        UseCases::TabCommandHandler.register(@commands, open_tab: @open_tab, close_tab: @close_tab, switch_tab: @switch_tab)
        UseCases::PluginCommandHandler.register(@commands, plugins: @plugins)
        @plugins.activate_all(value["plugins"])

        @command_line = UseCases::EditCommandLine.new(runner: @runner, plugins: @plugins, plugin_ui: @plugin_ui)
        start_visual = UseCases::StartVisual.new
        extend_visual = UseCases::ExtendVisual.new
        UseCases::MotionHandler.register(@actions, move: @move)
        UseCases::OperatorHandler.register(@actions, operate: @operate, selection: @selection)
        UseCases::EditHandler.register(@actions, operate: @operate)
        UseCases::TextObjectHandler.register(@actions, extend_visual: extend_visual)
        UseCases::InsertModeHandler.register(@actions, enter_insert: enter_insert)
        UseCases::NormalModeHandler.register(@actions, leave_insert: leave_insert, command_line: @command_line, start_visual: start_visual)
        UseCases::VisualModeHandler.register(@actions, start_visual: start_visual)
        UseCases::SelectionHandler.register(@actions, selection: @selection, extend_visual: extend_visual)
        UseCases::CommandLineHandler.register(@actions, command_line: @command_line)
        UseCases::InsertTextHandler.register(@actions, insert_text: insert_text)
        UseCases::MessageHandler.register(@actions)
        UseCases::WindowHandler.register(@actions, split_window: @split_window, close_window: @close_window, focus_window: focus_window, resize_layout: resize_layout, quit: @quit, tabs: @tabs)
        UseCases::TabHandler.register(@actions, switch_tab: @switch_tab)
        UseCases::PluginActionHandler.register(@actions, plugins: @plugins)

        from = @keymap.errors.length
        @keymap.add_checked(value["keymaps"], leader, known_actions, config.source)
        problems = @keymap.errors
        i = from
        while i < problems.length
          @config_errors << problems[i]
          i += 1
        end

        dispatcher = UseCases::Dispatcher.new(actions: @actions)
        @handle_key = UseCases::HandleKey.new(keymap: @keymap, input: @input, actions: @actions, dispatcher: dispatcher, insert_text: insert_text, command_line: @command_line, plugins: @plugins)
        @controller = InputController.new(terminal: terminal, clock: clock, decoder: KeyDecoder.new, handle_key: @handle_key)
        @frame_presenter = FramePresenter.new(input: @input, plugin_ui: @plugin_ui)
        @screen_presenter = ScreenPresenter.new(terminal: terminal)
      end

      # Opens the file to edit, shows its message, lets the plugins see the
      # buffer open, and then shows the first configuration problem, if
      # there is one, with the count of the others.
      #: (String) -> void
      def open(path)
        report(@state, @open_file.call(@state, path))
        @plugins.observe
        return if @config_errors.empty?
        more = @config_errors.length - 1
        first = @config_errors[0]
        report(@state, UseCases::Outcome.failure(more > 0 ? "#{first} (and #{more} more)" : first))
      end

      # Renders the state at the given size and writes it to the terminal,
      # telling the plugins first when the size changed so what they do
      # about it is in this frame.
      #: (Integer, Integer) -> Domain::Frame
      def render(rows, cols)
        @plugins.resized(rows, cols)
        frame = @frame_presenter.call(@state, rows, cols)
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
