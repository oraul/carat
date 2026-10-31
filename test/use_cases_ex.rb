require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("use_cases_ex")
D = Carat::Domain
U = Carat::UseCases

def state_with(lines, path)
  Carat::Domain::EditorState.new(Carat::Domain::Buffer.new(lines, path, "\n"), Carat::Domain::Options.new, 500)
end

# The ex use case over a plugin host with no plugins, whose own state is a
# throwaway: every command here takes its state as an argument.
def build(files)
  open_file = Carat::UseCases::OpenFile.new(files)
  close_window = Carat::UseCases::CloseWindow.new
  plugins = Carat::UseCases::PluginHost.new(state_with([], nil), files, open_file, close_window, Carat::Domain::Keymap.new, " ")
  save_file = Carat::UseCases::SaveFile.new(files, plugins)
  quit = Carat::UseCases::Quit.new(close_window)
  split_window = Carat::UseCases::SplitWindow.new(open_file)
  open_tab = Carat::UseCases::OpenTab.new(open_file)
  ex = Carat::UseCases::ExecuteEx.new(open_file, save_file, quit, split_window, close_window, open_tab, Carat::UseCases::CloseTab.new, Carat::UseCases::SwitchTab.new, plugins)
  plugins.attach(ex)
  ex
end

# Write.
files = Carat::Doubles::MemoryFiles.new
ex = build(files)
s = state_with(["one", "two"], "a.txt")
s.buffer.mark_unsaved
r = ex.call(s, "w")
t.assert_equal([true, "\"a.txt\" 2L, 8B written"], [r.ok, r.message], "write reports the written message")
t.assert_equal("one\ntwo\n", files.get("a.txt"), "write stores the text")
t.assert_equal(false, s.buffer.modified, "write clears the modified flag")
s.buffer.mark_unsaved
r = ex.call(s, "write")
t.assert_equal("\"a.txt\" 2L, 8B written", r.message, "long form writes")
s.buffer.mark_unsaved
r = ex.call(s, "w b.txt")
t.assert_equal("one\ntwo\n", files.get("b.txt"), "write to another path")
t.assert_equal("a.txt", s.buffer.path, "buffer path unchanged by writing elsewhere")
t.assert_equal(true, s.buffer.modified, "writing elsewhere keeps the buffer modified")
unnamed = state_with(["x"], nil)
r = ex.call(unnamed, "w")
t.assert_equal([false, "E32: No file name"], [r.ok, r.message], "write with no path fails")
r = ex.call(unnamed, "w new.txt")
t.assert_equal("new.txt", unnamed.buffer.path, "unnamed buffer adopts the written path")
t.assert_equal(false, unnamed.buffer.modified, "adopting the path clears the modified flag")
files.unwritable << "ro.txt"
ro = state_with(["x"], "ro.txt")
ro.buffer.mark_unsaved
r = ex.call(ro, "w")
t.assert_equal(false, r.ok, "write failure is a failure")
t.assert_equal("E212: Can't open file for writing", r.message[0, 33], "write failure reports E212")
t.assert_equal(true, ro.buffer.modified, "failed write keeps the buffer modified")

# Quit.
s = state_with(["x"], "a.txt")
r = ex.call(s, "q")
t.assert_equal([true, true], [r.ok, s.quit], "quit on a clean buffer ends the editor")
s = state_with(["x"], "a.txt")
s.buffer.mark_unsaved
r = ex.call(s, "q")
t.assert_equal([false, "E37: No write since last change (add ! to override)", false], [r.ok, r.message, s.quit], "quit refused while modified")
r = ex.call(s, "quit")
t.assert_equal(false, s.quit, "long form quit refused too")
r = ex.call(s, "q!")
t.assert_equal(true, s.quit, "forced quit ends the editor")
s = state_with(["x"], "a.txt")
s.buffer.mark_unsaved
ex.call(s, "quit!")
t.assert_equal(true, s.quit, "long form forced quit")

