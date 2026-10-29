require_relative "../carat"
require_relative "../carat/testing"
require_relative "../carat/plugins/hello/plugin"

t = Carat::Testing.new("editor_plugins")
D = Carat::Domain
A = Carat::PluginApi

E36 = "E36: Not enough room"
E382 = "E382: Cannot write, 'buftype' option is set"
INFO = "\u{F05A}"

# A test plugin that drives the window requests from key bindings and
# reports every response in the message row.
class Side < Carat::PluginApi::Plugin
  LINES = ["l0", "l1", "l2", "l3", "l4", "l5", "l6"]

  # @rbs @host: Carat::PluginApi::Host?

  #: () -> void
  def initialize
    @host = nil
  end

  # Returns the manifest.
  # @rbs skip
  def manifest
    Carat::PluginApi::Manifest.new(
      "side", "1.0.0", "1.0",
      {
        "plugin.side.open" => "Open the list on the left",
        "plugin.side.right" => "Open the list on the right",
        "plugin.side.wide" => "Open a list too wide to fit",
        "plugin.side.pick" => "Report the cursor row of the list",
        "plugin.side.close" => "Close the list",
        "plugin.side.lines" => "Replace the list's lines",
        "plugin.side.nope" => "Replace the lines of a list that does not exist",
        "plugin.side.file" => "Open b.txt in window 2",
        "plugin.side.far" => "Focus window 9",
        "plugin.side.count" => "Report the count and the register",
        "plugin.side.here" => "Open b.txt in the side window itself"
      },
      {},
      { "normal" => { "<leader>to" => "plugin.side.open", "<leader>tr" => "plugin.side.right", "<leader>tw" => "plugin.side.wide", "<leader>tc" => "plugin.side.close", "<leader>tl" => "plugin.side.lines", "<leader>tn" => "plugin.side.nope", "<leader>tf" => "plugin.side.file", "<leader>tx" => "plugin.side.far", "<leader>tt" => "plugin.side.count", "<leader>th" => "plugin.side.here" } },
      [], {}, {}
    )
  end

  #: (Carat::PluginApi::Host) -> void
  def activate(host)
    @host = host
  end

  #: (String, Carat::PluginApi::Context) -> void
  def on_action(name, context)
    host = @host
    return if host.nil?
    keymap = { "normal" => { "<CR>" => "plugin.side.pick" } }
    case name
    when "plugin.side.open" then report(host.open_scratch("list", :left, 30, LINES, keymap))
    when "plugin.side.right" then report(host.open_scratch("list", :right, 30, LINES, keymap))
    when "plugin.side.wide" then report(host.open_scratch("wide", :left, 79, LINES, nil))
    when "plugin.side.pick" then host.message("picked row #{context.row} in window #{context.window}", false)
    when "plugin.side.close" then report(host.close_scratch("list"))
    when "plugin.side.lines" then report(host.set_scratch_lines("list", ["x"]))
    when "plugin.side.nope" then report(host.set_scratch_lines("nope", ["x"]))
    when "plugin.side.file" then report(host.open_file(2, "b.txt"))
    when "plugin.side.far" then report(host.focus_window(9))
    when "plugin.side.here" then report(host.open_file(host.scratch_window("list").number, "b.txt"))
    when "plugin.side.count" then host.message("count #{context.count} register #{context.register.inspect} buffer #{context.buffer}", false)
    end
  end

  private

  #: (Carat::PluginApi::Response) -> void
  def report(response)
    host = @host
    return if host.nil?
    host.message("#{response.ok ? "ok" : "failed"} #{response.number} #{response.message}".rstrip, !response.ok)
  end
end

# The registry's plugins, then the hello fixture, which is not in the
# registry, and the side test plugin.
def plugin_list
  list = Carat::Plugins::Registry.all
  list << Carat::Plugins::Hello::Plugin.new
  list << Side.new
  list
end

# An editor on "a.txt" with "b.txt" on disk, the registry's plugins, the
# hello and side plugins, and the given configuration.
def editor_with(config, rows, cols)
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", "one\ntwo\nthree\n")
  files.put("b.txt", "zz\n")
  h = Carat::Doubles::EditorHarness.new(files, config, rows, cols, plugin_list)
  h.open("a.txt")
  h
end

def editor
  editor_with(Carat::Doubles::FixedConfig.defaults, 24, 80)
end

def session(keys)
  h = editor
  h.type(keys)
  h
end

# Every window as [row, col, text rows, columns, name].
def shape(h)
  out = []
  h.windows.each do |w|
    buffer = h.state.tab.layout.window_at(h.state.tab.layout.leaves[out.length]).buffer
    name = buffer.display_name
    out << [w[0], w[1], w[2], w[3], name.nil? ? "" : name]
  end
  out
