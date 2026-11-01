require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("editor_windows")
D = Carat::Domain

E36 = "E36: Not enough room"
E37 = "E37: No write since last change (add ! to override)"
E444 = "E444: Cannot close last window"

# An editor on "a.txt" (three lines) with "b.txt" and "c.txt" on disk.
def editor(rows, cols)
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", "one\ntwo\nthree\n")
  files.put("b.txt", "zz\n")
  files.put("c.txt", "cc\n")
  h = Carat::Doubles::EditorHarness.default(files, rows, cols)
  h.open("a.txt")
  h
end

# A 24 by 80 editor after typing keys.
def session(keys)
  h = editor(24, 80)
  h.type(keys)
  h
end

# The window count, the current window's number, and every window's
# [row, col, text rows, columns] in layout order.
def shape(h)
  out = []
  all = h.windows
  i = 0
  while i < all.length
    out << all[i][0, 4]
    i += 1
  end
  [h.window_count, h.window_index, out]
end

# The paths shown by the windows in layout order.
def paths(h)
  out = []
  all = h.windows
  i = 0
  while i < all.length
    out << all[i][4]
    i += 1
  end
  out
end

ONE = [[0, 0, 22, 80]]
STACKED = [[0, 0, 11, 80], [12, 0, 10, 80]]
BESIDE = [[0, 0, 22, 40], [0, 41, 22, 39]]

# Splitting, moving, cycling, closing: rows are [label, keys, [count, current, rectangles]].
t.table([
  ["Ctrl-W s splits with the new window above", "<C-w>s", [2, 1, STACKED]],
  [":sp splits", ":sp<CR>", [2, 1, STACKED]],
  [":split splits", ":split<CR>", [2, 1, STACKED]],
  ["a count sets the new window's rows", "5<C-w>s", [2, 1, [[0, 0, 5, 80], [6, 0, 16, 80]]]],
  ["Ctrl-W v splits with the new window left", "<C-w>v", [2, 1, BESIDE]],
  [":vs splits vertically", ":vs<CR>", [2, 1, BESIDE]],
  [":vsplit splits vertically", ":vsplit<CR>", [2, 1, BESIDE]],
  ["a count sets the new window's columns", "30<C-w>v", [2, 1, [[0, 0, 22, 30], [0, 31, 22, 49]]]],
  ["Ctrl-W j moves down", "<C-w>s<C-w>j", [2, 2, STACKED]],
  ["Ctrl-W k moves back up", "<C-w>s<C-w>j<C-w>k", [2, 1, STACKED]],
  ["Ctrl-W k with nothing above stays", "<C-w>s<C-w>k", [2, 1, STACKED]],
  ["Ctrl-W l moves right", "<C-w>v<C-w>l", [2, 2, BESIDE]],
  ["Ctrl-W h moves back left", "<C-w>v<C-w>l<C-w>h", [2, 1, BESIDE]],
  ["Ctrl-W l with nothing to the right stays", "<C-w>v<C-w>l<C-w>l", [2, 2, BESIDE]],
  ["a count moves several windows and stops at the edge", "<C-w>s<C-w>s5<C-w>j", [3, 3, [[0, 0, 5, 80], [6, 0, 5, 80], [12, 0, 10, 80]]]],
  ["Ctrl-W w goes to the next window", "<C-w>s<C-w>w", [2, 2, STACKED]],
  ["Ctrl-W w wraps to the first", "<C-w>s<C-w>w<C-w>w", [2, 1, STACKED]],
  ["Ctrl-W W wraps to the last", "<C-w>s<C-w>W", [2, 2, STACKED]],
  ["Ctrl-W W goes to the previous window", "<C-w>s<C-w>W<C-w>W", [2, 1, STACKED]],
  ["a count before Ctrl-W w picks that window", "<C-w>s<C-w>s3<C-w>w", [3, 3, [[0, 0, 5, 80], [6, 0, 5, 80], [12, 0, 10, 80]]]],
  ["a count past the last window picks the last", "<C-w>s<C-w>s9<C-w>W", [3, 3, [[0, 0, 5, 80], [6, 0, 5, 80], [12, 0, 10, 80]]]],
  ["a count before Ctrl-W W picks that window too", "<C-w>s<C-w>s2<C-w>W", [3, 2, [[0, 0, 5, 80], [6, 0, 5, 80], [12, 0, 10, 80]]]],
  ["Ctrl-W p returns to the previous window", "<C-w>s<C-w>j<C-w>p", [2, 1, STACKED]],
  ["Ctrl-W p again goes forward", "<C-w>s<C-w>j<C-w>p<C-w>p", [2, 2, STACKED]],
  ["Ctrl-W p after the previous window closed stays", "<C-w>s<C-w>j<C-w>o<C-w>p", [1, 1, ONE]],
  ["Ctrl-W c closes the window", "<C-w>s<C-w>c", [1, 1, ONE]],
  [":close closes the window", "<C-w>s:close<CR>", [1, 1, ONE]],
  [":clo closes the window", ":sp<CR>:clo<CR>", [1, 1, ONE]],
  ["Ctrl-W c on the last window stays", "<C-w>c", [1, 1, ONE]],
  ["a count before Ctrl-W c closes that window", "<C-w>s<C-w>s3<C-w>c", [2, 1, [[0, 0, 5, 80], [6, 0, 16, 80]]]],
  ["closing the bottom window gives its rows to the one above", "<C-w>s<C-w>j<C-w>c", [1, 1, ONE]],
  ["Ctrl-W o keeps only the current window", "<C-w>s<C-w>s<C-w>o", [1, 1, ONE]],
  [":only keeps only the current window", "<C-w>v:only<CR>", [1, 1, ONE]],
  [":on keeps only the current window", "<C-w>v<C-w>l:on<CR>", [1, 1, ONE]],
  ["Ctrl-W = equalizes rows", "5<C-w>s<C-w>=", [2, 1, STACKED]],
  ["Ctrl-W = equalizes columns", "30<C-w>v<C-w>=", [2, 1, BESIDE]],
  ["Ctrl-W q closes one of two windows", "<C-w>s<C-w>q", [1, 1, ONE]],
  ["a count before Ctrl-W q quits that window", "<C-w>s<C-w>s3<C-w>q", [2, 1, [[0, 0, 5, 80], [6, 0, 16, 80]]]],
  [":q closes one of two windows", "<C-w>v:q<CR>", [1, 1, ONE]],
  [":new splits with an empty buffer", ":new<CR>", [2, 1, STACKED]],
  [":vnew splits vertically with an empty buffer", ":vnew<CR>", [2, 1, BESIDE]],
  [":vne splits vertically with an empty buffer", ":vne<CR>", [2, 1, BESIDE]],
  [":sp file splits and shows the file", ":sp b.txt<CR>", [2, 1, STACKED]],
  ["nested splits", "<C-w>v<C-w>l<C-w>s", [3, 2, [[0, 0, 22, 40], [0, 41, 11, 39], [12, 41, 10, 39]]]]
]) do |keys|
  shape(session(keys))