# Write-quit.
files = Carat::Doubles::MemoryFiles.new
ex = build(files)
s = state_with(["hello"], "a.txt")
s.buffer.mark_unsaved
r = ex.call(s, "wq")
t.assert_equal([true, "hello\n", true], [r.ok, files.get("a.txt"), s.quit], "wq writes and quits")
s = state_with(["x"], nil)
r = ex.call(s, "wq")
t.assert_equal([false, "E32: No file name", false], [r.ok, r.message, s.quit], "wq with no file name stays")
files.unwritable << "ro.txt"
s = state_with(["x"], "ro.txt")
r = ex.call(s, "wq")
t.assert_equal(false, s.quit, "wq stays when the write fails")
s = state_with(["x"], "a.txt")
s.buffer.mark_unsaved
r = ex.call(s, "wq other.txt")
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
  s = state_with(["new"], kind == :unnamed ? nil : "a.txt")
  s.buffer.mark_unsaved if kind != :clean
  r = build(files).call(s, text)
  [r.ok, r.message, s.quit, files.get("a.txt"), s.buffer.modified]
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
ex = build(files)
s = state_with(["x"], "a.txt")
r = ex.call(s, "x b.txt")
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
ex = build(files)
s = state_with(["mem"], "a.txt")
r = ex.call(s, "e b.txt")
t.assert_equal([true, "\"b.txt\" 1L, 3B", "b.txt", ["zz"], [0, 0]], [r.ok, r.message, s.buffer.path, s.buffer.lines, s.cursor.to_a], "edit opens another file")
r = ex.call(s, "e new.txt")
t.assert_equal(["\"new.txt\" [New]", "new.txt", [""], false], [r.message, s.buffer.path, s.buffer.lines, s.buffer.modified], "edit starts a new file")
s = state_with(["mem"], "a.txt")
s.buffer.mark_unsaved
r = ex.call(s, "e b.txt")
t.assert_equal([false, "E37: No write since last change (add ! to override)", ["mem"]], [r.ok, r.message, s.buffer.lines], "edit refused while modified")
r = ex.call(s, "e!")
t.assert_equal([["disk"], false], [s.buffer.lines, s.buffer.modified], "forced reload discards changes")
r = ex.call(s, "edit b.txt")
t.assert_equal(["zz"], s.buffer.lines, "long form edit")
s = state_with(["x"], nil)
r = ex.call(s, "e")
t.assert_equal("E32: No file name", r.message, "edit with no path and no argument")
s = state_with(["mem"], "a.txt")
r = ex.call(s, "e")
t.assert_equal(["disk"], s.buffer.lines, "edit without argument reloads")

# Windows and tab pages through the registry, on a state laid out at 23 by
# 80: rows are [label, command line, [ok, message, windows, tab pages]].
E36 = "E36: Not enough room"
def run_window(text)
  files = Carat::Doubles::MemoryFiles.new
  files.put("b.txt", "zz\n")
  s = state_with(["mem"], "a.txt")
  s.tab.layout.arrange(0, 0, 23, 80)
  r = build(files).call(s, text)
  [r.ok, r.message, s.window_count, s.tab_count]
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
s = state_with(["mem"], "a.txt")
s.tab.layout.arrange(0, 0, 3, 80)
r = build(files).call(s, "sp")
t.assert_equal([false, E36, 1], [r.ok, r.message, s.window_count], "sp with two text rows reports E36")

