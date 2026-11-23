require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module AdaptersTabBarTest
  D = Carat::Domain
  H = D::Highlight

  # The paths listed and the one current, as a state and its buffer list.
  class Setup
    attr_reader :state #: Carat::Domain::EditorState
    attr_reader :list #: Carat::Domain::BufferList

    def initialize(state:, list:)
      @state = state
      @list = list
    end
  end

  # Lists a buffer per path ("" for an unnamed one, "*" before a path for
  # a modified one, "~" before a path for one a jump left unlisted, "!"
  # for a scratch buffer), the one at current shown in the current
  # window, with pages tab pages and the unicode icons.
  def self.setup(paths, current, pages)
    names = []
    paths.each { |p| names << p.to_s }
    buffers = []
    names.each do |name|
      path = name.delete_prefix("*").delete_prefix("~")
      buffer = D::Buffer.new(lines: ["x"], path: path.empty? || path == "!" ? nil : path, line_ending: "\n")
      buffer.mark_unsaved if name.start_with?("*")
      if path == "!"
        buffer.owner = "tree"
        buffer.title = "tree"
      end
      buffers << buffer
    end
    tabs = D::TabList.new(window: D::Window.new(buffer: buffers[current.to_i]))
    (pages.to_i - 1).times { tabs.add_tab(D::TabPage.new(window: D::Window.new(buffer: buffers[0]))) }
    tabs.tab_index = 0
    list = D::BufferList.new(tabs: tabs)
    buffers.each { |b| list.add(b) }
    names.each_with_index { |name, i| buffers[i].listed = false if name.start_with?("~") }
    options = D::Options.new
    options.icons = "unicode"
    Setup.new(state: D::EditorState.new(tabs: tabs, options: options), list: list)
  end

  # The row the tab bar paints for a setup, cols wide.
  def self.paint(setup, cols)
    frame = D::Frame.new(rows: 1, cols: cols.to_i)
    Carat::Adapters::TabBar.new(buffers: setup.list).paint(frame, setup.state, 0, cols.to_i)
    frame
  end

  # The paths f0.txt to f9.txt.
  def self.ten
    out = []
    10.times { |i| out << "f#{i}.txt" }
    out
  end

  # The paths f0.txt to f9.txt, f0.txt, f3.txt, and f9.txt a jump left
  # unlisted: seven tabs.
  def self.unlisted
    out = []
    ten.each { |path| out << (path == "f0.txt" || path == "f3.txt" || path == "f9.txt" ? "~" + path : path) }
    out
  end

  def self.main
    t = Carat::Testing.new("adapters_tab_bar")

    # One row per case, 40 columns wide.
    t.cases([
      ["two tabs, one modified: a tab per file with no icon and the modified dot", [["*src/a.rb", "b.txt"], 1, 1], "  a.rb ●   b.txt"],
      ["an unnamed buffer", [["", "b.txt"], 0, 1], "  " + Carat::Domain::Messages::NO_NAME + "     b.txt"],
      ["a buffer at the root shows / in its tab", [["/", "b.txt"], 0, 1], "  /     b.txt"],
      ["a scratch buffer has no tab", [["a.txt", "!", "b.txt"], 0, 1], "  a.txt     b.txt"],
      ["an unlisted buffer has no tab", [["~a.txt", "b.txt", "c.txt"], 1, 1], "  b.txt     c.txt"],
      ["an unlisted buffer at the end has no tab", [["a.txt", "b.txt", "~c.txt"], 0, 1], "  a.txt     b.txt"],
      ["the tab-page numbers at the right end", [["a.txt", "b.txt"], 0, 2], "  a.txt     b.txt" + (" " * 18) + "1  2"],
      ["tab pages without a second file", [["a.txt"], 0, 3], "  a.txt   " + (" " * 22) + "1  2  3"]
    ]) { |input| paint(setup(input[0], input[1], input[2]), 40).row_text(0) }

    # Overflow: ten tabs of 12 cells in 40 columns, counted at the ends,
    # the current one always shown.
    t.table([
      ["the first current", 0, "  f0.txt     f1.txt    8>"],
      ["the sixth current", 5, " <4   f4.txt     f5.txt    4>"],
      ["the last current", 9, " <8   f8.txt     f9.txt"]
    ]) { |current| paint(setup(ten, current, 1), 40).row_text(0) }
    t.assert_equal(" <1   f1.txt     f2.txt     f3.txt     f4.txt     f5.txt    4>", paint(setup(ten, 5, 1), 70).row_text(0), "a wider row starts its run as early as the current tab allows")
    t.assert_equal("  f0.txt", paint(setup(ten, 0, 1), 11).row_text(0), "a row narrower than the counts still shows the current tab, cut")
    t.table([
      ["unlisted buffers are neither shown nor counted", 5, " <2   f4.txt     f5.txt    3>"],
      ["a leading unlisted buffer is neither shown nor counted", 1, "  f1.txt     f2.txt    5>"]
    ]) { |current| paint(setup(unlisted, current, 1), 40).row_text(0) }

    # Scenarios "Two tabs, one modified" (the first row of the cases above) and "The selected tab has no icon and no fill":
    # the current tab in TabLineSel, the others in TabLine, the current page number bold in TabLineName and
    # the other dim in TabLine, the rest the fill.
    f = paint(setup(["*src/a.rb", "b.txt"], 0, 2), 40)
    t.assert_equal([H::TAB_LINE_SELECTED, H::TAB_LINE_SELECTED, H::TAB_LINE_SELECTED, H::TAB_LINE, H::TAB_LINE, H::TAB_LINE, H::TAB_LINE_FILL, H::TAB_LINE_NAME, H::TAB_LINE], [f.cell(0, 0).hl, f.cell(0, 2).hl, f.cell(0, 8).hl, f.cell(0, 9).hl, f.cell(0, 10).hl, f.cell(0, 18).hl, f.cell(0, 30).hl, f.cell(0, 35).hl, f.cell(0, 38).hl], "selected tab with its leading space, the plain tab in TabLine, fill, and the tab-page numbers: the current one TabLineName, the other TabLine")

    # Scenario "The tab row at 16 colors and NO_COLOR": bare, the row has no fill, the selected tab and the
    # current page number are in TabLineSel and every other name and count in Normal.
    bare = setup(["a.txt", "b.txt"], 0, 2)
    frame = D::Frame.new(rows: 1, cols: 40)
    bar = Carat::Adapters::TabBar.new(buffers: bare.list)
    bar.bare = true
    bar.paint(frame, bare.state, 0, 40)
    t.assert_equal(["  a.txt     b.txt", H::TAB_LINE_SELECTED, H::NORMAL, H::NORMAL, H::TAB_LINE_SELECTED, H::NORMAL], [frame.row_text(0)[0, 17], frame.cell(0, 3).hl, frame.cell(0, 13).hl, frame.cell(0, 25).hl, frame.cell(0, 35).hl, frame.cell(0, 38).hl], "bare: the selected tab and the current page in TabLineSel, the other tab, the fill, and the other page in Normal")
    filled = paint(setup(["a.txt", "b.txt"], 0, 2), 40)
    t.assert_equal([H::TAB_LINE_FILL, H::TAB_LINE_NAME], [filled.cell(0, 25).hl, filled.cell(0, 35).hl], "not bare, the fill and the TabLineName page number are back")

    # Scenario "The tab row at 16 colors and NO_COLOR", the overflow counts: bare, both counts are in Normal and the
    # current tab keeps its bold TabLineSel.
    cut = setup(ten, 5, 1)
    cut_frame = D::Frame.new(rows: 1, cols: 40)
    cut_bar = Carat::Adapters::TabBar.new(buffers: cut.list)
    cut_bar.bare = true
    cut_bar.paint(cut_frame, cut.state, 0, 40)
    cut_text = cut_frame.row_text(0)
    t.assert_equal([" <4   f4.txt     f5.txt    4>", H::NORMAL, H::NORMAL, H::NORMAL, H::TAB_LINE_SELECTED], [cut_text.rstrip, cut_frame.cell(0, 1).hl, cut_frame.cell(0, 2).hl, cut_frame.cell(0, cut_text.rstrip.length - 2).hl, cut_frame.cell(0, cut_text.index("f5.txt")).hl], "bare: the counts before and after the run are in Normal, the current tab in TabLineSel")

    # The modified mark keeps the tab's width: the second tab starts at
    # the same column whether the first is modified, in every icon set.
    t.table([
      ["nerd", "nerd", [true, true]],
      ["unicode", "unicode", [true, true]],
      ["ascii", "ascii", [true, true]]
    ]) do |set|
      plain = setup(["a.rb", "b.txt"], 1, 1)
      marked = setup(["*a.rb", "b.txt"], 1, 1)
      plain.state.options.icons = set.to_s
      marked.state.options.icons = set.to_s
      before = paint(plain, 40).row_text(0)
      after = paint(marked, 40).row_text(0)
      [before.index("b.txt") == after.index("b.txt"), before != after]
    end
    f = paint(setup(ten, 5, 1), 40)
    t.assert_equal([H::TAB_LINE, H::TAB_LINE], [f.cell(0, 1).hl, f.cell(0, f.row_text(0).index("4>").to_i).hl], "the counts are plain")

    # Scenario "Tabs under every icon set": no set draws a file icon or a gem, so the ascii `*` stays the modified
    # mark's alone and no separator ends a tab, in every icon set.
    t.table([
      ["no gem, separator, unicode", "unicode", "  a.txt     b.txt"],
      ["no gem, separator, nerd", "nerd", "  a.txt     b.txt"],
      ["no gem, separator, ascii", "ascii", "  a.txt     b.txt"]
    ]) do |set|
      one = setup(["a.txt", "b.txt"], 0, 1)
      one.state.options.icons = set.to_s
      paint(one, 40).row_text(0)
    end
    # The selected tab is told apart by its group alone: its first and last cells are in TabLineSel (bold on the editor's background), the other tab's in TabLine, and
    # no separator stands between or after them: the cell after the tab run is the fill.
    f = paint(setup(["a.txt", "b.txt"], 0, 1), 40)
    t.assert_equal([H::TAB_LINE_SELECTED, H::TAB_LINE_SELECTED, H::TAB_LINE, H::TAB_LINE, H::TAB_LINE_FILL], [f.cell(0, 0).hl, f.cell(0, 9).hl, f.cell(0, 10).hl, f.cell(0, 19).hl, f.cell(0, 20).hl], "the selected tab's cells are in the selected group, the other tab's in TabLine, no separator between or after them")
    ascii = setup(["*a.txt", "b.txt"], 0, 1)
    ascii.state.options.icons = "ascii"
    t.assert_equal("  a.txt *   b.txt", paint(ascii, 40).row_text(0), "under ascii the only * in a row is the modified mark")

    # Scenario "The row starts at the editor's first column": the cells before the start column are the
    # caller's, the first tab starts at it, the overflow counts and the run use the columns from it, and a
    # start past the width paints nothing.
    side = setup(["a.txt", "b.txt"], 0, 1)
    frame = D::Frame.new(rows: 1, cols: 40)
    frame.put(0, 0, "sidebar", H::NORMAL)
    Carat::Adapters::TabBar.new(buffers: side.list).paint(frame, side.state, 14, 40)
    t.assert_equal(["sidebar", "  a.txt     b.txt"], [frame.row_text(0)[0, 7], frame.row_text(0)[14, 17]], "the first tab starts at the start column and the cells before it are left alone")
    t.assert_equal([H::NORMAL, H::TAB_LINE_SELECTED, H::TAB_LINE_FILL], [frame.cell(0, 13).hl, frame.cell(0, 14).hl, frame.cell(0, 39).hl], "no fill before the start column, the first tab selected from it")
    far = setup(ten, 5, 2)
    frame = D::Frame.new(rows: 1, cols: 40)
    Carat::Adapters::TabBar.new(buffers: far.list).paint(frame, far.state, 14, 40)
    t.assert_equal(["", true, " 1  2"], [frame.row_text(0)[0, 13].strip, frame.row_text(0)[14, 20].include?("f5.txt"), frame.row_text(0)[34, 6].to_s], "overflow and the tab-page numbers stay in the columns from the start")
    frame = D::Frame.new(rows: 1, cols: 20)
    Carat::Adapters::TabBar.new(buffers: side.list).paint(frame, side.state, 30, 20)
    t.assert_equal("", frame.row_text(0), "a start past the width paints no tab")

    # Scenario "The sidebar's head reads the project and branch": the last segment of the base directory
    # bright, a faint dot, and the branch dim, all in the sidebar's layer, cut at the sidebar's edge; with no
    # branch the project alone, with the ascii icons a hyphen for the dot.
    headed = setup(["a.txt", "b.txt"], 0, 1)
    headed.list.base = "/work/carat"
    bar = Carat::Adapters::TabBar.new(buffers: headed.list)
    layer = H::SIDEBAR_LAYER
    frame = D::Frame.new(rows: 2, cols: 20)
    bar.paint_head(frame, 0, 0, 14, "main", "unicode")
    t.assert_equal([" carat · main", layer + H::NORMAL, layer + H::NORMAL, layer + H::NON_TEXT, layer + H::MESSAGE_DIM, layer + H::NORMAL], [frame.row_text(0), frame.cell(0, 0).hl, frame.cell(0, 1).hl, frame.cell(0, 7).hl, frame.cell(0, 9).hl, frame.cell(0, 13).hl], "the project, the dot, and the branch in their groups on the sidebar's layer")
    frame = D::Frame.new(rows: 1, cols: 20)
    bar.paint_head(frame, 0, 0, 14, "", "unicode")
    t.assert_equal(" carat", frame.row_text(0), "no branch leaves the project alone")
    frame = D::Frame.new(rows: 1, cols: 20)
    bar.paint_head(frame, 0, 0, 14, "main", "ascii")
    t.assert_equal(" carat - main", frame.row_text(0), "the ascii icons draw a hyphen for the dot")
    frame = D::Frame.new(rows: 1, cols: 20)
    bar.paint_head(frame, 0, 0, 8, "main", "unicode")
    t.assert_equal(" carat ·", frame.row_text(0), "the head is cut at the sidebar's edge")
    headed.list.base = "/"
    frame = D::Frame.new(rows: 1, cols: 20)
    bar.paint_head(frame, 0, 0, 14, "main", "unicode")
    t.assert_equal(" / · main", frame.row_text(0), "the root directory is its own name")
    headed.list.base = ""
    frame = D::Frame.new(rows: 1, cols: 20)
    bar.paint_head(frame, 0, 0, 14, "main", "unicode")
    t.assert_equal(" main", frame.row_text(0), "no base shows the branch alone")

    # TabBar#showing? tells whether the row shows as BufferList#tab_row? does, which FramePresenter
    # and ArrangeView agree on: rows are [label, paths, pages, showtabline, expected].
    [
      ["one file at 1 shows no row", ["a.txt"], 1, 1, false],
      ["two files at 1 show the row", ["a.txt", "b.txt"], 1, 1, true],
      ["one file on two tab pages at 1 shows the row", ["a.txt"], 2, 1, true],
      ["two files at 0 show no row", ["a.txt", "b.txt"], 1, 0, false],
      ["one file at 2 shows the row", ["a.txt"], 1, 2, true]
    ].each do |label, paths, pages, showtabline, expected|
      list = setup(paths, 0, pages)
      t.assert_equal(expected, Carat::Adapters::TabBar.new(buffers: list.list).showing?(list.state.tabs.tab_count, showtabline), "showing?: #{label}")
    end

    t.finish
  end
end

AdaptersTabBarTest.main if __FILE__ == $0