end

# The hello plugin: rows are [label, keys, message].
t.table([
  ["the default binding greets with the info icon and the open count", " hh", "#{INFO} Hello, world! 1 buffer opened"],
  ["the ex command greets", ":Hello<CR>", "#{INFO} Hello, world! 1 buffer opened"],
  ["the abbreviation greets", ":Hel<CR>", "#{INFO} Hello, world! 1 buffer opened"],
  ["the argument is the name", ":Hello Ada<CR>", "#{INFO} Hello, Ada! 1 buffer opened"],
  ["a partial abbreviation is unknown", ":He<CR>", "E492: Not an editor command: He"],
  ["buffer opens are counted", ":e b.txt<CR> hh", "#{INFO} Hello, world! 2 buffers opened"],
  ["a count reaches the plugin", "3 tt", "count 3 register \"\" buffer 1"],
  ["a register reaches the plugin", "\"a tt", "count 0 register \"a\" buffer 1"],
  ["an unknown plugin action reports it", ":Nope<CR>", "E492: Not an editor command: Nope"]
]) do |keys|
  session(keys).message
end

h = session(" hh")
t.assert_equal({ "hello" => "hello 1" }, h.state.segments, "greeting sets the status segment")
t.assert_equal("a.txt  hello 1", h.status_row[0, 14], "the segment shows on the status line")
h.type(" hh<C-w>v")
t.assert_equal("a.txt  hello 2", h.row(22)[0, 14], "the current window shows the segment")
t.assert_equal("a.txt   ", h.row(22)[41, 8], "the other window does not")
t.assert_equal("", h.message, "a window command clears the message")

# The configuration: disabled, options, bindings, icons.
config = Carat::Doubles::FixedConfig.defaults
config["plugins"]["hello"] = { "enabled" => false }
h = editor_with(config, 24, 80)
h.type(" hh")
t.assert_equal(["", [0, 0]], [h.message, h.cursor], "a disabled plugin's binding does nothing")
h.type(":Hello<CR>")
t.assert_equal("E492: Not an editor command: Hello", h.message, "a disabled plugin's command is unknown")
t.assert_equal(["disabled in the configuration", true], [h.plugins.reason("hello"), h.plugins.enabled?("side")], "only the disabled plugin is off")
config = Carat::Doubles::FixedConfig.defaults
config["plugins"]["hello"] = { "options" => { "greeting" => "Hi" } }
h = editor_with(config, 24, 80)
h.type(":Hello<CR>")
t.assert_equal("#{INFO} Hi, world! 1 buffer opened", h.message, "an option from the configuration reaches the plugin")
config = Carat::Doubles::FixedConfig.defaults
config["plugins"]["hello"] = { "options" => { "greeting" => 7 } }
h = editor_with(config, 24, 80)
h.type(":Hello<CR>")
t.assert_equal(["#{INFO} Hello, world! 1 buffer opened", ["plugin hello: option greeting must be a string"]], [h.message, h.plugins.errors], "an option of the wrong type keeps the default and is recorded")
config = Carat::Doubles::FixedConfig.defaults
config["keymaps"]["normal"][" hh"] = "cursor.down"
h = editor_with(config, 24, 80)
h.type(" hh")
t.assert_equal(["", [1, 0]], [h.message, h.cursor], "a configuration binding replaces the plugin's")
config = Carat::Doubles::FixedConfig.defaults
config["keymaps"]["normal"][" hh"] = nil
h = editor_with(config, 24, 80)
h.type(" hh")
t.assert_equal(["", [0, 0]], [h.message, h.cursor], "a null configuration binding removes the plugin's")
config = Carat::Doubles::FixedConfig.defaults
config["options"]["icons"] = "ascii"
h = editor_with(config, 24, 80)
h.type(":Hello<CR>")
t.assert_equal("i Hello, world! 1 buffer opened", h.message, "the ascii set gives the plugin its icon")
config = Carat::Doubles::FixedConfig.defaults
config["options"]["icons"] = "unicode"
h = editor_with(config, 24, 80)
h.type(":Hello<CR>")
t.assert_equal("◆ Hello, world! 1 buffer opened", h.message, "the unicode set too")

