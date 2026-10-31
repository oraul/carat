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

# Delete and the C1 controls show as <xx> markers and never reach a cell raw.
def control_free?(frame)
  r = 0
  while r < frame.rows
    c = 0
    while c < frame.cols
      code = frame.cell(r, c).code
      return false if code != 0 && Carat::Domain::DisplayWidth.control?(code)
      c += 1
    end
    r += 1
  end
  true
end

markers = [
  ["U+007F shows as <7f>", "a\u007Fb", "a<7f>b"],
  ["U+0080 shows as <80>", "a\u0080b", "a<80>b"],
  ["U+009B shows as <9b>", "a\u009Bb", "a<9b>b"],
  ["U+009D shows as <9d>", "a\u009Db", "a<9d>b"],
]
t.table(markers) do |line|
  s = state_for([line], "a.txt")
  s.options.number = false
  P.call(s, 4, 12).row_text(0)
end
widths = [
  ["U+007F marker is four cells wide and the frame holds no control", "a\u007Fb", [6, "b", 1, true]],
  ["U+0080 marker is four cells wide and the frame holds no control", "a\u0080b", [6, "b", 1, true]],
  ["U+009B marker is four cells wide and the frame holds no control", "a\u009Bb", [6, "b", 1, true]],
  ["U+009D marker is four cells wide and the frame holds no control", "a\u009Db", [6, "b", 1, true]],
]
t.table(widths) do |line|
  s = state_for([line], "a.txt")
  s.options.number = false
  f = P.call(s, 4, 12)
  [P.display_width(line, 4), f.row_text(0)[5, 1], f.cell(0, 1).width, control_free?(f)]
end
s = state_for(["a\u009Bb"], "a.txt")
s.options.number = false
s.cursor.move_to(0, 1)
f = P.call(s, 4, 12)
t.assert_equal(1, f.cursor_col, "cursor on a C1 control sits on the first cell of its marker")
s.cursor.move_to(0, 2)
f = P.call(s, 4, 12)
t.assert_equal(5, f.cursor_col, "cursor after a C1 control is placed past its four cells")
s = state_for(["a\u009B\x01\u007F"], "a.txt")
s.options.number = false
f = P.call(s, 4, 12)
t.assert_equal("a<9b>^A<7f>", f.row_text(0), "markers and caret notation mix on one line")
t.assert_true(control_free?(f), "no cell holds a control code point after a mixed line")
direct = D::Frame.new(1, 6)
t.assert_equal(3, direct.put(0, 0, "a\u009Bb", D::Highlight::NORMAL), "put stores one cell per control code point")
t.assert_equal(["a", 0xFFFD, "b"], [direct.cell(0, 0).char, direct.cell(0, 1).code, direct.cell(0, 2).char], "put stores the replacement character for a C1 control")
direct.put(0, 0, "\x01\u007F", D::Highlight::NORMAL)
t.assert_equal([0xFFFD, 0xFFFD], [direct.cell(0, 0).code, direct.cell(0, 1).code], "put stores the replacement character for C0 and delete")
t.assert_true(control_free?(direct), "a frame written to directly holds no control code point")

# Resizing.
s = state_for(["ab"], "a.txt")
f = P.call(s, 24, 80)
t.assert_equal(24, f.rows, "frame has 24 rows")
f = P.call(s, 10, 40)
t.assert_equal(10, f.rows, "frame has 10 rows after shrinking")
t.assert_equal("a.txt", f.row_text(8)[0, 5], "status line moved to row 8")

# Reuse: a render of the same size repaints the same frame and cells.
first_cell = f.cell(0, 0)
s.buffer.insert(D::Position.new(0, 0), "x")
again = P.call(s, 10, 40)
t.assert_true(again.equal?(f), "a render of the same size reuses the frame")
t.assert_true(again.cell(0, 0).equal?(first_cell), "a render of the same size reuses the cells")
t.assert_equal("  1 xab", again.row_text(0), "the reused frame shows the new text")

