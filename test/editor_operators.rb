require_relative "../carat/test_support"
require_relative "../carat/testing"

t = Carat::Testing.new("editor_operators")

# An editor over the default options with autoindent on, shiftwidth 2,
# tabstop 2, and expandtab on, as config/default.json sets them.
def editor(text)
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", text)
  h = Carat::Doubles::EditorHarness.default(files, 10, 80)
  h.open("a.txt")
  h
end

def editor_with(text, options)
  config = Carat::Doubles::FixedConfig.defaults
  options.each { |key, value| config["options"][key] = value }
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", text)
  h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 10, cols: 80, plugins: [])
  h.open("a.txt")
  h
end

# Operators over motions, doubled, and the standalone commands: rows are
# [label, [text, start, keys], [lines, cursor, mode]].
t.table([
  # Delete over motions.
  ["dw deletes to the next word", ["one two\n", [0, 0], "dw"], [["two"], [0, 0], :normal]],
  ["de deletes to the end of the word", ["one two\n", [0, 0], "de"], [[" two"], [0, 0], :normal]],
  ["db deletes back to the word start", ["one two\n", [0, 4], "db"], [["two"], [0, 0], :normal]],
  ["dj deletes two lines", ["a\nb\nc\n", [0, 0], "dj"], [["c"], [0, 0], :normal]],
  ["dk deletes this line and the one above", ["a\nb\nc\n", [1, 0], "dk"], [["c"], [0, 0], :normal]],
  ["df. deletes through the dot", ["ab.cd\n", [0, 0], "df."], [["cd"], [0, 0], :normal]],
  ["dt. deletes up to the dot", ["ab.cd\n", [0, 0], "dt."], [[".cd"], [0, 0], :normal]],
  ["dF. deletes back through the dot", ["ab.cd\n", [0, 4], "dF."], [["abd"], [0, 2], :normal]],
  ["d$ deletes to the end of the line", ["abc\n", [0, 1], "d$"], [["a"], [0, 0], :normal]],
  ["d0 deletes to the start of the line", ["abc\n", [0, 2], "d0"], [["c"], [0, 0], :normal]],
  ["d^ deletes to the first non-blank", ["  abc\n", [0, 4], "d^"], [["  c"], [0, 2], :normal]],
  ["dG deletes to the end of the buffer", ["a\nb\nc\n", [1, 0], "dG"], [["a"], [0, 0], :normal]],
  ["dgg deletes to the start of the buffer", ["a\nb\nc\n", [1, 0], "dgg"], [["c"], [0, 0], :normal]],
  ["dl at the last character deletes it", ["abc\n", [0, 2], "dl"], [["ab"], [0, 1], :normal]],
  ["dh at column 0 deletes nothing", ["abc\n", [0, 0], "dh"], [["abc"], [0, 0], :normal]],
  ["dj on the last line deletes nothing", ["a\nb\n", [1, 0], "dj"], [["a", "b"], [1, 0], :normal]],
  ["dw on the last word of the buffer deletes it", ["one two\n", [0, 4], "dw"], [["one "], [0, 3], :normal]],
  ["dw on the last character deletes it", ["ab\n", [0, 1], "dw"], [["a"], [0, 0], :normal]],
  ["de at the last character deletes it", ["ab\n", [0, 1], "de"], [["a"], [0, 0], :normal]],
  ["dw on an empty line deletes it", ["\nab\n", [0, 0], "dw"], [["ab"], [0, 0], :normal]],
  ["d} deletes whole lines from the line start", ["a\nb\n\nc\n", [0, 0], "d}"], [["", "c"], [0, 0], :normal]],
  ["d} from inside a line keeps the start", ["ab\ncd\n\ne\n", [0, 1], "d}"], [["a", "", "e"], [0, 0], :normal]],
  ["dw at the end of a line stays on the line", ["one two\nthree\n", [0, 4], "dw"], [["one ", "three"], [0, 3], :normal]],
  ["d) deletes the sentence", ["One. Two.\n", [0, 0], "d)"], [["Two."], [0, 0], :normal]],
  ["d) on the last sentence deletes to the end", ["One. Two.\n", [0, 5], "d)"], [["One. "], [0, 4], :normal]],
  ["d+ deletes two lines", ["a\nb\nc\n", [0, 0], "d+"], [["c"], [0, 0], :normal]],
  ["dH deletes to the top of the window", ["a\nb\nc\n", [1, 0], "dH"], [["c"], [0, 0], :normal]],
  ["dL deletes to the bottom of the window", ["a\nb\nc\n", [1, 0], "dL"], [["a"], [0, 0], :normal]],
  ["dM deletes to the middle of the window", ["a\nb\nc\n", [0, 0], "dM"], [["c"], [0, 0], :normal]],
  ["2dw with a count deletes two words", ["a b c\n", [0, 0], "2dw"], [["c"], [0, 0], :normal]],
  ["d2w with the count after", ["a b c\n", [0, 0], "d2w"], [["c"], [0, 0], :normal]],
  ["2d3w multiplies the counts", ["a b c d e f g\n", [0, 0], "2d3w"], [["g"], [0, 0], :normal]],
  # Doubled operators.
  ["dd deletes the line", ["a\nb\nc\n", [1, 0], "dd"], [["a", "c"], [1, 0], :normal]],
  ["dd goes to the first non-blank", ["a\n  b\n", [0, 0], "dd"], [["  b"], [0, 2], :normal]],
  ["dd on the last line", ["a\nb\n", [1, 0], "dd"], [["a"], [0, 0], :normal]],
  ["dd on the only line", ["abc\n", [0, 1], "dd"], [[""], [0, 0], :normal]],
  ["2dd deletes two lines", ["a\nb\nc\n", [0, 0], "2dd"], [["c"], [0, 0], :normal]],
  ["d2d counts after the first key", ["a\nb\nc\n", [0, 0], "d2d"], [["c"], [0, 0], :normal]],
  ["2d2d multiplies", ["a\nb\nc\nd\ne\n", [0, 0], "2d2d"], [["e"], [0, 0], :normal]],
  ["9dd clamps to the buffer", ["a\nb\nc\n", [1, 0], "9dd"], [["a"], [0, 0], :normal]],
  ["yd cancels", ["a\nb\n", [0, 0], "yd"], [["a", "b"], [0, 0], :normal]],
  # Change.
  ["cw changes the word only", ["one two\n", [0, 0], "cw"], [[" two"], [0, 0], :insert]],
  ["cw on the last character of a word changes it", ["one two\n", [0, 2], "cw"], [["on two"], [0, 2], :insert]],
  ["2cw changes two words", ["one two three\n", [0, 0], "2cw"], [[" three"], [0, 0], :insert]],
  ["cW changes the WORD", ["foo.bar baz\n", [0, 0], "cW"], [[" baz"], [0, 0], :insert]],
  ["cw on blanks changes the blanks", ["a  b\n", [0, 1], "cw"], [["ab"], [0, 1], :insert]],
  ["ce changes to the end of the word", ["one two\n", [0, 0], "ce"], [[" two"], [0, 0], :insert]],
  ["cc keeps the indent with autoindent", ["  ab\nc\n", [0, 0], "cc"], [["  ", "c"], [0, 2], :insert]],
  ["c$ changes to the end of the line", ["abc\n", [0, 1], "c$"], [["a"], [0, 1], :insert]],
  ["ciw changes the word", ["one two three\n", [0, 5], "ciw"], [["one  three"], [0, 4], :insert]],
  ["cj changes two lines", ["  a\nb\nc\n", [0, 1], "cj"], [["  ", "c"], [0, 2], :insert]],
  # Yank leaves the buffer alone.
  ["yw leaves the cursor", ["one two\n", [0, 0], "yw"], [["one two"], [0, 0], :normal]],
  ["yb moves the cursor to the start", ["one two\n", [0, 4], "yb"], [["one two"], [0, 0], :normal]],
  ["yy leaves the cursor", ["ab\ncd\n", [1, 1], "yy"], [["ab", "cd"], [1, 1], :normal]],
  ["yk moves up keeping the column", ["ab\ncd\n", [1, 1], "yk"], [["ab", "cd"], [0, 1], :normal]],
  ["yj leaves the cursor", ["ab\ncd\n", [0, 1], "yj"], [["ab", "cd"], [0, 1], :normal]],
  ["y$ leaves the cursor", ["abc\n", [0, 1], "y$"], [["abc"], [0, 1], :normal]],
  # Shift.
  [">> indents by shiftwidth", ["ab\n", [0, 1], ">>"], [["  ab"], [0, 2], :normal]],
  ["<< dedents", ["    ab\n", [0, 5], "<<"], [["  ab"], [0, 2], :normal]],
  ["<< at column 0 stays", ["ab\n", [0, 1], "<<"], [["ab"], [0, 0], :normal]],
  ["<< below shiftwidth goes to column 0", [" ab\n", [0, 1], "<<"], [["ab"], [0, 0], :normal]],
  ["3>> indents three lines", ["a\nb\nc\nd\n", [0, 0], "3>>"], [["  a", "  b", "  c", "d"], [0, 2], :normal]],
  [">j indents two lines", ["a\nb\nc\nd\n", [0, 0], ">j"], [["  a", "  b", "c", "d"], [0, 2], :normal]],
  [">ip indents the paragraph", ["a\nb\n\nc\n", [0, 0], ">ip"], [["  a", "  b", "", "c"], [0, 2], :normal]],
  [">> leaves empty lines empty", ["\na\n", [0, 0], "2>>"], [["", "  a"], [0, 0], :normal]],
  ["<k dedents two lines", ["  a\n  b\n", [1, 0], "<k"], [["a", "b"], [0, 0], :normal]],
  # Standalone commands.
  ["x deletes the character", ["abc\n", [0, 1], "x"], [["ac"], [0, 1], :normal]],
  ["x at the end moves left", ["abc\n", [0, 2], "x"], [["ab"], [0, 1], :normal]],
  ["3x stops at the line end", ["abcd\n", [0, 1], "3x"], [["a"], [0, 0], :normal]],
  ["x on an empty line does nothing", ["\n", [0, 0], "x"], [[""], [0, 0], :normal]],
  ["s substitutes the character", ["abc\n", [0, 1], "s"], [["ac"], [0, 1], :insert]],
  ["2s substitutes two characters", ["abc\n", [0, 1], "2s"], [["a"], [0, 1], :insert]],
  ["S substitutes the line keeping the indent", ["  ab\nc\n", [0, 3], "S"], [["  ", "c"], [0, 2], :insert]],
  ["C changes to the end of the line", ["abc\n", [0, 1], "C"], [["a"], [0, 1], :insert]],
  ["2C changes to the end of the next line", ["abc\nde\nf\n", [0, 1], "2C"], [["a", "f"], [0, 1], :insert]],
  ["D deletes to the end of the line", ["abc\n", [0, 1], "D"], [["a"], [0, 0], :normal]],
  ["2D deletes to the end of the next line", ["abc\nde\nf\n", [0, 1], "2D"], [["a", "f"], [0, 0], :normal]],
  ["Y then p puts the rest of the line", ["abc\n", [0, 1], "Yp"], [["abbcc"], [0, 3], :normal]],
  # Join.
  ["J joins with one space", ["ab\n  cd\n", [0, 0], "J"], [["ab cd"], [0, 2], :normal]],
  ["3J joins three lines", ["a\nb\nc\n", [0, 0], "3J"], [["a b c"], [0, 3], :normal]],
  ["J adds no space before a closing parenthesis", ["f(\n)\n", [0, 0], "J"], [["f()"], [0, 2], :normal]],
  ["J adds no space after a blank", ["ab \ncd\n", [0, 0], "J"], [["ab cd"], [0, 3], :normal]],
  ["J with an empty next line", ["ab\n\n", [0, 0], "J"], [["ab"], [0, 1], :normal]],
  ["J on the last line does nothing", ["a\nb\n", [1, 0], "J"], [["a", "b"], [1, 0], :normal]],
  ["9J joins what exists", ["a\nb\nc\n", [1, 0], "9J"], [["a", "b c"], [1, 1], :normal]],
  # Put.
  ["p puts charwise text after the cursor", ["ab cd\n", [0, 0], "ywp"], [["aab b cd"], [0, 3], :normal]],
  ["P puts charwise text before the cursor", ["ab cd\n", [0, 0], "ywP"], [["ab ab cd"], [0, 2], :normal]],
  ["3p repeats the text", ["ab\n", [0, 0], "yl3p"], [["aaaab"], [0, 3], :normal]],
  ["p puts lines below", ["  a\nb\n", [0, 0], "yyp"], [["  a", "  a", "b"], [1, 2], :normal]],
  ["P puts lines above", ["  a\nb\n", [0, 0], "yyP"], [["  a", "  a", "b"], [0, 2], :normal]],
  ["2p repeats the lines", ["a\nb\n", [0, 0], "yy2p"], [["a", "a", "a", "b"], [1, 0], :normal]],
  ["p after a multi-line charwise delete", ["ab\ncd\n", [0, 1], "dep"], [["ab", "cd"], [0, 1], :normal]],
  ["p on an empty line", ["\n", [0, 0], "ixy<Esc>0xp"], [["yx"], [0, 1], :normal]],
  ["dd then p moves the line down", ["a\nb\n", [0, 0], "ddp"], [["b", "a"], [1, 0], :normal]],
  ["x then P puts it back", ["ab\n", [0, 0], "xP"], [["ab"], [0, 0], :normal]],
  ["r replaces one character", ["abc\n", [0, 1], "rx"], [["axc"], [0, 1], :normal]],
  ["r with a count", ["abcd\n", [0, 0], "3rx"], [["xxxd"], [0, 2], :normal]],
  ["r with too few characters", ["abc\n", [0, 0], "5rx"], [["abc"], [0, 0], :normal]],
  ["r on an empty line", ["\n", [0, 0], "rx"], [[""], [0, 0], :normal]],
  ["r cancelled by Escape", ["abc\n", [0, 0], "r<Esc>"], [["abc"], [0, 0], :normal]],
  ["~ toggles and moves", ["abC\n", [0, 0], "~"], [["AbC"], [0, 1], :normal]],
  ["~ with a count past the end", ["abC\n", [0, 1], "5~"], [["aBc"], [0, 2], :normal]],
  ["~ on an empty line", ["\n", [0, 0], "~"], [[""], [0, 0], :normal]]
]) do |input|
  h = editor(input[0])
  h.state.cursor.move_to(input[1][0], input[1][1])
  h.type(input[2])
  [h.lines, h.cursor, h.mode]
