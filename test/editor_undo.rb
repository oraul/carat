require_relative "../carat/test_support"
require_relative "../carat/testing"

t = Carat::Testing.new("editor_undo")
A = Carat::PluginApi

# A test plugin that records the buffer changes it hears of and, when the
# buffer is written, replaces the first character of rows 0 and 1 in one
# edit request made from that event.
class Fixer < Carat::PluginApi::Plugin
  attr_reader :seen #: Array[String]

  # @rbs @host: Carat::PluginApi::Host?

  #: () -> void
  def initialize
    @host = nil
    @seen = []
  end

  # Returns the manifest.
  # @rbs skip
  def manifest
    Carat::PluginApi::Manifest.new("fixer", "1.0.0", "1.0", { "plugin.fixer.list" => "Open a list" }, {}, { "normal" => { "<leader>tu" => "plugin.fixer.list" } }, ["buffer_change", "buffer_save"], {}, {})
  end

  #: (Carat::PluginApi::Host) -> void
  def activate(host)
    @host = host
  end

  #: (String, Carat::PluginApi::Context) -> void
  def on_action(name, context)
    host = @host
    host.open_scratch("list", "left", 20, ["l0", "l1"], nil) unless host.nil?
  end

  #: (Carat::PluginApi::Event) -> void
  def on_event(event)
    @seen << event.to_line if event.name == "buffer_change"
    host = @host
    return if host.nil? || event.name != "buffer_save"
    host.edit_buffer(0, [A::Edit.new(0, 0, 0, 1, "X"), A::Edit.new(1, 0, 1, 1, "Y")])
  end
end

def editor(text)
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", text)
  h = Carat::Doubles::EditorHarness.default(files, 10, 80)
  h.open("a.txt")
  h
end