# Windows and the file commands.
files = Carat::Doubles::MemoryFiles.new
files.put("b.txt", "zz\n")
ex = build(files)
s = state_with(["mem"], "a.txt")
s.tab.layout.arrange(0, 0, 23, 80)
ex.call(s, "sp")
s.buffer.mark_unsaved
r = ex.call(s, "q")
t.assert_equal([true, 1, false, true], [r.ok, s.window_count, s.quit, s.buffer.modified], "q with two windows closes one and keeps the buffer")
ex.call(s, "sp b.txt")
s.buffer.mark_unsaved
r = ex.call(s, "close")
t.assert_equal([1, "a.txt", 2], [s.window_count, s.buffer.path, s.buffer_count], "close keeps the modified buffer hidden")
r = ex.call(s, "qa")
t.assert_equal([false, E37, false], [r.ok, r.message, s.quit], "qa is refused by the hidden buffer")
r = ex.call(s, "wa")
t.assert_equal([true, "\"b.txt\" 1L, 3B written", "zz\n", 1], [r.ok, r.message, files.get("b.txt"), s.buffer_count], "wa writes the hidden buffer, reports the write, and drops it once clean")
s = state_with(["mem"], "a.txt")
s.tab.layout.arrange(0, 0, 23, 80)
ex.call(s, "sp b.txt")
s.buffer.mark_unsaved
ex.call(s, "close")
r = ex.call(s, "q!")
t.assert_equal([true, false, "b.txt", 1], [r.ok, s.quit, s.buffer.path, s.buffer_count], "q! on the last window shows the hidden modified buffer and abandons the clean one")
s = state_with(["mem"], "a.txt")
s.tab.layout.arrange(0, 0, 23, 80)
ex.call(s, "sp b.txt")
s.buffer.mark_unsaved
ex.call(s, "close")
r = ex.call(s, "e b.txt")
t.assert_equal([true, "\"b.txt\" 1L, 3B", true, 1], [r.ok, r.message, s.buffer.modified, s.buffer_count], "e brings a hidden buffer back without reading it, dropping the clean one")
s = state_with(["mem"], "a.txt")
s.tab.layout.arrange(0, 0, 23, 80)
ex.call(s, "sp")
s.buffer.mark_unsaved
r = ex.call(s, "wq")
t.assert_equal([true, "mem\n", 1, false], [r.ok, files.get("a.txt"), s.window_count, s.quit], "wq with two windows writes and closes one")
s.buffer.mark_unsaved
r = ex.call(s, "x")
t.assert_equal([true, true], [r.ok, s.quit], "x on the last window writes and quits")
s = state_with(["mem"], "a.txt")
s.tab.layout.arrange(0, 0, 23, 80)
ex.call(s, "tabnew")
ex.call(s, "e b.txt")
s.buffer.mark_unsaved
ex.call(s, "tabfir")
r = ex.call(s, "qa")
t.assert_equal([false, E37], [r.ok, r.message], "qa is refused by a modified buffer in another tab page")
r = ex.call(s, "wqa")
t.assert_equal([true, true, "zz\n"], [r.ok, s.quit, files.get("b.txt")], "wqa writes the other tab page's buffer and quits")

# Unknown and empty.
r = ex.call(s, "foo")
t.assert_equal([false, "E492: Not an editor command: foo"], [r.ok, r.message], "unknown command")
r = ex.call(s, ":foo bar ")
t.assert_equal("E492: Not an editor command: foo bar", r.message, "unknown command keeps its argument text")
r = ex.call(s, "")
t.assert_equal([true, ""], [r.ok, r.message], "empty command does nothing")
r = ex.call(s, "12")
t.assert_equal("E492: Not an editor command: 12", r.message, "a bare number is not a command yet")

# Scratch buffers: never written, skipped by :wa, and not unsaved work.
files = Carat::Doubles::MemoryFiles.new
ex = build(files)
s = state_with(["one"], "a.txt")
scratch = D::Buffer.new(["l"], nil, "\n")
scratch.owner = "hello"
scratch.title = "list"
s.add_buffer(scratch)
s.tab.layout.arrange(0, 0, 23, 80)
side = D::Window.new(scratch)
side.fixed_width = true
s.tab.focus(s.tab.layout.split_edge(side, 20, true))
r = ex.call(s, "w")
t.assert_equal([false, "E382: Cannot write, 'buftype' option is set"], [r.ok, r.message], "write on a scratch buffer reports E382")
scratch.set_lines(0, 1, ["m"])
s.buffer_at(0).set_lines(0, 1, ["two"])
r = ex.call(s, "wa")
t.assert_equal([true, "\"a.txt\" 1L, 4B written", "two\n", true], [r.ok, r.message, files.get("a.txt"), scratch.modified], "write-all skips the scratch buffer and writes the file")
r = ex.call(s, "qa")
t.assert_equal([true, true], [r.ok, s.quit], "quit-all ignores the scratch buffer's changes")
s.quit = false
s.tab.focus(s.tab.layout.leaves[1])
r = ex.call(s, "Nope")
t.assert_equal("E492: Not an editor command: Nope", r.message, "a name no plugin declares is unknown")

t.finish
