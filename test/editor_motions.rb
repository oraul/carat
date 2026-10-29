require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("editor_motions")

def editor(text, scrolloff)
  config = Carat::Doubles::FixedConfig.defaults
  config["options"]["scrolloff"] = scrolloff
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", text)
  h = Carat::Doubles::EditorHarness.new(files, config, 10, 80, [])
  h.open("a.txt")
  h
end

# Cursor motions: rows are [label, [text, start, keys], expected cursor].
# Each key sequence is typed in one session, so a row can chain motions.
t.table([
  # Counts on the foundation motions.
  ["3l moves three columns", ["abcdef\n", [0, 0], "3l"], [0, 3]],
  ["12l takes a two-digit count", ["abcdefghijklmnop\n", [0, 0], "12l"], [0, 12]],
  ["0 without a count goes to column 0", ["abcdef\n", [0, 3], "0"], [0, 0]],
  ["10j takes 0 inside a count", ["a\nb\nc\nd\ne\nf\ng\nh\ni\nj\nk\nl\n", [0, 0], "10j"], [10, 0]],
  ["5h stops at column 0", ["abcdef\n", [0, 2], "5h"], [0, 0]],
  ["9j stops at the last line", ["a\nb\nc\n", [0, 0], "9j"], [2, 0]],
  ["9k stops at the first line", ["a\nb\nc\n", [2, 0], "9k"], [0, 0]],
  ["2G goes to line 2", ["a\nb\nc\nd\ne\n", [0, 0], "2G"], [1, 0]],
  ["9G clamps to the last line", ["a\nb\nc\n", [0, 0], "9G"], [2, 0]],
  ["3gg goes to line 3", ["a\nb\nc\nd\ne\n", [0, 0], "3gg"], [2, 0]],
  ["2$ goes to the end of the next line", ["abc\nde\n", [0, 0], "2$"], [1, 1]],
  # Find and till.
  ["f. finds the next dot", ["a.b.c\n", [0, 0], "f."], [0, 1]],
  ["F. with no dot to the left stays", ["a.b.c\n", [0, 0], "f.F."], [0, 1]],
  ["F. finds the previous dot", ["a.b.c\n", [0, 4], "F."], [0, 3]],
  ["2f. finds the second dot", ["a.b.c\n", [0, 0], "2f."], [0, 3]],
  ["tc stops before c", ["abc\n", [0, 0], "tc"], [0, 1]],
  ["Ta stops after a", ["abc\n", [0, 2], "Ta"], [0, 1]],
  ["fz with no z does nothing", ["abc\n", [0, 0], "fz"], [0, 0]],
  ["3f. past the last dot does nothing", ["a.b.c\n", [0, 0], "3f."], [0, 0]],
  ["; repeats f.", ["a.b.c.d\n", [0, 0], "f.;"], [0, 3]],
  ["; repeats f. again", ["a.b.c.d\n", [0, 0], "f.;;"], [0, 5]],
  [", reverses the repeat", ["a.b.c.d\n", [0, 0], "f.;;,"], [0, 3]],
  ["t. then ; skips the adjacent match", ["a.b.c\n", [0, 0], "t.;"], [0, 2]],
  ["t. alone stays before the dot", ["a.b.c\n", [0, 0], "t."], [0, 0]],
  ["; without a previous find does nothing", ["a.b\n", [0, 0], ";"], [0, 0]],
  ["fj finds a bound key literally", ["abjk\n", [0, 0], "fj"], [0, 2]],
  # Line motions.
  ["+ goes down to the first non-blank", ["abcd\n  ef\ngh\n", [0, 3], "+"], [1, 2]],
  ["- goes up to the first non-blank", ["abcd\n  ef\ngh\n", [0, 3], "+-"], [0, 0]],
  ["2_ goes one line down to the first non-blank", ["ab\n  cd\nef\n", [0, 0], "2_"], [1, 2]],
  ["_ stays on the line", ["  ab\n", [0, 3], "_"], [0, 2]],
  ["+ on the last line does nothing", ["ab\ncd\n", [1, 1], "+"], [1, 1]],
  # Word motions.
  ["w stops at punctuation", ["foo.bar baz\n", [0, 0], "w"], [0, 3]],
  ["w moves past punctuation", ["foo.bar baz\n", [0, 0], "ww"], [0, 4]],
  ["w moves to the next word", ["foo.bar baz\n", [0, 0], "www"], [0, 8]],
  ["W moves over a WORD", ["foo.bar baz\n", [0, 0], "W"], [0, 8]],
  ["w crosses lines to an empty line", ["one two\n\nthree\n", [0, 4], "w"], [1, 0]],
  ["w leaves an empty line", ["one two\n\nthree\n", [0, 4], "ww"], [2, 0]],
  ["w at the end of the buffer goes to the last character", ["one two\n", [0, 4], "w"], [0, 6]],
  ["w on the last character does nothing", ["one two\n", [0, 6], "w"], [0, 6]],
  ["3w counts words", ["a b c d\n", [0, 0], "3w"], [0, 6]],
  ["b goes to the start of the previous word", ["foo.bar baz\n", [0, 10], "b"], [0, 8]],
  ["B goes to the start of the previous WORD", ["foo.bar baz\n", [0, 10], "bB"], [0, 0]],
  ["b crosses lines", ["ab \ncd\n", [1, 0], "b"], [0, 0]],
  ["b stops on an empty line", ["ab\n\ncd\n", [2, 0], "b"], [1, 0]],
  ["e goes to the end of the word", ["foo.bar baz\n", [0, 0], "e"], [0, 2]],
  ["E goes to the end of the WORD", ["foo.bar baz\n", [0, 0], "eE"], [0, 6]],
  ["e at the end of a word goes to the next end", ["ab cd\n", [0, 1], "e"], [0, 4]],
  ["e on the last character does nothing", ["ab cd\n", [0, 4], "e"], [0, 4]],
  ["ge goes to the end of the previous word", ["foo.bar baz\n", [0, 8], "ge"], [0, 6]],
  ["ge again stops at punctuation", ["foo.bar baz\n", [0, 8], "gege"], [0, 3]],
  ["gE goes to the end of the previous WORD", ["foo.bar baz\n", [0, 10], "gE"], [0, 6]],
  ["ge crosses lines", ["ab\ncd\n", [1, 0], "ge"], [0, 1]],
  ["keyword characters include non-ASCII letters", ["éa b\n", [0, 0], "e"], [0, 1]],
  # Sentences and paragraphs.
  [") goes to the next sentence", ["One. Two! Three\n", [0, 0], ")"], [0, 5]],
  [") again", ["One. Two! Three\n", [0, 0], "))"], [0, 10]],
  ["( goes back a sentence", ["One. Two! Three\n", [0, 0], "))("], [0, 5]],
  [") on the last sentence goes to the end", ["One. Two! Three\n", [0, 10], ")"], [0, 14]],
  [") crosses lines", ["One two.\nThree.\n", [0, 0], ")"], [1, 0]],
  [") stops at an empty line", ["One.\n\nTwo.\n", [0, 0], ")"], [1, 0]],
  [") from an empty line goes to the next paragraph", ["One.\n\nTwo.\n", [1, 0], ")"], [2, 0]],
  ["( from inside a sentence goes to its start", ["One. Two.\n", [0, 7], "("], [0, 5]],
  ["( at the start of the buffer does nothing", ["One.\n", [0, 0], "("], [0, 0]],
  ["} goes to the next empty line", ["a\nb\n\nc\nd\n", [0, 0], "}"], [2, 0]],
  ["} without another empty line goes to the end", ["a\nb\n\nc\nd\n", [0, 0], "}}"], [4, 0]],
  ["{ goes back to the empty line", ["a\nb\n\nc\nd\n", [0, 0], "}}{"], [2, 0]],
  ["{ without an empty line goes to the start", ["a\nb\n", [1, 0], "{"], [0, 0]],
  ["2} counts paragraphs", ["a\n\nb\n\nc\n", [0, 0], "2}"], [3, 0]]
]) do |input|
  h = editor(input[0], 0)
  h.state.cursor.move_to(input[1][0], input[1][1])
  h.type(input[2])
  h.cursor