# Keys through the editor: rows are [label, [text, start, keys], [lines,
# cursor, message]].
t.table([
  ["u undoes a delete", ["abc\n", [0, 0], "xu"], [["abc"], [0, 0], "1 change; before #1  0 seconds ago"]],
  ["Ctrl-R redoes it", ["abc\n", [0, 0], "xu<C-r>"], [["bc"], [0, 0], "1 change; after #1  0 seconds ago"]],
  ["a count undoes several states", ["abcd\n", [0, 0], "xxx2u"], [["bcd"], [0, 0], "2 changes; before #2  0 seconds ago"]],
  ["a count redoes several states", ["abcd\n", [0, 0], "xxx3u2<C-r>"], [["cd"], [0, 0], "2 changes; after #2  0 seconds ago"]],
  ["nothing to undo", ["abc\n", [0, 0], "u"], [["abc"], [0, 0], "Already at oldest change"]],
  ["nothing to redo", ["abc\n", [0, 0], "x<C-r>"], [["bc"], [0, 0], "Already at newest change"]],
  ["undoing a deleted line", ["a\nb\nc\n", [1, 0], "ddu"], [["a", "b", "c"], [1, 0], "1 more line; before #1  0 seconds ago"]],
  ["redoing it", ["a\nb\nc\n", [1, 0], "ddu<C-r>"], [["a", "c"], [1, 0], "1 line less; after #1  0 seconds ago"]],
  ["undoing three lines", ["a\nb\nc\nd\n", [0, 0], "3ddu"], [["a", "b", "c", "d"], [0, 0], "3 more lines; before #1  0 seconds ago"]],
  ["undoing an opened line", ["ab\ncd\n", [0, 1], "ox<Esc>u"], [["ab", "cd"], [0, 1], "1 line less; before #1  0 seconds ago"]],
  ["an insert session is one state", ["x\n", [0, 0], "oab<Esc>u"], [["x"], [0, 0], "1 line less; before #1  0 seconds ago"]],
  ["undo puts the cursor back", ["abcd\n", [0, 2], "x0u"], [["abcd"], [0, 2], "1 change; before #1  0 seconds ago"]],
  ["undo goes to the first non-blank of a changed line", ["  ab\ncd\n", [0, 3], "xju"], [["  ab", "cd"], [0, 3], "1 change; before #1  0 seconds ago"]],
  ["undoing a whole buffer delete", ["a\n", [0, 0], "ddu"], [["a"], [0, 0], "1 more line; before #1  0 seconds ago"]],
  ["undoing everything typed into an empty buffer", ["\n", [0, 0], "ihi<Esc>u"], [[""], [0, 0], "1 line less; before #1  0 seconds ago"]],
  ["a new branch after undo", ["abc\n", [0, 0], "xu$xu<C-r>"], [["ab"], [0, 1], "1 change; after #2  0 seconds ago"]],
  ["g- reaches the abandoned branch", ["abc\n", [0, 0], "xu$xg-"], [["bc"], [0, 0], "2 changes; after #1  0 seconds ago"]],
  ["g- to the original", ["abc\n", [0, 0], "xu$xg-g-"], [["abc"], [0, 0], "1 change; before #1  0 seconds ago"]],
  ["g+ forward again", ["abc\n", [0, 0], "xu$xg-g-g+g+"], [["ab"], [0, 1], "2 changes; after #2  0 seconds ago"]],
  ["g- at the oldest", ["abc\n", [0, 0], "g-"], [["abc"], [0, 0], "Already at oldest change"]],
  ["g+ at the newest", ["abc\n", [0, 0], "xg+"], [["bc"], [0, 0], "Already at newest change"]],
  ["a count on g-", ["abcd\n", [0, 0], "xxx2g-"], [["bcd"], [0, 0], "2 changes; before #2  0 seconds ago"]],
  ["U after two changes", ["abcd\n", [0, 0], "xxU"], [["abcd"], [0, 0], ""]],
  ["U undoes U", ["abcd\n", [0, 0], "xxUU"], [["cd"], [0, 0], ""]],
  ["u undoes U", ["abc\n", [0, 0], "xUu"], [["bc"], [0, 0], "1 change; before #2  0 seconds ago"]],
  ["U puts the cursor where the run started", ["abcd\n", [0, 2], "xhxU"], [["abcd"], [0, 2], ""]],
  ["U with nothing saved", ["abc\n", [0, 0], "U"], [["abc"], [0, 0], ""]],
  ["an arrow key in insert mode splits the state", ["x\n", [0, 0], "ia<Right>b<Esc>u"], [["ax"], [0, 1], "1 change; before #2  0 seconds ago"]],
  ["a visual block insert is one state", ["ab\ncd\n", [0, 0], "<C-v>jI-<Esc>u"], [["ab", "cd"], [0, 0], "2 changes; before #1  0 seconds ago"]],
  ["a visual delete is one state", ["abc\ndef\n", [0, 0], "vjdu"], [["abc", "def"], [0, 0], "1 more line; before #1  0 seconds ago"]],
  [":undo undoes one state", ["abc\n", [0, 0], "xx:undo<CR>"], [["bc"], [0, 0], "1 change; before #2  0 seconds ago"]],
  [":u N goes to a state", ["abcd\n", [0, 0], "xxx:u 1<CR>"], [["bcd"], [0, 0], "2 changes; after #1  0 seconds ago"]],
  [":undo 0 goes to the original", ["abc\n", [0, 0], "xx:undo 0<CR>"], [["abc"], [0, 0], "2 changes; before #1  0 seconds ago"]],
  [":undo N not found", ["abc\n", [0, 0], "xx:undo 7<CR>"], [["c"], [0, 0], "E830: Undo number 7 not found"]],
  [":undo with a bad argument", ["abc\n", [0, 0], "x:undo x<CR>"], [["bc"], [0, 0], "E474: Invalid argument"]],
  [":redo", ["abc\n", [0, 0], "xu:red<CR>"], [["bc"], [0, 0], "1 change; after #1  0 seconds ago"]],
  [":earlier and :later", ["abcd\n", [0, 0], "xxx:earlier 2<CR>:later<CR>"], [["cd"], [0, 0], "1 change; after #2  0 seconds ago"]],
  [":ea with no count", ["abcd\n", [0, 0], "xx:ea<CR>"], [["bcd"], [0, 0], "1 change; before #2  0 seconds ago"]],
  [":lat at the newest", ["abcd\n", [0, 0], "x:lat 3<CR>"], [["bcd"], [0, 0], "Already at newest change"]],
  [":earlier with a time", ["abc\n", [0, 0], "x:earlier 10s<CR>"], [["bc"], [0, 0], "Not implemented: :earlier 10s"]],
  [":later with a file count", ["abc\n", [0, 0], "x:later 1f<CR>"], [["bc"], [0, 0], "Not implemented: :later 1f"]],
  [":earlier with a bad argument", ["abc\n", [0, 0], "x:earlier x<CR>"], [["bc"], [0, 0], "E475: Invalid argument: x"]],
  ["the dot repeat is one state", ["one two\n", [0, 0], "cwX<Esc>w.u"], [["X two"], [0, 2], "1 change; before #2  0 seconds ago"]]
]) do |input|
  h = editor(input[0])
  h.state.cursor.move_to(input[1][0], input[1][1])
  h.type(input[2])
  [h.lines, h.cursor, h.message]
