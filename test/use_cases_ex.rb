require_relative "../carat/test_support"
require_relative "../carat/testing"

t = Carat::Testing.new("use_cases_ex")
D = Carat::Domain
U = Carat::UseCases

# A state over a buffer of the lines and the path, with its own buffer
# list and tab list, and the ex use case wired over them with a plugin
# host with no plugins.
class World < Struct.new(:state, :buffers, :tabs, :ex)
end

def world(files, lines, path)
  buffer = D::Buffer.new(lines, path, "\n")
  tabs = D::TabList.new(D::Window.new(buffer))
  buffers = D::BufferList.new(tabs)
  buffers.add(buffer)
  state = D::EditorState.new(tabs, D::Options.new)
  commands = U::ExTable.new
  ex = U::ExecuteEx.new(commands: commands)
  open_file = U::OpenFile.new(files: files, buffers: buffers)
  close_window = U::CloseWindow.new(buffers: buffers, tabs: tabs)
  split_window = U::SplitWindow.new(open_file: open_file, buffers: buffers, tabs: tabs)
  open_tab = U::OpenTab.new(open_file: open_file, buffers: buffers, tabs: tabs)
  plugins = U::PluginHost.new(state: state, buffers: buffers, tabs: tabs, input: D::InputState.new, plugin_ui: D::PluginUi.new, files: files, open_file: open_file, close_window: close_window, split_window: split_window, open_tab: open_tab, keymap: D::Keymap.new, leader: " ", runner: ex)
  save_file = U::SaveFile.new(files: files, plugins: plugins, buffers: buffers)
  quit = U::Quit.new(close_window: close_window, buffers: buffers, tabs: tabs)
  U::FileCommandHandler.register(commands, save_file: save_file, quit: quit, open_file: open_file)
  U::WindowCommandHandler.register(commands, split_window: split_window, close_window: close_window)
  U::TabCommandHandler.register(commands, open_tab: open_tab, close_tab: U::CloseTab.new(buffers: buffers, tabs: tabs), switch_tab: U::SwitchTab.new(tabs: tabs))
  U::PluginCommandHandler.register(commands, plugins: plugins)
  World.new(state, buffers, tabs, ex)
end

# Write.
files = Carat::Doubles::MemoryFiles.new
s_w = world(files, ["one", "two"], "a.txt")
s = s_w.state
s.buffer.mark_unsaved
r = s_w.ex.call(s, "w")
t.assert_equal([true, "\"a.txt\" 2L, 8B written"], [r.ok, r.message], "write reports the written message")
t.assert_equal("one\ntwo\n", files.get("a.txt"), "write stores the text")
t.assert_equal(false, s.buffer.modified?, "write clears the modified flag")
s.buffer.mark_unsaved
r = s_w.ex.call(s, "write")
t.assert_equal("\"a.txt\" 2L, 8B written", r.message, "long form writes")
s.buffer.mark_unsaved
r = s_w.ex.call(s, "w b.txt")
t.assert_equal("one\ntwo\n", files.get("b.txt"), "write to another path")
t.assert_equal("a.txt", s.buffer.path, "buffer path unchanged by writing elsewhere")
t.assert_equal(true, s.buffer.modified?, "writing elsewhere keeps the buffer modified")
unnamed_w = world(files, ["x"], nil)
unnamed = unnamed_w.state
r = unnamed_w.ex.call(unnamed, "w")
t.assert_equal([false, "E32: No file name"], [r.ok, r.message], "write with no path fails")
r = unnamed_w.ex.call(unnamed, "w new.txt")
t.assert_equal("new.txt", unnamed.buffer.path, "unnamed buffer adopts the written path")
t.assert_equal(false, unnamed.buffer.modified?, "adopting the path clears the modified flag")
files.unwritable << "ro.txt"
ro_w = world(files, ["x"], "ro.txt")
ro = ro_w.state
ro.buffer.mark_unsaved
r = ro_w.ex.call(ro, "w")
t.assert_equal(false, r.ok, "write failure is a failure")
t.assert_equal("E212: Can't open file for writing", r.message[0, 33], "write failure reports E212")
t.assert_equal(true, ro.buffer.modified?, "failed write keeps the buffer modified")

