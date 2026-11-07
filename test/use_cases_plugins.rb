require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module UseCasesPluginsTest
  D = Carat::Domain
  U = Carat::UseCases
  A = Carat::PluginApi

  # A test plugin: records every event and action it receives, keeps its
  # host, and raises on demand.
  class Probe < Carat::PluginApi::Plugin
    attr_reader :log #: Array[String]
    attr_reader :link #: Carat::PluginApi::Host?
    attr_accessor :raise_in_action #: bool
    attr_accessor :raise_in_event #: bool
    attr_accessor :deactivated #: bool

    # @rbs @name: String
    # @rbs @api: String
    # @rbs @events: Array[String]
    # @rbs @actions: Hash[String, String]
    # @rbs @commands: Hash[String, String]
    # @rbs @bindings: untyped

    #: (String, String, Array[String], Hash[String, String], Hash[String, String], untyped) -> void
    def initialize(name, api, events, actions, commands, bindings)
      @name = name
      @api = api
      @events = events
      @actions = actions
      @commands = commands
      @bindings = bindings
      @log = []
      @link = nil
      @raise_in_action = false
      @raise_in_event = false
      @deactivated = false
    end

    # Returns the manifest.
    # @rbs skip
    def manifest
      Carat::PluginApi::Manifest.new(name: @name, version: "1.0.0", api_version: @api, actions: @actions, commands: @commands, bindings: @bindings, events: @events, options: ["plugin.#{@name}.depth 3", "plugin.#{@name}.deep false", "plugin.#{@name}.names a b"], option_types: { "depth" => "integer", "deep" => "bool", "names" => "list" }, filetypes: [])
    end

    #: (Carat::PluginApi::Host) -> void
    def activate(host)
      @link = host
      @log << "activate"
    end

    #: () -> void
    def deactivate
      @deactivated = true
      @log << "deactivate"
    end

    #: (Carat::PluginApi::Event) -> void
    def on_event(event)
      raise ArgumentError, "event boom" if @raise_in_event
      @log << event.to_line
    end

    #: (String, Carat::PluginApi::Context) -> void
    def on_action(name, context)
      raise ArgumentError, "boom" if @raise_in_action
      @log << "action #{name} c#{context.count} r#{context.register.inspect} b#{context.buffer} w#{context.window} #{context.path} #{context.row},#{context.col}"
    end

    #: (Carat::PluginApi::Command) -> void
    def on_command(command)
      @log << "command #{command.name} #{command.bang} #{command.args.inspect}"
    end

    # The host as never nil, for the request tests.
    #: () -> Carat::PluginApi::Host
    def host
      h = @link
      h.nil? ? Carat::PluginApi::Host.new : h
    end
  end

  ALL = Carat::PluginApi::EVENTS
  ACTIONS = { "plugin.probe.go" => "Go" }
  COMMANDS = { "Probe" => "Pr" }
  BINDINGS = ["keymap.normal <leader>pp plugin.probe.go"]

  def self.probe(events)
    Probe.new("probe", "2.0", events, ACTIONS, COMMANDS, BINDINGS)
  end

  # What setup builds. An object, not an array: destructured from an
  # array inside a method, the five values lost their types on the pinned
  # Spinel and the test did not compile.
  class Rig
    attr_reader :state #: Carat::Domain::EditorState
    attr_reader :host #: Carat::UseCases::PluginHost
    attr_reader :keymap #: Carat::Domain::Keymap
    attr_reader :files #: Carat::Doubles::MemoryFiles
    attr_reader :ex #: Carat::UseCases::ExecuteEx
    attr_reader :config #: Carat::Domain::Config

    #: (Carat::Domain::EditorState, Carat::UseCases::PluginHost, Carat::Domain::Keymap, Carat::Doubles::MemoryFiles, Carat::UseCases::ExecuteEx, Carat::Domain::Config) -> void
    def initialize(state, host, keymap, files, ex, config)
      @config = config
      @state = state
      @host = host
      @keymap = keymap
      @files = files
      @ex = ex
    end
  end

  # A state over a.txt with b.txt and c.txt on disk, a keymap, and the host
  # over it with the given plugins registered and activated.
  def self.setup(plugins, lines)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\ntwo\n")
    files.put("b.txt", "zz\n")
    files.put("dir/b.txt", "1\n")
    files.put("dir/a.txt", "2\n")
    first = Carat::Domain::Buffer.from_text("", nil)
    tabs = Carat::Domain::TabList.new(window: Carat::Domain::Window.new(buffer: first))
    buffers = Carat::Domain::BufferList.new(tabs: tabs)
    buffers.add(first)
    state = Carat::Domain::EditorState.new(tabs: tabs, options: Carat::Domain::Options.new)
    keymap = Carat::Domain::Keymap.new
    commands = Carat::UseCases::ExTable.new
    ex = Carat::UseCases::ExecuteEx.new(commands: commands)
    probe_path = Carat::UseCases::ProbePath.new(files: files)
    open_file = Carat::UseCases::OpenFile.new(files: files, buffers: buffers, probe_path: probe_path)
    close_window = Carat::UseCases::CloseWindow.new(buffers: buffers, tabs: tabs)
    split_window = Carat::UseCases::SplitWindow.new(open_file: open_file, buffers: buffers, tabs: tabs)
    open_side_window = Carat::UseCases::OpenSideWindow.new(buffers: buffers, tabs: tabs)
    open_tab = Carat::UseCases::OpenTab.new(open_file: open_file, buffers: buffers, tabs: tabs)
    host = Carat::UseCases::PluginHost.new(state: state, buffers: buffers, tabs: tabs, input: Carat::Domain::InputState.new, plugin_ui: Carat::Domain::PluginUi.new, files: files, open_file: open_file, probe_path: probe_path, split_window: split_window, open_side_window: open_side_window, open_float: Carat::UseCases::OpenFloat.new(tabs: tabs), close_float: Carat::UseCases::CloseFloat.new(tabs: tabs), open_tab: open_tab, keymap: keymap, leader: " ", runner: ex)
    save_file = Carat::UseCases::SaveFile.new(files: files, plugins: host)
    save_all = Carat::UseCases::SaveAll.new(save_file: save_file, buffers: buffers)
    quit = Carat::UseCases::Quit.new(buffers: buffers, tabs: tabs)
    quit_all = Carat::UseCases::QuitAll.new(buffers: buffers)
    Carat::UseCases::FileCommandHandler.register(commands, save_file: save_file, save_all: save_all, quit: quit, quit_all: quit_all, open_file: open_file)
    Carat::UseCases::WindowCommandHandler.register(commands, split_window: split_window, close_window: close_window, close_other_windows: Carat::UseCases::CloseOtherWindows.new(buffers: buffers))
    Carat::UseCases::TabCommandHandler.register(commands, open_tab: open_tab, close_tab: Carat::UseCases::CloseTab.new(buffers: buffers, tabs: tabs), close_other_tabs: Carat::UseCases::CloseOtherTabs.new(buffers: buffers, tabs: tabs), switch_tab: Carat::UseCases::SwitchTab.new(tabs: tabs))
    Carat::UseCases::PluginCommandHandler.register(commands, plugins: host)
    plugins.each { |p| host.register(p) }
    config = Carat::Domain::Config.new
    config.read(".caratrc", lines, false)
    host.activate_all(config)
    keymap.add_lines(["keymap.normal <leader>pp cursor.down"], " ", "")
    open_file.call(state, "a.txt")
    state.tab.layout.arrange(0, 0, 23, 80)
    host.observe
    Rig.new(state, host, keymap, files, ex, config)
  end

  def self.codes(text)
    Carat::Domain::KeyNotation.parse(text, " ").codes
  end

  def self.main
    t = Carat::Testing.new("use_cases_plugins")

    # Registration and validation.
    p = probe(ALL)
    rig = setup([p], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    t.assert_equal([1, true, ""], [host.count, host.enabled?("probe"), host.reason("probe")], "a valid plugin is registered and enabled")
    t.assert_equal(["activate", "buffer_open b1 w1 a.txt 0,0"], p.log, "activation and the open of the start file, which takes the number of the empty first buffer; the empty buffer was never announced")
    t.assert_equal("Go", host.describe("plugin.probe.go"), "the host describes a plugin's action")
    t.assert_equal("", host.describe("plugin.probe.nope"), "and not another")

    bad = Probe.new("probe", "3.0", [], ACTIONS, {}, [])
    rig = setup([bad], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    t.assert_equal([false, "needs API 3.0, the host has 2.3"], [host.enabled?("probe"), host.reason("probe")], "a newer major version is refused with both versions")
    t.assert_equal(["plugin probe: needs API 3.0, the host has 2.3"], host.errors, "the refusal is recorded")
    t.assert_equal([], bad.log, "a refused plugin is not activated")

    minor = Probe.new("probe", "2.7", [], ACTIONS, {}, [])
    rig = setup([minor], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    t.assert_equal([false, "needs API 2.7, the host has 2.3"], [host.enabled?("probe"), host.reason("probe")], "a newer minor version is refused")
    older = Probe.new("probe", "1.3", [], ACTIONS, {}, [])
    rig = setup([older], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    t.assert_equal([false, "needs API 1.3, the host has 2.3"], [host.enabled?("probe"), host.reason("probe")], "an older major version is refused")
    same = Probe.new("probe", "2.0", [], ACTIONS, {}, [])
    rig = setup([same], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    t.assert_equal(true, host.enabled?("probe"), "the host's own version is accepted")

    foreign = Probe.new("probe", "2.0", [], { "plugin.other.go" => "Go" }, {}, [])
    rig = setup([foreign], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    t.assert_equal([false, "action \"plugin.other.go\" is not plugin.probe.<action>"], [host.enabled?("probe"), host.reason("probe")], "a broken manifest rule disables the plugin")

    # The configuration: disabled, options, bindings below the configuration.
    p = probe([])
    rig = setup([p], "plugin.probe.enabled false\n")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    t.assert_equal([false, "disabled in the configuration", []], [host.enabled?("probe"), host.reason("probe"), p.log], "a disabled entry registers without activating")
    outcome = host.action("plugin.probe.go", D::Command.plain("plugin.probe.go"))
    t.assert_equal("Plugin probe is disabled", outcome.message, "an action of a disabled plugin says so")
    t.assert_equal(false, host.command?("Probe"), "a disabled plugin's command is unknown")
    t.assert_equal("E492: Not an editor command: Probe", ex.call(state, "Probe").message, "and reports E492")
    t.assert_equal(:none, keymap.lookup(:normal, codes("<leader>px")).kind, "a disabled plugin's bindings are not merged")

    p = probe([])
    rig = setup([p], "plugin.probe.depth 7\nplugin.probe.deep true\nplugin.probe.names x \"y z\"\n")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    t.assert_equal(["7", "true", "x\ny z", "No option named nope"], [p.host.option("depth").text, p.host.option("deep").text, p.host.option("names").text, p.host.option("nope").message], "options of the right type replace the defaults, as text")
    t.assert_equal([[], []], [host.errors, rig.config.report], "no option problems")
    p = probe([])
    rig = setup([p], "")
    t.assert_equal(["3", "false", "a\nb"], [p.host.option("depth").text, p.host.option("deep").text, p.host.option("names").text], "the manifest's default lines give the defaults")
    p = probe([])
    rig = setup([p], "plugin.probe.names\n")
    t.assert_equal(["", []], [p.host.option("names").text, rig.config.report], "a list option with no words is the empty list")
    p = probe([])
    rig = setup([p], "plugin.probe.depth many\nplugin.probe.extra 1\n")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    t.assert_equal("3", p.host.option("depth").text, "an option of the wrong type keeps the default")
    t.assert_equal([[], [".caratrc:1: plugin.probe.depth takes a number", ".caratrc:2: plugin probe has no option extra"]], [host.errors, rig.config.report], "wrong types and unknown options are reported by file and line")
    t.assert_equal([:match, "cursor.down"], [keymap.lookup(:normal, codes("<leader>pp")).kind, keymap.lookup(:normal, codes("<leader>pp")).value], "the configuration's binding wins over the plugin's")
    p = probe([])
    rig = setup([p], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    t.assert_equal(true, host.enabled?("probe"), "a plugin with no entry is enabled")

    # Action routing with the context.
    p = probe([])
    rig = setup([p], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    state.cursor.row = 1
    host.action("plugin.probe.go", D::Command.new(register: "a", count: 3, operator: "", action: "plugin.probe.go", char: "", linewise: false, keys: []))
    t.assert_equal(["activate", "action plugin.probe.go c3 r\"a\" b1 w1 a.txt 1,0"], p.log, "the action reaches the plugin with the count, register, buffer, window, path, and cursor")
    outcome = host.action("plugin.nope.go", D::Command.plain("plugin.nope.go"))
    t.assert_equal("No plugin named nope", outcome.message, "an action for an unregistered plugin says so")
    outcome = host.action("plugin.probe.other", D::Command.plain("plugin.probe.other"))
    t.assert_equal("Plugin probe has no action plugin.probe.other", outcome.message, "an undeclared action says so")
    outcome = host.action("plugin", D::Command.plain("plugin"))
    t.assert_equal("No plugin named ", outcome.message, "an action with no plugin segment names none")

    # Command routing by name and abbreviation.
    p = probe([])
    rig = setup([p], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    t.assert_equal([true, true, true, false], [host.command?("Probe"), host.command?("Pr"), host.command?("Pro"), host.command?("P")], "the name, the abbreviation, and a spelling between are known, a shorter one is not")
    r = ex.call(state, "Probe! x y")
    t.assert_equal([true, ""], [r.ok, r.message], "a plugin command succeeds silently")
    ex.call(state, "Pr")
    t.assert_equal(["activate", "command Probe true \"x y\"", "command Probe false \"\""], p.log, "the plugin receives the declared name, the bang, and the arguments")

    # Events in order.
    p = probe(ALL)
    rig = setup([p], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    p.log.clear
    ex.call(state, "e b.txt")
    host.observe
    t.assert_equal(["buffer_open b2 w1 b.txt 0,0", "cursor_move b2 w1 b.txt 0,0"], p.log, "opening a file delivers buffer_open, then cursor_move; the clean buffer it replaced stays listed")
    p.log.clear
    state.buffer.set_lines(0, 1, ["z"])
    state.cursor.col = 0
    host.observe
    t.assert_equal(["buffer_change b2 w1 b.txt 0,0 -1 +1"], p.log, "an edit at the same cursor delivers buffer_change only, with its rows")
    p.log.clear
    state.cursor.col = 1
    host.observe
    t.assert_equal(["cursor_move b2 w1 b.txt 0,1"], p.log, "a cursor move delivers cursor_move")
    p.log.clear
    state.mode = D::Mode::INSERT
    host.observe
    t.assert_equal(["mode_change b2 w1 b.txt 0,1 insert"], p.log, "a mode change carries the mode name")
    state.mode = D::Mode::NORMAL
    host.observe
    p.log.clear
    state.buffer.set_lines(0, 1, ["zz"])
    state.cursor.col = 0
    state.mode = D::Mode::INSERT
    host.observe
    t.assert_equal(["buffer_change b2 w1 b.txt 0,0 -1 +1", "cursor_move b2 w1 b.txt 0,0", "mode_change b2 w1 b.txt 0,0 insert"], p.log, "several differences come in the fixed order")
    state.mode = D::Mode::NORMAL
    host.observe
    p.log.clear
    ex.call(state, "e!")
    host.observe
    t.assert_equal(["buffer_change b2 w1 b.txt 0,0 -1 +1"], p.log, "reloading the current buffer delivers buffer_change")
    p.log.clear
    ex.call(state, "w")
    t.assert_equal([], p.log, "a write queues buffer_save")
    host.observe
    t.assert_equal(["buffer_save b2 w1 b.txt 0,0"], p.log, "and the end of the key delivers it, and nothing else changed")
    p.log.clear
    ex.call(state, "sp")
    host.observe
    t.assert_equal(["window_focus b2 w2 b.txt 0,0"], p.log, "a split focuses the new window, which has the next id")
    p.log.clear
    ex.call(state, "q")
    host.observe
    t.assert_equal(["window_focus b2 w1 b.txt 0,0"], p.log, "closing it focuses the one left")
    p.log.clear
    host.resized(24, 80)
    host.resized(24, 80)
    host.resized(30, 100)
    t.assert_equal(["resize b0 w0  24,80", "resize b0 w0  30,100"], p.log, "resize is delivered once per new size")
    p.log.clear
    ex.call(state, "q")
    host.observe
    host.observe
    t.assert_equal(["quit b2 w1 b.txt 0,0", "deactivate"], p.log, "quit is delivered once, then deactivate")
    t.assert_equal(true, p.deactivated, "the plugin was deactivated")

    # Unsubscribed events are not delivered.
    p = probe(["buffer_save"])
    rig = setup([p], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    state.buffer.set_lines(0, 1, ["q"])
    state.mode = D::Mode::INSERT
    host.observe
    t.assert_equal(["activate"], p.log, "a plugin subscribed to buffer_save alone hears nothing of edits or modes")
    ex.call(state, "w")
    host.observe
    t.assert_equal(["activate", "buffer_save b1 w1 a.txt 0,0"], p.log, "but hears the save")

    # Requests: reading, moving, messages, status, ex.
    p = probe([])
    rig = setup([p], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    h = p.host
    state.cursor.row = 1
    view = h.read_buffer(0)
    t.assert_equal([true, state.buffer.id, "a.txt", ["one", "two"], 1, 0, false], [view.ok, view.buffer, view.path, view.lines, view.row, view.col, view.modified], "read_buffer 0 reads the current buffer")
    copied = view.lines
    copied << "x"
    t.assert_equal(2, state.buffer.line_count, "the lines are a copy")
    a_id = state.buffer.id
    ex.call(state, "sp b.txt")
    view = h.read_buffer(a_id)
    t.assert_equal([true, a_id, "a.txt", 0, 0], [view.ok, view.buffer, view.path, view.row, view.col], "a buffer that is not current reads by its id with the cursor at 0,0")
    t.assert_equal([false, "No buffer 99"], [h.read_buffer(99).ok, h.read_buffer(99).message], "an id no listed buffer has fails")
    t.assert_equal(false, h.read_buffer(-1).ok, "a negative id fails")
    ex.call(state, "q")
    r = h.move_cursor(1, 50)
    t.assert_equal([true, [1, 2]], [r.ok, state.cursor.to_a], "move_cursor clamps the column into the row")
    h.move_cursor(-3, 1)
    t.assert_equal([0, 1], state.cursor.to_a, "and the row into the buffer")
    h.message("hi", false)
    t.assert_equal(["hi", false], [state.message, state.message_error], "message shows plain text")
    h.message("bad", true)
    t.assert_equal(["bad", true], [state.message, state.message_error], "message shows an error")
    h.set_status("probe 1")
    t.assert_equal({ "probe" => "probe 1" }, host.plugin_ui.segments, "set_status keeps the segment by plugin name")
    t.assert_equal([["probe"], [10]], [host.plugin_ui.owners, host.plugin_ui.priorities], "set_status gives the segment priority 10")
    r = h.set_segment("probe 2", 95)
    t.assert_equal([true, "probe 2", [95]], [r.ok, host.plugin_ui.text_at(0), host.plugin_ui.priorities], "set_segment replaces the text and the priority in place")
    r = h.set_segment("x", 100)
    t.assert_equal([false, "priority must be 0 to 99", "probe 2"], [r.ok, r.message, host.plugin_ui.text_at(0)], "a priority above 99 is refused and changes nothing")
    t.assert_equal(false, h.set_segment("x", -1).ok, "a negative priority is refused")
    h.set_status("")
    t.assert_equal([{}, [], []], [host.plugin_ui.segments, host.plugin_ui.owners, host.plugin_ui.priorities], "empty text removes it with its place and priority")
    state.buffer.set_lines(0, 1, ["edited"])
    r = h.run_ex("w")
    t.assert_equal([true, "\"a.txt\" 2L, 11B written", "edited\ntwo\n"], [r.ok, r.message, files.get("a.txt")], "run_ex runs the command and returns its outcome")
    r = h.run_ex("nope")
    t.assert_equal([false, "E492: Not an editor command: nope"], [r.ok, r.message], "a failed ex command is a failed response")
    t.assert_equal("\u{F05A}", h.icon("info").text, "icon reads the nerd set by default")
    state.options.icons = "ascii"
    t.assert_equal(["i", false, "No icon named nope"], [h.icon("info").text, h.icon("nope").ok, h.icon("nope").message], "and the ascii set when configured, refusing an unknown name")

    # Requests: the edit transaction.
    p = probe([])
    rig = setup([p], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    h = p.host
    r = h.edit_buffer(0, [A::Edit.new(from_row: 0, from_col: 0, to_row: 0, to_col: 3, text: "ONE"), A::Edit.new(from_row: 1, from_col: 3, to_row: 1, to_col: 3, text: "!")])
    t.assert_equal([true, ["ONE", "two!"], true, 2], [r.ok, state.buffer.lines, state.buffer.modified?, r.number], "two edits apply as one batch")
    r = h.edit_buffer(0, [A::Edit.new(from_row: 0, from_col: 0, to_row: 0, to_col: 1, text: "x"), A::Edit.new(from_row: 5, from_col: 0, to_row: 5, to_col: 0, text: "y")])
    t.assert_equal([false, "edit 2: row 5 is outside the buffer", ["ONE", "two!"]], [r.ok, r.message, state.buffer.lines], "one bad edit refuses the whole list")
    r = h.edit_buffer(0, [A::Edit.new(from_row: 0, from_col: 0, to_row: 0, to_col: 2, text: "x"), A::Edit.new(from_row: 0, from_col: 1, to_row: 0, to_col: 3, text: "y")])
    t.assert_equal([false, "edit 2: overlaps the edit before it", ["ONE", "two!"]], [r.ok, r.message, state.buffer.lines], "overlapping edits are refused")
    r = h.edit_buffer(0, [A::Edit.new(from_row: 1, from_col: 0, to_row: 1, to_col: 1, text: "x"), A::Edit.new(from_row: 0, from_col: 0, to_row: 0, to_col: 1, text: "y")])
    t.assert_equal([false, "edit 2: overlaps the edit before it"], [r.ok, r.message], "edits out of order are refused")
    r = h.edit_buffer(0, [A::Edit.new(from_row: 0, from_col: 2, to_row: 0, to_col: 1, text: "x")])
    t.assert_equal("edit 1: end precedes start", r.message, "an end before its start is refused")
    r = h.edit_buffer(0, [A::Edit.new(from_row: 0, from_col: 0, to_row: 0, to_col: 9, text: "x")])
    t.assert_equal("edit 1: column 9 is outside row 0", r.message, "a column past the line is refused")
    r = h.edit_buffer(0, [A::Edit.new(from_row: 0, from_col: 1, to_row: 1, to_col: 1, text: "\n\n")])
    t.assert_equal(["O", "", "wo!"], state.buffer.lines, "a replacement may span lines and insert newlines")
    state.cursor.row = 2
    state.cursor.col = 2
    r = h.edit_buffer(0, [A::Edit.new(from_row: 0, from_col: 0, to_row: 2, to_col: 3, text: "a")])
    t.assert_equal([["a"], [0, 0]], [state.buffer.lines, state.cursor.to_a], "the cursor is kept inside the text")
    t.assert_equal(false, h.edit_buffer(99, []).ok, "editing a missing buffer fails")
    t.assert_equal(true, h.edit_buffer(0, []).ok, "an empty list succeeds")

    # Requests: signs of two plugins.
    p = probe([])
    q = Probe.new("other", "2.0", [], { "plugin.other.go" => "Go" }, {}, [])
    rig = setup([p, q], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    r = p.host.place_sign(0, 1, "error")
    t.assert_equal([true, "\u{F057}", "probe"], [r.ok, state.buffer.sign_at(1), state.buffer.layer_at(0).owner], "a sign is the icon's glyph with its owner")
    q.host.place_sign(0, 0, "warning")
    p.host.place_sign(0, 1, "info")
    t.assert_equal(["\u{F071}", "\u{F05A}"], [state.buffer.sign_at(0), state.buffer.sign_at(1)], "a plugin's later sign on a row replaces its own")
    q.host.place_sign(0, 1, "warning")
    t.assert_equal("\u{F05A}", state.buffer.sign_at(1), "the plugin registered first shows when two mark a row")
    r = p.host.clear_signs(0)
    t.assert_equal([true, 1, "\u{F071}", "\u{F071}"], [r.ok, r.number, state.buffer.sign_at(0), state.buffer.sign_at(1)], "a plugin clears only its own signs")
    t.assert_equal("Row 7 is outside the buffer", p.host.place_sign(0, 7, "error").message, "a row outside the buffer is refused")
    t.assert_equal("No icon named nope", p.host.place_sign(0, 0, "nope").message, "an unknown icon is refused")
    t.assert_equal(false, p.host.clear_signs(99).ok, "clearing a missing buffer fails")

    # Requests: the file system.
    p = probe([])
    rig = setup([p], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    h = p.host
    r = h.list_dir("dir/")
    t.assert_equal([true, ["a.txt", "b.txt"]], [r.ok, r.lines], "list_dir answers the sorted entry names")
    info = h.stat("a.txt")
    t.assert_equal([true, 8, 0, false, false], [info.ok, info.size, info.mtime, info.directory, info.symlink], "stat answers size, mtime, and the directory and symlink flags")
    info = h.stat("nope")
    t.assert_equal([false, 0], [info.ok, info.size], "stat of a missing path fails")

    # A plugin that raises is disabled and the editor goes on.
    p = probe(ALL)
    rig = setup([p], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    p.raise_in_action = true
    host.action("plugin.probe.go", D::Command.plain("plugin.probe.go"))
    t.assert_equal(["Plugin probe disabled: boom", true, false, "boom"], [state.message, state.message_error, host.enabled?("probe"), host.reason("probe")], "a raise in an action disables the plugin with a message")
    state.buffer.set_lines(0, 1, ["x"])
    host.observe
    t.assert_equal(["one", "two"].length, 2, "the buffer is untouched by the failed plugin")
    t.assert_equal(false, p.log.join(" ").include?("buffer_change"), "a disabled plugin receives no events")
    outcome = host.action("plugin.probe.go", D::Command.plain("plugin.probe.go"))
    t.assert_equal("Plugin probe is disabled", outcome.message, "its action now reports it disabled")
    p = probe(ALL)
    rig = setup([p], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    p.raise_in_event = true
    state.buffer.set_lines(0, 1, ["x"])
    host.observe
    t.assert_equal(["Plugin probe disabled: event boom", false, ["x", "two"]], [state.message, host.enabled?("probe"), state.buffer.lines], "a raise in an event disables the plugin and keeps the edit")
    r = p.host.set_status("gone")
    t.assert_equal([false, "Plugin probe is disabled", {}], [r.ok, r.message, host.plugin_ui.segments], "a disabled plugin's requests are refused")
    t.assert_equal([false, false, "Plugin probe is disabled"], [p.host.read_buffer(0).ok, p.host.stat("a.txt").ok, p.host.icon("info").message], "reads, stats, and icons too")
    p = probe([])
    rig = setup([p], "")
    state, host, keymap, files, ex = rig.state, rig.host, rig.keymap, rig.files, rig.ex
    p.host.set_status("here")
    p.raise_in_event = false
    p.raise_in_action = true
    host.action("plugin.probe.go", D::Command.plain("plugin.probe.go"))
    t.assert_equal({}, host.plugin_ui.segments, "a disabled plugin's segment is dropped when it is disabled")

    t.finish
  end
end

UseCasesPluginsTest.main if __FILE__ == $0
