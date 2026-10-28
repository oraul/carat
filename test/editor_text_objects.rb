require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("editor_text_objects")

def editor(text)
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", text)
  h = Carat::Doubles::EditorHarness.default(files, 10, 80)
  h.open("a.txt")
  h
end

# Text objects under d: rows are [label, [text, start, keys], [lines, cursor]].
t.table([
  # Words.
  ["diw deletes the word", ["one two three\n", [0, 5], "diw"], [["one  three"], [0, 4]]],
  ["daw deletes the word and the blanks after it", ["one two three\n", [0, 5], "daw"], [["one three"], [0, 4]]],
  ["daw at the end takes the blanks before", ["one two\n", [0, 5], "daw"], [["one"], [0, 2]]],
  ["diw on blanks deletes the blanks", ["a   b\n", [0, 2], "diw"], [["ab"], [0, 1]]],
  ["daw on blanks deletes the blanks and the next word", ["a   b c\n", [0, 2], "daw"], [["a c"], [0, 1]]],
  ["d2iw takes the word and the blanks", ["one two three\n", [0, 0], "d2iw"], [["two three"], [0, 0]]],
  ["d2aw takes two words", ["one two three\n", [0, 0], "d2aw"], [["three"], [0, 0]]],
  ["diW deletes the WORD", ["foo.bar baz\n", [0, 1], "diW"], [[" baz"], [0, 0]]],
  ["daW deletes the WORD and the blanks", ["foo.bar baz\n", [0, 1], "daW"], [["baz"], [0, 0]]],
  ["diw on an empty line does nothing", ["\n", [0, 0], "diw"], [[""], [0, 0]]],
  # Sentences.
  ["dis deletes the sentence", ["One. Two. Three.\n", [0, 6], "dis"], [["One.  Three."], [0, 5]]],
  ["das deletes the sentence and the blanks", ["One. Two. Three.\n", [0, 6], "das"], [["One. Three."], [0, 5]]],
  ["das on the last sentence takes the blanks before", ["One. Two.\n", [0, 6], "das"], [["One."], [0, 3]]],
  ["dis on the first sentence", ["One. Two.\n", [0, 1], "dis"], [[" Two."], [0, 0]]],
  # Paragraphs.
  ["dip deletes the paragraph", ["a\nb\n\nc\n", [0, 0], "dip"], [["", "c"], [0, 0]]],
  ["dap deletes the paragraph and the empty lines after it", ["a\nb\n\nc\n", [0, 0], "dap"], [["c"], [0, 0]]],
  ["dap on the last paragraph takes the empty lines before", ["a\n\nb\nc\n", [2, 0], "dap"], [["a"], [0, 0]]],
  ["dip on empty lines deletes them", ["a\n\n\nb\n", [1, 0], "dip"], [["a", "b"], [1, 0]]],
  ["dap on empty lines takes the next paragraph", ["a\n\nb\nc\n", [1, 0], "dap"], [["a"], [0, 0]]],
  ["d2ap deletes two paragraphs", ["a\n\nb\n\nc\n", [0, 0], "d2ap"], [["c"], [0, 0]]],
  # Brackets.
  ["di( deletes inside the parentheses", ["f(a, (b), c)\n", [0, 6], "di("], [["f(a, (), c)"], [0, 6]]],
  ["da( deletes the parentheses too", ["f(a, (b), c)\n", [0, 6], "da("], [["f(a, , c)"], [0, 5]]],
  ["2di) takes the second enclosing pair", ["f(a, (b), c)\n", [0, 6], "2di)"], [["f()"], [0, 2]]],
  ["dib is di(", ["f(a, (b), c)\n", [0, 6], "dib"], [["f(a, (), c)"], [0, 6]]],
  ["di( with the cursor on the opening bracket", ["f(a, (b), c)\n", [0, 5], "di("], [["f(a, (), c)"], [0, 6]]],
  ["di( with the cursor on the closing bracket", ["f(a, (b), c)\n", [0, 7], "di("], [["f(a, (), c)"], [0, 6]]],
  ["di[ deletes inside square brackets", ["x[1][2]\n", [0, 2], "di["], [["x[][2]"], [0, 2]]],
  ["daB deletes the braces", ["{ a }\n", [0, 2], "daB"], [[""], [0, 0]]],
  ["di< deletes inside angle brackets", ["<a>\n", [0, 1], "di<"], [["<>"], [0, 1]]],
  ["di{ over lines is linewise", ["f {\n  a\n  b\n}\n", [1, 2], "di{"], [["f {", "}"], [1, 0]]],
  ["da{ over lines is charwise", ["f {\n  a\n}\n", [1, 2], "da{"], [["f "], [0, 1]]],
  ["di( with no pair does nothing", ["abc\n", [0, 1], "di("], [["abc"], [0, 1]]],
  ["di( on an empty pair does nothing", ["()\n", [0, 0], "di("], [["()"], [0, 0]]],
  # Quotes.
  ["di\" deletes inside the string", ["say \"hi there\" now\n", [0, 6], "di\""], [["say \"\" now"], [0, 5]]],
  ["da\" deletes the string and the blanks after it", ["say \"hi there\" now\n", [0, 6], "da\""], [["say now"], [0, 4]]],
  ["da\" at the end takes the blanks before", ["say \"hi\"\n", [0, 6], "da\""], [["say"], [0, 2]]],
  ["di' before the string uses the first one", ["say 'hi' now\n", [0, 0], "di'"], [["say '' now"], [0, 5]]],
  ["di\" skips an escaped quote", ["a \"b\\\"c\" d\n", [0, 3], "di\""], [["a \"\" d"], [0, 3]]],
  ["di` deletes inside backticks", ["`ab`\n", [0, 1], "di`"], [["``"], [0, 1]]],
  ["di\" with no string does nothing", ["abc\n", [0, 1], "di\""], [["abc"], [0, 1]]]
]) do |input|
  h = editor(input[0])
  h.state.cursor.move_to(input[1][0], input[1][1])
  h.type(input[2])
  [h.lines, h.cursor]
end

h = editor("abc\n")
h.type("di(")
t.assert_equal(:normal, h.mode, "a missing object returns to normal mode")
t.assert_equal("", h.message_row, "a missing object shows no message")

h = editor("one two\n")
h.type("ciw")
t.assert_equal([[" two"], [0, 0], :insert], [h.lines, h.cursor, h.mode], "ciw ends in insert mode")

h = editor("one two\n")
h.type("yiw")
t.assert_equal("one", h.state.registers.read("").text, "yiw yanks the word")
h.type("$")
h.type("yaw")
t.assert_equal(" two", h.state.registers.read("").text, "yaw at the end yanks the blanks before")
t.assert_equal([0, 3], h.cursor, "yaw moves the cursor to the start of the object")

t.finish