# Every plugin disabled: the editor starts, edits, saves, and quits.
config = Carat::Doubles::FixedConfig.defaults
config["plugins"]["hello"] = { "enabled" => false }
config["plugins"]["side"] = { "enabled" => false }
config["plugins"]["explorer"] = { "enabled" => false }
h = editor_with(config, 24, 80)
t.assert_equal("\"a.txt\" 3L, 14B", h.message, "the file opens")
h.type("x:w<CR>")
t.assert_equal(["ne", "two", "three"], h.lines, "x edits")
t.assert_equal("ne\ntwo\nthree\n", h.files.get("a.txt"), "the file is written")
h.type(":q<CR>")
t.assert_equal(true, h.quit?, "the editor quits")
t.assert_equal([false, false, false], [h.plugins.enabled?("hello"), h.plugins.enabled?("side"), h.plugins.enabled?("explorer")], "every plugin was off")

# Plugin windows: rows are [label, keys, [message, windows]].
LEFT = [[0, 0, 22, 30, "list"], [0, 31, 22, 49, "a.txt"]]
RIGHT = [[0, 0, 22, 49, "a.txt"], [0, 50, 22, 30, "list"]]
t.table([
  ["a side window on the left", " to", ["ok 1", LEFT, 1]],
  ["a side window on the right", " tr", ["ok 2", RIGHT, 2]],
  ["the width survives equalize", " to<C-w>=", ["", LEFT, 1]],
  ["the width survives a split of the other window", " to<C-w>l<C-w>v<C-w>=", ["", [[0, 0, 22, 30, "list"], [0, 31, 22, 24, "a.txt"], [0, 56, 22, 24, "a.txt"]], 2]],
  ["reopening focuses the side window", " to<C-w>l to", ["ok 1", LEFT, 1]],
  ["no room reports E36", " tw", ["failed 0 #{E36}", [[0, 0, 22, 80, "a.txt"]], 1]],
  ["the plugin closes its window", " to tc", ["ok 0", [[0, 0, 22, 80, "a.txt"]], 1]],
  ["closing a list that is not shown fails", " tc", ["failed 0 No window shows list", [[0, 0, 22, 80, "a.txt"]], 1]],
  [":q closes the side window", " to:q<CR>", ["", [[0, 0, 22, 80, "a.txt"]], 1]],
  ["Ctrl-W q closes the side window", " to<C-w>q", ["", [[0, 0, 22, 80, "a.txt"]], 1]],
  ["open a file in the file window", " to tf", ["ok 2 \"b.txt\" 1L, 3B", [[0, 0, 22, 30, "list"], [0, 31, 22, 49, "b.txt"]], 2]],
  ["focusing a missing window fails", " to tx", ["failed 0 No window 9", LEFT, 1]]
]) do |keys|
  h = session(keys)
  [h.message, shape(h), h.window_index]
end

# The scratch keymap, its fallback, and its scope.
h = session(" to")
t.assert_equal(Side::LINES, h.lines, "the side window shows the plugin's lines")
t.assert_equal("list", h.status_row[0, 4], "its status line shows the title")
h.type("jj<CR>")
t.assert_equal([[2, 0], "picked row 2 in window 1"], [h.cursor, h.message], "j falls through to the mode's keymap and Enter runs the plugin's action")
h.type("<C-w>l<CR>")
t.assert_equal(["", 2], [h.message, h.window_index], "the scratch keymap does not apply in the file window")
h.type("<C-w>h")
t.assert_equal("list", h.status_row[0, 4], "back in the side window")
t.assert_equal(["a.txt", ""], h.buffer_paths, "the scratch buffer is listed without a path")
h.type(":q<CR>")
t.assert_equal([["a.txt"], 1], [h.buffer_paths, h.window_count], "quitting the side window drops the scratch buffer")

# Replacing the lines, writing, and quitting with a scratch buffer.
h = session(" to5j")
t.assert_equal([5, 0], h.cursor, "the cursor is on row 5 of the list")
h.type(" tl")
t.assert_equal([["x"], [0, 0], "ok 0", "list  "], [h.lines, h.cursor, h.message, h.status_row[0, 6]], "the lines are replaced, the cursor clamped, and the buffer unmodified")
h.type(" tn")
t.assert_equal("failed 0 No scratch buffer nope", h.message, "an unknown title fails")
h.type(":w<CR>")
t.assert_equal(E382, h.message, "writing a scratch buffer is refused")
h.type("x")
t.assert_equal([[""], true], [h.lines, h.buffer.modified], "editing the scratch buffer is allowed")
h.type(":qa<CR>")
t.assert_equal(true, h.quit?, "quit-all ignores the scratch buffer's changes")
h = session(" to<C-w>lx<C-w>h tl")
h.type(":wa<CR>")
t.assert_equal(["\"a.txt\" 3L, 13B written", "ne\ntwo\nthree\n"], [h.message, h.files.get("a.txt")], "write-all skips the scratch buffer")
h.type(":q<CR>:q<CR>")
t.assert_equal(true, h.quit?, "and the editor quits")
h = session(" to tf")
t.assert_equal([2, ["zz"]], [h.window_index, h.lines], "open_file shows the file in window 2 and makes it current")
h.type("<C-w>c")
t.assert_equal([1, false], [h.window_count, h.quit?], "closing the file window with Ctrl-W c leaves the side window")
h.type(":q<CR>")
t.assert_equal(true, h.quit?, "quitting the last side window ends the editor")

