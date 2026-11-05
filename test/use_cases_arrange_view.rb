require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module UseCasesArrangeViewTest
  D = Carat::Domain

  #: (Integer) -> Array[String]
  def self.numbered(count)
    out = []
    i = 0
    while i < count
      out << "line #{i}"
      i += 1
    end
    out
  end

  #: (Array[String]) -> Carat::Domain::EditorState
  def self.state_for(lines)
    options = Carat::Domain::Options.new
    options.number = false
    options.scrolloff = 0
    Carat::Domain::EditorState.new(tabs: Carat::Domain::TabList.new(window: Carat::Domain::Window.new(buffer: Carat::Domain::Buffer.new(lines: lines, path: "a.txt", line_ending: "\n"))), options: options)
  end

  #: (Carat::Domain::Window) -> Array[Integer]
  def self.rect(window)
    [window.row, window.col, window.height, window.width]
  end

  def self.main
    t = Carat::Testing.new("use_cases_arrange_view")

    listed = D::BufferList.new(tabs: D::TabList.new(window: D::Window.new(buffer: D::Buffer.new(lines: [""], path: nil, line_ending: "\n"))))
    arrange = Carat::UseCases::ArrangeView.new(cache: D::LineCache.new, buffers: listed)

    # Nothing happens before the size is known.
    s = state_for(numbered(40))
    arrange.call(s)
    t.assert_equal([0, 0, 0, 0], rect(s.window), "before the size is known the window keeps no rectangle")
    s.resize(10, 40)
    t.assert_equal([10, 40], [s.screen_rows, s.screen_cols], "the size is recorded in the state")

    # The layout gets every row but the message row.
    arrange.call(s)
    t.assert_equal([0, 0, 8, 40], rect(s.window), "one window takes the rows above its status line and the message row")

    # Two listed file buffers, or two tab pages, give the top row to the
    # buffer tabs; a scratch buffer does not count.
    t.assert_equal([false, false, true], [listed.tab_row?(1), listed.tab_row?(0), listed.tab_row?(2)], "one tab page and no files has no tabs row, two tab pages have one")
    listed.add(D::Buffer.new(lines: [""], path: "a.txt", line_ending: "\n"))
    scratch = D::Buffer.new(lines: [""], path: nil, line_ending: "\n")
    scratch.owner = "tree"
    scratch.title = "tree"
    listed.add(scratch)
    t.assert_equal(false, listed.tab_row?(1), "one file and a scratch buffer have no tabs row")
    listed.add(D::Buffer.new(lines: [""], path: "b.txt", line_ending: "\n"))
    arrange.call(s)
    t.assert_equal([1, 0, 7, 40], rect(s.window), "with two files listed the window starts under the tabs row")
    listed.remove(listed.buffer_at(2))
    arrange.call(s)

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

    # The clamp and the scrolloff cap that ArrangeView and ScrollWindow share.
    w = s.window
    t.assert_equal(32, w.max_top(40), "the last first-shown line fills the window to the last line")
    t.assert_equal(0, w.max_top(5), "a buffer shorter than the window has max top 0")
    t.assert_equal(2, w.margin(2), "a scrolloff under half the window is kept")
    t.assert_equal(3, w.margin(99), "scrolloff is capped at half the window")
    w.scroll_top_to(50, 40)
    t.assert_equal(32, w.top, "scroll_top_to clamps a top past the end to max top")
    w.scroll_top_to(-4, 40)
    t.assert_equal(0, w.top, "scroll_top_to clamps a negative top to the first line")
    w.scroll_top_to(7, 40)
    t.assert_equal(7, w.top, "scroll_top_to keeps a top in range")

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
    s.tabs.add_tab(D::TabPage.new(window: D::Window.new(buffer: D::Buffer.new(lines: ["b"], path: "b.txt", line_ending: "\n"))))
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
  end
end

UseCasesArrangeViewTest.main if __FILE__ == $0
