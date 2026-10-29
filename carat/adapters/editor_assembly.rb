require_relative "../ports/terminal_port"
require_relative "../ports/clock_port"
require_relative "../ports/file_port"
require_relative "../domain/editor_state"
require_relative "../domain/keymap"
require_relative "../domain/options"
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
require_relative "../use_cases/files/execute_ex"
require_relative "../use_cases/edit_command_line"
require_relative "../use_cases/dispatcher"
require_relative "../use_cases/handle_key"
require_relative "key_decoder"
require_relative "input_controller"
require_relative "frame_presenter"
require_relative "screen_presenter"

module Carat
  module Adapters
    # Wires the entities, use cases, and adapters of one editor over the
    # given ports. bin/carat.rb builds it over the drivers; the editor
    # harness builds it over the doubles, so both run the same graph.
    class EditorAssembly
      attr_reader :state #: Domain::EditorState
      attr_reader :keymap #: Domain::Keymap
      attr_reader :controller #: InputController
      attr_reader :frame_presenter #: FramePresenter
      attr_reader :screen_presenter #: ScreenPresenter
      attr_reader :open_file #: UseCases::OpenFile

      #: (Ports::TerminalPort, Ports::ClockPort, Ports::FilePort, untyped) -> void
      def initialize(terminal, clock, files, config)
        leader = config["leader"].is_a?(String) ? config["leader"] : "\\"
        timeoutlen = config["timeoutlen"].is_a?(Integer) ? config["timeoutlen"] : 1000
        options = Domain::Options.from_config(config["options"])
        @keymap = Domain::Keymap.build(config["keymaps"], leader)
        @state = Domain::EditorState.new(Domain::Buffer.from_text("", nil), options, timeoutlen)

        move = UseCases::Move.new
        operate = UseCases::Operate.new
        enter_insert = UseCases::EnterInsert.new(move)
        insert_text = UseCases::InsertText.new(enter_insert)
        leave_insert = UseCases::LeaveInsert.new
        @open_file = UseCases::OpenFile.new(files)
        save_file = UseCases::SaveFile.new(files)
        close_window = UseCases::CloseWindow.new
        quit = UseCases::Quit.new(close_window)
        split_window = UseCases::SplitWindow.new(@open_file)
        focus_window = UseCases::FocusWindow.new
        resize_layout = UseCases::ResizeLayout.new
        open_tab = UseCases::OpenTab.new(@open_file)
        close_tab = UseCases::CloseTab.new
        switch_tab = UseCases::SwitchTab.new
        execute_ex = UseCases::ExecuteEx.new(@open_file, save_file, quit, split_window, close_window, open_tab, close_tab, switch_tab)
        command_line = UseCases::EditCommandLine.new(execute_ex)
        dispatcher = UseCases::Dispatcher.new(move, operate, enter_insert, insert_text, leave_insert, command_line, quit, split_window, close_window, focus_window, resize_layout, switch_tab)
        handle_key = UseCases::HandleKey.new(@keymap, dispatcher, insert_text, command_line)

        @controller = InputController.new(terminal, clock, KeyDecoder.new, handle_key)
        @frame_presenter = FramePresenter.new
        @screen_presenter = ScreenPresenter.new(terminal)
      end

      # Opens the file to edit and shows its message.
      #: (String) -> void
      def open(path)
        outcome = @open_file.call(@state, path)
        @state.show(outcome.message, !outcome.ok)
      end

      # Renders the state at the given size and writes it to the terminal.
      #: (Integer, Integer) -> Domain::Frame
      def render(rows, cols)
        frame = @frame_presenter.call(@state, rows, cols)
        @screen_presenter.present(frame)
        frame
      end
    end
  end
end
