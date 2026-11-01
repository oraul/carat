require_relative "../carat/test_support"
require_relative "../carat/testing"

t = Carat::Testing.new("editor_registers")

def editor(text)
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", text)
  h = Carat::Doubles::EditorHarness.default(files, 10, 80)
  h.open("a.txt")
  h
end

# Registers through the editor: rows are [label, [text, start, keys], lines].
t.table([
  ["dd then p", ["a\nb\n", [0, 0], "ddp"], ["b", "a"]],
  ["x then P", ["ab\n", [0, 0], "xP"], ["ab"]],
  ["the latest write wins", ["one two\n", [0, 0], "ywx$p"], ["ne twoo"]],
  ["yank into a and put from a", ["ab cd\n", [0, 0], "\"ayww\"ap"], ["ab cab d"]],
  ["the unnamed register follows a named yank", ["a\nb\n", [0, 0], "\"ayyp"], ["a", "a", "b"]],
  ["an uppercase name reads the lowercase register", ["a\n", [0, 0], "\"ayy\"Ap"], ["a", "a"]],
  ["append lines", ["a\nb\n", [0, 0], "\"ayyj\"Ayy\"ap"], ["a", "b", "a", "b"]],
  ["append characters", ["ab\n", [0, 0], "\"ayll\"Ayl\"aP"], ["aabb"]],
  ["mixed kinds become linewise", ["ab\nc\n", [0, 0], "\"aylj\"Ayyk\"ap"], ["ab", "a", "c", "c"]],
  ["a named delete fills the register", ["one two\n", [0, 0], "\"bdw$\"bp"], ["twoone "]],
  ["a named change fills the register", ["one two\n", [0, 0], "\"ccw<Esc>$\"cp"], [" twoone"]],
  ["registers survive a cancelled command", ["ab\n", [0, 0], "yl\"zdzp"], ["aab"]],
  ["the unnamed register holds only the appended text", ["a\nb\n", [0, 0], "\"ayyj\"Ayyp"], ["a", "b", "b"]]
]) do |input|
  h = editor(input[0])
  h.state.cursor.move_to(input[1][0], input[1][1])
  h.type(input[2])
  h.lines
end

h = editor("ab\n")
h.type("\"bp")
t.assert_equal("E353: Nothing in register b", h.message_row, "an empty named register reports E353")
t.assert_equal(["ab"], h.lines, "and changes nothing")
h.type("\"Bp")
t.assert_equal("E353: Nothing in register B", h.message_row, "the message names the register as typed")

h = editor("one\ntwo\n")
h.type("\"ayy")
entry = h.assembly.registers.read("a")
t.assert_equal(["one", true], [entry.text, entry.linewise?], "a linewise entry stores the line")
h.type("j\"Ayw")
entry = h.assembly.registers.read("a")
t.assert_equal(["one\ntwo", true], [entry.text, entry.linewise?], "appending charwise text to a linewise entry adds a line")
t.assert_equal(["two", false], [h.assembly.registers.read("").text, h.assembly.registers.read("").linewise?], "the unnamed register holds the new text only")
t.assert_equal(entry, h.assembly.registers.read("A"), "A reads the same entry as a")

# A block yank stores a blockwise entry, and p puts it as a block.
h = editor("ab\ncd\n")
h.type("<C-v>jy")
entry = h.assembly.registers.read("")
t.assert_equal(["a\nc", :blockwise], [entry.text, entry.kind], "a block yank stores a blockwise entry")
h.type("$p")
t.assert_equal([["aba", "cdc"], [0, 2]], [h.lines, h.cursor], "p puts the block after the cursor on each row")

t.finish
