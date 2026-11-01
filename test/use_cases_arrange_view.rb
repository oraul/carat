require_relative "../carat/test_support"
require_relative "../carat/testing"

t = Carat::Testing.new("use_cases_arrange_view")
D = Carat::Domain

#: (Integer) -> Array[String]
def numbered(count)
  out = []
  i = 0
  while i < count
    out << "line #{i}"
    i += 1
  end
  out
end

#: (Array[String]) -> Carat::Domain::EditorState
def state_for(lines)
  options = Carat::Domain::Options.new
  options.number = false
  options.scrolloff = 0
  Carat::Domain::EditorState.new(Carat::Domain::TabList.new(Carat::Domain::Window.new(Carat::Domain::Buffer.new(lines, "a.txt", "\n"))), options)
end

#: (Carat::Domain::Window) -> Array[Integer]
def rect(window)
  [window.row, window.col, window.height, window.width]
end

arrange = Carat::UseCases::ArrangeView.new(cache: D::LineCache.new)

# Nothing happens before the size is known.
s = state_for(numbered(40))
arrange.call(s)
t.assert_equal([0, 0, 0, 0], rect(s.window), "before the size is known the window keeps no rectangle")
s.resize(10, 40)
t.assert_equal([10, 40], [s.screen_rows, s.screen_cols], "the size is recorded in the state")

# The layout gets every row but the message row.
arrange.call(s)
t.assert_equal([0, 0, 8, 40], rect(s.window), "one window takes the rows above its status line and the message row")

# Vertical scrolling to the cursor, both ways, with scrolloff.
s.cursor.move_to(20, 0)
arrange.call(s)
t.assert_equal(13, s.window.top, "a cursor below the window scrolls it down until the cursor is on the last row")
s.cursor.move_to(2, 0)
arrange.call(s)
t.assert_equal(2, s.window.top, "a cursor above the window scrolls it up until the cursor is on the first row")
s.options.scrolloff = 2
s.cursor.move_to(30, 0)
arrange.call(s)
t.assert_equal(25, s.window.top, "scrolloff keeps rows below the cursor")

# Horizontal scrolling to the cursor's display column.
s = state_for(["é" + "a" * 99])
s.resize(10, 40)
s.cursor.move_to(0, 50)
arrange.call(s)
t.assert_equal(11, s.window.left, "a cursor past the right edge scrolls the window right")
s.cursor.move_to(0, 5)
arrange.call(s)
t.assert_equal(5, s.window.left, "a cursor left of the window scrolls it back")
s = state_for(["\t\tx"])
s.resize(10, 6)
s.cursor.move_to(0, 2)
arrange.call(s)
t.assert_equal(11, s.window.left, "tabs count with their display width")

# The tab line takes the top row when there are several tab pages.
s = state_for(numbered(3))
s.resize(10, 40)
s.tabs.add_tab(D::TabPage.new(D::Window.new(D::Buffer.new(["b"], "b.txt", "\n"))))
s.tabs.tab_index = 0
arrange.call(s)
t.assert_equal([1, 0, 7, 40], rect(s.window), "the windows start under the tab line")

# Two splits with no frame between them: the second split sees the
# rectangle the first one left.
files = Carat::Doubles::MemoryFiles.new
files.put("a.txt", numbered(40).join("\n") + "\n")
h = Carat::Doubles::EditorHarness.default(files, 24, 80)
h.open("a.txt")
assembly = h.assembly
codes = D::KeyNotation.parse("<C-w>s<C-w>s", "").codes
i = 0
while i < codes.length
  assembly.handle_key.call(assembly.state, codes[i])
  i += 1
end
heights = []
windows = h.windows
i = 0
while i < windows.length
  heights << windows[i][2]
  i += 1
end
t.assert_equal([5, 5, 10], heights, "two splits typed with no frame between them give 5, 5, and 10 text rows")
t.assert_equal(1, h.window_index, "the top window is current")
t.assert_equal("", h.message, "no split reported E36")

# A screen motion after a jump with no frame between them.
h = Carat::Doubles::EditorHarness.default(files, 10, 40)
h.open("a.txt")
assembly = h.assembly
assembly.state.options.scrolloff = 0
codes = D::KeyNotation.parse("30GH", "").codes
i = 0
while i < codes.length
  assembly.handle_key.call(assembly.state, codes[i])
  i += 1
end
t.assert_equal([22, 0], h.cursor, "H after 30G goes to line 23, the top line the window shows after the jump")

t.finish
