require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("use_cases_ex")
D = Carat::Domain
U = Carat::UseCases

def build(files)
  open_file = Carat::UseCases::OpenFile.new(files)
  save_file = Carat::UseCases::SaveFile.new(files)
  Carat::UseCases::ExecuteEx.new(open_file, save_file, Carat::UseCases::Quit.new)
end

def state_with(lines, path)
  Carat::Domain::EditorState.new(Carat::Domain::Buffer.new(lines, path, "\n"), Carat::Domain::Options.new, 500)
end

# Write.
files = Carat::Doubles::MemoryFiles.new
ex = build(files)
s = state_with(["one", "two"], "a.txt")
s.buffer.modified = true
r = ex.call(s, "w")
t.assert_equal([true, "\"a.txt\" 2L, 8B written"], [r.ok, r.message], "write reports the written message")
t.assert_equal("one\ntwo\n", files.get("a.txt"), "write stores the text")
t.assert_equal(false, s.buffer.modified, "write clears the modified flag")
s.buffer.modified = true
r = ex.call(s, "write")
t.assert_equal("\"a.txt\" 2L, 8B written", r.message, "long form writes")
s.buffer.modified = true
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
ro.buffer.modified = true
r = ex.call(ro, "w")
t.assert_equal(false, r.ok, "write failure is a failure")
t.assert_equal("E212: Can't open file for writing", r.message[0, 33], "write failure reports E212")
t.assert_equal(true, ro.buffer.modified, "failed write keeps the buffer modified")

# Quit.
s = state_with(["x"], "a.txt")
r = ex.call(s, "q")
t.assert_equal([true, true], [r.ok, s.quit], "quit on a clean buffer ends the editor")
s = state_with(["x"], "a.txt")
s.buffer.modified = true
r = ex.call(s, "q")
t.assert_equal([false, "E37: No write since last change (add ! to override)", false], [r.ok, r.message, s.quit], "quit refused while modified")
r = ex.call(s, "quit")
t.assert_equal(false, s.quit, "long form quit refused too")
r = ex.call(s, "q!")
t.assert_equal(true, s.quit, "forced quit ends the editor")
s = state_with(["x"], "a.txt")
s.buffer.modified = true
ex.call(s, "quit!")
t.assert_equal(true, s.quit, "long form forced quit")

# Write-quit.
files = Carat::Doubles::MemoryFiles.new
ex = build(files)
s = state_with(["hello"], "a.txt")
s.buffer.modified = true
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
s.buffer.modified = true
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
  s.buffer.modified = kind != :clean
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
s.buffer.modified = true
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

# Unknown and empty.
r = ex.call(s, "foo")
t.assert_equal([false, "E492: Not an editor command: foo"], [r.ok, r.message], "unknown command")
r = ex.call(s, ":foo bar ")
t.assert_equal("E492: Not an editor command: foo bar", r.message, "unknown command keeps its argument text")
r = ex.call(s, "")
t.assert_equal([true, ""], [r.ok, r.message], "empty command does nothing")
r = ex.call(s, "12")
t.assert_equal("E492: Not an editor command: 12", r.message, "a bare number is not a command yet")

t.finish
