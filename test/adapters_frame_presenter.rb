require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("adapters_frame_presenter")
D = Carat::Domain
P = Carat::Adapters::FramePresenter.new

def state_for(lines, path)
  buffer = Carat::Domain::Buffer.new(lines, path, "\n")
  options = Carat::Domain::Options.new
  options.number = true
  options.tabstop = 4
  Carat::Domain::EditorState.new(buffer, options, 500)
end

# Layout of three lines in a six-row frame.
s = state_for(["one", "two", "three"], "a.txt")
f = P.call(s, 6, 14)
t.assert_equal(["  1 one", "  2 two", "  3 three", "~"], f.text_rows[0, 4], "window rows with numbers and a tilde")
t.assert_equal("a.txt", f.row_text(4)[0, 5], "status line starts with the path")
t.assert_equal("1,1 All", f.row_text(4)[-7, 7], "status line ends with the cursor and position")
t.assert_equal("", f.row_text(5), "message row is blank")
t.assert_equal(D::Highlight::STATUS, f.cell(4, 0).hl, "status line uses the status highlight")
t.assert_equal(D::Highlight::STATUS, f.cell(4, 13).hl, "status highlight fills the row")
narrow = P.call(s, 6, 12)
t.assert_equal("a.txt", narrow.row_text(4), "the ruler is dropped when it would touch the path")
t.assert_equal(D::Highlight::LINE_NUMBER, f.cell(0, 0).hl, "gutter uses the line number highlight")
t.assert_equal(D::Highlight::NON_TEXT, f.cell(3, 0).hl, "tilde uses the non-text highlight")
t.assert_equal([0, 4], [f.cursor_row, f.cursor_col], "cursor sits after the gutter")
t.assert_equal(:block, f.cursor_shape, "block cursor in normal mode")

s.options.number = false
f = P.call(s, 6, 12)
t.assert_equal("one", f.row_text(0), "number off removes the gutter")
t.assert_equal(0, f.cursor_col, "cursor at column 0 without a gutter")

big = []
1000.times { |i| big << "L#{i + 1}" }
s = state_for(big, "big.txt")
f = P.call(s, 6, 20)
t.assert_equal("   1 L1", f.row_text(0), "gutter widens to the digits of the line count")
t.assert_equal("Top", f.row_text(4)[-3, 3], "position is Top at the start of a long buffer")

# Relative numbers.
s = state_for(["a", "b", "c"], "a.txt")
s.options.relativenumber = true
s.cursor.move_to(1, 0)
f = P.call(s, 6, 12)
t.assert_equal(["  1 a", "  2 b", "  1 c"], f.text_rows[0, 3], "relative numbers around the cursor with the absolute number on its row")
s.options.number = false
f = P.call(s, 6, 12)
t.assert_equal("  0 b", f.row_text(1), "cursor row shows 0 when number is off")

# Status line content.
s = state_for(["ab", "cdef"], "a.txt")
s.buffer.modified = true
s.cursor.move_to(1, 2)
f = P.call(s, 6, 30)
t.assert_equal("a.txt [+]", f.row_text(4)[0, 9], "modified buffer shows [+]")
t.assert_equal("2,3 All", f.row_text(4)[-7, 7], "status line shows row,col and All")
s = state_for([""], nil)
f = P.call(s, 6, 30)
t.assert_equal("[No Name]", f.row_text(4)[0, 9], "unnamed buffer")

# Message row priorities.
s = state_for(["ab"], "a.txt")
s.mode = D::Mode::INSERT
f = P.call(s, 6, 30)
t.assert_equal("-- INSERT --", f.row_text(5), "insert indicator")
t.assert_equal(:bar, f.cursor_shape, "bar cursor in insert mode")
s.show("E37: No write since last change (add ! to override)", true)
f = P.call(s, 6, 60)
t.assert_equal("E37: No write since last change (add ! to override)", f.row_text(5), "message replaces the indicator")
t.assert_equal(D::Highlight::MESSAGE_ERROR, f.cell(5, 0).hl, "error message highlight")
s.clear_message
s.mode = D::Mode::CMDLINE
s.cmdline = "wq"
f = P.call(s, 6, 30)
t.assert_equal(":wq", f.row_text(5), "command line with colon")
t.assert_equal([5, 3], [f.cursor_row, f.cursor_col], "cursor after the command line text")

# Vertical scrolling with scrolloff.
lines = []
20.times { |i| lines << "line #{i + 1}" }
s = state_for(lines, "a.txt")
s.options.number = false
s.options.scrolloff = 2
row = 0
while row <= 10
  s.cursor.move_to(row, 0)
  P.call(s, 8, 20)
  row += 1
end
f = P.call(s, 8, 20)
t.assert_equal("line 8", f.row_text(0), "first window row shows line 8 after moving to row 10")
t.assert_equal(3, f.cursor_row, "cursor row is third from the bottom of the six window rows")
t.assert_equal(7, s.window.top, "window top is 7")
t.assert_equal("50%", f.row_text(6)[-3, 3], "position shows a percentage")
s.cursor.move_to(19, 0)
f = P.call(s, 8, 20)
t.assert_equal("line 20", f.row_text(5), "last line at the bottom when the cursor reaches it")
t.assert_equal("Bot", f.row_text(6)[-3, 3], "position is Bot at the end")
s.cursor.move_to(0, 0)
f = P.call(s, 8, 20)
t.assert_equal("line 1", f.row_text(0), "scrolls back up to the start")

# Horizontal scrolling.
s = state_for(["a" * 29 + "X" + "b" * 10], "a.txt")
s.options.number = false
s.cursor.move_to(0, 30)
f = P.call(s, 4, 12)
t.assert_true(f.cursor_col >= 0 && f.cursor_col < 12, "cursor is inside the frame")
t.assert_equal("X", f.row_text(0)[f.cursor_col - 1, 1], "the row shows the text around the cursor")
t.assert_equal(true, f.row_text(0)[0, 1] != "a" || s.window.left > 0, "row no longer starts at column 0")
s.cursor.move_to(0, 0)
f = P.call(s, 4, 12)
t.assert_equal(0, s.window.left, "scrolls back to column 0")

# Tabs and wide characters.
s = state_for(["a\tb"], "a.txt")
s.options.number = false
f = P.call(s, 4, 12)
t.assert_equal("a   b", f.row_text(0), "tab expands to the next multiple of tabstop")
s.cursor.move_to(0, 2)
f = P.call(s, 4, 12)
t.assert_equal(4, f.cursor_col, "cursor after a tab is placed by display width")
s = state_for(["日x"], "a.txt")
s.options.number = false
s.cursor.move_to(0, 1)
f = P.call(s, 4, 12)
t.assert_equal(2, f.cursor_col, "cursor after a wide character is at column 2")
t.assert_equal(2, f.cell(0, 0).width, "wide character cell has width 2")
t.assert_equal("", f.cell(0, 1).char, "the cell after a wide character is a continuation")
s = state_for(["a\x01b"], "a.txt")
s.options.number = false
f = P.call(s, 4, 12)
t.assert_equal("a^Ab", f.row_text(0), "control characters show as caret notation")

# Resizing.
s = state_for(["ab"], "a.txt")
f = P.call(s, 24, 80)
t.assert_equal(24, f.rows, "frame has 24 rows")
f = P.call(s, 10, 40)
t.assert_equal(10, f.rows, "frame has 10 rows after shrinking")
t.assert_equal("a.txt", f.row_text(8)[0, 5], "status line moved to row 8")

t.finish