end

# Options that change an operator: rows are [label, [text, start, options, keys], [lines, cursor]].
t.table([
  ["cc without autoindent", ["  ab\nc\nd\n", [0, 0], { "autoindent" => false }, "2cc"], [["", "d"], [0, 0]]],
  [">> with tabs", ["ab\n", [0, 0], { "expandtab" => false, "shiftwidth" => 4, "tabstop" => 8 }, ">>"], [["    ab"], [0, 4]]],
  [">> twice with tabs makes a tab", ["ab\n", [0, 0], { "expandtab" => false, "shiftwidth" => 4, "tabstop" => 8 }, ">>>>"], [["\tab"], [0, 1]]],
  ["<< with tabs", ["\t  ab\n", [0, 0], { "expandtab" => false, "shiftwidth" => 4, "tabstop" => 8 }, "<<"], [["      ab"], [0, 6]]],
  [">> with shiftwidth 0 uses tabstop", ["ab\n", [0, 0], { "shiftwidth" => 0, "tabstop" => 4 }, ">>"], [["    ab"], [0, 4]]]
]) do |input|
  h = editor_with(input[0], input[2])
  h.state.cursor.move_to(input[1][0], input[1][1])
  h.type(input[3])
  [h.lines, h.cursor]
end

# Messages and the modified flag.
h = editor("ab\n")
h.type("p")
t.assert_equal("E353: Nothing in register \"", h.message_row, "p from an empty register reports E353")
t.assert_equal(["ab"], h.lines, "an empty put changes nothing")
t.assert_true(!h.buffer.modified?, "an empty put does not modify the buffer")
h.type("yy")
t.assert_true(!h.buffer.modified?, "a yank does not modify the buffer")
h.type("dd")
t.assert_true(h.buffer.modified?, "a delete modifies the buffer")

# The register holds the deleted text with its kind.
h = editor("one two\nthree\n")
h.type("dw")
t.assert_equal(["one ", false], [h.assembly.registers.read("").text, h.assembly.registers.read("").linewise?], "dw stores charwise text")
h.type("dd")
t.assert_equal(["two", true], [h.assembly.registers.read("").text, h.assembly.registers.read("").linewise?], "dd stores a line")
h.type("cc")
t.assert_equal("three", h.assembly.registers.read("").text, "cc stores the changed line")

t.finish
