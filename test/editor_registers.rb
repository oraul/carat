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

# The numbered, small delete, black hole, and read-only registers: rows
# are [label, [text, start, keys], lines].
t.table([
  ["register 0 survives a delete", ["a\nb\n", [0, 0], "yyjdd\"0p"], ["a", "a"]],
  ["a named yank leaves register 0", ["a\nb\n", [0, 0], "yyj\"byy\"0p"], ["a", "b", "a"]],
  ["register 1 takes a line delete", ["a\nb\n", [0, 0], "yydd\"1p"], ["b", "a"]],
  ["line deletes shift through the numbered registers", ["a\nb\nc\nx\n", [0, 0], "dddddd\"3p"], ["x", "a"]],
  ["x fills register -", ["ab\nc\n", [0, 0], "xjdd\"-p"], ["ba"]],
  ["a delete across lines uses register 1", ["ab\ncd\n", [0, 1], "vjd\"1P"], ["b", "cda"]],
  ["the black hole takes nothing", ["ab\n", [0, 0], "yl\"_xp"], ["ba"]],
  ["the black hole leaves the numbered registers", ["a\nb\n", [0, 0], "dd\"_dd\"1p"], ["", "a"]],
  ["put the last inserted text", ["\n", [0, 0], "ihi<Esc>\".p"], ["hihi"]],
  ["put the last command line", ["\n", [0, 0], ":w<CR>\":p"], ["w"]],
  ["put the file name", ["\n", [0, 0], "\"%P"], ["a.txt"]],
  ["a digit names a register to write", ["a\nb\n", [0, 0], "\"5yyj\"5p"], ["a", "b", "a"]],
  ["a visual put stores the replaced text as a delete", ["a\nb\n", [0, 0], "yyjVp\"1p"], ["a", "a", "b"]],
  ["a visual yank fills register 0", ["ab\n", [0, 0], "vly$\"0p"], ["abab"]]
]) do |input|
  h = editor(input[0])
  h.state.cursor.move_to(input[1][0], input[1][1])
  h.type(input[2])
  h.lines
end

registers = nil
h = editor("a\nb\nc\nx\n")
h.type("dddddd")
registers = h.assembly.registers
t.assert_equal([["c", true], ["b", true], ["a", true]], [[registers.read("1").text, registers.read("1").linewise?], [registers.read("2").text, registers.read("2").linewise?], [registers.read("3").text, registers.read("3").linewise?]], "three line deletes fill registers 1 to 3")
h = editor("a\nb\n")
h.type("\"add")
t.assert_equal(["a", "a"], [h.assembly.registers.read("a").text, h.assembly.registers.read("1").text], "a named line delete fills register 1 too")
h = editor("ab\n\nc\n")
h.state.cursor.move_to(0, 1)
h.type("d}")
t.assert_equal(["b", true], [h.assembly.registers.read("1").text, h.assembly.registers.read("-").nil?], "a paragraph motion uses register 1 and not register -")

# Read-only registers refuse writes.
h = editor("a\nb\n")
h.type("\".dd")
t.assert_equal([["a", "b"], "E354: Invalid register name: '.'"], [h.lines, h.message], "a delete into . is refused")
h.type("\"%yy")
t.assert_equal("E354: Invalid register name: '%'", h.message, "a yank into % is refused")
h.type("v\":d")
t.assert_equal([["a", "b"], "E354: Invalid register name: ':'", :normal], [h.lines, h.message, h.mode], "a visual delete into : leaves visual mode and is refused")
h.type("\"/cw")
t.assert_equal([["a", "b"], "E354: Invalid register name: '/'", :normal], [h.lines, h.message, h.mode], "a change into / is refused")
h.type("\"_p")
t.assert_equal("E353: Nothing in register _", h.message, "the black hole cannot be put")
h.type("\"/p")
t.assert_equal("E353: Nothing in register /", h.message, "the search register holds nothing yet")

# :registers and :display list the registers that hold text.
h = editor("one\n")
h.type("yy:registers<CR>")
t.assert_equal("Type Name Content\n  l  \"\"   one^J\n  l  \"0   one^J\n  c  \"%   a.txt", h.message, ":registers after a line yank")
t.assert_equal(["  l  \"\"   one^J", "  l  \"0   one^J", "  c  \"%   a.txt", "Press ENTER or type command to continue"], [h.row(6), h.row(7), h.row(8), h.row(9)], "the listing takes the bottom rows over the window")
h.type("<CR>")
t.assert_equal(["", "", "one"], [h.message, h.row(9), h.lines[0]], "Enter dismisses the listing and does nothing else")
t.assert_equal([h.row(4), h.row(4), h.row(4), true], [h.row(5), h.row(6), h.row(7), h.row(8).include?("a.txt")], "the window rows and the status line under the listing are drawn again")
h.type(":di 0<CR>")
t.assert_equal("Type Name Content\n  l  \"0   one^J", h.message, ":display with a name keeps that register")
h.type("x")
t.assert_equal([["ne"], ""], [h.lines, h.message], "another key dismisses the listing and is handled")
h.type("ihi<Esc>:reg .:-<CR>")
t.assert_equal("Type Name Content\n  c  \"-   o\n  c  \".   hi\n  c  \":   di 0", h.message, "the small delete, inserted text, and command line registers are listed")
h = editor("a\nb\n")
h.type("<C-v>jy:reg \"<CR>")
t.assert_equal("Type Name Content\n  b  \"\"   a^Jb", h.message, "a block is listed with its rows")

t.finish
