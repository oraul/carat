require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorCmdlineTest
  def self.editor(files)
    h = Carat::Doubles::EditorHarness.default(files, 10, 60)
    h.open("a.txt")
    h
  end

  def self.files_with(text)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", text)
    files
  end

  E37 = "E37: No write since last change (add ! to override)"

  def self.main
    t = Carat::Testing.new("editor_cmdline")

    # Entering and editing the command line.
    h = editor(files_with("ab\n"))
    h.type(":")
    t.assert_equal([:cmdline, ":"], [h.mode, h.message_row], "colon enters command-line mode")
    t.assert_equal([9, 1], [h.frame.cursor_row, h.frame.cursor_col], "cursor after the colon")
    h.type("wx<BS>")
    t.assert_equal(":w", h.message_row, "typing and correcting")
    t.assert_equal([9, 2], [h.frame.cursor_row, h.frame.cursor_col], "cursor after the text")
    h.type("<BS><BS>")
    t.assert_equal([:normal, ""], [h.mode, h.message_row], "backspace on an empty command line leaves")
    h.type(":")
    h.type("<BS>")
    t.assert_equal(:normal, h.mode, "backspace on empty returns to normal mode")

    h = editor(files_with("ab\n"))
    h.type("ix<Esc>")
    h.type(":w<Esc>")
    t.assert_equal(:normal, h.mode, "escape discards the command line")
    t.assert_equal("ab\n", h.files.get("a.txt"), "escape does not write")
    t.assert_equal("", h.message_row, "nothing shown after escape")

    h = editor(files_with("ab\n"))
    h.type(":<CR>")
    t.assert_equal([:normal, "", ["ab"], false], [h.mode, h.message_row, h.lines, h.quit?], "empty command does nothing")

    # Unknown command.
    h = editor(files_with("ab\n"))
    h.type(":foo<CR>")
    t.assert_equal("E492: Not an editor command: foo", h.message_row, "unknown command reports E492")
    t.assert_equal(:normal, h.mode, "back in normal mode after an unknown command")
    t.assert_equal(Carat::Domain::Highlight::MESSAGE_ERROR, h.frame.cell(9, 0).hl, "E492 is shown as an error")

    # Write.
    h = editor(files_with("one\ntwo\n"))
    h.type("ix<Esc>")
    h.type(":w<CR>")
    t.assert_equal("\"a.txt\" 2L, 9B written", h.message_row, "write shows the written message")
    t.assert_equal("xone\ntwo\n", h.files.get("a.txt"), "write stores the buffer text")
    t.assert_equal(false, h.buffer.modified?, "write clears the modified flag")
    t.assert_equal("a.txt ", h.status_row[0, 6], "status line no longer shows [+]")
    h.type(":write<CR>")
    t.assert_equal("\"a.txt\" 2L, 9B written", h.message_row, "long form write")
    h.type(":w b.txt<CR>")
    t.assert_equal("xone\ntwo\n", h.files.get("b.txt"), "write to another path")
    t.assert_equal("\"b.txt\" 2L, 9B written", h.message_row, "written message names the other path")

    # Quit.
    h = editor(files_with("ab\n"))
    h.type(":q<CR>")
    t.assert_equal(true, h.quit?, "quit ends the editor on a clean buffer")
    h = editor(files_with("ab\n"))
    h.type("ix<Esc>:q<CR>")
    t.assert_equal([false, E37, :normal], [h.quit?, h.message_row, h.mode], "quit refused while modified")
    h.type(":quit<CR>")
    t.assert_equal(false, h.quit?, "long form quit refused too")
    h.type(":q!<CR>")
    t.assert_equal(true, h.quit?, "forced quit ends the editor")
    t.assert_equal("ab\n", h.files.get("a.txt"), "forced quit does not write")

    # Write-quit.
    h = editor(files_with("ab\n"))
    h.type("Ac<Esc>:wq<CR>")
    t.assert_equal([true, "abc\n"], [h.quit?, h.files.get("a.txt")], "wq writes and quits")
    h = editor(files_with("ab\n"))
    h.type("ix<Esc>:wq!<CR>")
    t.assert_equal([true, "xab\n"], [h.quit?, h.files.get("a.txt")], "wq with bang")

    # Exit.
    h = editor(files_with("ab\n"))
    h.type("Ac<Esc>:x<CR>")
    t.assert_equal([true, "abc\n", false], [h.quit?, h.files.get("a.txt"), h.buffer.modified?], "x writes a modified buffer and quits")
    h = editor(files_with("ab\n"))
    h.type(":x<CR>")
    t.assert_equal([true, "ab\n", ""], [h.quit?, h.files.get("a.txt"), h.message_row], "x on a clean buffer quits without writing")
    h = editor(files_with("ab\n"))
    h.type("ix<Esc>:exit!<CR>")
    t.assert_equal([true, "xab\n"], [h.quit?, h.files.get("a.txt")], "long form exit with bang")

    # Write-all and quit-all.
    h = editor(files_with("ab\n"))
    h.type("ix<Esc>:wa<CR>")
    t.assert_equal(["\"a.txt\" 1L, 4B written", "xab\n", false, false], [h.message_row, h.files.get("a.txt"), h.buffer.modified?, h.quit?], "wa writes the modified buffer and stays")
    h.type(":wa<CR>")
    t.assert_equal(["", false], [h.message_row, h.quit?], "wa on a clean buffer shows nothing")
    h = editor(files_with("ab\n"))
    h.type("ix<Esc>:qa<CR>")
    t.assert_equal([false, E37, :normal], [h.quit?, h.message_row, h.mode], "qa refused while modified")
    h.type(":quitall<CR>")
    t.assert_equal(false, h.quit?, "long form qa refused too")
    h.type(":qa!<CR>")
    t.assert_equal([true, "ab\n"], [h.quit?, h.files.get("a.txt")], "forced qa does not write")
    h = editor(files_with("ab\n"))
    h.type("ix<Esc>:wqa!<CR>")
    t.assert_equal([true, "xab\n"], [h.quit?, h.files.get("a.txt")], "wqa with bang writes and quits")
    h = editor(files_with("ab\n"))
    h.type(":xa<CR>")
    t.assert_equal([true, "ab\n"], [h.quit?, h.files.get("a.txt")], "xa on a clean buffer quits without writing")

    # Edit.
    files = files_with("ab\n")
    files.put("b.txt", "zz\n")
    h = editor(files)
    h.type(":e b.txt<CR>")
    t.assert_equal(["b.txt", ["zz"], [0, 0], "\"b.txt\" 1L, 3B"], [h.buffer.path, h.lines, h.cursor, h.message_row], "edit opens another file")
    t.assert_equal("  1 zz", h.row(0), "the screen shows the other file")
    files.put("l.txt", "ok\ncaf\xE9\n")
    h.type(":e l.txt<CR>")
    t.assert_equal([["ok", "caf\xE9"], "\"l.txt\" [ILLEGAL BYTE in line 2] 2L, 8B"], [h.lines, h.message_row], "edit opens a file that is not UTF-8 and names its first illegal line")
    t.assert_equal("  2 caf\u{FFFD}", h.row(1), "the illegal byte is drawn as one replacement character")
    h.type(":w<CR>")
    t.assert_equal(["ok\ncaf\xE9\n", "\"l.txt\" 2L, 8B written"], [files.get("l.txt"), h.message_row], "writing the unedited file gives back its bytes")
    h.type("ggx:w<CR>")
    t.assert_equal("k\ncaf\xE9\n", files.get("l.txt"), "an edit elsewhere keeps the illegal byte")
    h.type(":e b.txt<CR>")
    h.type(":e new.txt<CR>")
    t.assert_equal(["new.txt", [""], "\"new.txt\" [New]"], [h.buffer.path, h.lines, h.message_row], "edit starts a new file")
    h.type("ix<Esc>:e b.txt<CR>")
    t.assert_equal([E37, "new.txt"], [h.message_row, h.buffer.path], "edit refused while modified")
    h.type(":e!<CR>")
    t.assert_equal([[""], false], [h.lines, h.buffer.modified?], "forced reload discards changes")
    h.type(":edit a.txt<CR>")
    t.assert_equal(["ab"], h.lines, "long form edit")

    # Paths that are not regular files of bounded size are refused and
    # the current buffer stays: rows are [label, command, [message,
    # error, buffer path, lines]].
    hostile = files_with("ab\n")
    hostile.mkdir("lib")
    hostile.special("pipe")
    hostile.special("/dev/zero")
    hostile.put("big.bin", "x" * 67_108_865)
    hostile.put("edge.bin", "x" * 67_108_864)
    hostile.put("link.txt", "linked\n")
    hostile.link("link.txt")
    t.table([
      ["a directory", ":e lib<CR>", ["\"lib\" is a directory", true, "a.txt", ["ab"]]],
      ["a FIFO", ":e pipe<CR>", ["\"pipe\" is not a file", true, "a.txt", ["ab"]]],
      ["a device", ":e /dev/zero<CR>", ["\"/dev/zero\" is not a file", true, "a.txt", ["ab"]]],
      ["a file over the limit", ":e big.bin<CR>", ["E484: Can't open file big.bin: File too large", true, "a.txt", ["ab"]]],
      ["a linked regular file opens", ":e link.txt<CR>", ["\"link.txt\" 1L, 7B", false, "link.txt", ["linked"]]]
    ]) do |keys|
      hh = editor(hostile)
      hh.type(keys.to_s)
      [hh.message_row, hh.state.message_error, hh.buffer.path, hh.lines]
    end
    hh = editor(hostile)
    hh.type(":e edge.bin<CR>")
    t.assert_equal(["edge.bin", 1, "\"edge.bin\" 1L, 67108864B"], [hh.buffer.path, hh.buffer.line_count, hh.message_row], "a file of exactly the limit opens")

    # Several windows and tab pages.
    h = editor(files_with("ab\n"))
    h.type("<C-w>s:q<CR>")
    t.assert_equal([1, false], [h.window_count, h.quit?], "q with two windows closes one")
    h.type(":q<CR>")
    t.assert_equal(true, h.quit?, "q on the last window quits")
    h = editor(files_with("ab\n"))
    h.type("<C-w>sx:wq<CR>")
    t.assert_equal(["b\n", 1, false], [h.files.get("a.txt"), h.window_count, h.quit?], "wq with two windows writes and closes one")
    h = editor(files_with("ab\n"))
    h.type("<C-w>vx:x<CR>")
    t.assert_equal(["b\n", 1, false], [h.files.get("a.txt"), h.window_count, h.quit?], "x with two windows writes and closes one")
    files = files_with("ab\n")
    files.put("b.txt", "zz\n")
    h = editor(files)
    h.type(":sp b.txt<CR><C-w>j:e b.txt<CR>")
    t.assert_equal([["zz"], ["b.txt", "b.txt"], ["a.txt", "b.txt"]], [h.lines, [h.windows[0][4], h.windows[1][4]], h.buffer_paths], "e shows the listed buffer in the window and keeps the one it left hidden")
    t.assert_true(h.state.tab.layout.window_at(h.state.tab.current).buffer.equal?(h.state.tab.layout.window_at(h.state.tab.previous).buffer), "both windows share one buffer")
    files.put("a.txt", "fresh\n")
    h.type(":e a.txt<CR>")
    t.assert_equal(["ab"], h.lines, "e a.txt shows the hidden buffer without reading the file again")
    h.type(":e!<CR>")
    t.assert_equal(["fresh"], h.lines, "e! reads it again")
    files = files_with("ab\n")
    h = editor(files)
    h.type("<C-w>s")
    files.put("a.txt", "new text\n")
    h.type(":e<CR>")
    t.assert_equal([["new text"], "  1 new text", "  1 new text"], [h.lines, h.row(0), h.row(5)], "e reloads the file for every window showing it")
    files = files_with("ab\n")
    files.put("b.txt", "zz\n")
    files.put("c.txt", "cc\n")
    h = editor(files)
    h.type(":sp b.txt<CR>x<C-w>jx:tabe c.txt<CR>x:wa<CR>")
    t.assert_equal(["b\n", "z\n", "c\n", false], [h.files.get("a.txt"), h.files.get("b.txt"), h.files.get("c.txt"), h.assembly.buffers.any_modified?], "wa writes every buffer in every tab page")
    h = editor(files_with("ab\n"))
    h.type("<C-w>s:tabnew<CR>:qa<CR>")
    t.assert_equal(true, h.quit?, "qa quits with several windows and tab pages")
    files = files_with("ab\n")
    files.put("b.txt", "zz\n")
    h = editor(files)
    h.type(":tabe b.txt<CR>xgt:qa<CR>")
    t.assert_equal([false, E37], [h.quit?, h.message_row], "qa is refused by a modified buffer in another tab page")
    h.type("x:wqa<CR>")
    t.assert_equal(["b\n", "z\n", true], [h.files.get("a.txt"), h.files.get("b.txt"), h.quit?], "wqa writes the buffers of both tab pages and quits")

    # Leader mappings go through the same path.
    h = editor(files_with("ab\n"))
    h.type(" q")
    t.assert_equal(true, h.quit?, "leader q quits")

    # A message stays until the next key.
    h = editor(files_with("ab\n"))
    h.type(":foo<CR>")
    t.assert_equal("E492: Not an editor command: foo", h.message_row, "message shown")
    h.wait
    t.assert_equal("E492: Not an editor command: foo", h.message_row, "message stays while idle")
    h.type("l")
    t.assert_equal("", h.message_row, "message clears on the next key")

    # Every ex command is recognized from its abbreviation to its full name.
    h = Carat::Doubles::EditorHarness.default(files_with("ab\n"), 24, 80)
    h.open("a.txt")
    h.type(":vsp<CR>")
    t.assert_equal([2, true], [h.window_count, h.windows[0][1] < h.windows[1][1]], "vsp splits vertically as vsplit does")
    h.type(":clo<CR>:spl<CR>")
    t.assert_equal([2, true], [h.window_count, h.windows[0][0] < h.windows[1][0]], "spl splits as split does")
    h = editor(files_with("ab\n"))
    h.type("x:wr<CR>")
    t.assert_equal(["b\n", "\"a.txt\" 1L, 2B written"], [h.files.get("a.txt"), h.message_row], "wr writes as write does")
    h = editor(files_with("ab\n"))
    h.type("x:wal<CR>")
    t.assert_equal(["b\n", false], [h.files.get("a.txt"), h.assembly.buffers.any_modified?], "wal writes every modified buffer as wall does")
    h.type(":xi<CR>")
    t.assert_equal(true, h.quit?, "xi leaves as xit does")
    h = editor(files_with("ab\n"))
    h.type(":tabnew<CR>:tabnew<CR>:tabfirs<CR>")
    t.assert_equal([3, 1], [h.tab_count, h.tab_index], "tabfirs goes to the first tab page")
    h.type(":tabf<CR>")
    t.assert_equal("E492: Not an editor command: tabf", h.message_row, "a spelling shorter than the abbreviation is unknown")
    h.type(":vsplitx<CR>")
    t.assert_equal("E492: Not an editor command: vsplitx", h.message_row, "a spelling longer than the full name is unknown")

    # The command history: <Up> and <Down> recall by the typed prefix.
    h = editor(files_with("ab\n"))
    h.type(":set ft?<CR>:tabf<CR>:<Up>")
    t.assert_equal(":tabf", h.message_row, "up recalls the last command")
    h.type("<Up>")
    t.assert_equal(":set ft?", h.message_row, "up again recalls the one before")
    h.type("<Up>")
    t.assert_equal(":set ft?", h.message_row, "past the oldest nothing changes")
    h.type("<Down><Down>")
    t.assert_equal(":", h.message_row, "down past the newest gives back the typed text")
    h.type("s<Up>")
    t.assert_equal(":set ft?", h.message_row, "up recalls only commands starting with the typed text")
    h.type("<Down>")
    t.assert_equal(":s", h.message_row, "down returns to the typed text")
    h.type("<Esc>:<Down>")
    t.assert_equal(":", h.message_row, "down before any recall changes nothing")

    t.finish
  end
end

EditorCmdlineTest.main if __FILE__ == $0