# Quit.
s_w = world(files, ["x"], "a.txt")
s = s_w.state
r = s_w.ex.call(s, "q")
t.assert_equal([true, true], [r.ok, s.quit], "quit on a clean buffer ends the editor")
s_w = world(files, ["x"], "a.txt")
s = s_w.state
s.buffer.mark_unsaved
r = s_w.ex.call(s, "q")
t.assert_equal([false, "E37: No write since last change (add ! to override)", false], [r.ok, r.message, s.quit], "quit refused while modified")
r = s_w.ex.call(s, "quit")
t.assert_equal(false, s.quit, "long form quit refused too")
r = s_w.ex.call(s, "q!")
t.assert_equal(true, s.quit, "forced quit ends the editor")
s_w = world(files, ["x"], "a.txt")
s = s_w.state
s.buffer.mark_unsaved
s_w.ex.call(s, "quit!")
t.assert_equal(true, s.quit, "long form forced quit")

# Write-quit.
files = Carat::Doubles::MemoryFiles.new
s_w = world(files, ["hello"], "a.txt")
s = s_w.state
s.buffer.mark_unsaved
r = s_w.ex.call(s, "wq")
t.assert_equal([true, "hello\n", true], [r.ok, files.get("a.txt"), s.quit], "wq writes and quits")
s_w = world(files, ["x"], nil)
s = s_w.state
r = s_w.ex.call(s, "wq")
t.assert_equal([false, "E32: No file name", false], [r.ok, r.message, s.quit], "wq with no file name stays")
files.unwritable << "ro.txt"
s_w = world(files, ["x"], "ro.txt")
s = s_w.state
r = s_w.ex.call(s, "wq")
t.assert_equal(false, s.quit, "wq stays when the write fails")
s_w = world(files, ["x"], "a.txt")
s = s_w.state
s.buffer.mark_unsaved
r = s_w.ex.call(s, "wq other.txt")
t.assert_equal(["x\n", true], [files.get("other.txt"), s.quit], "wq with a path writes there and quits")

# Runs one ex command on a fresh editor whose buffer holds ["new"] over a
# disk file "a.txt" holding "old\n", and reports what it observed:
# [ok, message, quit, text of a.txt on disk, modified]. The kind is :clean,
# :modified, :unnamed (modified, no path), or :unwritable (modified, a.txt
# refuses writes).
def run_ex(text, kind)
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", "old\n")
  files.unwritable << "a.txt" if kind == :unwritable
  s_w = world(files, ["new"], kind == :unnamed ? nil : "a.txt")
  s = s_w.state
  s.buffer.mark_unsaved if kind != :clean
  r = s_w.ex.call(s, text)
  [r.ok, r.message, s.quit, files.get("a.txt"), s.buffer.modified?]
end

E37 = "E37: No write since last change (add ! to override)"
E141 = "E141: No file name for buffer 1"
E212 = "E212: Can't open file for writing: Permission denied"
WRITTEN = "\"a.txt\" 1L, 4B written"