# Two stacked windows: the layout is split after a first render sized the
# window, and the old window at the bottom stays current.
s = state_for(["one", "two", "three"], "a.txt")
P.call(s, 9, 14)
top = s.tab.layout.split(0, false, 0, 5)
f = P.call(s, 9, 14)
t.assert_equal(["  1 one", "  2 two", "  3 three"], f.text_rows[0, 3], "the top window shows the lines")
t.assert_equal("a.txt", f.row_text(3)[0, 5], "row 3 is the top window's status line")
t.assert_equal(["  1 one", "  2 two", "  3 three"], f.text_rows[4, 3], "the bottom window shows the same lines")
t.assert_equal("a.txt", f.row_text(7)[0, 5], "row 7 is the bottom window's status line")
t.assert_equal("", f.row_text(8), "row 8 is the message row")
t.assert_equal([D::Highlight::STATUS_NC, D::Highlight::STATUS], [f.cell(3, 0).hl, f.cell(7, 0).hl], "the current window's status line is highlighted, the other inactive")
s.window.cursor.move_to(1, 0)
f = P.call(s, 9, 14)
t.assert_equal([5, 4], [f.cursor_row, f.cursor_col], "the cursor is placed in the bottom window")
t.assert_equal(["1,1 All", "2,1 All"], [f.row_text(3)[-7, 7], f.row_text(7)[-7, 7]], "each status line shows its own cursor")
s.tab.focus(top)
f = P.call(s, 9, 14)
t.assert_equal([0, 4], [f.cursor_row, f.cursor_col], "focusing the top window moves the cursor there")
t.assert_equal([D::Highlight::STATUS, D::Highlight::STATUS_NC], [f.cell(3, 0).hl, f.cell(7, 0).hl], "the highlights follow the current window")

# Two windows side by side with the separator between them.
s = state_for(["one", "two"], "a.txt")
P.call(s, 6, 21)
s.tab.layout.split(0, true, 0, 5)
f = P.call(s, 6, 21)
t.assert_equal("  1 one   \u2502  1 one", f.row_text(0), "both windows on row 0 with the separator at column 10")
t.assert_equal("  2 two   \u2502  2 two", f.row_text(1), "row 1 too")
t.assert_equal("~         \u2502~", f.row_text(2), "tilde rows in both windows")
t.assert_equal(D::Highlight::STATUS, f.cell(0, 10).hl, "the separator carries the status highlight")
t.assert_equal(D::Highlight::NON_TEXT, f.cell(2, 0).hl, "the tilde keeps its highlight")
t.assert_equal(["a.txt", "a.txt"], [f.row_text(4)[0, 5], f.row_text(4)[11, 5]], "row 4 holds both status lines")
t.assert_equal(D::Highlight::STATUS, f.cell(4, 10).hl, "the separator continues through the status row")
t.assert_equal("", f.row_text(5), "row 5 is the message row")
t.assert_equal([0, 15], [f.cursor_row, f.cursor_col], "the cursor is in the right window, which stayed current")
s.buffer.modified = true
f = P.call(s, 6, 21)
t.assert_equal("a.txt [+]", f.row_text(4)[0, 9], "a status line clipped to its window still shows the marker")
t.assert_equal(" ", f.cell(4, 9).char, "the left status line stops before the separator")

# A long line is clipped at the window's edge.
s = state_for(["abcdefghijklmnopqrstuvwxyz"], "a.txt")
s.options.number = false
P.call(s, 4, 11)
s.tab.layout.split(0, true, 0, 1)
f = P.call(s, 4, 11)
t.assert_equal("abcde\u2502abcde", f.row_text(0), "each window shows what fits before its edge")

# Two tab pages: the tab line takes the top row.
s = state_for(["one", "two", "three"], "a.txt")
other = D::Buffer.new(["zz"], "b.txt", "\n")
s.add_buffer(other)
s.add_tab(D::TabPage.new(D::Window.new(other)))
s.tab_index = 0
f = P.call(s, 7, 30)
t.assert_equal(" 1 a.txt  2 b.txt", f.row_text(0), "the tab line lists both tab pages")
t.assert_equal([D::Highlight::TAB_LINE_SELECTED, D::Highlight::TAB_LINE, D::Highlight::TAB_LINE_FILL], [f.cell(0, 0).hl, f.cell(0, 9).hl, f.cell(0, 18).hl], "selected, plain, and fill highlights")
t.assert_equal("  1 one", f.row_text(1), "the first text row is row 1")
t.assert_equal("a.txt", f.row_text(5)[0, 5], "the status line is on row 5")
t.assert_equal("", f.row_text(6), "the message row stays last")
t.assert_equal([1, 4], [f.cursor_row, f.cursor_col], "the cursor is under the tab line")
s.tab_index = 1
other.modified = true
f = P.call(s, 7, 30)
t.assert_equal(" 1 a.txt  2 b.txt [+]", f.row_text(0), "the modified marker shows in the label")
t.assert_equal([D::Highlight::TAB_LINE, D::Highlight::TAB_LINE_SELECTED], [f.cell(0, 0).hl, f.cell(0, 9).hl], "the second label is selected now")
t.assert_equal("  1 zz", f.row_text(1), "the second tab page's window is drawn")
s.remove_tab(1)
f = P.call(s, 7, 30)
t.assert_equal("  1 one", f.row_text(0), "with one tab page there is no tab line")

