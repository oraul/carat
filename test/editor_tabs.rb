require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("editor_tabs")
D = Carat::Domain

E37 = "E37: No write since last change (add ! to override)"
E784 = "E784: Cannot close last tab page"

# A 24 by 80 editor on "a.txt" (three lines) with "b.txt" on disk, after
# typing keys.
def session(keys)
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", "one\ntwo\nthree\n")
  files.put("b.txt", "zz\n")
  h = Carat::Doubles::EditorHarness.default(files, 24, 80)
  h.open("a.txt")
  h.type(keys)
  h
end

# The path shown by the current window of every tab page.
def tab_paths(h)
  s = h.state
  out = []
  i = 0
  while i < s.tab_count
    path = s.tab_at(i).window.buffer.path
    out << (path.nil? ? "" : path)
    i += 1
  end
  out
end

# Opening, closing, and moving: rows are [label, keys, [tab count, current tab, paths per tab]].
t.table([
  [":tabnew opens a tab page after the current one", ":tabnew<CR>", [2, 2, ["a.txt", ""]]],
  [":tabe file opens a tab page on the file", ":tabe b.txt<CR>", [2, 2, ["a.txt", "b.txt"]]],
  [":tabedit file", ":tabedit b.txt<CR>", [2, 2, ["a.txt", "b.txt"]]],
  [":tabedit without a file opens an empty buffer", ":tabedit<CR>", [2, 2, ["a.txt", ""]]],
  [":tabe without a file opens an empty buffer", ":tabe<CR>", [2, 2, ["a.txt", ""]]],
  ["a new tab page goes after the current one", ":tabnew<CR>:tabnew<CR>:tabfir<CR>:tabe b.txt<CR>", [4, 2, ["a.txt", "b.txt", "", ""]]],
  [":tabclose closes the current tab page", ":tabnew<CR>:tabclose<CR>", [1, 1, ["a.txt"]]],
  [":tabc closes the current tab page", ":tabnew<CR>:tabc<CR>", [1, 1, ["a.txt"]]],
  ["closing the first of three makes the next one current", ":tabnew<CR>:tabe b.txt<CR>:tabfir<CR>:tabc<CR>", [2, 1, ["", "b.txt"]]],
  ["closing the last of three makes the one before it current", ":tabnew<CR>:tabe b.txt<CR>:tabc<CR>", [2, 2, ["a.txt", ""]]],
  [":tabclose on the last tab page stays", ":tabclose<CR>", [1, 1, ["a.txt"]]],
  [":tabonly keeps the current tab page", ":tabnew<CR>:tabe b.txt<CR>:tabonly<CR>", [1, 1, ["b.txt"]]],
  [":tabo keeps the current tab page", ":tabnew<CR>:tabnew<CR>:tabfir<CR>:tabo<CR>", [1, 1, ["a.txt"]]],
  [":q closes the tab page", ":tabnew<CR>:q<CR>", [1, 1, ["a.txt"]]],
  ["Ctrl-W c closes the tab page", ":tabnew<CR><C-w>c", [1, 1, ["a.txt"]]],
  ["Ctrl-W q closes the tab page", ":tabe b.txt<CR><C-w>q", [1, 1, ["a.txt"]]],
  ["gt goes to the next tab page", ":tabnew<CR>:tabfir<CR>gt", [2, 2, ["a.txt", ""]]],
  ["gt wraps", ":tabnew<CR>gt", [2, 1, ["a.txt", ""]]],
  ["gT goes back", ":tabnew<CR>gtgT", [2, 2, ["a.txt", ""]]],
  ["gT wraps", ":tabnew<CR>:tabfir<CR>gT", [2, 2, ["a.txt", ""]]],
  [":tabn goes to the next tab page", ":tabnew<CR>:tabfir<CR>:tabn<CR>", [2, 2, ["a.txt", ""]]],
  [":tabnext wraps", ":tabnew<CR>:tabnext<CR>", [2, 1, ["a.txt", ""]]],
  [":tabp goes back", ":tabnew<CR>:tabp<CR>", [2, 1, ["a.txt", ""]]],
  [":tabprevious wraps", ":tabnew<CR>:tabfir<CR>:tabprevious<CR>", [2, 2, ["a.txt", ""]]],
  [":tabN goes back", ":tabnew<CR>:tabN<CR>", [2, 1, ["a.txt", ""]]],
  [":tabNext goes back", ":tabnew<CR>:tabNext<CR>", [2, 1, ["a.txt", ""]]],
  [":tabl goes to the last", ":tabnew<CR>:tabnew<CR>:tabfir<CR>:tabl<CR>", [3, 3, ["a.txt", "", ""]]],
  [":tablast goes to the last", ":tabnew<CR>:tabnew<CR>:tabfir<CR>:tablast<CR>", [3, 3, ["a.txt", "", ""]]],
  [":tabfir goes to the first", ":tabnew<CR>:tabnew<CR>:tabfir<CR>", [3, 1, ["a.txt", "", ""]]],
  [":tabfirst goes to the first", ":tabnew<CR>:tabnew<CR>:tabfirst<CR>", [3, 1, ["a.txt", "", ""]]],
  ["3gt goes to tab page 3", ":tabnew<CR>:tabnew<CR>:tabfir<CR>3gt", [3, 3, ["a.txt", "", ""]]],
  ["2gt goes to tab page 2", ":tabnew<CR>:tabnew<CR>:tabfir<CR>2gt", [3, 2, ["a.txt", "", ""]]],
  ["5gt with three tab pages does nothing", ":tabnew<CR>:tabnew<CR>:tabfir<CR>5gt", [3, 1, ["a.txt", "", ""]]],
  ["2gT goes two back, wrapping", ":tabnew<CR>:tabnew<CR>:tabfir<CR>2gT", [3, 2, ["a.txt", "", ""]]],
  ["1gT goes one back", ":tabnew<CR>:tabnew<CR>1gT", [3, 2, ["a.txt", "", ""]]]
]) do |keys|
  h = session(keys)
  [h.tab_count, h.tab_index, tab_paths(h)]
