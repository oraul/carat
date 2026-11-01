require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("editor_grammar")

def editor(text)
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", text)
  h = Carat::Doubles::EditorHarness.default(files, 10, 80)
  h.open("a.txt")
  h
end

# The grammar through the editor: rows are [label, [text, start, keys],
# [lines, cursor, mode]].
t.table([
  ["a count applies to a motion", ["abcdef\n", [0, 0], "3l"], [["abcdef"], [0, 3], :normal]],
  ["an operator then a motion", ["one two\n", [0, 0], "dw"], [["two"], [0, 0], :normal]],
  ["an operator then a text object", ["one two\n", [0, 5], "diw"], [["one "], [0, 3], :normal]],
  ["counts before and after multiply", ["a b c d e f g\n", [0, 0], "2d3w"], [["g"], [0, 0], :normal]],
  ["a count after the operator", ["a b c\n", [0, 0], "d2w"], [["c"], [0, 0], :normal]],
  ["a doubled operator is linewise", ["a\nb\nc\n", [1, 0], "dd"], [["a", "c"], [1, 0], :normal]],
  ["a count on a doubled operator", ["a\nb\nc\n", [0, 0], "2dd"], [["c"], [0, 0], :normal]],
  ["a count between the doubled keys", ["a\nb\nc\n", [0, 0], "d2d"], [["c"], [0, 0], :normal]],
  ["a different operator cancels", ["a\nb\n", [0, 0], "yd"], [["a", "b"], [0, 0], :normal]],
  ["a register prefix with a count", ["a\nb\nc\n", [0, 0], "\"a2dd"], [["c"], [0, 0], :normal]],
  ["an invalid register name drops the prefix", ["ab\n", [0, 0], "\"1x"], [["b"], [0, 0], :normal]],
  ["the unnamed register by name", ["a\nb\n", [0, 0], "\"\"dd"], [["b"], [0, 0], :normal]],
  ["a find motion takes a bound key literally", ["abjk\n", [0, 0], "fj"], [["abjk"], [0, 2], :normal]],
  ["a find motion under an operator", ["ab.cd\n", [0, 0], "df."], [["cd"], [0, 0], :normal]],
  ["escape cancels a pending operator", ["ab\ncd\n", [0, 0], "d<Esc>j"], [["ab", "cd"], [1, 0], :normal]],
  ["escape cancels a pending count", ["abcdef\n", [0, 0], "3<Esc>l"], [["abcdef"], [0, 1], :normal]],
  ["an unbound key discards a count", ["abcdef\n", [0, 0], "3zl"], [["abcdef"], [0, 1], :normal]],
  ["an unbound key in operator-pending mode cancels", ["ab\n", [0, 0], "dzl"], [["ab"], [0, 1], :normal]],
  ["a standalone action takes the count", ["abcdef\n", [0, 0], "3x"], [["def"], [0, 0], :normal]],
  ["a count before an insert action is ignored", ["ab\n", [0, 0], "3i"], [["ab"], [0, 0], :insert]],
  ["an operator then an unbound sequence cancels", ["ab\n", [0, 0], "dil"], [["ab"], [0, 0], :normal]],
  ["change ends in insert mode", ["one two\n", [0, 0], "cw"], [[" two"], [0, 0], :insert]],
  ["a count on a remap", ["ab\n", [0, 0], "2<C-c>"], [["ab"], [0, 0], :normal]]
]) do |input|
  h = editor(input[0])
  h.state.cursor.move_to(input[1][0], input[1][1])
  h.type(input[2])
  [h.lines, h.cursor, h.mode]
end

# Operator-pending mode is visible while the operator waits.
h = editor("ab\n")
h.type("d")
t.assert_equal(:operator_pending, h.mode, "an operator enters operator-pending mode")
t.assert_equal(:block, h.frame.cursor_shape, "the cursor stays a block while pending")
h.type("w")
t.assert_equal(:normal, h.mode, "the motion returns to normal mode")

# A multi-key binding inside a count: digits are not read while a prefix
# waits, so "g" then "g" with a count goes to that line.
h = editor("a\nb\nc\nd\n")
h.type("3gg")
t.assert_equal([2, 0], h.cursor, "a count before gg")
h.type("g")
t.assert_equal([103], h.state.pending_keys, "g is pending in the keymap")
h.type("1")
t.assert_equal([2, 0], h.cursor, "a digit after a prefix is not a count")
t.assert_equal([], h.state.pending_keys, "the unbound sequence is dropped")

# The pending-keys display.
h = editor("a\nb\nc\n")
h.type("j")
t.assert_equal("", h.message_row, "nothing pending after a motion")
h.type("\"a2d")
t.assert_true(h.message_row.end_with?("\"a2d"), "the keys typed so far show at the right edge")
t.assert_equal(80, h.message_row.length, "they end at the last column")
h.type("3")
t.assert_true(h.message_row.end_with?("\"a2d3"), "a second count joins the display")
h.type("d")
t.assert_equal("", h.message_row, "the display clears when the command completes")
t.assert_equal(["a"], h.lines, "six lines asked, the two below deleted")
h = editor("ab\n")
h.type("g")
t.assert_true(h.message_row.end_with?("g"), "a keymap prefix shows too")
h.type("x")
t.assert_equal("", h.message_row, "an unbound sequence clears the display")
h.type("d")
h.type("<Esc>")
t.assert_equal("", h.message_row, "escape clears the display")
t.assert_equal(:normal, h.mode, "escape returns to normal mode")
h.type("f")
t.assert_true(h.message_row.end_with?("f"), "a find motion waiting for its character shows")
h.type("<Esc>")
t.assert_equal("", h.message_row, "escape cancels the find motion")
t.assert_equal([0, 0], h.cursor, "and nothing moved")
h.type("ix<Esc>")
t.assert_equal("", h.message_row, "insert mode shows nothing pending")

# The command that completes carries its keys.
grammar = Carat::Domain::CommandGrammar.new
grammar.digit(50)
t.assert_equal(:operator, grammar.accept("operator.delete", :operator, [100]), "d after a count is an operator")
t.assert_equal(:complete, grammar.accept("motion.word_forward", :motion, [119]), "w completes it")
command = grammar.take
t.assert_equal([50, 100, 119], command.keys, "the command remembers the keys that formed it")
t.assert_equal("", grammar.typed, "the grammar is empty after take")

t.finish