# Exit. Rows are [label, [command line, buffer kind], [ok, message, quit, disk, modified]].
t.table([
  ["x on a clean buffer quits without writing", ["x", :clean], [true, "", true, "old\n", false]],
  ["x on a modified buffer writes and quits", ["x", :modified], [true, "", true, "new\n", false]],
  ["x with no file name stays", ["x", :unnamed], [false, "E32: No file name", false, "old\n", true]],
  ["x stays when the write fails", ["x", :unwritable], [false, E212, false, "old\n", true]],
  ["x! on a modified buffer writes and quits", ["x!", :modified], [true, "", true, "new\n", false]],
  ["x! on a clean buffer quits", ["x!", :clean], [true, "", true, "old\n", false]],
  ["x! with no file name stays", ["x!", :unnamed], [false, "E32: No file name", false, "old\n", true]],
  ["x! stays when the write fails", ["x!", :unwritable], [false, E212, false, "old\n", true]],
  ["xit writes and quits", ["xit", :modified], [true, "", true, "new\n", false]],
  ["xit! writes and quits", ["xit!", :modified], [true, "", true, "new\n", false]],
  ["exi writes and quits", ["exi", :modified], [true, "", true, "new\n", false]],
  ["exi! writes and quits", ["exi!", :modified], [true, "", true, "new\n", false]],
  ["exit writes and quits", ["exit", :modified], [true, "", true, "new\n", false]],
  ["exit! writes and quits", ["exit!", :modified], [true, "", true, "new\n", false]],
  ["xit on a clean buffer quits without writing", ["xit", :clean], [true, "", true, "old\n", false]],
  ["exit on a clean buffer quits without writing", ["exit", :clean], [true, "", true, "old\n", false]]
]) do |input|
  run_ex(input[0], input[1])
end
files = Carat::Doubles::MemoryFiles.new
s_w = world(files, ["x"], "a.txt")
s = s_w.state
r = s_w.ex.call(s, "x b.txt")
t.assert_equal([true, "x\n", nil, true], [r.ok, files.get("b.txt"), files.get("a.txt"), s.quit], "x with a path writes there even when clean and quits")

# Quit-all.
t.table([
  ["qa on a clean buffer quits", ["qa", :clean], [true, "", true, "old\n", false]],
  ["qa refused while modified", ["qa", :modified], [false, E37, false, "old\n", true]],
  ["qa refused on a modified unnamed buffer", ["qa", :unnamed], [false, E37, false, "old\n", true]],
  ["qa! on a clean buffer quits", ["qa!", :clean], [true, "", true, "old\n", false]],
  ["qa! discards changes", ["qa!", :modified], [true, "", true, "old\n", true]],
  ["qa! discards an unnamed buffer", ["qa!", :unnamed], [true, "", true, "old\n", true]],
  ["qall on a clean buffer quits", ["qall", :clean], [true, "", true, "old\n", false]],
  ["qall refused while modified", ["qall", :modified], [false, E37, false, "old\n", true]],
  ["qall! discards changes", ["qall!", :modified], [true, "", true, "old\n", true]],
  ["quita on a clean buffer quits", ["quita", :clean], [true, "", true, "old\n", false]],
  ["quita refused while modified", ["quita", :modified], [false, E37, false, "old\n", true]],
  ["quita! discards changes", ["quita!", :modified], [true, "", true, "old\n", true]],
  ["quitall on a clean buffer quits", ["quitall", :clean], [true, "", true, "old\n", false]],
  ["quitall refused while modified", ["quitall", :modified], [false, E37, false, "old\n", true]],
  ["quitall! discards changes", ["quitall!", :modified], [true, "", true, "old\n", true]]
]) do |input|
  run_ex(input[0], input[1])
end

# Write-all.
t.table([
  ["wa on a clean buffer writes nothing", ["wa", :clean], [true, "", false, "old\n", false]],
  ["wa writes a modified buffer", ["wa", :modified], [true, WRITTEN, false, "new\n", false]],
  ["wa with no file name reports E141", ["wa", :unnamed], [false, E141, false, "old\n", true]],
  ["wa reports a failed write", ["wa", :unwritable], [false, E212, false, "old\n", true]],
  ["wa! on a clean buffer writes nothing", ["wa!", :clean], [true, "", false, "old\n", false]],
  ["wa! writes a modified buffer", ["wa!", :modified], [true, WRITTEN, false, "new\n", false]],
  ["wa! with no file name reports E141", ["wa!", :unnamed], [false, E141, false, "old\n", true]],
  ["wall on a clean buffer writes nothing", ["wall", :clean], [true, "", false, "old\n", false]],
  ["wall writes a modified buffer", ["wall", :modified], [true, WRITTEN, false, "new\n", false]],
  ["wall with no file name reports E141", ["wall", :unnamed], [false, E141, false, "old\n", true]],
  ["wall! writes a modified buffer", ["wall!", :modified], [true, WRITTEN, false, "new\n", false]]
]) do |input|
  run_ex(input[0], input[1])
