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
    SLOTS.set_lsp("", :none, 0)
    SLOTS.clear_progress
    BAR.plain = false
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
  # The bar of a plain scenario 60 wide after progress titled title with
  # each report's percent (-1 for none), reduced motion and plain as given.
  def self.progress(title, percents, reduced, plain)
    s = scenario("plain")
    s.options.reducedmotion = reduced == true
    BAR.plain = plain == true
    list = percents.to_a
    i = 0
    while i < list.length
      SLOTS.set_progress(i == 0 ? title.to_s : "", "", Carat::Json.element(list, i).to_i)
      i += 1
    end
    paint(s, 60).row_text(0)
  end

  def self.lsp_state_of(name)
    case name.to_s
    when "starting" then :starting
    when "ready" then :ready
    when "indexing" then :indexing
    when "stopped" then :stopped
    when "crashed" then :crashed
    when "untrusted" then :untrusted
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
      SLOTS.set_lsp("ruby-lsp", :ready, 0)
      s
    when "folder"
      state_for("src/lib/a.rb", 3)
    when "plugin and lsp"
      s = state_for("a.txt", 3)
      UI.segment("probe", "x", 10)
      SLOTS.set_lsp("ruby-lsp", :ready, 0)
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

  # A diagnostic of a severity on row 0.
  def self.diag(severity)
    D::Diagnostic.new(row: 0, col: 0, severity: severity.to_i, message: "m")
  end

  # A published list of the diagnostics of the severities.
  def self.listed(severities)
    list = D::DiagnosticList.new
    severities.each { |severity| list.add(diag(severity)) }
    list
  end

  # One letter per cell of the bar row, by group: P the normal pill, S
  # StatusLine, d StatusLineDim, e the error count, and ? any other.
  def self.group_letters(frame, cols)
    letters = ""
    cols.to_i.times do |x|
      hl = frame.cell(0, x).hl
      letters += hl == H::STATUS_MODE_NORMAL ? "P" : (hl == H::STATUS ? "S" : (hl == H::STATUS_DIM ? "d" : (hl == H::STATUS_DIAGNOSTIC_ERROR ? "e" : "?")))
    end
    letters
  end

  def self.main
    t = Carat::Testing.new("adapters_status_bar")
    right = "  utf-8   1:1  All "

    # One row per segment, 60 columns wide, the unicode icons.
    t.table([
      ["the mode and the file", "plain", pad(" NORMAL  a.txt ", right, 60)],
      ["the modified icon after the file", "modified", pad(" NORMAL  a.txt ● ", right, 60)],
      ["an unnamed buffer", "unnamed", pad(" NORMAL  " + D::Messages::NO_NAME + " ", right, 60)],
      ["a scratch title", "scratch", pad(" NORMAL  list ", right, 60)],
      ["the file type", "ruby", pad(" NORMAL  a.rb ", "  ruby " + right, 60)],
      ["the git branch", "branch", pad(" NORMAL  a.txt   ± main ", right, 60)],
      ["the counts above zero", "two counts", pad(" NORMAL  a.txt   ✖ 2 ◇ 1 ", right, 60)],
      ["every count in order", "four counts", pad(" NORMAL  a.txt   ✖ 1 ▲ 2 ◆ 3 ◇ 4 ", right, 60)],
      ["the lsp slot", "lsp", pad(" NORMAL  a.txt ", "  ruby-lsp ● " + right, 60)],
      ["the lsp slot after the plugins' segments", "plugin and lsp", pad(" NORMAL  a.txt ", "  x   ruby-lsp ● " + right, 60)],
      ["the folder before the file name", "folder", pad(" NORMAL  src/lib/a.rb ", "  ruby " + right, 60)],
      ["the position and Top", "cursor at the top", pad(" NORMAL  a.txt ", "  utf-8   5:3  Top ", 60)],
      ["a percentage", "cursor in the middle", pad(" NORMAL  a.txt ", "  utf-8   51:1  50% ", 60)],
      ["Bot", "cursor at the bottom", pad(" NORMAL  a.txt ", "  utf-8   100:1  Bot ", 60)]
    ]) { |name| paint(scenario(name), 60).row_text(0) }

    # Scenario: A plain buffer in normal mode, 40 columns wide.
    t.assert_equal(pad(" NORMAL  a.txt", "utf-8   1:1  All ", 40), paint(scenario("plain"), 40).row_text(0), "a plain buffer in normal mode: the file at the left, the encoding, position, and percent at the right end")
    # Scenario: A modified Ruby buffer in insert mode.
    s = state_for("a.rb", 3)
    s.buffer.mark_unsaved
    s.mode = D::Mode::INSERT
    s.cursor.move_to(2, 4)
    t.assert_equal([true, pad(" INSERT  a.rb ● ", "  ruby   utf-8   3:5  All ", 60)], [s.buffer.modified?, paint(s, 60).row_text(0)], "a modified Ruby buffer in insert mode")

    # Scenario: frame rows show the status bar in carat-dark, carat-light,
    # and option.icons ascii: the pill in its mode's group, the file and the
    # fill in StatusLine, each theme's pill and bar readable.
    # paint takes no theme, so the groups are asserted once; each theme
    # only checks its colors.
    f = paint(scenario("modified"), 60)
    t.assert_equal([H::STATUS_MODE_NORMAL, H::STATUS_MODE_NORMAL, H::STATUS, H::STATUS], [f.cell(0, 1).hl, f.cell(0, 6).hl, f.cell(0, 9).hl, f.cell(0, 30).hl], "the pill, the file, and the fill groups")
    ["carat-dark", "carat-light"].each do |name|
      theme = D::Themes.find(name, "theme")
      t.assert_true(theme.bg(H::STATUS_MODE_NORMAL) != theme.bg(H::STATUS) && theme.fg(H::STATUS_MODE_NORMAL) != theme.bg(H::STATUS_MODE_NORMAL) && theme.fg(H::STATUS) != theme.bg(H::STATUS), "#{name}: the pill stands out from the bar and both are readable")
    end
    ascii = scenario("modified")
    ascii.options.icons = "ascii"
    t.assert_equal(pad(" NORMAL  a.txt * ", right, 60), paint(ascii, 60).row_text(0), "option.icons ascii: the modified icon is an asterisk")

    # Scenario: Empty slots take no room. Empty slots take no cells: the bar is the same as without them.
    plain = paint(scenario("plain"), 60).row_text(0)
    SLOTS.set_lsp("", :crashed, 0)
    t.assert_equal(plain, paint(scenario("plain"), 60).row_text(0), "an lsp state without a server name shows nothing")

    # Scenario: The slot names the state. The slot shows the server's name and one dot, with the hint of a crash or an untrusted directory. Scenario: Filled slots and Scenario: The lsp slot keeps its place are the first rows of the segment table above.
    t.table([
      ["ready is the name and a dot", "ready", " ruby-lsp ● "],
      ["starting is the same dot", "starting", " ruby-lsp ● "],
      ["indexing is the same dot, the percent left to the progress bar", "indexing", " ruby-lsp ● "],
      ["stopped is the same dot", "stopped", " ruby-lsp ● "],
      ["crashed names the restart command after the dot", "crashed", " ruby-lsp ● crashed :LspRestart "],
      ["untrusted names the start command after the dot", "untrusted", " ruby-lsp ● untrusted :LspStart "]
    ]) do |state|
      s = scenario("plain")
      SLOTS.set_lsp("ruby-lsp", lsp_state_of(state), 42)
      text = paint(s, 80).row_text(0)
      at = text.index(" ruby-lsp").to_i
      text[at, text.index("  utf-8").to_i - at]
    end
    t.assert_equal([true, false], [SLOTS.set_lsp("x", :ready, 0), SLOTS.set_lsp("x", :ready, 0)], "setting the same server again changes nothing")
    t.assert_equal(["crashed :LspRestart", "untrusted :LspStart", "", "", ""], [D::StatusSlots.hint(:crashed), D::StatusSlots.hint(:untrusted), D::StatusSlots.hint(:ready), D::StatusSlots.hint(:stopped), D::StatusSlots.hint(:none)], "only a crash and an untrusted directory name a command")
    # The dot is the modified icon of the set: * under option.icons ascii.
    s = scenario("plain")
    s.options.icons = "ascii"
    SLOTS.set_lsp("ruby-lsp", :ready, 0)
    t.assert_equal(pad(" NORMAL  a.txt ", "  ruby-lsp * " + right, 60), paint(s, 60).row_text(0), "option.icons ascii: the server's dot is an asterisk")

    # Scenario: Widths drop segments one by one. One row per width:
    # segments go by priority, the file is cut last.
    t.table([
      ["40 columns keep every segment", 40, pad(" NORMAL  a.rb ", "  ruby " + "  utf-8 " + "  1:1 " + " All ", 40)],
      ["32 columns drop the encoding", 32, pad(" NORMAL  a.rb ", "  ruby " + "  1:1 " + " All ", 32)],
      ["25 columns drop the file type", 25, pad(" NORMAL  a.rb ", "  1:1 " + " All ", 25)],
      ["20 columns drop the percent", 20, pad(" NORMAL  a.rb ", "  1:1 ", 20)],
      ["19 columns drop the position", 19, " NORMAL  a.rb"],
      ["12 columns cut the file", 12, " NORMAL  a.r"],
      ["6 columns cut the pill", 6, " NORMA"]
    ]) { |cols| paint(scenario("ruby"), cols).row_text(0) }

    # The diagnostics outlast the lsp slot, the percent, and the branch.
    s = scenario("four counts")
    SLOTS.set_lsp("ruby-lsp", :ready, 0)
    SLOTS.branch = "main"
    t.assert_equal(pad(" NORMAL  a.txt   ✖ 1 ▲ 2 ◆ 3 ◇ 4 ", "  1:1 ", 40), paint(s, 40).row_text(0), "at 40 columns the counts stay with the position")

    # Scenario: A plugin segment by its priority.
    s = scenario("plain")
    UI.segment("high", "hi", 95)
    UI.segment("low", "lo", 10)
    t.assert_equal(pad(" NORMAL  a.txt ", "  hi   lo   utf-8   1:1  All ", 60), paint(s, 60).row_text(0), "both segments in the order they were set")
    t.assert_equal(pad(" NORMAL  a.txt ", "  hi " + "  utf-8 " + "  1:1 " + " All ", 39), paint(s, 39).row_text(0), "the segment of priority 10 goes before the encoding")
    t.assert_equal(pad(" NORMAL  a.txt ", "  hi ", 20), paint(s, 20).row_text(0), "the segment of priority 95 outlasts the position")

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
    t.assert_equal([H::STATUS_MODE_NORMAL, H::STATUS, H::STATUS, H::STATUS_DIM], [f.cell(0, 7).hl, f.cell(0, 8).hl, f.cell(0, 30).hl, f.cell(0, 59).hl], "the pill ends at its closing space, the status group fills the rest, and the percent's last space is dim")

    # Scenario: The spacing between the groups and Scenario: The bar's groups and spacing. A row of every group, 80
    # columns wide: the pill, the file and the position in StatusLine, the
    # branch, the stopped server, the file type, the encoding, and the percent in
    # StatusLineDim, the counts in their own group; two cells between the
    # pill and the file and between the position and the percent, three
    # between the other groups, the fill in StatusLine. NO_COLOR draws the
    # same groups and the same cells.
    s = scenario("ruby")
    SLOTS.branch = "main"
    SLOTS.errors = 2
    SLOTS.set_lsp("ruby-lsp", :stopped, 0)
    text = " NORMAL  a.rb " + "  ± main " + "  ✖ 2 "
    right = "  ruby-lsp ● " + "  ruby " + "  utf-8 " + "  1:1 " + " All "
    groups = "P" * 8 + "S" * 6 + "S" + "d" * 8 + "S" + "e" * 5
    right_groups = "S" + "d" * 12 + "S" + "d" * 6 + "S" + "d" * 7 + "S" + "S" * 5 + "d" * 5
    fill = 80 - text.length - right.length
    expected = groups + "S" * fill + right_groups
    f = paint(s, 80)
    t.assert_equal([pad(text, right, 80), expected], [f.row_text(0), group_letters(f, 80)], "each group's color and the spacing between the groups")
    BAR.plain = true
    f = paint(s, 80)
    t.assert_equal([pad(text, right, 80), expected], [f.row_text(0), group_letters(f, 80)], "NO_COLOR keeps the groups and the spacing")
    BAR.plain = false

    # Scenario: The quiet text. The branch, the file type, and the encoding
    # are in StatusLineDim, while the file and the position lead in
    # StatusLine; a stopped server is quiet too.
    s = scenario("ruby")
    SLOTS.branch = "main"
    f = paint(s, 60)
    text = f.row_text(0)
    quiet = ["main", "ruby", "utf-8", "All"].map { |word| f.cell(0, text.index(word).to_i).hl }
    lead = ["a.rb", "1:1"].map { |word| f.cell(0, text.index(word).to_i).hl }
    t.assert_equal([[H::STATUS_DIM, H::STATUS_DIM, H::STATUS_DIM, H::STATUS_DIM], [H::STATUS, H::STATUS]], [quiet, lead], "the branch, the type, the encoding, and the percent step back; the file and the position do not")
    f = paint(scenario("cursor in the middle"), 60)
    t.assert_equal([H::STATUS_DIM, H::STATUS_DIM, H::STATUS_DIM], [f.cell(0, f.row_text(0).index("50%").to_i).hl, f.cell(0, f.row_text(0).index("50%").to_i + 2).hl, f.cell(0, f.row_text(0).index("50%").to_i + 3).hl], "a percentage and its spaces are in StatusLineDim")

    # Scenario: The folder before the file name. The folder is in
    # StatusLineDim and the name in StatusLine, under NO_COLOR as well; a
    # name with no folder, a root, and a scratch title are all StatusLine.
    t.table([
      ["a folder before the name", "src/lib/a.rb", "ddddddddSSSS"],
      ["an absolute path", "/home/u/a.rb", "ddddddddSSSS"],
      ["a multi-byte folder counts cells, not bytes", "é/ü/a.rb", "ddddSSSS"],
      ["no folder", "a.rb", "SSSS"],
      ["the root", "/", "S"],
      ["a path ending in a slash", "dir/", "dddd"]
    ]) do |path|
      groups = group_letters(paint(state_for(path.to_s, 3), 60), 60)
      groups[9, D::DisplayWidth.text_width(path.to_s, 0)]
    end
    s = state_for("src/a.rb", 3)
    s.buffer.mark_unsaved
    t.assert_equal("dddd" + "SSSS" + "SS", group_letters(paint(s, 60), 60)[9, 10], "the modified icon after the name is in StatusLine")
    s = scenario("scratch")
    t.assert_equal("SSSS", group_letters(paint(s, 60), 60)[9, 4], "a scratch title is in StatusLine")
    BAR.plain = true
    t.assert_equal("ddddddddSSSS", group_letters(paint(scenario("folder"), 60), 60)[9, 12], "NO_COLOR keeps the folder in StatusLineDim and the name in StatusLine")
    BAR.plain = false
    f = paint(scenario("folder"), 12)
    t.assert_equal([" NORMAL  src", "PPPPPPPPSddd"], [f.row_text(0), group_letters(f, 12)], "a bar cut inside the folder keeps the cut cells dim")

    # The lsp slot's name is quiet and its dot takes the group of its state.
    t.table([
      ["starting", "starting", [H::STATUS_DIM, H::STATUS_LSP_STARTING, H::STATUS_LSP_STARTING]],
      ["ready", "ready", [H::STATUS_DIM, H::STATUS_LSP_READY, H::STATUS_LSP_READY]],
      ["indexing", "indexing", [H::STATUS_DIM, H::STATUS_LSP_STARTING, H::STATUS_LSP_STARTING]],
      ["stopped", "stopped", [H::STATUS_DIM, H::STATUS_DIM, H::STATUS_DIM]],
      ["crashed", "crashed", [H::STATUS_DIM, H::STATUS_LSP_ERROR, H::STATUS_LSP_ERROR]],
      ["untrusted", "untrusted", [H::STATUS_DIM, H::STATUS_DIM, H::STATUS_DIM]]
    ]) do |state|
      s = scenario("lsp")
      SLOTS.set_lsp("ruby-lsp", lsp_state_of(state), 5)
      f = paint(s, 70)
      text = f.row_text(0)
      at = text.index("ruby-lsp").to_i
      [f.cell(0, at).hl, f.cell(0, at + 9).hl, f.cell(0, text.index("  utf-8").to_i - 1).hl]
    end
    # The hint a crash or an untrusted directory names is in the dot's group.
    s = scenario("lsp")
    SLOTS.set_lsp("ruby-lsp", :crashed, 0)
    f = paint(s, 70)
    at = f.row_text(0).index("crashed").to_i
    t.assert_equal([H::STATUS_LSP_ERROR, H::STATUS_LSP_ERROR, H::STATUS_LSP_ERROR], [f.cell(0, at - 1).hl, f.cell(0, at).hl, f.cell(0, at + 18).hl], "the restart hint after the dot is in the error group")
    f = paint(scenario("four counts"), 60)
    text = f.row_text(0)
    # Scenario: A row per state. Each count, and the closing space after the
    # last one, carries its kind's count group, drawn on the bar's background.
    t.assert_equal([H::STATUS_DIAGNOSTIC_ERROR, H::STATUS_DIAGNOSTIC_WARN, H::STATUS_DIAGNOSTIC_INFO, H::STATUS_DIAGNOSTIC_HINT, H::STATUS_DIAGNOSTIC_HINT], [f.cell(0, text.index("✖").to_i).hl, f.cell(0, text.index("▲").to_i).hl, f.cell(0, text.index("◆").to_i).hl, f.cell(0, text.index("4").to_i).hl, f.cell(0, text.index("4").to_i + 1).hl], "each count in its status bar count group, the closing space in the last one's")

    # The slots are empty until a service fills them.
    empty = D::StatusSlots.new
    t.assert_equal(["", false, false, :none], [empty.branch, empty.diagnostics?, empty.lsp?, empty.lsp_state], "new slots are empty")
    list = listed([1, 1, 2, 4])
    t.assert_equal([true, 2, 1, 0, 1, true], [empty.count_diagnostics(list), empty.errors, empty.warnings, empty.infos, empty.hints, empty.diagnostics?], "a buffer's diagnostics are counted by severity")
    again = empty.count_diagnostics(list)
    other = empty.count_diagnostics(listed([3]))
    t.assert_equal([false, true, 0, 1], [again, other, empty.errors, empty.infos], "counting the same again changes nothing, another list replaces the counts")
    none = empty.count_diagnostics(D::DiagnosticList.new)
    t.assert_equal([true, false], [none, empty.diagnostics?], "no diagnostics empty the slot")

    # The progress of long work before the lsp slot.
    t.cases([
      ["a bar at a percent", ["Indexing", [40], false, false], pad(" NORMAL  a.txt ", "  Indexing ━━━━──────   utf-8   1:1  All ", 60)],
      ["a percent rounds down to whole cells", ["Indexing", [99], false, false], pad(" NORMAL  a.txt ", "  Indexing ━━━━━━━━━─   utf-8   1:1  All ", 60)],
      ["without a percent three cells move per report", ["Indexing", [-1, -1, -1], false, false], pad(" NORMAL  a.txt ", "  Indexing ──━━━─────   utf-8   1:1  All ", 60)],
      ["a report without a percent keeps the last", ["Indexing", [30, -1], false, false], pad(" NORMAL  a.txt ", "  Indexing ━━━───────   utf-8   1:1  All ", 60)],
      ["reduced motion leaves out a bar without a percent", ["Indexing", [-1], true, false], pad(" NORMAL  a.txt ", "  Indexing   utf-8   1:1  All ", 60)],
      ["reduced motion keeps a bar with a percent", ["Indexing", [40], true, false], pad(" NORMAL  a.txt ", "  Indexing ━━━━──────   utf-8   1:1  All ", 60)],
      ["a plain bar under NO_COLOR", ["Indexing", [40], false, true], pad(" NORMAL  a.txt ", "  Indexing ####------   utf-8   1:1  All ", 60)],
      ["no title, the bar alone", ["", [100], false, false], pad(" NORMAL  a.txt ", "  ━━━━━━━━━━   utf-8   1:1  All ", 60)]
    ]) do |input|
      progress(input[0], input[1], input[2], input[3])
    end
    s = scenario("plain")
    SLOTS.set_progress("Indexing", "", 40)
    f = paint(s, 60)
    x = f.row_text(0).index("━").to_i
    t.assert_equal([H::STATUS_LSP_READY, H::STATUS_DIM, H::STATUS, H::STATUS], [f.cell(0, x).hl, f.cell(0, x + 4).hl, f.cell(0, x - 1).hl, f.cell(0, x - 3).hl], "done cells in StatusLineLspReady, the undone ones in StatusLineDim, the space and the title in StatusLine")
    BAR.plain = true
    f = paint(s, 60)
    x = f.row_text(0).index("#").to_i
    t.assert_equal([H::STATUS, H::STATUS_DIM], [f.cell(0, x).hl, f.cell(0, x + 4).hl], "plain done cells in StatusLine, the undone ones in StatusLineDim")
    BAR.plain = false
    # An ascii bar: # and - under option.icons ascii, the done cells still
    # in StatusLineLspReady.
    s.options.icons = "ascii"
    f = paint(s, 60)
    x = f.row_text(0).index("#").to_i
    t.assert_equal([" Indexing ####------ ", H::STATUS_LSP_READY, H::STATUS_DIM], [f.row_text(0)[x - 10, 21], f.cell(0, x).hl, f.cell(0, x + 4).hl], "an ascii bar reads #### and ------ with the done cells in StatusLineLspReady and the rest in StatusLineDim")
    s.options.icons = "unicode"
    SLOTS.branch = "main"
    # A narrow bar drops the segment before the file type.
    t.assert_equal(pad(" NORMAL  a.txt   ± main ", "  1:1 " + " All ", 36), paint(s, 36).row_text(0), "a narrow bar drops the progress (35) before the branch (40)")
    t.assert_equal([true, false, false], [SLOTS.clear_progress, SLOTS.clear_progress, SLOTS.progress?], "clearing ends the progress once")

    t.finish
  end
end

AdaptersStatusBarTest.main if __FILE__ == $0