# The sign column: two cells before the numbers while the buffer has signs.
s = state_for(["one", "two", "three"], "a.txt")
f = P.call(s, 6, 20)
t.assert_equal("  1 one", f.row_text(0), "no sign column without signs")
s.buffer.signs["1"] = "X"
s.buffer.sign_owners["1"] = "test"
f = P.call(s, 6, 20)
t.assert_equal(["    1 one", "X   2 two", "    3 three"], [f.row_text(0), f.row_text(1), f.row_text(2)], "the sign sits in its column and the numbers move right")
t.assert_equal([D::Highlight::LINE_NUMBER, D::Highlight::LINE_NUMBER], [f.cell(1, 0).hl, f.cell(0, 1).hl], "the sign column carries the line number highlight")
t.assert_equal([0, 6], [f.cursor_row, f.cursor_col], "the cursor moves right with the gutter")
s.options.number = false
f = P.call(s, 6, 20)
t.assert_equal(["  one", "X two"], [f.row_text(0), f.row_text(1)], "the sign column stays when numbers are off")
s.buffer.signs.clear
f = P.call(s, 6, 20)
t.assert_equal("one", f.row_text(0), "clearing the signs removes the column")

# A scratch buffer's status line shows its title; the current window's
# shows the plugins' segments.
s = state_for(["one"], "a.txt")
scratch = D::Buffer.new(["item"], nil, "\n")
scratch.owner = "test"
scratch.title = "list"
s.add_buffer(scratch)
P.call(s, 6, 40)
side = D::Window.new(scratch)
side.fixed_width = true
id = s.tab.layout.split_edge(side, 12, true)
f = P.call(s, 6, 40)
t.assert_equal("list", f.row_text(4)[0, 4], "the side window's status line shows the scratch title")
t.assert_equal("a.txt", f.row_text(4)[13, 5], "the file window keeps its path")
s.segments["hello"] = "hello 1"
s.segments["other"] = "x"
f = P.call(s, 6, 40)
t.assert_equal("a.txt  hello 1 x", f.row_text(4)[13, 16], "the current window's status line shows the segments in order")
t.assert_equal(["list", false], [f.row_text(4)[0, 4], f.row_text(4)[0, 12].include?("hello")], "the other window's does not")
s.tab.focus(id)
f = P.call(s, 6, 40)
t.assert_equal(["list  hello ", "a.txt   "], [f.row_text(4)[0, 12], f.row_text(4)[13, 8]], "the segments follow the current window, clipped to the window")
scratch.modified = true
f = P.call(s, 6, 40)
t.assert_equal("list [+]  he", f.row_text(4)[0, 12], "the modified marker comes before the segments")
t.assert_equal(["item", "  1 one"], [f.row_text(0)[0, 4], f.row_text(0)[13, 7]], "the side window has no line numbers while the file window keeps them")
scratch.signs["0"] = "!"
f = P.call(s, 6, 40)
t.assert_equal("! item", f.row_text(0)[0, 6], "its sign column still shows")

# A plugin's prompt takes the place of the colon, with the cursor after
# the text.
s = state_for(["one"], "a.txt")
s.mode = D::Mode::CMDLINE
s.prompt = "Rename to: "
s.prompt_owner = "test"
s.cmdline = "a.rb"
f = P.call(s, 6, 40)
t.assert_equal(["Rename to: a.rb", 5, 15], [f.row_text(5), f.cursor_row, f.cursor_col], "the prompt row and the cursor after it")
s.prompt_owner = ""
f = P.call(s, 6, 40)
t.assert_equal([":a.rb", 5], [f.row_text(5), f.cursor_col], "an ex command line keeps its colon")

# The visual selection: the Visual highlight on the selected cells of the
# current window, the cell under the cursor left in its own highlight.
VIS = D::Highlight::VISUAL
NOR = D::Highlight::NORMAL

# Renders lines in a visual mode with the anchor and the cursor given and
# returns the frame; tabstop is 4 and the gutter four cells wide.
def visual_frame(lines, mode, anchor, head)
  s = state_for(lines, "a.txt")
  s.mode = mode
  s.window.anchor = Carat::Domain::Position.new(anchor[0], anchor[1])
  s.cursor.move_to(head[0], head[1])
  P.call(s, 6, 20)
end

# The highlight of each cell of a row from frame column 4, where the text
# starts, for count cells.
def highlights(frame, row, count)
  out = []
  c = 4
  while c < 4 + count
    out << frame.cell(row, c).hl
    c += 1
  end
  out