end

# The time in the message is how long ago the state was made.
h = editor("abc\n")
h.type("x")
h.clock.advance(5.0)
h.type("u")
t.assert_equal("1 change; before #1  5 seconds ago", h.message, "the message counts the seconds since the change")
h.clock.advance(-4.0)
h.type("<C-r>")
t.assert_equal("1 change; after #1  1 second ago", h.message, "one second is singular")

# :undolist lists the leaves.
h = editor("abc\n")
h.type(":undolist<CR>")
t.assert_equal("Nothing to undo", h.message, ":undolist before any change")
h.type("xu$x:undol<CR>")
t.assert_equal("number changes  when               saved\n     1       1  0 seconds ago\n     2       1  0 seconds ago", h.message, "two branches are two leaves")
h.type("<CR>")
h.type(":w<CR>x:undolist<CR>")
t.assert_equal("number changes  when               saved\n     1       1  0 seconds ago\n     3       2  0 seconds ago", h.message, "the write is on state 2, which is no leaf")
h.type("<CR>u:undolist<CR>")
t.assert_equal("number changes  when               saved\n     1       1  0 seconds ago\n     3       2  0 seconds ago", h.message, "undo keeps the leaves")
h.type("<CR>:undo 2<CR>a<Esc>:undolist<CR>")
t.assert_equal("number changes  when               saved\n     1       1  0 seconds ago\n     3       2  0 seconds ago", h.message, "an empty insert session makes no state")

# The modified flag follows undo and redo back to the write.
h = editor("abc\n")
h.type("x:w<CR>x")
t.assert_true(h.buffer.modified?, "an edit after the write modifies the buffer")
h.type("u")
t.assert_true(!h.buffer.modified?, "undo back to the write clears the flag")
h.type("<C-r>")
t.assert_true(h.buffer.modified?, "redo away from it sets it again")
h = editor("abc\n")
h.type("xu")
t.assert_true(!h.buffer.modified?, "undo to the loaded text clears the flag")

# undolevels limits the history.
files = Carat::Doubles::MemoryFiles.new
files.put("a.txt", "abcdef\n")
config = Carat::Doubles::FixedConfig.defaults
config["options"]["undolevels"] = 3
h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 10, cols: 80, plugins: [])
h.open("a.txt")
h.type("xxxxx10u")
t.assert_equal(["cdef"], h.lines, "three levels keep the last three changes")

# Undo on a large buffer: the state holds the buffer's own line strings.
big = []
i = 0
while i < 100_000
  big << "line #{i}"
  i += 1
end
h = editor(big.join("\n") + "\n")
h.type("50000Gx")
tree = h.buffer.undo
change = tree.transaction_at(tree.slot(1)).record_at(0)
t.assert_equal([1, 1], [change.removed.length, change.inserted.length], "a change on a large buffer keeps one removed and one inserted line")
t.assert_true(change.inserted[0].equal?(h.buffer.lines[49_999]), "the inserted line is the buffer's own")
h.type("u")
t.assert_true(h.buffer.lines[49_999].equal?(change.removed[0]), "undo puts the removed string itself back")

# Plugins: an undo is a buffer_change with its rows, and an edit request
# from an event is undone in one step.
files = Carat::Doubles::MemoryFiles.new
files.put("a.txt", "a\nb\nc\n")
fixer = Fixer.new
h = Carat::Doubles::EditorHarness.with_plugins(files, 10, 80, [fixer])
h.open("a.txt")
h.type("jdd")
count = fixer.seen.length
h.type("u")
t.assert_equal([count + 1, "buffer_change b2 w1 a.txt 1,0 -0 +1"], [fixer.seen.length, fixer.seen[fixer.seen.length - 1]], "the undo reaches the plugin as one buffer_change with its rows")
h.type(":w<CR>")
t.assert_equal(["X", "Y", "c"], h.lines, "the plugin edits two rows after the write")
h.type("u")
t.assert_equal([["a", "b", "c"], false], [h.lines, h.buffer.modified?], "one u undoes the whole request and returns to the write")
h.type("<C-r>")
t.assert_equal(["X", "Y", "c"], h.lines, "one Ctrl-R redoes it")

# A plugin's scratch buffer keeps no history.
h.type(" tu")
t.assert_equal([true, ["l0", "l1"]], [h.buffer.scratch?, h.lines], "the plugin's list is focused")
h.type("xu")
t.assert_equal([["0", "l1"], "Already at oldest change"], [h.lines, h.message], "u in a plugin's buffer undoes nothing")

t.finish
