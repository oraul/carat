require_relative "../carat/test_support"
require_relative "../carat/testing"

t = Carat::Testing.new("editor_repeat")

def editor(text)
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", text)
  h = Carat::Doubles::EditorHarness.default(files, 10, 80)
  h.open("a.txt")
  h
end

# The dot command: rows are [label, [text, start, keys], [lines, cursor]].
t.table([
  ["an operator with a motion", ["one two three\n", [0, 0], "dw."], [["three"], [0, 0]]],
  ["an operator with a text object", ["a (b) (c)\n", [0, 3], "di)f(l."], [["a () ()"], [0, 6]]],
  ["a doubled operator", ["a\nb\nc\nd\n", [0, 0], "dd."], [["c", "d"], [0, 0]]],
  ["a doubled operator with a count", ["a\nb\nc\nd\ne\n", [0, 0], "2dd."], [["e"], [0, 0]]],
  ["an indent", ["a\nb\n", [0, 0], ">>j."], [["  a", "  b"], [1, 2]]],
  ["x", ["abc\n", [0, 0], "x."], [["c"], [0, 0]]],
  ["s with its text", ["abc\n", [0, 0], "sX<Esc>l."], [["XXc"], [0, 1]]],
  ["S with its text", ["a\nb\n", [0, 0], "SX<Esc>j."], [["X", "X"], [1, 0]]],
  ["C with its text", ["ab\ncd\n", [0, 1], "C!<Esc>j."], [["a!", "c!"], [1, 1]]],
  ["D", ["ab\ncd\n", [0, 1], "Dj."], [["a", ""], [1, 0]]],
  ["J", ["a\nb\nc\n", [0, 0], "J."], [["a b c"], [0, 3]]],
  ["p", ["a\n", [0, 0], "yyp."], [["a", "a", "a"], [2, 0]]],
  ["P with a count", ["ab\n", [0, 0], "yl2P."], [["aaaaab"], [0, 2]]],
  ["r", ["abcd\n", [0, 0], "rxl."], [["xxcd"], [0, 1]]],
  ["r with a count", ["abcdef\n", [0, 0], "2rxll."], [["xxcxxf"], [0, 4]]],
  ["~", ["abcd\n", [0, 0], "~."], [["ABcd"], [0, 2]]],
  ["a change with its text", ["one two\n", [0, 0], "cwX<Esc>w."], [["X X"], [0, 2]]],
  ["an insert command", ["a\nb\n", [0, 0], "A!<Esc>j."], [["a!", "b!"], [1, 1]]],
  ["i with its text", ["ab\n", [0, 0], "ix<Esc>."], [["xxab"], [0, 0]]],
  ["an opened line with Enter typed", ["a\n", [0, 0], "ox<CR>y<Esc>."], [["a", "x", "y", "x", "y"], [4, 0]]],
  ["O", ["a\n", [0, 0], "Ox<Esc>."], [["x", "x", "a"], [0, 0]]],
  ["Backspace in the session", ["\n", [0, 0], "iabc<BS><Esc>."], [["aabb"], [0, 2]]],
  ["text after an arrow key is a new change", ["\n", [0, 0], "ia<Right>b<Esc>0."], [["bab"], [0, 0]]],
  ["nothing to repeat", ["abc\n", [0, 1], "."], [["abc"], [0, 1]]],
  ["a yank between", ["abcd\n", [0, 0], "xyl."], [["cd"], [0, 0]]],
  ["a motion between", ["abcd\n", [0, 0], "xl."], [["bd"], [0, 1]]],
  ["undo between", ["abcd\n", [0, 0], "xu."], [["bcd"], [0, 0]]],
  ["an ex command between", ["abcd\n", [0, 0], "x:w<CR>."], [["cd"], [0, 0]]],
  ["U between", ["abcd\n", [0, 0], "xU."], [["bcd"], [0, 0]]],
  ["the original count", ["abcdefg\n", [0, 0], "2x."], [["efg"], [0, 0]]],
  ["a new count replaces it", ["abcdefghij\n", [0, 0], "2x3.."], [["ij"], [0, 0]]],
  ["a count on an operator with a motion", ["a b c d e\n", [0, 0], "dw2."], [["d e"], [0, 0]]],
  ["visual characters on one line", ["abcdef\n", [0, 0], "vld."], [["ef"], [0, 0]]],
  ["visual characters across lines", ["abc\ndef\nghi\njkl\n", [0, 1], "vjd."], [["ai", "jkl"], [0, 1]]],
  ["visual lines", ["a\nb\nc\nd\n", [0, 0], "Vj>jj."], [["  a", "  b", "  c", "  d"], [2, 2]]],
  ["a visual block", ["abc\ndef\n", [0, 0], "<C-v>jd."], [["c", "f"], [0, 0]]],
  ["a visual block to the line ends", ["abc\ndefg\nhi\njklm\n", [0, 0], "<C-v>j$djj."], [["", "", "", ""], [2, 0]]],
  ["a visual block insert", ["ab\ncd\n", [0, 0], "<C-v>jI-<Esc>l."], [["--ab", "--cd"], [0, 1]]],
  ["a visual change", ["abcdef\n", [0, 0], "vlcX<Esc>l."], [["XXef"], [0, 1]]],
  ["a visual case change", ["abcd\n", [0, 0], "vU."], [["Abcd"], [0, 0]]],
  ["a visual replace", ["abcd\n", [0, 0], "vlrxll."], [["xxxx"], [0, 2]]]
]) do |input|
  h = editor(input[0])
  h.state.cursor.move_to(input[1][0], input[1][1])
  h.type(input[2])
  [h.lines, h.cursor]
end

# A named register is reused.
h = editor("one two three\n")
h.type("\"adw.")
t.assert_equal(["three", "two "], [h.lines[0], h.assembly.registers.read("a").text], "the repeat deletes into register a again")

# Numbered registers count up on each repeat.
h = editor("a\nb\nc\nx\n")
h.type("dddddd\"1p..")
t.assert_equal(["x", "c", "b", "a"], h.lines, "\"1p then . . puts registers 1, 2, and 3")
t.assert_equal("\"3", "\"" + h.assembly.last_change.command.register, "the change remembers the last register used")

# The repeat is one undo state.
h = editor("one two\n")
h.type("cwX<Esc>w.u")
t.assert_equal(["X two"], h.lines, "u undoes the whole repeat")

# The "." register holds the text of the last insert session, also after a
# repeat.
h = editor("\n")
h.type("ihi<Esc>.")
t.assert_equal(["hhii", "hi"], [h.lines[0], h.assembly.registers.read(".").text], "the repeat leaves the \".\" register alone")

t.finish
