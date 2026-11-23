require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorInsertTest
  def self.editor(text, autoindent, expandtab)
    config = Carat::Doubles::FixedConfig.with("option.autoindent #{autoindent}\noption.expandtab #{expandtab}\noption.tabstop 4\n")
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", text)
    h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 10, cols: 40, plugins: [])
    h.open("a.txt")
    h
  end

  def self.main
    t = Carat::Testing.new("editor_insert")

    # Rows are [label, [text, start, keys], [lines, cursor, mode]], autoindent off.
    t.cases([
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
      h.state.cursor.move_to(Carat::Json.element(input[1], 0), Carat::Json.element(input[1], 1))
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
    h = editor("\tx\n", false, true)
    h.type("A<Tab>")
    t.assert_equal([["\tx   "], [0, 5]], [h.lines, h.cursor], "Expandtab after a tab: the spaces reach the tab stop by screen cell")
    h = editor("\u3042\n", false, true)
    h.type("A<Tab>")
    t.assert_equal([["\u3042  "], [0, 3]], [h.lines, h.cursor], "Expandtab after a wide character: the spaces reach the tab stop by screen cell")
    h = editor("\n", false, false)
    h.type("i<Tab>")
    t.assert_equal([["\t"], [0, 1]], [h.lines, h.cursor], "noexpandtab inserts a tab character")

    # Scenario: No indicator in insert mode.
    # Message row in insert mode (no indicator) and cursor shape.
    h = editor("ab\n", false, true)
    h.type("i")
    t.assert_equal("", h.message_row, "insert mode leaves the message row blank, the status bar pill shows INSERT")
    t.assert_true(h.status_row.include?("INSERT"), "the status bar's pill shows the mode")
    t.assert_equal(:bar, h.frame.cursor_shape, "bar cursor in insert mode")
    h.type("<Esc>")
    t.assert_equal("", h.message_row, "indicator cleared in normal mode")
    t.assert_equal(:block, h.frame.cursor_shape, "block cursor in normal mode")

    # The screen shows the typed text.
    h = editor("ab\n", false, true)
    h.type("ihello ")
    t.assert_equal("  1 hello ab", h.row(0), "typed text appears on the screen")
    t.assert_equal(" INSERT  a.txt ●", h.status_row[0, 16], "the status bar shows the mode and the buffer as modified")

    # Bracketed paste: pasted text is text, never keys. These prove the
    # key-input scenarios "A paste in insert mode runs nothing" and
    # "A paste in normal mode runs nothing".
    h = editor("ab\n", false, true)
    h.type("i")
    h.raw("\e[200~x\e:w!\e[201~")
    t.assert_equal(["x:w!ab"], h.lines, "paste: the Escape is dropped and the colon and the text after it are inserted, not run")
    t.assert_equal(:insert, h.mode, "paste: the pasted Escape does not leave insert mode")
    t.assert_equal([0, 4], h.cursor, "paste: the cursor is after the pasted text")
    t.assert_equal(false, h.quit?, "paste: nothing ran")

    h = editor("ab\n", false, true)
    h.type("i")
    h.raw("\e[200~c")
    h.raw("d\r\nef\t\e[201~")
    t.assert_equal(["cd", "ef\tab"], h.lines, "paste: a paste over two reads, a CRLF breaking the line and a tab inserted")
    h.raw("\e[200~jk\e[201~")
    t.assert_equal(["cd", "ef\tjkab"], h.lines, "paste: pasted text matches no insert-mode binding")

    h = editor("ab\n", false, true)
    h.type("i")
    h.raw("\e[200~日é\e[201~")
    t.assert_equal(["日éab"], h.lines, "paste: multi-byte characters are inserted")
    h.type("<Esc>u")
    t.assert_equal(["ab"], h.lines, "paste: the undo takes the paste back")

    h = editor("ab\n", false, true)
    h.raw("\e[200~dd:q!\r\e[201~")
    t.assert_equal(["ab"], h.lines, "paste: pasted text in normal mode runs no command")
    t.assert_equal(:normal, h.mode, "paste: pasted text in normal mode starts no command line")
    t.assert_equal(false, h.quit?, "paste: pasted text in normal mode does not quit")

    h = editor("ab\n", false, true)
    h.type(":")
    h.raw("\e[200~w\e!\r\e[201~")
    t.assert_equal(:cmdline, h.mode, "paste: a pasted Escape and newline do not leave or run the command line")
    h.type("<Esc>")
    t.assert_equal(:normal, h.mode, "paste: a typed Escape still leaves the command line")

    h = editor("ab\n", false, true)
    h.type("i")
    h.raw("\e[200~\e[201~")
    t.assert_equal(["ab"], h.lines, "paste: an empty paste inserts nothing")
    h.raw("\e[Cc")
    t.assert_equal(["acb"], h.lines, "paste: keys after the paste are keys again, the arrow moving the cursor")

    t.finish
  end
end

EditorInsertTest.main if __FILE__ == $0