end

# Messages: rows are [label, [rows, cols, keys], message].
t.table([
  ["two text rows cannot be split", [4, 80, "<C-w>s"], E36],
  ["three text rows can", [5, 80, "<C-w>s"], ""],
  ["nine columns cannot be split with the gutter", [10, 9, "<C-w>v"], E36],
  ["eleven columns can", [10, 11, "<C-w>v"], ""],
  [":sp reports E36 too", [4, 80, ":sp<CR>"], E36],
  ["closing the last window reports E444", [24, 80, "<C-w>c"], E444],
  [":close on the last window reports E444", [24, 80, ":close<CR>"], E444],
  ["Ctrl-W o with one window says so", [24, 80, "<C-w>o"], "Already only one window"],
  [":only with one window says so", [24, 80, ":only<CR>"], "Already only one window"],
  ["Ctrl-W o with two windows says nothing", [24, 80, "<C-w>s<C-w>o"], ""],
  [":sp file shows the opened message", [24, 80, ":sp b.txt<CR>"], "\"b.txt\" 1L, 3B"]
]) do |input|
  h = editor(input[0], input[1])
  h.type(input[2])
  h.message
end
h = editor(4, 80)
h.type("<C-w>s")
t.assert_equal(1, h.window_count, "E36 leaves one window")
t.assert_equal(D::Highlight::MESSAGE_ERROR, h.frame.cell(3, 0).hl, "E36 is shown as an error")