end

# Messages: rows are [label, keys, message].
t.table([
  [":tabclose on the last tab page reports E784", ":tabclose<CR>", E784],
  [":tabc on the last tab page reports E784", ":tabc<CR>", E784],
  [":tabonly with one tab page says so", ":tabonly<CR>", "Already only one tab page"],
  [":tabo with one tab page says so", ":tabo<CR>", "Already only one tab page"],
  [":tabe file shows the opened message", ":tabe b.txt<CR>", "\"b.txt\" 1L, 3B"],
  [":tabnew shows nothing", ":tabnew<CR>", ""]
]) do |keys|
  session(keys).message_row
end

# The new tab page's window shows the buffer from its start.
h = session("jj:tabe b.txt<CR>")
t.assert_equal([["zz"], [0, 0], "b.txt"], [h.lines, h.cursor, h.buffer.path], "the new tab page shows the file at the top")
t.assert_equal("  1 zz", h.row(1), "the text starts under the tab line")
t.assert_equal([2, 0], [h.state.tab_at(0).window.cursor.row, h.state.tab_at(0).window.cursor.col], "the first tab page kept its cursor")
h = session(":tabnew<CR>")
t.assert_equal([[""], nil, false], [h.lines, h.buffer.path, h.buffer.modified?], ":tabnew shows an unnamed empty buffer")
t.assert_equal([["a.txt", ""], 2], [h.buffer_paths, h.state.total_windows], "both buffers are listed and each tab page has a window")