# Quitting the last file window beside a side window ends the editor, or
# closes its tab page: rows are [label, keys, [quit, windows, tab pages,
# message]].
t.table([
  [":q beside a side window ends the editor", " to<C-w>l:q<CR>", [true, 2, 1, ""]],
  ["Ctrl-W q there too", " to<C-w>l<C-w>q", [true, 2, 1, ""]],
  [":wq there too", " to<C-w>l:wq<CR>", [true, 2, 1, ""]],
  [":x there too", " to<C-w>l:x<CR>", [true, 2, 1, ""]],
  [":q on a modified buffer is refused", " to<C-w>lx:q<CR>", [false, 2, 1, "E37: No write since last change (add ! to override)"]],
  [":q! there ends the editor", " to<C-w>lx:q!<CR>", [true, 2, 1, ""]],
  [":q in the side window closes only it", " to:q<CR>", [false, 1, 1, ""]],
  [":q in a split file window closes it", " to<C-w>l<C-w>v:q<CR>", [false, 2, 1, ""]],
  [":q in a second tab page closes that tab page", ":tabnew b.txt<CR> to<C-w>l:q<CR>", [false, 1, 1, ""]]
]) do |keys|
  h = session(keys)
  [h.quit?, h.window_count, h.tab_count, h.message]
end

# The open file request and scratch buffers across tab pages.
h = session(" to<C-w>lx<C-w>h tf")
t.assert_equal([["zz"], ["", "b.txt", "a.txt"], true], [h.lines, h.buffer_paths, h.state.buffer_at(2).modified], "opening over a modified buffer keeps it hidden in the list")
h = session(" to th")
t.assert_equal([["zz"], false, 2], [h.lines, h.state.window.fixed_width, h.window_count], "a side window that takes a file loses its fixed width")
h = session(" to tfx tf")
t.assert_equal(["ok 2", 2, ["z"], true], [h.message, h.window_index, h.lines, h.buffer.modified], "opening the file a window already shows leaves it as it is, changes kept")
h = session(" to:tabnew<CR> to")
titles = []
i = 0
while i < h.state.buffer_count
  titles << h.state.buffer_at(i).title
  i += 1
end
t.assert_equal([2, 2, 2], [h.tab_count, h.tab_index, h.window_count], "a side window opens in the second tab page")
t.assert_equal(["", "list", ""], titles, "and shows the one scratch buffer the first tab page shows")
h.type("gt")
t.assert_equal([2, "list"], [h.window_count, h.state.window.buffer.title], "the first tab page still shows it")

# A side window has no line numbers.
h = session(" to")
t.assert_equal(["l0", "l1"], [h.row(0)[0, 2], h.row(1)[0, 2]], "the side window's rows start at its first column")

# A plugin that raises is disabled in the running editor.
class Boom < Carat::PluginApi::Plugin
  # Returns the manifest.
  # @rbs skip
  def manifest
    Carat::PluginApi::Manifest.new("boom", "1.0.0", "1.0", { "plugin.boom.go" => "Raise" }, {}, { "normal" => { " bb" => "plugin.boom.go" } }, [:cursor_move], {}, {})
  end

  #: (String, Carat::PluginApi::Context) -> void
  def on_action(name, context)
    raise ArgumentError, "boom"
  end

  #: (Carat::PluginApi::Event) -> void
  def on_event(event)
    raise ArgumentError, "event boom"
  end
end

files = Carat::Doubles::MemoryFiles.new
files.put("a.txt", "one\ntwo\n")
h = Carat::Doubles::EditorHarness.with_plugins(files, 24, 80, [Boom.new])
h.open("a.txt")
t.assert_equal(["Plugin boom disabled: event boom", true], [h.message, h.state.message_error], "a raise in an event at startup disables the plugin")
h.type(" bb")
t.assert_equal("Plugin boom is disabled", h.message, "its binding now reports it disabled")
h.type("x")
t.assert_equal([["ne", "two"], ""], [h.lines, h.message], "the editor goes on editing")
h = Carat::Doubles::EditorHarness.with_plugins(files, 24, 80, [Boom.new])
h.assembly.plugins.register(Side.new)
h.open("a.txt")
t.assert_equal(true, h.plugins.enabled?("boom") == false, "the event plugin is off again")

t.finish