# Files in the new window: rows are [label, keys, [paths, lines, modified]].
t.table([
  [":sp file shows the file above", ":sp b.txt<CR>", [["b.txt", "a.txt"], ["zz"], false]],
  [":vs file shows the file left", ":vs c.txt<CR>", [["c.txt", "a.txt"], ["cc"], false]],
  [":new shows an unnamed empty buffer", ":new<CR>", [["", "a.txt"], [""], false]],
  [":vnew shows an unnamed empty buffer", ":vnew<CR>", [["", "a.txt"], [""], false]],
  ["Ctrl-W s shows the same buffer", "<C-w>s", [["a.txt", "a.txt"], ["one", "two", "three"], false]],
  ["the old window keeps its buffer after Ctrl-W j", ":sp b.txt<CR><C-w>j", [["b.txt", "a.txt"], ["one", "two", "three"], false]]
]) do |keys|
  h = session(keys)
  [paths(h), h.lines, h.buffer.modified?]
end

# Edits are shared between windows on one buffer.
h = session("<C-w>sx")
t.assert_equal(["ne", "two", "three"], h.lines, "x deletes in the shared buffer")
t.assert_equal(["  1 ne", "  1 ne"], [h.row(0), h.row(12)], "both windows show the edit")
t.assert_equal(["a.txt [+]", "a.txt [+]"], [h.row(11)[0, 9], h.row(22)[0, 9]], "both status lines carry the marker")

# Status lines and the separator.
h = session("<C-w>s<C-w>jj")
t.assert_equal(["1,1 All", "2,1 All"], [h.row(11)[-7, 7], h.row(22)[-7, 7]], "each status line shows its own cursor")
t.assert_equal([D::Highlight::STATUS_NC, D::Highlight::STATUS], [h.frame.cell(11, 0).hl, h.frame.cell(22, 0).hl], "the current window's status line is highlighted, the other inactive")
t.assert_equal([13, 4], [h.frame.cursor_row, h.frame.cursor_col], "the cursor is in the bottom window")
h = session("<C-w>v")
t.assert_equal("│", h.frame.cell(0, 40).char, "a separator column between the windows")
t.assert_equal(D::Highlight::STATUS, h.frame.cell(0, 40).hl, "the separator uses the status highlight")
t.assert_equal("  1 one", h.row(0)[41, 7], "the right window starts after the separator")
t.assert_equal("a.txt", h.row(22)[41, 5], "the right window's status line starts after the separator")
t.assert_equal([0, 4], [h.frame.cursor_row, h.frame.cursor_col], "the cursor is in the left window")
h.type("<C-w>l")
t.assert_equal([0, 45], [h.frame.cursor_row, h.frame.cursor_col], "the cursor moves to the right window")

# Each window has its own cursor and scroll position.
h = session("<C-w>sj<C-w>jjj")
t.assert_equal([[1, 0], [2, 0]], [[h.windows[0][5], h.windows[0][6]], [h.windows[1][5], h.windows[1][6]]], "cursors are independent")
h.type("<C-w>k")
t.assert_equal([1, 0], h.cursor, "switching back restores the other cursor")
lines = +""
40.times { |i| lines << "line #{i + 1}\n" }
files = Carat::Doubles::MemoryFiles.new
files.put("long.txt", lines)
h = Carat::Doubles::EditorHarness.default(files, 24, 80)
h.open("long.txt")
h.type("<C-w>sG")
t.assert_equal([39, 0], [h.windows[0][5], h.windows[1][5]], "G moves only the top window's cursor")
t.assert_equal(" 40 line 40", h.row(10), "the top window scrolled to the end")
t.assert_equal("  1 line 1", h.row(12), "the bottom window did not scroll")

# Fixed width survives equalize and resize.
h = session("20<C-w>v")
h.state.window.fixed_width = true
h.type("<C-w>=")
t.assert_equal([2, 1, [[0, 0, 22, 20], [0, 21, 22, 59]]], shape(h), "Ctrl-W = leaves a fixed-width window alone")
h.resize(24, 60)
t.assert_equal([[0, 0, 22, 20], [0, 21, 22, 39]], shape(h)[2], "a resize leaves a fixed-width window alone")
h.state.window.fixed_width = false
h.type("<C-w>=")
t.assert_equal([[0, 0, 22, 30], [0, 31, 22, 29]], shape(h)[2], "without the flag the columns are shared")