end

# Write-quit-all.
t.table([
  ["wqa on a clean buffer quits without writing", ["wqa", :clean], [true, "", true, "old\n", false]],
  ["wqa writes a modified buffer and quits", ["wqa", :modified], [true, "", true, "new\n", false]],
  ["wqa with no file name stays", ["wqa", :unnamed], [false, E141, false, "old\n", true]],
  ["wqa stays when the write fails", ["wqa", :unwritable], [false, E212, false, "old\n", true]],
  ["wqa! on a clean buffer quits", ["wqa!", :clean], [true, "", true, "old\n", false]],
  ["wqa! writes a modified buffer and quits", ["wqa!", :modified], [true, "", true, "new\n", false]],
  ["wqa! with no file name stays", ["wqa!", :unnamed], [false, E141, false, "old\n", true]],
  ["wqa! stays when the write fails", ["wqa!", :unwritable], [false, E212, false, "old\n", true]],
  ["wqall writes a modified buffer and quits", ["wqall", :modified], [true, "", true, "new\n", false]],
  ["wqall! writes a modified buffer and quits", ["wqall!", :modified], [true, "", true, "new\n", false]],
  ["xa on a clean buffer quits without writing", ["xa", :clean], [true, "", true, "old\n", false]],
  ["xa writes a modified buffer and quits", ["xa", :modified], [true, "", true, "new\n", false]],
  ["xa with no file name stays", ["xa", :unnamed], [false, E141, false, "old\n", true]],
  ["xa stays when the write fails", ["xa", :unwritable], [false, E212, false, "old\n", true]],
  ["xa! writes a modified buffer and quits", ["xa!", :modified], [true, "", true, "new\n", false]],
  ["xa! with no file name stays", ["xa!", :unnamed], [false, E141, false, "old\n", true]],
  ["xall writes a modified buffer and quits", ["xall", :modified], [true, "", true, "new\n", false]],
  ["xall! writes a modified buffer and quits", ["xall!", :modified], [true, "", true, "new\n", false]],
  ["xall on a clean buffer quits without writing", ["xall", :clean], [true, "", true, "old\n", false]]
]) do |input|
  run_ex(input[0], input[1])
end

# Edit.
files = Carat::Doubles::MemoryFiles.new
files.put("b.txt", "zz\n")
files.put("a.txt", "disk\n")
s_w = world(files, ["mem"], "a.txt")
s = s_w.state
r = s_w.ex.call(s, "e b.txt")
t.assert_equal([true, "\"b.txt\" 1L, 3B", "b.txt", ["zz"], [0, 0]], [r.ok, r.message, s.buffer.path, s.buffer.lines, s.cursor.to_a], "edit opens another file")
r = s_w.ex.call(s, "e new.txt")
t.assert_equal(["\"new.txt\" [New]", "new.txt", [""], false], [r.message, s.buffer.path, s.buffer.lines, s.buffer.modified?], "edit starts a new file")
s_w = world(files, ["mem"], "a.txt")
s = s_w.state
s.buffer.mark_unsaved
r = s_w.ex.call(s, "e b.txt")
t.assert_equal([false, "E37: No write since last change (add ! to override)", ["mem"]], [r.ok, r.message, s.buffer.lines], "edit refused while modified")
r = s_w.ex.call(s, "e!")
t.assert_equal([["disk"], false], [s.buffer.lines, s.buffer.modified?], "forced reload discards changes")
r = s_w.ex.call(s, "edit b.txt")
t.assert_equal(["zz"], s.buffer.lines, "long form edit")
s_w = world(files, ["x"], nil)
s = s_w.state
r = s_w.ex.call(s, "e")
t.assert_equal("E32: No file name", r.message, "edit with no path and no argument")
s_w = world(files, ["mem"], "a.txt")
s = s_w.state
r = s_w.ex.call(s, "e")
t.assert_equal(["disk"], s.buffer.lines, "edit without argument reloads")

