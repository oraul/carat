require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("editor_cmdline")

def editor(files)
  h = Carat::Doubles::EditorHarness.default(files, 10, 60)
  h.open("a.txt")
  h
end

def files_with(text)
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", text)
  files
end

E37 = "E37: No write since last change (add ! to override)"

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
t.assert_equal(false, h.buffer.modified, "write clears the modified flag")
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

# Edit.
files = files_with("ab\n")
files.put("b.txt", "zz\n")
h = editor(files)
h.type(":e b.txt<CR>")
t.assert_equal(["b.txt", ["zz"], [0, 0], "\"b.txt\" 1L, 3B"], [h.buffer.path, h.lines, h.cursor, h.message_row], "edit opens another file")
t.assert_equal("  1 zz", h.row(0), "the screen shows the other file")
h.type(":e new.txt<CR>")
t.assert_equal(["new.txt", [""], "\"new.txt\" [New]"], [h.buffer.path, h.lines, h.message_row], "edit starts a new file")
h.type("ix<Esc>:e b.txt<CR>")
t.assert_equal([E37, "new.txt"], [h.message_row, h.buffer.path], "edit refused while modified")
h.type(":e!<CR>")
t.assert_equal([[""], false], [h.lines, h.buffer.modified], "forced reload discards changes")
h.type(":edit a.txt<CR>")
t.assert_equal(["ab"], h.lines, "long form edit")

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

t.finish
