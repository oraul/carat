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
      ["open_file", a.open_file.buffers], ["save_all", a.save_all.buffers], ["quit", a.quit.buffers], ["quit_all", a.quit_all.buffers],
      ["close_window", a.close_window.buffers], ["close_other_windows", a.close_other_windows.buffers], ["split_window", a.split_window.buffers],
      ["open_side_window", a.open_side_window.buffers], ["open_tab", a.open_tab.buffers], ["close_tab", a.close_tab.buffers],
      ["close_other_tabs", a.close_other_tabs.buffers], ["rename_path", host.rename_path.buffers], ["delete_path", host.delete_path.buffers],
      ["registry", host.registry.buffers], ["events", host.events.buffers], ["buffer_requests", host.buffer_requests.buffers],
      ["window_requests", host.window_requests.buffers], ["list_buffers", a.list_buffers.buffers], ["switch_buffer", a.switch_buffer.buffers],
      ["delete_buffer", a.delete_buffer.buffers], ["arrange_view", a.arrange_view.buffers], ["tab_bar", a.frame_presenter.tab_bar.buffers], ["pin_hover", a.pin_hover.buffers]
    ]), "the buffer list")
    t.assert_equal([], strangers(a.completion_menu, [
      ["handle_key", a.handle_key.completion], ["show_completion", a.show_completion.menu], ["close_completion", a.show_completion.close_completion.menu], ["show_docs", a.show_completion.show_docs.menu]
    ]), "the completion menu")
    t.assert_equal([true, true], [a.handle_key.show_completion.equal?(a.show_completion), a.show_completion.source.equal?(h.completions)], "the key handler holds the one ShowCompletion, over the source the harness gave")
    t.assert_equal([true, true, true], [a.show_completion.show_docs.source.equal?(h.completions), a.show_completion.show_docs.open_float.equal?(a.show_completion.open_float), a.show_completion.show_docs.close_float.equal?(a.show_completion.close_float)], "the documentation float shares the popup's source and float use cases")
    t.assert_equal([true, true], [a.controller.show_completion.equal?(a.show_completion), a.services.completion.equal?(h.completions.request)], "the input controller holds the one ShowCompletion and the gateway the source's request")
    t.assert_equal([], strangers(a.hover, [
      ["services", a.services.hover], ["request_hover", a.request_hover.hover], ["show_hover", a.show_hover.hover],
      ["follow_hover", a.follow_hover.hover], ["pin_hover", a.pin_hover.hover]
    ]), "the hover request")
    t.assert_equal([], strangers(a.signature, [
      ["services", a.services.signature], ["request_signature", a.request_signature.signature], ["show_signature", a.show_signature.signature],
      ["follow_signature", a.follow_signature.signature], ["handle_key", a.handle_key.signature], ["controller", a.controller.signature]
    ]), "the signature request")
    t.assert_equal([true, true, true], [a.controller.show_signature.equal?(a.show_signature), a.handle_key.request_signature.equal?(a.request_signature), a.handle_key.follow_signature.equal?(a.follow_signature)], "the input controller holds the one ShowSignature and the key handler the one RequestSignature and FollowSignature")
    t.assert_equal([true, true], [a.controller.show_hover.equal?(a.show_hover), a.handle_key.follow_hover.equal?(a.follow_hover)], "the input controller holds the one ShowHover and the key handler the one FollowHover")
    t.assert_equal([], strangers(a.tabs, [
      ["state", a.state.tabs], ["buffers", a.buffers.tabs], ["feed", a.buffers.feed.tabs], ["quit", a.quit.tabs],
      ["close_window", a.close_window.tabs], ["split_window", a.split_window.tabs], ["open_side_window", a.open_side_window.tabs],
      ["open_tab", a.open_tab.tabs], ["close_tab", a.close_tab.tabs], ["close_other_tabs", a.close_other_tabs.tabs],
      ["switch_tab", a.switch_tab.tabs], ["registry", host.registry.tabs], ["events", host.events.tabs], ["window_requests", host.window_requests.tabs]
    ]), "the tab list")
    t.assert_equal([], strangers(a.state, [
      ["host", host.state], ["registry", host.registry.state], ["events", host.events.state],
      ["buffer_requests", host.buffer_requests.state], ["window_requests", host.window_requests.state], ["ui_requests", host.ui_requests.state]
    ]), "the editor state")
    t.assert_equal([], strangers(a.registers, [
      ["operate", a.operate.registers], ["put_register", a.put_register.registers], ["delete_selection", a.delete_selection.registers],
      ["yank_selection", a.yank_selection.registers], ["change_selection", a.change_selection.registers], ["put_over_selection", a.put_over_selection.registers],
      ["execute_command_line", a.execute_command_line.registers], ["leave_insert", a.repeat_last.leave_insert.registers], ["substitute_lines", a.substitute_lines.registers],
      ["global_command", a.global_command.registers], ["delete_lines", a.delete_lines.registers], ["find_match", a.find_match.registers]
    ]), "the registers")
    t.assert_equal([], strangers(a.last_change, [
      ["dispatcher", a.dispatcher.last_change], ["repeat_last", a.repeat_last.last_change],
      ["insert_text", a.repeat_last.insert_text.last_change], ["leave_insert", a.repeat_last.leave_insert.last_change],
      ["break_line", a.break_line.last_change], ["erase_character", a.erase_character.last_change], ["insert_tab", a.insert_tab.last_change]
    ]), "the last change")
    t.assert_equal([], strangers(a.buffers.feed, [["dispatcher", a.dispatcher.feed]]), "the buffer feed")
    t.assert_equal([], strangers(a.last_find, [["move", a.move.last_find], ["operate", a.operate.last_find]]), "the last find")
    t.assert_equal([], strangers(a.keymap, [["handle_key", a.handle_key.keymap], ["registry", host.registry.keymap]]), "the keymap")
    t.assert_equal([], strangers(a.input, [["handle_key", a.handle_key.input], ["controller", a.controller.input], ["frame_presenter", a.frame_presenter.input], ["ui_requests", host.ui_requests.input]]), "the input state")
    t.assert_equal([], strangers(a.plugin_ui, [
      ["host", host.plugin_ui], ["registry", host.registry.plugin_ui], ["ui_requests", host.ui_requests.plugin_ui],
      ["enter_command_line", a.enter_command_line.plugin_ui], ["cancel_command_line", a.cancel_command_line.plugin_ui],
      ["execute_command_line", a.execute_command_line.plugin_ui], ["frame_presenter", a.frame_presenter.plugin_ui], ["status_bar", a.frame_presenter.status_bar.plugin_ui], ["recall_history", a.recall_history.plugin_ui]
    ]), "the plugin UI state")
    t.assert_equal([], strangers(a.status_slots, [["status_bar", a.frame_presenter.status_bar.slots]]), "the status slots")
    t.assert_equal([], strangers(host, [
      ["save_file", a.save_file.plugins], ["cancel_command_line", a.cancel_command_line.plugins],
      ["execute_command_line", a.execute_command_line.plugins], ["handle_key", a.handle_key.plugins]
    ]), "the plugin host")
    action = a.actions.find("plugin.hello.greet")
    command = a.commands.find("Hello")
    t.assert_equal([true, true], [action.is_a?(Carat::UseCases::PluginActionHandler), command.is_a?(Carat::UseCases::PluginCommandHandler)], "the plugin handlers are registered")
    t.assert_equal([], strangers(a.runner, [["execute_command_line", a.execute_command_line.runner], ["ui_requests", host.ui_requests.runner], ["global_command", a.global_command.runner]]), "the command runner")
    t.assert_true(a.runner.is_a?(Carat::UseCases::ExecuteEx), "the command runner is the ex runner")
    t.assert_equal([], strangers(a.open_file, [["split_window", a.split_window.open_file], ["open_tab", a.open_tab.open_file]]), "the open file use case")
    t.assert_equal([], strangers(a.open_side_window, [["window_requests", host.window_requests.open_side_window]]), "the open side window use case")
    t.assert_equal([], strangers(a.split_window, [["window_requests", host.window_requests.split_window], ["pin_hover", a.pin_hover.split_window]]), "the split window use case")
    t.assert_equal([], strangers(a.open_tab, [["window_requests", host.window_requests.open_tab]]), "the open tab use case")
    t.assert_equal([], strangers(a.tabs, [["open_float", a.open_float.tabs], ["close_float", a.close_float.tabs]]), "the float use cases hold the tab list")
    t.assert_equal([], strangers(a.probe_path, [["plugin_host", host.probe_path], ["open_file", a.open_file.probe_path], ["make_path", host.make_path.probe_path], ["rename_path", host.rename_path.probe_path], ["delete_path", host.delete_path.probe_path], ["file_requests", host.file_requests.probe_path]]), "the file operations")
    t.assert_equal([], strangers(host.make_path.resolve_inside, [["rename_path", host.rename_path.resolve_inside], ["delete_path", host.delete_path.resolve_inside]]), "the containment check of the file operations")
    t.assert_equal([], strangers(a.handle_key, [["controller", a.controller.handle_key]]), "the key handler")
    t.assert_equal([], strangers(a.last_substitute, [["substitute_lines", a.substitute_lines.last_substitute], ["global_command", a.global_command.last_substitute]]), "the last substitute")
    t.assert_equal([], strangers(a.last_search, [["find_match", a.find_match.last_search], ["substitute_lines", a.substitute_lines.last_search], ["global_command", a.global_command.last_search], ["preview_search", a.preview_search.last_search], ["cancel_command_line", a.cancel_command_line.last_search], ["execute_command_line", a.execute_command_line.last_search], ["frame_presenter", a.frame_presenter.last_search]]), "the last search, in the searches and the substitute")
    t.assert_equal([], strangers(a.search_history, [["find_match", a.find_match.search_history], ["substitute_lines", a.substitute_lines.search_history], ["global_command", a.global_command.search_history], ["open_search_prompt", a.open_search_prompt.search_history], ["recall_history", a.recall_history.search_history], ["execute_command_line", a.execute_command_line.search_history]]), "the search history, in the searches and the substitute")
    substitute = a.commands.find("s")
    repeat = a.actions.find("substitute.repeat")
    shared = []
    shared << "s" unless substitute.is_a?(Carat::UseCases::SubstituteCommandHandler) && substitute.substitute_lines.equal?(a.substitute_lines)
    shared << "&" unless repeat.is_a?(Carat::UseCases::SubstituteHandler) && repeat.substitute_lines.equal?(a.substitute_lines)
    t.assert_equal([], shared, "the substitute use case behind :s and &")
    global_handler = a.commands.find("g")
    vglobal = a.commands.find("v")
    delete = a.commands.find("d")
    shared = []
    shared << "g" unless global_handler.is_a?(Carat::UseCases::GlobalCommandHandler) && global_handler.global_command.equal?(a.global_command)
    shared << "v" unless vglobal.is_a?(Carat::UseCases::GlobalCommandHandler) && vglobal.global_command.equal?(a.global_command)
    shared << "d" unless delete.is_a?(Carat::UseCases::DeleteCommandHandler) && delete.delete_lines.equal?(a.delete_lines)
    t.assert_equal([], shared, "the global and delete use cases behind :g, :v, and :d")
    t.assert_equal([], strangers(a.command_history, [["recall_history", a.recall_history.command_history], ["enter_command_line", a.enter_command_line.command_history], ["execute_command_line", a.execute_command_line.command_history]]), "the command history")
    t.assert_equal([], strangers(a.search_prompt, [
      ["open_search_prompt", a.open_search_prompt.search_prompt], ["preview_search", a.preview_search.search_prompt], ["recall_history", a.recall_history.search_prompt],
      ["enter_command_line", a.enter_command_line.search_prompt], ["cancel_command_line", a.cancel_command_line.search_prompt], ["execute_command_line", a.execute_command_line.search_prompt],
      ["handle_key", a.handle_key.search_prompt], ["frame_presenter", a.frame_presenter.search_prompt]
    ]), "the search prompt")
    t.assert_equal([], strangers(a.preview_search, [["recall_history", a.recall_history.preview_search], ["edit_command_line", a.edit_command_line.preview_search]]), "the search preview use case")
    t.assert_equal([], strangers(a.open_search_prompt, [["handle_key", a.handle_key.open_search_prompt]]), "the open search prompt use case")
    t.assert_equal([], strangers(a.find_match, [["jump_to_match", a.jump_to_match.find_match], ["operate", a.operate.find_match]]), "the find match use case")
    t.assert_equal([], strangers(a.walk_history, [["undo_step", a.undo_step.walk_history], ["redo_step", a.redo_step.walk_history], ["undo_to_state", a.undo_to_state.walk_history], ["travel_history", a.travel_history.walk_history]]), "the undo history walk")
    t.assert_equal([], strangers(a.save_file, [["save_all", a.save_all.save_file]]), "the save file use case")
    t.assert_equal([], strangers(a.open_float, [["show_hover", a.show_hover.open_float]]), "the open float use case, in the hover")
    t.assert_equal([], strangers(a.open_float, [["show_signature", a.show_signature.open_float]]), "the open float use case, in the signature")
    t.assert_equal([], strangers(a.close_float, [["show_signature", a.show_signature.close_float], ["follow_signature", a.follow_signature.close_float]]), "the close float use case, in the signature")
    t.assert_equal([], strangers(a.close_float, [["show_hover", a.show_hover.close_float], ["follow_hover", a.follow_hover.close_float], ["pin_hover", a.pin_hover.close_float]]), "the close float use case, in the hover")
    t.assert_equal([], strangers(a.actions, [["dispatcher", a.dispatcher.actions], ["handle_key", a.handle_key.actions], ["repeat_last", a.repeat_last.actions]]), "the action table")
    t.assert_equal([], strangers(a.dispatcher, [["handle_key", a.handle_key.dispatcher]]), "the dispatcher")
    t.assert_equal([], strangers(a.insert_text, [["handle_key", a.handle_key.insert_text], ["repeat_last", a.repeat_last.insert_text]]), "the insert text use case")
    t.assert_equal([], strangers(a.edit_command_line, [["handle_key", a.handle_key.command_line]]), "the command line editor")
    t.assert_equal([], strangers(a.cache, [["arrange_view", a.arrange_view.cache], ["frame_presenter", a.frame_presenter.cache]]), "the line cache")
    t.assert_equal([], strangers(a.start_screen, [["controller", a.controller.start_screen], ["frame_presenter", a.frame_presenter.start_screen]]), "the start screen")
    t.assert_equal([], strangers(a.arrange_view, [["handle_key", a.handle_key.arrange_view]]), "the arrange view use case")
    t.assert_equal([], strangers(a.plugins.syntax, [["highlight_view", a.highlight_view.syntax]]), "the plugins as tokenizers")
    t.assert_equal([], strangers(a.plugins.registry, [["plugin_syntax", a.plugins.syntax.registry]]), "the plugin registry, in the tokenizer part")

    # Each port is one instance too.
    t.assert_equal([], strangers(h.terminal, [["assembly", a.terminal], ["controller", a.controller.terminal], ["screen_presenter", a.screen_presenter.terminal]]), "the terminal port")
    t.assert_equal([], strangers(h.clock, [["assembly", a.clock], ["controller", a.controller.clock], ["dispatcher", a.dispatcher.clock], ["walk_history", a.walk_history.clock], ["list_undo", a.list_undo.clock], ["services", a.services.clock]]), "the clock port")
    t.assert_equal([], strangers(h.files, [["assembly", a.files], ["open_file", a.open_file.files], ["save_file", a.save_file.files], ["probe_path", a.probe_path.files], ["make_path", host.make_path.files],
      ["resolve_inside", host.make_path.resolve_inside.files], ["rename_path", host.rename_path.files], ["delete_path", host.delete_path.files], ["file_requests", host.file_requests.files],
      ["ui_requests", host.ui_requests.files], ["window_requests", host.window_requests.files]]), "the file port")
    t.assert_equal([], strangers(h.processes, [["assembly", a.processes], ["services", a.services.processes]]), "the process port")
    t.assert_equal([], strangers(h.messages, [["assembly", a.messages], ["services", a.services.messages]]), "the message queue port")
    t.assert_equal([], strangers(a.services, [["controller", a.controller.services], ["save_file", a.save_file.services]]), "the language services")
    t.assert_equal([], strangers(a.status_slots, [["services", a.services.slots]]), "the status slots, in the language services")
    t.assert_equal([], strangers(a.buffers, [["services", a.services.buffers]]), "the buffer list, in the language services")
    t.assert_equal([], strangers(h.files, [["services", a.services.files]]), "the file port, in the language services")
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
    through = Carat::Adapters::EditorAssembly.new(terminal: h.terminal, clock: h.clock, files: files, config: gateway, processes: h.processes, messages: h.messages, completions: h.completions, plugin_list: [])
    t.assert_equal([true, true], [through.config.equal?(gateway), through.files.equal?(gateway.files)], "the assembly and the gateway hold the one file port")
    bare = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Domain::Config.new, rows: 10, cols: 40, plugins: [])
    t.assert_equal([1000, "\\", false, 1000, 1000], [bare.state.options.timeoutlen, Carat::Domain::Keymap.leader_from(Carat::Domain::Config.new), bare.state.options.number, bare.state.options.undolevels, bare.assembly.buffers.feed.undolevels], "a configuration without lines falls back to Vim's defaults")
    odd = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with("keymap.normal zq foo.bar\n"), rows: 10, cols: 40, plugins: [])
    t.assert_equal([".caratrc:1: unknown action foo.bar"], odd.assembly.config_errors, "a configuration problem names its file and line")

    t.finish
  end
end

AdaptersAssemblyTest.main if __FILE__ == $0