# Windows and tab pages through the registry, on a state laid out at 23 by
# 80: rows are [label, command line, [ok, message, windows, tab pages]].
E36 = "E36: Not enough room"
def run_window(text)
  files = Carat::Doubles::MemoryFiles.new
  files.put("b.txt", "zz\n")
  s_w = world(files, ["mem"], "a.txt")
  s = s_w.state
  s.tab.layout.arrange(0, 0, 23, 80)
  r = s_w.ex.call(s, text)
  [r.ok, r.message, s.tab.window_count, s_w.tabs.tab_count]
end
t.table([
  ["sp splits", "sp", [true, "", 2, 1]],
  ["split splits", "split", [true, "", 2, 1]],
  ["sp file shows the file", "sp b.txt", [true, "\"b.txt\" 1L, 3B", 2, 1]],
  ["vs splits", "vs", [true, "", 2, 1]],
  ["vsplit splits", "vsplit", [true, "", 2, 1]],
  ["vs file shows the file", "vs b.txt", [true, "\"b.txt\" 1L, 3B", 2, 1]],
  ["new splits", "new", [true, "", 2, 1]],
  ["vne splits", "vne", [true, "", 2, 1]],
  ["vnew splits", "vnew", [true, "", 2, 1]],
  ["clo on the last window fails", "clo", [false, "E444: Cannot close last window", 1, 1]],
  ["close on the last window fails", "close", [false, "E444: Cannot close last window", 1, 1]],
  ["on with one window says so", "on", [true, "Already only one window", 1, 1]],
  ["only with one window says so", "only", [true, "Already only one window", 1, 1]],
  ["tabnew opens a tab page", "tabnew", [true, "", 1, 2]],
  ["tabe opens a tab page", "tabe", [true, "", 1, 2]],
  ["tabedit file opens a tab page on the file", "tabedit b.txt", [true, "\"b.txt\" 1L, 3B", 1, 2]],
  ["tabc on the last tab page fails", "tabc", [false, "E784: Cannot close last tab page", 1, 1]],
  ["tabclose on the last tab page fails", "tabclose", [false, "E784: Cannot close last tab page", 1, 1]],
  ["tabo with one tab page says so", "tabo", [true, "Already only one tab page", 1, 1]],
  ["tabonly with one tab page says so", "tabonly", [true, "Already only one tab page", 1, 1]],
  ["tabn with one tab page stays", "tabn", [true, "", 1, 1]],
  ["tabnext with one tab page stays", "tabnext", [true, "", 1, 1]],
  ["tabp with one tab page stays", "tabp", [true, "", 1, 1]],
  ["tabprevious with one tab page stays", "tabprevious", [true, "", 1, 1]],
  ["tabN with one tab page stays", "tabN", [true, "", 1, 1]],
  ["tabNext with one tab page stays", "tabNext", [true, "", 1, 1]],
  ["tabfir with one tab page stays", "tabfir", [true, "", 1, 1]],
  ["tabfirst with one tab page stays", "tabfirst", [true, "", 1, 1]],
  ["tabl with one tab page stays", "tabl", [true, "", 1, 1]],
  ["tablast with one tab page stays", "tablast", [true, "", 1, 1]]
]) do |text|
  run_window(text)
end
files = Carat::Doubles::MemoryFiles.new
s_w = world(files, ["mem"], "a.txt")
s = s_w.state
s.tab.layout.arrange(0, 0, 3, 80)
r = s_w.ex.call(s, "sp")
t.assert_equal([false, E36, 1], [r.ok, r.message, s.tab.window_count], "sp with two text rows reports E36")