end

f = visual_frame(["abc"], D::Mode::VISUAL, [0, 0], [0, 1])
t.assert_equal([VIS, NOR, NOR, NOR], highlights(f, 0, 4), "charwise: the anchor's cell is selected, the cursor's cell keeps its highlight")
t.assert_equal("-- VISUAL --", f.row_text(5), "the charwise mode line")
f = visual_frame(["ab", "cd"], D::Mode::VISUAL, [0, 1], [1, 0])
t.assert_equal([NOR, VIS, VIS], highlights(f, 0, 3), "charwise across lines selects the first row's line end")
t.assert_equal([NOR, NOR, NOR], highlights(f, 1, 3), "and stops at the cursor on the last row")
f = visual_frame(["ab", "cd"], D::Mode::VISUAL, [1, 1], [0, 1])
t.assert_equal([NOR, NOR, VIS], highlights(f, 0, 3), "with the cursor first, its row is selected after it")
t.assert_equal([VIS, VIS, NOR], highlights(f, 1, 3), "and the anchor's row up to the anchor")
f = visual_frame(["ab", "cd"], D::Mode::VISUAL_LINE, [0, 0], [0, 0])
t.assert_equal([NOR, VIS, VIS], highlights(f, 0, 3), "linewise selects the whole row and its line end")
t.assert_equal([NOR, NOR, NOR], highlights(f, 1, 3), "but not the next row")
t.assert_equal("-- VISUAL LINE --", f.row_text(5), "the linewise mode line")
f = visual_frame(["", "x"], D::Mode::VISUAL_LINE, [1, 0], [0, 0])
t.assert_equal([NOR, VIS], [f.cell(0, 4).hl, f.cell(1, 5).hl], "an empty line shows its selected line end, under the cursor here")
f = visual_frame(["abcd", "a\tb", "abcd"], D::Mode::VISUAL_BLOCK, [0, 1], [2, 2])
t.assert_equal([NOR, VIS, VIS, NOR], highlights(f, 0, 4), "blockwise: the block's columns on the first row")
t.assert_equal([NOR, VIS, VIS, NOR, NOR], highlights(f, 1, 5), "a tab is selected only in the block's columns")
t.assert_equal([NOR, VIS, NOR, NOR], highlights(f, 2, 4), "the cursor's cell keeps its highlight")
t.assert_equal("-- VISUAL BLOCK --", f.row_text(5), "the blockwise mode line")
f = visual_frame(["a中b", "abcd"], D::Mode::VISUAL_BLOCK, [0, 1], [1, 1])
t.assert_equal([NOR, VIS, VIS, NOR], highlights(f, 0, 4), "a wide character fills the block's two columns")
t.assert_equal([NOR, NOR, VIS, NOR], highlights(f, 1, 4), "the same columns on the next row")
s = state_for(["abc", "a"], "a.txt")
s.mode = D::Mode::VISUAL_BLOCK
s.window.anchor = D::Position.new(0, 1)
s.cursor.move_to(1, 1)
s.cursor.want_col = -1
f = P.call(s, 6, 20)
t.assert_equal([NOR, VIS, VIS, VIS], highlights(f, 0, 4), "after $ the block reaches every row's end")
t.assert_equal([NOR, NOR, NOR], highlights(f, 1, 3), "a shorter row ends at its line end, under the cursor here")
s = state_for(["abcd", "a", "abcd"], "a.txt")
s.mode = D::Mode::VISUAL_BLOCK
s.window.anchor = D::Position.new(0, 2)
s.cursor.move_to(2, 3)
f = P.call(s, 6, 20)
t.assert_equal([NOR, NOR], highlights(f, 1, 2), "a row ending before the block draws nothing")
s.mode = D::Mode::NORMAL
f = P.call(s, 6, 20)
t.assert_equal([NOR, NOR, NOR, NOR], highlights(f, 0, 4), "normal mode draws no selection")

# Two windows on one buffer: only the current one draws its selection.
s = state_for(["one", "two", "three"], "a.txt")
P.call(s, 9, 14)
s.tab.layout.split(0, false, 0, 5)
s.mode = D::Mode::VISUAL_LINE
s.window.anchor = D::Position.new(0, 0)
s.cursor.move_to(1, 0)
f = P.call(s, 9, 14)
t.assert_equal([VIS, VIS, VIS], highlights(f, 4, 3), "the current window, at the bottom, draws its selection")
t.assert_equal([NOR, NOR, NOR], highlights(f, 0, 3), "the other window on the same buffer draws none")
t.assert_equal([NOR, NOR, NOR], highlights(f, 1, 3), "on any row")

t.finish