# Hidden buffers after closing tab pages.
h = session(":tabe b.txt<CR>x:tabclose<CR>:qa<CR>")
t.assert_equal([false, E37, ["a.txt", "b.txt"]], [h.quit?, h.message_row, h.buffer_paths], "a modified buffer in a closed tab page stays hidden and blocks :qa")
h = session(":tabe b.txt<CR>x:tabfir<CR>:tabonly<CR>")
t.assert_equal([1, ["a.txt", "b.txt"]], [h.tab_count, h.buffer_paths], ":tabonly keeps the modified buffer hidden")
h.type(":qa!<CR>")
t.assert_equal(true, h.quit?, ":qa! ends the editor")
h = session(":tabe b.txt<CR>:tabclose<CR>")
t.assert_equal(["a.txt"], h.buffer_paths, "a clean buffer leaves the list with its tab page")
h = session(":tabe b.txt<CR>xgt:qa<CR>")
t.assert_equal([false, E37, 1], [h.quit?, h.message_row, h.tab_index], ":qa is refused by a modified buffer in another tab page")
h = session(":tabe b.txt<CR>xgtx:wa<CR>")
t.assert_equal(["ne\ntwo\nthree\n", "z\n", false], [h.files.get("a.txt"), h.files.get("b.txt"), h.state.any_modified?], ":wa writes the buffers of every tab page")
h = session("x:tabe b.txt<CR>x:wqa<CR>")
t.assert_equal(["ne\ntwo\nthree\n", "z\n", true], [h.files.get("a.txt"), h.files.get("b.txt"), h.quit?], ":wqa writes every tab page's buffer and quits")
h = session("<C-w>s:tabnew<CR>:qa<CR>")
t.assert_equal(true, h.quit?, ":qa quits with several windows and tab pages")

# Each tab page keeps its own layout.
h = session("<C-w>s:tabnew<CR>")
t.assert_equal([1, 2], [h.window_count, h.tab_index], "the new tab page has one window")
h.type("gt")
t.assert_equal([2, 1], [h.window_count, h.tab_index], "the first tab page still has two")
h.type("<C-w>j:tabnew<CR>gT")
t.assert_equal(2, h.window_index, "the first tab page remembers its current window")

# The tab line.
h = session(":tabe b.txt<CR>")
t.assert_equal(" 1 a.txt  2 b.txt", h.row(0), "the tab line lists the tab pages with their files")
t.assert_equal([D::Highlight::TAB_LINE, D::Highlight::TAB_LINE_SELECTED, D::Highlight::TAB_LINE_FILL], [h.frame.cell(0, 0).hl, h.frame.cell(0, 9).hl, h.frame.cell(0, 18).hl], "the current label is selected, the rest filled")
t.assert_equal(D::Highlight::TAB_LINE_FILL, h.frame.cell(0, 79).hl, "the fill reaches the right edge")
t.assert_equal([1, 0, 21, 80], h.windows[0][0, 4], "the window starts under the tab line with one row less")
t.assert_equal("b.txt", h.row(22)[0, 5], "the status line is above the message row")
t.assert_equal([1, 4], [h.frame.cursor_row, h.frame.cursor_col], "the cursor is under the tab line")
h.type("gtx")
t.assert_equal(" 1 a.txt [+]  2 b.txt", h.row(0), "a modified buffer is marked in its label")
t.assert_equal([D::Highlight::TAB_LINE_SELECTED, D::Highlight::TAB_LINE], [h.frame.cell(0, 0).hl, h.frame.cell(0, 13).hl], "the first label is now selected")
h = session(":tabnew<CR>")
t.assert_equal(" 1 a.txt  2 [No Name]", h.row(0), "an unnamed buffer shows as [No Name]")
h.type(":tabclose<CR>")
t.assert_equal("  1 one", h.row(0), "one tab page has no tab line")
t.assert_equal([0, 0, 22, 80], h.windows[0][0, 4], "the window takes the top row again")
files = Carat::Doubles::MemoryFiles.new
files.put("dir/sub/deep.txt", "d\n")
h = Carat::Doubles::EditorHarness.default(files, 24, 80)
h.open("dir/sub/deep.txt")
h.type(":tabnew<CR>")
t.assert_equal(" 1 deep.txt  2 [No Name]", h.row(0), "a label shows the file name without its directory")
t.assert_equal("dir/sub/deep.txt", h.state.tab_at(0).window.buffer.path, "the status line path is untouched")

t.finish