# Windows and the file commands.
files = Carat::Doubles::MemoryFiles.new
files.put("b.txt", "zz\n")
s_w = world(files, ["mem"], "a.txt")
s = s_w.state
s.tab.layout.arrange(0, 0, 23, 80)
s_w.ex.call(s, "sp")
s.buffer.mark_unsaved
r = s_w.ex.call(s, "q")
t.assert_equal([true, 1, false, true], [r.ok, s.tab.window_count, s.quit, s.buffer.modified?], "q with two windows closes one and keeps the buffer")
s_w.ex.call(s, "sp b.txt")
s.buffer.mark_unsaved
r = s_w.ex.call(s, "close")
t.assert_equal([1, "a.txt", 2], [s.tab.window_count, s.buffer.path, s_w.buffers.count], "close keeps the modified buffer hidden")
r = s_w.ex.call(s, "qa")
t.assert_equal([false, E37, false], [r.ok, r.message, s.quit], "qa is refused by the hidden buffer")
r = s_w.ex.call(s, "wa")
t.assert_equal([true, "\"b.txt\" 1L, 3B written", "zz\n", 1], [r.ok, r.message, files.get("b.txt"), s_w.buffers.count], "wa writes the hidden buffer, reports the write, and drops it once clean")
s_w = world(files, ["mem"], "a.txt")
s = s_w.state
s.tab.layout.arrange(0, 0, 23, 80)
s_w.ex.call(s, "sp b.txt")
s.buffer.mark_unsaved
s_w.ex.call(s, "close")
r = s_w.ex.call(s, "q!")
t.assert_equal([true, false, "b.txt", 1], [r.ok, s.quit, s.buffer.path, s_w.buffers.count], "q! on the last window shows the hidden modified buffer and abandons the clean one")
s_w = world(files, ["mem"], "a.txt")
s = s_w.state
s.tab.layout.arrange(0, 0, 23, 80)
s_w.ex.call(s, "sp b.txt")
s.buffer.mark_unsaved
s_w.ex.call(s, "close")
r = s_w.ex.call(s, "e b.txt")
t.assert_equal([true, "\"b.txt\" 1L, 3B", true, 1], [r.ok, r.message, s.buffer.modified?, s_w.buffers.count], "e brings a hidden buffer back without reading it, dropping the clean one")
s_w = world(files, ["mem"], "a.txt")
s = s_w.state
s.tab.layout.arrange(0, 0, 23, 80)
s_w.ex.call(s, "sp")
s.buffer.mark_unsaved
r = s_w.ex.call(s, "wq")
t.assert_equal([true, "mem\n", 1, false], [r.ok, files.get("a.txt"), s.tab.window_count, s.quit], "wq with two windows writes and closes one")
s.buffer.mark_unsaved
r = s_w.ex.call(s, "x")
t.assert_equal([true, true], [r.ok, s.quit], "x on the last window writes and quits")
s_w = world(files, ["mem"], "a.txt")
s = s_w.state
s.tab.layout.arrange(0, 0, 23, 80)
s_w.ex.call(s, "tabnew")
s_w.ex.call(s, "e b.txt")
s.buffer.mark_unsaved
s_w.ex.call(s, "tabfir")
r = s_w.ex.call(s, "qa")
t.assert_equal([false, E37], [r.ok, r.message], "qa is refused by a modified buffer in another tab page")
r = s_w.ex.call(s, "wqa")
t.assert_equal([true, true, "zz\n"], [r.ok, s.quit, files.get("b.txt")], "wqa writes the other tab page's buffer and quits")

# Unknown and empty.
r = s_w.ex.call(s, "foo")
t.assert_equal([false, "E492: Not an editor command: foo"], [r.ok, r.message], "unknown command")
r = s_w.ex.call(s, ":foo bar ")
t.assert_equal("E492: Not an editor command: foo bar", r.message, "unknown command keeps its argument text")
r = s_w.ex.call(s, "")
t.assert_equal([true, ""], [r.ok, r.message], "empty command does nothing")
r = s_w.ex.call(s, "12")
t.assert_equal("E492: Not an editor command: 12", r.message, "a bare number is not a command yet")

