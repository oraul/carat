require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("editor_insert")

def editor(text, autoindent, expandtab)
  config = Carat::Doubles::FixedConfig.defaults
  config["options"]["autoindent"] = autoindent
  config["options"]["expandtab"] = expandtab
  config["options"]["tabstop"] = 4
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", text)
  h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 10, cols: 40, plugins: [])
  h.open("a.txt")
  h
end

# Rows are [label, [text, start, keys], [lines, cursor, mode]], autoindent off.
t.table([
  ["typing a word", ["ab\n", [0, 0], "ixy"], [["xyab"], [0, 2], :insert]],
  ["typing a non-ascii character", ["ab\n", [0, 0], "aé"], [["aéb"], [0, 2], :insert]],
  ["right reaches the end of the line", ["ab\n", [0, 1], "i<Right><Right>"], [["ab"], [0, 2], :insert]],
  ["left stops at 0", ["ab\n", [0, 1], "i<Left><Left>"], [["ab"], [0, 0], :insert]],
  ["enter splits the line", ["ab\n", [0, 1], "i<CR>"], [["a", "b"], [1, 0], :insert]],
  ["enter at the end opens a line", ["ab\n", [0, 1], "A<CR>"], [["ab", ""], [1, 0], :insert]],
  ["backspace in a line", ["abc\n", [0, 2], "i<BS>"], [["ac"], [0, 1], :insert]],
  ["backspace joins lines", ["ab\ncd\n", [1, 0], "i<BS>"], [["abcd"], [0, 2], :insert]],
  ["backspace at the start of the buffer", ["ab\n", [0, 0], "i<BS>"], [["ab"], [0, 0], :insert]],
  ["delete in a line", ["abc\n", [0, 1], "i<Del>"], [["ac"], [0, 1], :insert]],
  ["delete at the end of a line joins", ["ab\ncd\n", [0, 1], "A<Del>"], [["abcd"], [0, 2], :insert]],
  ["delete at the end of the buffer", ["ab\n", [0, 1], "A<Del>"], [["ab"], [0, 2], :insert]],
  ["escape after typing", ["\n", [0, 0], "iab<Esc>"], [["ab"], [0, 1], :normal]],
  ["escape at column 0", ["ab\n", [0, 0], "i<Esc>"], [["ab"], [0, 0], :normal]],
  ["down keeps the insert column", ["abc\nxyz\n", [0, 0], "A<Down>"], [["abc", "xyz"], [1, 3], :insert]],
  ["typing then moving then typing", ["\n", [0, 0], "iab<Left>X"], [["aXb"], [0, 2], :insert]],
  ["unbound control key inserts nothing", ["ab\n", [0, 0], "i<C-g>"], [["ab"], [0, 0], :insert]]
]) do |input|
  h = editor(input[0], false, true)
  h.state.cursor.move_to(input[1][0], input[1][1])
  h.type(input[2])
  [h.lines, h.cursor, h.mode]
end

h = editor("ab\n", false, true)
h.type("ix")
t.assert_true(h.buffer.modified?, "typing marks the buffer modified")

# Autoindent.
h = editor("  ab\n", true, true)
h.type("A<CR>")
t.assert_equal([["  ab", "  "], [1, 2]], [h.lines, h.cursor], "autoindent copies the indent")
h = editor("  ab\n", true, true)
h.type("o")
t.assert_equal([["  ab", "  "], [1, 2]], [h.lines, h.cursor], "o copies the indent with autoindent")
h = editor("  ab\n", false, true)
h.type("o")
t.assert_equal([["  ab", ""], [1, 0]], [h.lines, h.cursor], "o does not indent without autoindent")

# Tab.
h = editor("a\n", false, true)
h.type("a<Tab>")
t.assert_equal([["a   "], [0, 4]], [h.lines, h.cursor], "expandtab inserts spaces to the next tabstop")
h = editor("\n", false, false)
h.type("i<Tab>")
t.assert_equal([["\t"], [0, 1]], [h.lines, h.cursor], "noexpandtab inserts a tab character")

# Mode indicator and cursor shape.
h = editor("ab\n", false, true)
h.type("i")
t.assert_equal("-- INSERT --", h.message_row, "insert indicator shown")
t.assert_equal(:bar, h.frame.cursor_shape, "bar cursor in insert mode")
h.type("<Esc>")
t.assert_equal("", h.message_row, "indicator cleared in normal mode")
t.assert_equal(:block, h.frame.cursor_shape, "block cursor in normal mode")

# The screen shows the typed text.
h = editor("ab\n", false, true)
h.type("ihello ")
t.assert_equal("  1 hello ab", h.row(0), "typed text appears on the screen")
t.assert_equal("a.txt [+]", h.status_row[0, 9], "status line shows the buffer as modified")

t.finish
