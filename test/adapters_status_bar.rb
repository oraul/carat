require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module AdaptersStatusBarTest
  D = Carat::Domain
  H = D::Highlight
  UI = D::PluginUi.new
  SLOTS = D::StatusSlots.new
  BAR = Carat::Adapters::StatusBar.new(plugin_ui: UI, slots: SLOTS)

  # A state over one ten-row window of the lines, with the unicode icons;
  # the slots and the plugins' segments start empty.
  def self.state_for(path, count)
    lines = []
    count.to_i.times { |i| lines << "line #{i + 1}" }
    buffer = D::Buffer.new(lines: lines, path: path, line_ending: "\n")
    options = D::Options.new
    options.icons = "unicode"
    s = D::EditorState.new(tabs: D::TabList.new(window: D::Window.new(buffer: buffer)), options: options)
    s.window.height = 10
    SLOTS.branch = ""
    SLOTS.errors = 0
    SLOTS.warnings = 0
    SLOTS.infos = 0
    SLOTS.hints = 0
    SLOTS.lsp_name = ""
    SLOTS.lsp_state = :none
    UI.segments.clear
    UI.owners.clear
    UI.priorities.clear
    s
  end

  # The bar of a state painted on a frame of one row, cols wide.
  def self.paint(state, cols)
    frame = D::Frame.new(rows: 1, cols: cols.to_i)
    BAR.paint(frame, 0, cols.to_i, state)
    frame
  end

  # The row a bar of width cols shows with left at the left and right at
  # the right end, its trailing blanks removed as row_text removes them.
  def self.pad(left, right, cols)
    (left.to_s + " " * (cols.to_i - left.to_s.length - right.to_s.length) + right.to_s).rstrip
  end

  # The lsp state of its name.
  def self.lsp_state_of(name)
    case name.to_s
    when "starting" then :starting
    when "ready" then :ready
    when "error" then :error
    else :none
    end
  end

  # The state of a named case.
  def self.scenario(name)
    case name.to_s
    when "modified"
      s = state_for("a.txt", 3)
      s.buffer.mark_unsaved
      s
    when "unnamed"
      state_for(nil, 1)
    when "scratch"
      s = state_for(nil, 1)
      s.buffer.owner = "tree"
      s.buffer.title = "list"
      s
    when "ruby"
      state_for("a.rb", 3)
    when "branch"
      s = state_for("a.txt", 3)
      SLOTS.branch = "main"
      s
    when "two counts"
      s = state_for("a.txt", 3)
      SLOTS.errors = 2
      SLOTS.hints = 1
      s
    when "four counts"
      s = state_for("a.txt", 3)
      SLOTS.errors = 1
      SLOTS.warnings = 2
      SLOTS.infos = 3
      SLOTS.hints = 4
      s
    when "lsp"
      s = state_for("a.txt", 3)
      SLOTS.lsp_name = "ruby-lsp"
      SLOTS.lsp_state = :ready
      s
    when "plugin and lsp"
      s = state_for("a.txt", 3)
      UI.segment("probe", "x", 10)
      SLOTS.lsp_name = "ruby-lsp"
      s
    when "cursor at the top"
      s = state_for("a.txt", 100)
      s.cursor.move_to(4, 2)
      s
    when "cursor in the middle"
      s = state_for("a.txt", 100)
      s.window.top = 45
      s.cursor.move_to(50, 0)
      s
    when "cursor at the bottom"
      s = state_for("a.txt", 100)
      s.window.top = 90
      s.cursor.move_to(99, 0)
      s
    else
      state_for("a.txt", 3)
    end
  end

  def self.main
    t = Carat::Testing.new("adapters_status_bar")
    right = " utf-8  1:1  All "

    # One row per segment, 60 columns wide, the unicode icons.
    t.table([
      ["the mode and the file", "plain", pad(" NORMAL  a.txt ", right, 60)],
      ["the modified icon after the file", "modified", pad(" NORMAL  a.txt ● ", right, 60)],
      ["an unnamed buffer", "unnamed", pad(" NORMAL  [No Name] ", right, 60)],
      ["a scratch title", "scratch", pad(" NORMAL  list ", right, 60)],
      ["the file type", "ruby", pad(" NORMAL  a.rb ", " ruby " + right, 60)],
      ["the git branch", "branch", pad(" NORMAL  a.txt  ± main ", right, 60)],
      ["the counts above zero", "two counts", pad(" NORMAL  a.txt  ✖ 2 ◇ 1 ", right, 60)],
      ["every count in order", "four counts", pad(" NORMAL  a.txt  ✖ 1 ▲ 2 ◆ 3 ◇ 4 ", right, 60)],
      ["the lsp slot", "lsp", pad(" NORMAL  a.txt ", " ruby-lsp " + right, 60)],
      ["the lsp slot after the plugins' segments", "plugin and lsp", pad(" NORMAL  a.txt ", " x  ruby-lsp " + right, 60)],
      ["the position and Top", "cursor at the top", pad(" NORMAL  a.txt ", " utf-8  5:3  Top ", 60)],
      ["a percentage", "cursor in the middle", pad(" NORMAL  a.txt ", " utf-8  51:1  50% ", 60)],
      ["Bot", "cursor at the bottom", pad(" NORMAL  a.txt ", " utf-8  100:1  Bot ", 60)]
    ]) { |name| paint(scenario(name), 60).row_text(0) }

    # Empty slots take no cells: the bar is the same as without them.
    plain = paint(scenario("plain"), 60).row_text(0)
    SLOTS.lsp_state = :error
    t.assert_equal(plain, paint(scenario("plain"), 60).row_text(0), "an lsp state without a server name shows nothing")

    # One row per width: segments go by priority, the file is cut last.
    t.table([
      ["40 columns keep every segment", 40, pad(" NORMAL  a.rb ", " ruby  utf-8  1:1  All ", 40)],
      ["30 columns drop the encoding", 30, pad(" NORMAL  a.rb ", " ruby  1:1  All ", 30)],
      ["25 columns drop the file type", 25, pad(" NORMAL  a.rb ", " 1:1  All ", 25)],
      ["22 columns drop the percent", 22, pad(" NORMAL  a.rb ", " 1:1 ", 22)],
      ["17 columns drop the position", 17, " NORMAL  a.rb"],
      ["12 columns cut the file", 12, " NORMAL  a.r"],
      ["6 columns cut the pill", 6, " NORMA"]
    ]) { |cols| paint(scenario("ruby"), cols).row_text(0) }

    # The diagnostics outlast the lsp slot, the percent, and the branch.
    s = scenario("four counts")
    SLOTS.lsp_name = "ruby-lsp"
    SLOTS.branch = "main"
    t.assert_equal(pad(" NORMAL  a.txt  ✖ 1 ▲ 2 ◆ 3 ◇ 4 ", " 1:1 ", 40), paint(s, 40).row_text(0), "at 40 columns the counts stay with the position")

    # A plugin's segment by its priority.
    s = scenario("plain")
    UI.segment("high", "hi", 95)
    UI.segment("low", "lo", 10)
    t.assert_equal(pad(" NORMAL  a.txt ", " hi  lo  utf-8  1:1  All ", 60), paint(s, 60).row_text(0), "both segments in the order they were set")
    t.assert_equal(pad(" NORMAL  a.txt ", " hi  1:1  All ", 32), paint(s, 32).row_text(0), "the segment of priority 10 goes before the encoding")
    t.assert_equal(pad(" NORMAL  a.txt ", " hi ", 20), paint(s, 20).row_text(0), "the segment of priority 95 outlasts the position")

    # The pill names the mode and takes its group.
    t.table([
      ["normal", D::Mode::NORMAL, [" NORMAL ", H::STATUS_MODE_NORMAL]],
      ["insert", D::Mode::INSERT, [" INSERT ", H::STATUS_MODE_INSERT]],
      ["visual", D::Mode::VISUAL, [" VISUAL ", H::STATUS_MODE_VISUAL]],
      ["visual line", D::Mode::VISUAL_LINE, [" V-LINE ", H::STATUS_MODE_VISUAL]],
      ["visual block", D::Mode::VISUAL_BLOCK, [" V-BLOCK ", H::STATUS_MODE_VISUAL]],
      ["replace", D::Mode::REPLACE, [" REPLACE ", H::STATUS_MODE_REPLACE]],
      ["operator pending", D::Mode::OPERATOR_PENDING, [" O-PENDING ", H::STATUS_MODE_NORMAL]],
      ["command line", D::Mode::CMDLINE, [" COMMAND ", H::STATUS_MODE_COMMAND]]
    ]) do |mode|
      s = scenario("plain")
      s.mode = mode.is_a?(Symbol) ? mode : D::Mode::NORMAL
      f = paint(s, 60)
      text = f.row_text(0)
      width = text.index("a.txt").to_i - 1
      [text[0, width], f.cell(0, 1).hl]
    end
    f = paint(scenario("plain"), 60)
    t.assert_equal([H::STATUS_MODE_NORMAL, H::STATUS, H::STATUS, H::STATUS], [f.cell(0, 7).hl, f.cell(0, 8).hl, f.cell(0, 30).hl, f.cell(0, 59).hl], "the pill ends at its closing space and the status group fills the rest")

    # The lsp slot's group follows its state; the counts take theirs.
    t.table([
      ["starting", "starting", H::STATUS_LSP_STARTING],
      ["ready", "ready", H::STATUS_LSP_READY],
      ["error", "error", H::STATUS_LSP_ERROR]
    ]) do |state|
      s = scenario("lsp")
      SLOTS.lsp_state = lsp_state_of(state)
      f = paint(s, 60)
      at = f.row_text(0).index("ruby-lsp").to_i
      [f.cell(0, at - 1).hl, f.cell(0, at).hl, f.cell(0, at + 8).hl].uniq.length == 1 ? f.cell(0, at).hl : -1
    end
    f = paint(scenario("four counts"), 60)
    text = f.row_text(0)
    t.assert_equal([H::DIAGNOSTIC_ERROR, H::DIAGNOSTIC_WARN, H::DIAGNOSTIC_INFO, H::DIAGNOSTIC_HINT, H::DIAGNOSTIC_HINT], [f.cell(0, text.index("✖").to_i).hl, f.cell(0, text.index("▲").to_i).hl, f.cell(0, text.index("◆").to_i).hl, f.cell(0, text.index("4").to_i).hl, f.cell(0, text.index("4").to_i + 1).hl], "each count in its diagnostic group, the closing space in the last one's")

    # The slots are empty until a service fills them.
    empty = D::StatusSlots.new
    t.assert_equal(["", false, false, :none], [empty.branch, empty.diagnostics?, empty.lsp?, empty.lsp_state], "new slots are empty")

    t.finish
  end
end

AdaptersStatusBarTest.main if __FILE__ == $0