# Resizing the terminal keeps the layout.
h = session("<C-w>s")
h.resize(20, 80)
t.assert_equal([[0, 0, 11, 80], [12, 0, 6, 80]], shape(h)[2], "the bottom window absorbs the lost rows")
t.assert_equal("a.txt", h.row(18)[0, 5], "the bottom status line is on row 18")
h = session("<C-w>v")
h.resize(24, 40)
t.assert_equal([[0, 0, 22, 38], [0, 39, 22, 1]], shape(h)[2], "the right window gives up its columns first, down to one")
t.assert_equal("│", h.frame.cell(0, 38).char, "the separator moved")
h.type("<C-w>=")
t.assert_equal([[0, 0, 22, 20], [0, 21, 22, 19]], shape(h)[2], "equalizing shares the narrower width")

# Quitting windows.
h = session("<C-w>s<C-w>q")
t.assert_equal([1, false], [h.window_count, h.quit?], "Ctrl-W q closes one of two windows")
h = session("<C-w>q")
t.assert_equal(true, h.quit?, "Ctrl-W q on the last window quits")
h = session("x<C-w>q")
t.assert_equal([false, E37], [h.quit?, h.message_row], "Ctrl-W q on the last window refuses a modified buffer")
h = session("<C-w>sx:q<CR>")
t.assert_equal([1, false, true], [h.window_count, h.quit?, h.buffer.modified?], "the other window keeps showing the modified buffer")

# A modified buffer whose last window closes stays hidden.
h = session(":sp b.txt<CR>x<C-w>c:qa<CR>")
t.assert_equal([false, E37, ["a.txt"]], [h.quit?, h.message_row, paths(h)], "the hidden buffer blocks :qa")
t.assert_equal(["a.txt", "b.txt"], h.buffer_paths, "the hidden buffer is still listed")
h.type(":wa<CR>")
t.assert_equal(["z\n", "\"b.txt\" 1L, 2B written"], [h.files.get("b.txt"), h.message_row], ":wa writes the hidden buffer")
t.assert_equal(["a.txt"], h.buffer_paths, "a clean hidden buffer leaves the list")
h.type(":qa<CR>")
t.assert_equal(true, h.quit?, ":qa then ends the editor")
h = session(":sp b.txt<CR>x<C-w>c:e b.txt<CR>")
t.assert_equal([["z"], true, "\"b.txt\" 1L, 2B"], [h.lines, h.buffer.modified?, h.message_row], ":e brings the hidden buffer back without reading the file")
h = session(":sp b.txt<CR><C-w>c")
t.assert_equal(["a.txt"], h.buffer_paths, "a clean buffer leaves the list when its window closes")
h = session(":sp b.txt<CR>x:q<CR>")
t.assert_equal([1, "a.txt", false], [h.window_count, h.buffer.path, h.quit?], ":q closes the window and keeps the buffer")
h.type(":qa<CR>")
t.assert_equal([false, E37], [h.quit?, h.message_row], "and :qa is refused")
h.type(":q<CR>")
t.assert_equal([false, E37], [h.quit?, h.message_row], ":q on the last window is refused by the hidden buffer")
h.type(":q!<CR>")
t.assert_equal([false, "b.txt", ["z"]], [h.quit?, h.buffer.path, h.lines], ":q! shows the hidden buffer instead of quitting")
h.type(":q!<CR>")
t.assert_equal(true, h.quit?, "a second :q! quits")
h = session(":sp b.txt<CR>x<C-w>c<C-w>o")
t.assert_equal("Already only one window", h.message_row, "Ctrl-W o reports one window")
h = session("<C-w>s<C-w>s<C-w>jx<C-w>o")
t.assert_equal([1, true], [h.window_count, h.buffer.modified?], ":only keeps the current window with its buffer")

# E141 names the buffer by its list position.
h = session(":new<CR>ix<Esc><C-w>jx:wa<CR>")
t.assert_equal(["E141: No file name for buffer 2", "ne\ntwo\nthree\n"], [h.message_row, h.files.get("a.txt")], ":wa reports the nameless buffer and writes the others")
t.assert_equal([true, false], [h.state.buffer_at(1).modified?, h.quit?], "the nameless buffer stays modified")
h.type(":wqa<CR>")
t.assert_equal([false, "E141: No file name for buffer 2"], [h.quit?, h.message_row], ":wqa does not quit while a buffer could not be written")

t.finish
