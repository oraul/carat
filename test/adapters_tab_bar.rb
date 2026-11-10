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
    Carat::Adapters::TabBar.new(buffers: setup.list).paint(frame, setup.state, cols.to_i)
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
    t.table([
      ["a tab per file with its icon and modified dot", [["*src/a.rb", "b.txt"], 1, 1], " ◈ a.rb ●  • b.txt"],
      ["an unnamed buffer", [["", "b.txt"], 0, 1], " • [No Name]    • b.txt"],
      ["a scratch buffer has no tab", [["a.txt", "!", "b.txt"], 0, 1], " • a.txt    • b.txt"],
      ["an unlisted buffer has no tab", [["~a.txt", "b.txt", "c.txt"], 1, 1], " • b.txt    • c.txt"],
      ["an unlisted buffer at the end has no tab", [["a.txt", "b.txt", "~c.txt"], 0, 1], " • a.txt    • b.txt"],
      ["the tab-page numbers at the right end", [["a.txt", "b.txt"], 0, 2], " • a.txt    • b.txt" + (" " * 16) + "1  2"],
      ["tab pages without a second file", [["a.txt"], 0, 3], " • a.txt" + (" " * 24) + "1  2  3"]
    ]) { |input| paint(setup(input[0], input[1], input[2]), 40).row_text(0) }

    # Overflow: ten tabs of 12 cells in 40 columns, counted at the ends,
    # the current one always shown.
    t.table([
      ["the first current", 0, " • f0.txt    • f1.txt    8>"],
      ["the sixth current", 5, " <4  • f4.txt    • f5.txt    4>"],
      ["the last current", 9, " <8  • f8.txt    • f9.txt"]
    ]) { |current| paint(setup(ten, current, 1), 40).row_text(0) }
    t.assert_equal(" <1  • f1.txt    • f2.txt    • f3.txt    • f4.txt    • f5.txt    4>", paint(setup(ten, 5, 1), 70).row_text(0), "a wider row starts its run as early as the current tab allows")
    t.assert_equal(" • f0.txt", paint(setup(ten, 0, 1), 11).row_text(0), "a row narrower than the counts still shows the current tab, cut")
    t.table([
      ["unlisted buffers are neither shown nor counted", 5, " <2  • f4.txt    • f5.txt    3>"],
      ["a leading unlisted buffer is neither shown nor counted", 1, " • f1.txt    • f2.txt    5>"]
    ]) { |current| paint(setup(unlisted, current, 1), 40).row_text(0) }

    # Groups: the current tab selected with its icon's file-icon group,
    # the others plain, the counts plain, the rest the fill.
    f = paint(setup(["*src/a.rb", "b.txt"], 0, 2), 40)
    t.assert_equal([H::TAB_LINE_SELECTED, H::ICON_RUBY, H::TAB_LINE_SELECTED, H::TAB_LINE, H::TAB_LINE, H::TAB_LINE_FILL, H::TAB_LINE_SELECTED, H::TAB_LINE], [f.cell(0, 0).hl, f.cell(0, 1).hl, f.cell(0, 8).hl, f.cell(0, 10).hl, f.cell(0, 11).hl, f.cell(0, 30).hl, f.cell(0, 35).hl, f.cell(0, 38).hl], "selected tab, ruby icon, plain tab and its icon, fill, and the tab-page numbers")
    f = paint(setup(ten, 5, 1), 40)
    t.assert_equal([H::TAB_LINE, H::TAB_LINE], [f.cell(0, 1).hl, f.cell(0, 29).hl], "the counts are plain")

    t.finish
  end
end

AdaptersTabBarTest.main if __FILE__ == $0