end

# Screen motions in a window of 8 text rows over forty lines: rows are
# [label, [scrolloff, keys to scroll, keys], expected row].
forty = (1..40).map { |n| "line #{n}" }.join("\n") + "\n"
t.table([
  ["H goes to the top of the window", [0, "18G", "H"], 10],
  ["M goes to the middle of the window", [0, "18G", "M"], 13],
  ["L goes to the bottom of the window", [0, "18G", "L"], 17],
  ["3H counts from the top", [0, "18G", "3H"], 12],
  ["2L counts from the bottom", [0, "18G", "2L"], 16],
  ["L honors scrolloff", [2, "", "L"], 5],
  ["H ignores scrolloff at the buffer start", [2, "", "H"], 0],
  ["H honors scrolloff when scrolled", [2, "20G", "H"], 16],
  ["M in a window showing the whole buffer", [0, "", "M"], 3]
]) do |input|
  h = editor(forty, input[0])
  h.type(input[1]) unless input[1].empty?
  h.type(input[2])
  h.cursor[0]
end

h = editor("a\nb\nc\n", 0)
h.type("3G")
h.state.window.height = 0
h.type("M")
t.assert_equal([1, 0], h.cursor, "M before any render treats the buffer as the window")

# The wanted column through the new motions.
h = editor("abcdef\nab\nabcdef\n", 0)
h.type("4l")
h.type("3G")
t.assert_equal([2, 4], h.cursor, "G keeps the wanted column")
h.type("H")
t.assert_equal([0, 4], h.cursor, "H keeps the wanted column")
h.type("+")
h.type("j")
t.assert_equal([2, 0], h.cursor, "+ sets the wanted column")

t.finish
