require_relative "../carat/test_support"
require_relative "../carat/testing"
require_relative "../carat/plugins/hello/plugin"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module AdaptersAssemblyTest
  # The labels of the holders whose object is not the expected one, by
  # identity: equal values are not enough, since a keyword default would
  # build a second object that compares equal while sharing nothing.
  def self.strangers(expected, holders)
    out = []
    holders.each { |label, held| out << label unless held.equal?(expected) }
    out
  end

  def self.main
    t = Carat::Testing.new("adapters_assembly")

    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\ntwo\n")
    h = Carat::Doubles::EditorHarness.with_plugins(files, 24, 80, [Carat::Plugins::Hello::Plugin.new])
    h.open("a.txt")
    a = h.assembly
    host = a.plugins

    # The guard checks itself: a second object of the same kind is a
    # stranger, the same object is not.
    t.assert_equal([["second"], []], [strangers(a.buffers, [["second", Carat::Domain::BufferList.new(tabs: a.tabs)]]), strangers(a.buffers, [["same", a.buffers]])], "strangers tells a second object from the shared one")

    # Each shared object is one instance, held by every collaborator that
    # needs it.
    t.assert_equal([], strangers(a.buffers, [
      ["open_file", a.open_file.buffers], ["save_file", a.save_file.buffers], ["quit", a.quit.buffers],
      ["close_window", a.close_window.buffers], ["split_window", a.split_window.buffers], ["open_tab", a.open_tab.buffers],
      ["close_tab", a.close_tab.buffers], ["file_ops", host.file_ops.buffers], ["registry", host.registry.buffers],
      ["events", host.events.buffers], ["buffer_requests", host.buffer_requests.buffers], ["window_requests", host.window_requests.buffers]
    ]), "the buffer list")
    t.assert_equal([], strangers(a.tabs, [
      ["state", a.state.tabs], ["buffers", a.buffers.tabs], ["feed", a.buffers.feed.tabs], ["quit", a.quit.tabs],
      ["close_window", a.close_window.tabs], ["split_window", a.split_window.tabs], ["open_tab", a.open_tab.tabs],
      ["close_tab", a.close_tab.tabs], ["switch_tab", a.switch_tab.tabs], ["registry", host.registry.tabs],
      ["events", host.events.tabs], ["window_requests", host.window_requests.tabs]
    ]), "the tab list")
    t.assert_equal([], strangers(a.state, [
      ["host", host.state], ["registry", host.registry.state], ["events", host.events.state],
      ["buffer_requests", host.buffer_requests.state], ["window_requests", host.window_requests.state], ["ui_requests", host.ui_requests.state]
    ]), "the editor state")
    t.assert_equal([], strangers(a.registers, [["operate", a.operate.registers], ["selection", a.selection.registers], ["command_line", a.command_line.registers], ["leave_insert", a.repeat_last.leave_insert.registers]]), "the registers")
    t.assert_equal([], strangers(a.last_change, [
      ["dispatcher", a.dispatcher.last_change], ["repeat_last", a.repeat_last.last_change],
      ["insert_text", a.repeat_last.insert_text.last_change], ["leave_insert", a.repeat_last.leave_insert.last_change]
    ]), "the last change")
    t.assert_equal([], strangers(a.buffers.feed, [["dispatcher", a.dispatcher.feed]]), "the buffer feed")
    t.assert_equal([], strangers(a.last_find, [["move", a.move.last_find], ["operate", a.operate.last_find]]), "the last find")
    t.assert_equal([], strangers(a.keymap, [["handle_key", a.handle_key.keymap], ["registry", host.registry.keymap]]), "the keymap")
    t.assert_equal([], strangers(a.input, [["handle_key", a.handle_key.input], ["frame_presenter", a.frame_presenter.input], ["ui_requests", host.ui_requests.input]]), "the input state")
    t.assert_equal([], strangers(a.plugin_ui, [
      ["host", host.plugin_ui], ["registry", host.registry.plugin_ui], ["ui_requests", host.ui_requests.plugin_ui],
      ["command_line", a.command_line.plugin_ui], ["frame_presenter", a.frame_presenter.plugin_ui]
    ]), "the plugin UI state")
    t.assert_equal([], strangers(host, [
      ["save_file", a.save_file.plugins], ["command_line", a.command_line.plugins], ["handle_key", a.handle_key.plugins]
    ]), "the plugin host")
    action = a.actions.find("plugin.hello.greet")
    command = a.commands.find("Hello")
    t.assert_equal([true, true], [action.is_a?(Carat::UseCases::PluginActionHandler), command.is_a?(Carat::UseCases::PluginCommandHandler)], "the plugin handlers are registered")
    t.assert_equal([], strangers(a.runner, [["command_line", a.command_line.runner], ["ui_requests", host.ui_requests.runner]]), "the command runner")
    t.assert_true(a.runner.is_a?(Carat::UseCases::ExecuteEx), "the command runner is the ex runner")
    t.assert_equal([], strangers(a.open_file, [["split_window", a.split_window.open_file], ["open_tab", a.open_tab.open_file]]), "the open file use case")
    t.assert_equal([], strangers(a.close_window, [["quit", a.quit.close_window], ["registry", host.registry.close_window], ["window_requests", host.window_requests.close_window]]), "the close window use case")
    t.assert_equal([], strangers(a.split_window, [["window_requests", host.window_requests.split_window]]), "the split window use case")
    t.assert_equal([], strangers(a.open_tab, [["window_requests", host.window_requests.open_tab]]), "the open tab use case")
    t.assert_equal([], strangers(host.file_ops, [["file_requests", host.file_requests.file_ops], ["ui_requests", host.ui_requests.file_ops], ["window_requests", host.window_requests.file_ops]]), "the file operations")
    t.assert_equal([], strangers(a.handle_key, [["controller", a.controller.handle_key]]), "the key handler")
    t.assert_equal([], strangers(a.cache, [["arrange_view", a.arrange_view.cache], ["frame_presenter", a.frame_presenter.cache]]), "the line cache")
    t.assert_equal([], strangers(a.arrange_view, [["handle_key", a.handle_key.arrange_view]]), "the arrange view use case")
    t.assert_equal([], strangers(a.plugins.syntax, [["highlight_view", a.highlight_view.syntax]]), "the plugins as tokenizers")
    t.assert_equal([], strangers(a.plugins.registry, [["plugin_syntax", a.plugins.syntax.registry]]), "the plugin registry, in the tokenizer part")

    # Each port is one instance too.
    t.assert_equal([], strangers(h.terminal, [["assembly", a.terminal], ["controller", a.controller.terminal], ["screen_presenter", a.screen_presenter.terminal]]), "the terminal port")
    t.assert_equal([], strangers(h.clock, [["assembly", a.clock], ["controller", a.controller.clock], ["dispatcher", a.dispatcher.clock], ["undo", a.undo.clock]]), "the clock port")
    t.assert_equal([], strangers(h.files, [["assembly", a.files], ["open_file", a.open_file.files], ["save_file", a.save_file.files], ["file_ops", host.file_ops.files]]), "the file port")
    signals = Carat::Doubles::ManualSignals.new
    main_loop = Carat::Drivers::MainLoop.new(assembly: a, terminal: h.terminal, signals: signals)
    t.assert_equal([true, true, true], [main_loop.assembly.equal?(a), main_loop.terminal.equal?(h.terminal), main_loop.signals.equal?(signals)], "the main loop holds the assembly, the terminal, and the signal port it was given")

    # The configuration comes through the port: its lines name the files
    # of their problems, timeoutlen lands in the options, and what it
    # leaves out falls back to Vim's defaults in the domain.
    fixed = Carat::Doubles::FixedConfig.new(value: Carat::Doubles::FixedConfig.defaults)
    served = fixed.load
    t.assert_equal(["config/default.caratrc", "<Space>", "500", []], [served.line_at(0).source, Carat::Domain::Keymap.leader_from(served), served.last("option.timeoutlen").words[0], served.report], "the fixed config serves the shipped defaults")
    t.assert_equal([500, "<Space>"], [a.state.options.timeoutlen, Carat::Domain::Keymap.leader_from(a.config.load)], "the assembly reads timeoutlen and the leader from the port")
    gateway = Carat::Adapters::RcConfigGateway.new(files: files)
    t.assert_equal([true, 500], [gateway.files.equal?(files), Carat::Domain::Options.from_config(gateway.load).timeoutlen], "the gateway reads the shipped defaults through the file port it was given")
    through = Carat::Adapters::EditorAssembly.new(terminal: h.terminal, clock: h.clock, files: files, config: gateway, plugin_list: [])
    t.assert_equal([true, true], [through.config.equal?(gateway), through.files.equal?(gateway.files)], "the assembly and the gateway hold the one file port")
    bare = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Domain::Config.new, rows: 10, cols: 40, plugins: [])
    t.assert_equal([1000, "\\", false, 1000, 1000], [bare.state.options.timeoutlen, Carat::Domain::Keymap.leader_from(Carat::Domain::Config.new), bare.state.options.number, bare.state.options.undolevels, bare.assembly.buffers.feed.undolevels], "a configuration without lines falls back to Vim's defaults")
    odd = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with("keymap.normal zq foo.bar\n"), rows: 10, cols: 40, plugins: [])
    t.assert_equal([".caratrc:1: unknown action foo.bar"], odd.assembly.config_errors, "a configuration problem names its file and line")

    t.finish
  end
end

AdaptersAssemblyTest.main if __FILE__ == $0