# Scratch buffers: never written, skipped by :wa, and not unsaved work.
files = Carat::Doubles::MemoryFiles.new
s_w = world(files, ["one"], "a.txt")
s = s_w.state
scratch = D::Buffer.new(["l"], nil, "\n")
scratch.owner = "hello"
scratch.title = "list"
s_w.buffers.add(scratch)
s.tab.layout.arrange(0, 0, 23, 80)
side = D::Window.new(scratch)
side.fixed_width = true
s.tab.focus(s.tab.layout.split_edge(side, 20, true))
r = s_w.ex.call(s, "w")
t.assert_equal([false, "E382: Cannot write, 'buftype' option is set"], [r.ok, r.message], "write on a scratch buffer reports E382")
scratch.set_lines(0, 1, ["m"])
s_w.buffers.buffer_at(0).set_lines(0, 1, ["two"])
r = s_w.ex.call(s, "wa")
t.assert_equal([true, "\"a.txt\" 1L, 4B written", "two\n", true], [r.ok, r.message, files.get("a.txt"), scratch.modified?], "write-all skips the scratch buffer and writes the file")
r = s_w.ex.call(s, "qa")
t.assert_equal([true, true], [r.ok, s.quit], "quit-all ignores the scratch buffer's changes")
s.quit = false
s.tab.focus(s.tab.layout.leaves[1])
r = s_w.ex.call(s, "Nope")
t.assert_equal("E492: Not an editor command: Nope", r.message, "a name no plugin declares is unknown")


# Every documented command and abbreviation: each `:name[suffix]` form in
# the Ex commands table of docs/compatibility.md is registered with that
# name, and every spelling from its abbreviation to its full name runs it;
# every registered name is documented.
def documented_ex(text)
  specs = []
  inside = false
  text.each_line do |line|
    if line.start_with?("## ")
      inside = line.strip == "## Ex commands"
      next
    end
    next unless inside && line.start_with?("| `:")
    cell = line.split("|")[1]
    spans = cell.split("`")
    k = 1
    while k < spans.length
      spec = spans[k].split(" ")[0]
      spec = spec[1, spec.length - 1]
      spec = spec[0, spec.length - 1] if spec.end_with?("!")
      specs << spec unless specs.include?(spec)
      k += 2
    end
  end
  specs
end

table = Carat::Doubles::EditorHarness.default(Carat::Doubles::MemoryFiles.new, 10, 40).assembly.commands
specs = documented_ex(File.read("docs/compatibility.md"))
wrong = []
specs.each do |spec|
  name = D::ExName.parse(spec)
  if spec.include?("[") || table.names.include?(spec)
    len = name.short.length
    while len <= name.full.length
      typed = name.full[0, len]
      handler = table.find(typed)
      found = handler.nil? ? "nothing" : handler.name.full
      wrong << "#{spec}: #{typed} runs #{found}" unless found == name.full
      len += 1
    end
  elsif table.find(spec).nil?
    # A bang form such as :x! documents an abbreviation of a longer name.
    wrong << "#{spec}: runs nothing"
  end
end
t.assert_equal([], wrong, "every documented spelling from the abbreviation to the full name runs its command")
undocumented = table.names.reject { |n| specs.include?(n) }
t.assert_equal([], undocumented, "every registered ex command is documented")
t.assert_true(specs.include?("vs[plit]") && specs.include?("tabfir[st]") && specs.length >= 25, "the documented commands are read from the table")
t.table([
  ["vsp splits vertically", "vsp", "vsplit"],
  ["spl splits", "spl", "split"],
  ["wr writes", "wr", "write"],
  ["wal writes all", "wal", "wall"],
  ["xi exits", "xi", "xit"],
  ["exi exits", "exi", "exit"],
  ["tabfirs goes to the first tab page", "tabfirs", "tabfirst"],
  ["quita quits all", "quita", "quitall"],
  ["qui quits", "qui", "quit"],
  ["tabne goes to the next tab page", "tabne", "tabnext"],
  ["tabnew opens a tab page", "tabnew", "tabnew"],
  ["tabf is too short", "tabf", ""],
  ["vsplitx is too long", "vsplitx", ""],
  ["tab names nothing", "tab", ""],
  ["ne is not new", "ne", ""]
]) do |typed|
  handler = table.find(typed)
  handler.nil? ? "" : handler.name.full
end

t.finish
