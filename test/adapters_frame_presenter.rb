require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module AdaptersFramePresenterTest
  D = Carat::Domain
  INPUT = Carat::Domain::InputState.new
  UI = Carat::Domain::PluginUi.new
  CACHE = Carat::Domain::LineCache.new
  SLOTS = Carat::Domain::StatusSlots.new
  LISTED = Carat::Domain::BufferList.new(tabs: Carat::Domain::TabList.new(window: Carat::Domain::Window.new(buffer: Carat::Domain::Buffer.new(lines: [""], path: nil, line_ending: "\n"))))
  ARRANGE = Carat::UseCases::ArrangeView.new(cache: CACHE, buffers: LISTED)
  LAST = Carat::Domain::LastSearch.new
  PROMPT = Carat::Domain::SearchPrompt.new
  P = Carat::Adapters::FramePresenter.new(input: INPUT, plugin_ui: UI, cache: CACHE, last_search: LAST, search_prompt: PROMPT, start_screen: Carat::Domain::StartScreen.new, status_bar: Carat::Adapters::StatusBar.new(plugin_ui: UI, slots: SLOTS), tab_bar: Carat::Adapters::TabBar.new(buffers: LISTED))

  # Draws the state at a size as the editor does: the size goes into the
  # state, ArrangeView lays the windows out, and the presenter reads it.
  #: (Carat::Domain::EditorState, Integer, Integer) -> Carat::Domain::Frame
  def self.draw(state, rows, cols)
    state.resize(rows, cols)
    ARRANGE.call(state)
    P.call(state)
  end

  # A state over one window showing the lines; the plugins' segments and
  # prompt start empty.
  def self.state_for(lines, path)
    buffer = Carat::Domain::Buffer.new(lines: lines, path: path, line_ending: "\n")
    options = Carat::Domain::Options.new
    options.number = true
    options.tabstop = 4
    UI.segments.clear
    UI.owners.clear
    UI.priorities.clear
    UI.close_prompt
    Carat::Domain::EditorState.new(tabs: Carat::Domain::TabList.new(window: Carat::Domain::Window.new(buffer: buffer)), options: options)
  end

  # Delete and the C1 controls show as <xx> markers and never reach a cell raw.
  def self.control_free?(frame)
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

  # The visual selection: the Visual highlight on the selected cells of the
  # current window, the cell under the cursor left in its own highlight.
  VIS = D::Highlight::VISUAL

  NOR = D::Highlight::NORMAL

  # Renders lines in a visual mode with the anchor and the cursor given and
  # returns the frame; tabstop is 4 and the gutter four cells wide.
  def self.visual_frame(lines, mode, anchor, head)
    s = state_for(lines, "a.txt")
    s.mode = mode
    s.window.anchor = Carat::Domain::Position.new(row: anchor[0], col: anchor[1])
    s.cursor.move_to(head[0], head[1])
    draw(s, 6, 20)
  end

  # The highlight of each cell of a row from frame column 4, where the text
  # starts, for count cells.
  def self.highlights(frame, row, count)
    out = []
    c = 4
    while c < 4 + count
      out << frame.cell(row, c).hl
      c += 1
    end
    out
  end

  # The cursor-line layer of highlight ids.
  LIT = D::Highlight::CURSOR_LINE_LAYER

  # For the first rows of a frame, 1 where the cell at column col is on
  # the cursor-line layer and 0 elsewhere.
  def self.lit_rows(frame, rows, col)
    out = []
    r = 0
    while r < rows
      out << (frame.cell(r, col).hl >= LIT ? 1 : 0)
      r += 1
    end
    out
  end

  # The cursor line in one case, by name: which of the first rows are lit
  # at a column, after the steps the case takes.
  def self.cursor_line(name)
    s = state_for(["one", "two", "three"], "a.txt")
    s.options.cursorline = name != "off"
    s.cursor.move_to(1, 0)
    case name
    when "the gutter"
      return lit_rows(draw(s, 6, 14), 4, 0)
    when "the blanks after the text"
      return lit_rows(draw(s, 6, 14), 4, 13)
    when "j"
      s.cursor.move_to(0, 0)
      draw(s, 6, 14)
      draw(s, 6, 14)
      s.cursor.move_to(1, 0)
      draw(s, 6, 14)
      return lit_rows(draw(s, 6, 14), 4, 4)
    when "turned off"
      draw(s, 6, 14)
      draw(s, 6, 14)
      s.options.cursorline = false
      draw(s, 6, 14)
      return lit_rows(draw(s, 6, 14), 4, 4)
    when "stacked", "stacked, top focused"
      draw(s, 9, 14)
      top = s.tab.layout.split(0, false, 0, 5)
      s.tab.focus(top) if name == "stacked, top focused"
      s.window.cursor.move_to(0, 0)
      return lit_rows(draw(s, 9, 14), 8, 4)
    when "side by side"
      draw(s, 6, 21)
      s.tab.layout.split(0, true, 0, 5)
      s.window.cursor.move_to(0, 0)
      f = draw(s, 6, 21)
      return [lit_rows(f, 1, 4)[0], lit_rows(f, 1, 9)[0], lit_rows(f, 1, 15)[0], lit_rows(f, 1, 20)[0]]
    end
    lit_rows(draw(s, 6, 14), 4, 4)
  end

  # The cursor shape of a frame drawn in a mode, by its keymap name.
  def self.shape_in(mode)
    s = state_for(["one"], "a.txt")
    s.mode = D::Mode.from_name(mode) || D::Mode::NORMAL
    draw(s, 6, 14).cursor_shape
  end

  def self.main
    t = Carat::Testing.new("adapters_frame_presenter")

    # Layout of three lines in a six-row frame.
    s = state_for(["one", "two", "three"], "a.txt")
    f = draw(s, 6, 14)
    t.assert_equal(["  1 one", "  2 two", "  3 three", "~"], f.text_rows[0, 4], "window rows with numbers and a tilde")
    t.assert_equal(" NORMAL  a.txt", f.row_text(4), "the status bar keeps the mode and the file at 14 columns")
    t.assert_equal("", f.row_text(5), "message row is blank")
    t.assert_equal([D::Highlight::STATUS_MODE_NORMAL, D::Highlight::STATUS], [f.cell(4, 0).hl, f.cell(4, 13).hl], "the pill in the mode's group, the file in the status highlight")
    wide = draw(s, 6, 40)
    t.assert_equal("utf-8  1:1  All", wide.row_text(4)[-15, 15], "a wide bar ends with the encoding, the position, and the percent")
    t.assert_equal(D::Highlight::STATUS, wide.cell(4, 20).hl, "the status highlight fills the row between")
    narrow = draw(s, 6, 12)
    t.assert_equal(" NORMAL  a.t", narrow.row_text(4), "the file is cut at the edge of a narrow bar")
    t.assert_equal(D::Highlight::LINE_NUMBER, f.cell(0, 0).hl, "gutter uses the line number highlight")
    t.assert_equal(D::Highlight::NON_TEXT, f.cell(3, 0).hl, "tilde uses the non-text highlight")
    t.assert_equal([0, 4], [f.cursor_row, f.cursor_col], "cursor sits after the gutter")
    t.assert_equal(:block, f.cursor_shape, "block cursor in normal mode")

    s.options.number = false
    f = draw(s, 6, 12)
    t.assert_equal("one", f.row_text(0), "number off removes the gutter")
    t.assert_equal(0, f.cursor_col, "cursor at column 0 without a gutter")

    big = []
    1000.times { |i| big << "L#{i + 1}" }
    s = state_for(big, "big.txt")
    f = draw(s, 6, 20)
    t.assert_equal("   1 L1", f.row_text(0), "gutter widens to the digits of the line count")
    t.assert_equal("Top", draw(s, 6, 40).row_text(4)[-3, 3], "position is Top at the start of a long buffer")

    # Relative numbers.
    s = state_for(["a", "b", "c"], "a.txt")
    s.options.relativenumber = true
    s.cursor.move_to(1, 0)
    f = draw(s, 6, 12)
    t.assert_equal(["  1 a", "  2 b", "  1 c"], f.text_rows[0, 3], "relative numbers around the cursor with the absolute number on its row")
    s.options.number = false
    f = draw(s, 6, 12)
    t.assert_equal("  0 b", f.row_text(1), "cursor row shows 0 when number is off")

    # Status bar content.
    s = state_for(["ab", "cdef"], "a.txt")
    s.options.icons = "unicode"
    s.buffer.mark_unsaved
    s.cursor.move_to(1, 2)
    f = draw(s, 6, 30)
    t.assert_equal(" NORMAL  a.txt ●", f.row_text(4)[0, 16], "a modified buffer shows the modified icon")
    t.assert_equal("2:3  All", f.row_text(4)[-8, 8], "the bar shows row:col and All")
    s = state_for([""], nil)
    f = draw(s, 6, 30)
    t.assert_equal(" NORMAL  [No Name]", f.row_text(4)[0, 18], "unnamed buffer")

    # Message row priorities.
    s = state_for(["ab"], "a.txt")
    s.mode = D::Mode::INSERT
    f = draw(s, 6, 30)
    t.assert_equal("-- INSERT --", f.row_text(5), "insert indicator")
    t.assert_equal(:bar, f.cursor_shape, "bar cursor in insert mode")
    s.show("E37: No write since last change (add ! to override)", true)
    f = draw(s, 6, 60)
    t.assert_equal("E37: No write since last change (add ! to override)", f.row_text(5), "message replaces the indicator")
    t.assert_equal(D::Highlight::MESSAGE_ERROR, f.cell(5, 0).hl, "error message highlight")
    s.clear_message
    s.mode = D::Mode::CMDLINE
    s.cmdline = "wq"
    f = draw(s, 6, 30)
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
      draw(s, 8, 20)
      row += 1
    end
    f = draw(s, 8, 20)
    t.assert_equal("line 8", f.row_text(0), "first window row shows line 8 after moving to row 10")
    t.assert_equal(3, f.cursor_row, "cursor row is third from the bottom of the six window rows")
    t.assert_equal(7, s.window.top, "window top is 7")
    t.assert_equal("50%", draw(s, 8, 40).row_text(6)[-3, 3], "position shows a percentage")
    s.cursor.move_to(19, 0)
    f = draw(s, 8, 20)
    t.assert_equal("line 20", f.row_text(5), "last line at the bottom when the cursor reaches it")
    t.assert_equal("Bot", draw(s, 8, 40).row_text(6)[-3, 3], "position is Bot at the end")
    s.cursor.move_to(0, 0)
    f = draw(s, 8, 20)
    t.assert_equal("line 1", f.row_text(0), "scrolls back up to the start")

    # Horizontal scrolling.
    s = state_for(["a" * 29 + "X" + "b" * 10], "a.txt")
    s.options.number = false
    s.cursor.move_to(0, 30)
    f = draw(s, 4, 12)
    t.assert_true(f.cursor_col >= 0 && f.cursor_col < 12, "cursor is inside the frame")
    t.assert_equal("X", f.row_text(0)[f.cursor_col - 1, 1], "the row shows the text around the cursor")
    t.assert_equal(true, f.row_text(0)[0, 1] != "a" || s.window.left > 0, "row no longer starts at column 0")
    s.cursor.move_to(0, 0)
    f = draw(s, 4, 12)
    t.assert_equal(0, s.window.left, "scrolls back to column 0")

    # Tabs and wide characters.
    s = state_for(["a\tb"], "a.txt")
    s.options.number = false
    f = draw(s, 4, 12)
    t.assert_equal("a   b", f.row_text(0), "tab expands to the next multiple of tabstop")
    s.cursor.move_to(0, 2)
    f = draw(s, 4, 12)
    t.assert_equal(4, f.cursor_col, "cursor after a tab is placed by display width")
    s = state_for(["日x"], "a.txt")
    s.options.number = false
    s.cursor.move_to(0, 1)
    f = draw(s, 4, 12)
    t.assert_equal(2, f.cursor_col, "cursor after a wide character is at column 2")
    t.assert_equal(2, f.cell(0, 0).width, "wide character cell has width 2")
    t.assert_equal("", f.cell(0, 1).char, "the cell after a wide character is a continuation")
    s = state_for(["a\x01b"], "a.txt")
    s.options.number = false
    f = draw(s, 4, 12)
    t.assert_equal("a^Ab", f.row_text(0), "control characters show as caret notation")

    markers = [
      ["U+007F shows as <7f>", "a\u007Fb", "a<7f>b"],
      ["U+0080 shows as <80>", "a\u0080b", "a<80>b"],
      ["U+009B shows as <9b>", "a\u009Bb", "a<9b>b"],
      ["U+009D shows as <9d>", "a\u009Db", "a<9d>b"],
    ]
    t.table(markers) do |line|
      s = state_for([line.to_s], "a.txt")
      s.options.number = false
      draw(s, 4, 12).row_text(0)
    end
    widths = [
      ["U+007F marker is four cells wide and the frame holds no control", "a\u007Fb", [6, "b", 1, true]],
      ["U+0080 marker is four cells wide and the frame holds no control", "a\u0080b", [6, "b", 1, true]],
      ["U+009B marker is four cells wide and the frame holds no control", "a\u009Bb", [6, "b", 1, true]],
      ["U+009D marker is four cells wide and the frame holds no control", "a\u009Db", [6, "b", 1, true]],
    ]
    t.table(widths) do |line|
      s = state_for([line.to_s], "a.txt")
      s.options.number = false
      f = draw(s, 4, 12)
      [P.display_width(line, 4), f.row_text(0)[5, 1], f.cell(0, 1).width, control_free?(f)]
    end
    s = state_for(["a\u009Bb"], "a.txt")
    s.options.number = false
    s.cursor.move_to(0, 1)
    f = draw(s, 4, 12)
    t.assert_equal(1, f.cursor_col, "cursor on a C1 control sits on the first cell of its marker")
    s.cursor.move_to(0, 2)
    f = draw(s, 4, 12)
    t.assert_equal(5, f.cursor_col, "cursor after a C1 control is placed past its four cells")
    s = state_for(["a\u009B\x01\u007F"], "a.txt")
    s.options.number = false
    f = draw(s, 4, 12)
    t.assert_equal("a<9b>^A<7f>", f.row_text(0), "markers and caret notation mix on one line")
    t.assert_true(control_free?(f), "no cell holds a control code point after a mixed line")
    direct = D::Frame.new(rows: 1, cols: 6)
    t.assert_equal(3, direct.put(0, 0, "a\u009Bb", D::Highlight::NORMAL), "put stores one cell per control code point")
    t.assert_equal(["a", 0xFFFD, "b"], [direct.cell(0, 0).char, direct.cell(0, 1).code, direct.cell(0, 2).char], "put stores the replacement character for a C1 control")
    direct.put(0, 0, "\x01\u007F", D::Highlight::NORMAL)
    t.assert_equal([0xFFFD, 0xFFFD], [direct.cell(0, 0).code, direct.cell(0, 1).code], "put stores the replacement character for C0 and delete")
    t.assert_true(control_free?(direct), "a frame written to directly holds no control code point")

    # Resizing.
    s = state_for(["ab"], "a.txt")
    f = draw(s, 24, 80)
    t.assert_equal(24, f.rows, "frame has 24 rows")
    f = draw(s, 10, 40)
    t.assert_equal(10, f.rows, "frame has 10 rows after shrinking")
    t.assert_equal(" NORMAL  a.txt", f.row_text(8)[0, 14], "the status bar moved to row 8")

    # Reuse: renders of the same size paint two frames in turn, so the frame
    # on the screen stays intact while the other is drawn.
    second = draw(s, 10, 40)
    t.assert_true(!second.equal?(f), "the next render paints the other frame")
    s.buffer.insert(D::Position.new(row: 0, col: 0), "x")
    again = draw(s, 10, 40)
    t.assert_true(again.equal?(f), "the render after that repaints the first frame again")
    t.assert_equal("  1 xab", again.row_text(0), "the reused frame shows the new text")
    t.assert_equal("  1 ab", second.row_text(0), "the other frame still shows what it showed")

    # Two stacked windows: the layout is split after a first render sized the
    # window, and the old window at the bottom stays current.
    s = state_for(["one", "two", "three"], "a.txt")
    draw(s, 9, 14)
    top = s.tab.layout.split(0, false, 0, 5)
    f = draw(s, 9, 14)
    t.assert_equal(["  1 one", "  2 two", "  3 three"], f.text_rows[0, 3], "the top window shows the lines")
    t.assert_equal("─" * 14, f.row_text(3), "row 3 is a separator row under the top window")
    t.assert_equal([D::Highlight::WINDOW_SEPARATOR, D::Highlight::WINDOW_SEPARATOR], [f.cell(3, 0).hl, f.cell(3, 13).hl], "the separator row is in WinSeparator")
    t.assert_equal(["  1 one", "  2 two", "  3 three"], f.text_rows[4, 3], "the bottom window shows the same lines")
    t.assert_equal(" NORMAL  a.txt", f.row_text(7), "row 7 is the status bar")
    t.assert_equal("", f.row_text(8), "row 8 is the message row")
    s.window.cursor.move_to(1, 0)
    f = draw(s, 22, 40)
    t.assert_equal("2:1  All", f.row_text(20)[-8, 8], "the bar shows the current window's cursor")
    f = draw(s, 9, 14)
    t.assert_equal([5, 4], [f.cursor_row, f.cursor_col], "the cursor is placed in the bottom window")
    s.tab.focus(top)
    f = draw(s, 9, 14)
    t.assert_equal([0, 4], [f.cursor_row, f.cursor_col], "focusing the top window moves the cursor there")
    t.assert_equal("1:1  All", draw(s, 22, 40).row_text(20)[-8, 8], "the bar follows the current window")

    # Two windows side by side with the separator between them.
    s = state_for(["one", "two"], "a.txt")
    draw(s, 6, 21)
    s.tab.layout.split(0, true, 0, 5)
    f = draw(s, 6, 21)
    t.assert_equal("  1 one   \u2502  1 one", f.row_text(0), "both windows on row 0 with the separator at column 10")
    t.assert_equal("  2 two   \u2502  2 two", f.row_text(1), "row 1 too")
    t.assert_equal("~         \u2502~", f.row_text(2), "tilde rows in both windows")
    t.assert_equal(D::Highlight::WINDOW_SEPARATOR, f.cell(0, 10).hl, "the separator is in WinSeparator")
    t.assert_equal(D::Highlight::NON_TEXT, f.cell(2, 0).hl, "the tilde keeps its highlight")
    t.assert_equal(" NORMAL  a.txt", f.row_text(4)[0, 14], "row 4 is one status bar")
    t.assert_equal([D::Highlight::STATUS, "."], [f.cell(4, 10).hl, f.cell(4, 10).char], "the separator stops above the bar")
    t.assert_equal("", f.row_text(5), "row 5 is the message row")
    t.assert_equal([0, 15], [f.cursor_row, f.cursor_col], "the cursor is in the right window, which stayed current")
    s.buffer.mark_unsaved
    f = draw(s, 6, 21)
    t.assert_equal(" NORMAL  a.txt \u{F111}", f.row_text(4), "the modified icon stays when the rest is dropped")

    # A long line is clipped at the window's edge.
    s = state_for(["abcdefghijklmnopqrstuvwxyz"], "a.txt")
    s.options.number = false
    draw(s, 4, 11)
    s.tab.layout.split(0, true, 0, 1)
    f = draw(s, 4, 11)
    t.assert_equal("abcde\u2502abcde", f.row_text(0), "each window shows what fits before its edge")

    # Two tab pages: the tabs row takes the top row, with the tab-page
    # numbers at its right end; the list here has no file buffer.
    s = state_for(["one", "two", "three"], "a.txt")
    other = D::Buffer.new(lines: ["zz"], path: "b.txt", line_ending: "\n")
    s.tabs.add_tab(D::TabPage.new(window: D::Window.new(buffer: other)))
    s.tabs.tab_index = 0
    f = draw(s, 7, 30)
    t.assert_equal("                         1  2", f.row_text(0), "the tab-page numbers stand at the right end")
    t.assert_equal([D::Highlight::TAB_LINE_FILL, D::Highlight::TAB_LINE_SELECTED, D::Highlight::TAB_LINE], [f.cell(0, 0).hl, f.cell(0, 25).hl, f.cell(0, 28).hl], "fill, selected, and plain highlights")
    t.assert_equal("  1 one", f.row_text(1), "the first text row is row 1")
    t.assert_equal(" NORMAL  a.txt", f.row_text(5)[0, 14], "the status bar is on row 5")
    t.assert_equal("", f.row_text(6), "the message row stays last")
    t.assert_equal([1, 4], [f.cursor_row, f.cursor_col], "the cursor is under the tabs row")
    s.tabs.tab_index = 1
    f = draw(s, 7, 30)
    t.assert_equal([D::Highlight::TAB_LINE, D::Highlight::TAB_LINE_SELECTED], [f.cell(0, 25).hl, f.cell(0, 28).hl], "the second number is selected now")
    t.assert_equal("  1 zz", f.row_text(1), "the second tab page's window is drawn")
    s.tabs.remove_tab(1)
    f = draw(s, 7, 30)
    t.assert_equal("  1 one", f.row_text(0), "with one tab page and no files listed there is no tabs row")
    LISTED.add(s.buffer)
    LISTED.add(other)
    s.options.icons = "unicode"
    f = draw(s, 7, 30)
    t.assert_equal(" • a.txt    • b.txt", f.row_text(0), "two listed files show their tabs, the current one selected")
    t.assert_equal([D::Highlight::TAB_LINE_SELECTED, D::Highlight::ICON_DEFAULT, D::Highlight::TAB_LINE], [f.cell(0, 0).hl, f.cell(0, 1).hl, f.cell(0, 11).hl], "the selected tab's icon takes its file-icon group")
    LISTED.remove(other)
    LISTED.remove(s.buffer)

    # The sign column: two cells before the numbers while the buffer has signs.
    s = state_for(["one", "two", "three"], "a.txt")
    f = draw(s, 6, 20)
    t.assert_equal("  1 one", f.row_text(0), "no sign column without signs")
    s.buffer.place_sign("test", 0, 1, "X")
    f = draw(s, 6, 20)
    t.assert_equal(["    1 one", "X   2 two", "    3 three"], [f.row_text(0), f.row_text(1), f.row_text(2)], "the sign sits in its column and the numbers move right")
    t.assert_equal([D::Highlight::SIGN_COLUMN, D::Highlight::SIGN_COLUMN], [f.cell(1, 0).hl, f.cell(0, 1).hl], "the sign column carries the SignColumn highlight")
    t.assert_equal([0, 6], [f.cursor_row, f.cursor_col], "the cursor moves right with the gutter")
    s.options.number = false
    f = draw(s, 6, 20)
    t.assert_equal(["  one", "X two"], [f.row_text(0), f.row_text(1)], "the sign column stays when numbers are off")
    s.buffer.clear_signs("test")
    f = draw(s, 6, 20)
    t.assert_equal("one", f.row_text(0), "clearing the signs removes the column")

    # The bar shows the current window's buffer, a scratch title too, and
    # the plugins' segments.
    s = state_for(["one"], "a.txt")
    scratch = D::Buffer.new(lines: ["item"], path: nil, line_ending: "\n")
    scratch.owner = "test"
    scratch.title = "list"
    draw(s, 6, 40)
    side = D::Window.new(buffer: scratch)
    side.fixed_width = true
    id = s.tab.layout.split_edge(side, 12, true)
    f = draw(s, 6, 40)
    t.assert_equal(" NORMAL  a.txt ", f.row_text(4)[0, 15], "the bar shows the current file window")
    UI.segment("hello", "hello 1", 25)
    UI.segment("other", "x", 25)
    f = draw(s, 6, 40)
    t.assert_equal(" NORMAL  a.txt     hello 1  x  1:1  All", f.row_text(4), "the plugins' segments stand in order before the position, the encoding dropped first")
    UI.segment("other", "x", 5)
    t.assert_equal(" NORMAL  a.txt" + (" " * 8) + "hello 1  1:1  All", draw(s, 6, 40).row_text(4), "a segment of priority 5 is dropped before the encoding")
    s.tab.focus(id)
    f = draw(s, 6, 40)
    t.assert_equal(" NORMAL  list ", f.row_text(4)[0, 14], "the bar follows the current window to the scratch title")
    t.assert_equal(["item", "  1 one"], [f.row_text(0)[0, 4], f.row_text(0)[13, 7]], "the side window has no line numbers while the file window keeps them")
    scratch.place_sign("test", 0, 0, "!")
    f = draw(s, 6, 40)
    t.assert_equal("! item", f.row_text(0)[0, 6], "its sign column still shows")

    # A plugin's prompt takes the place of the colon, with the cursor after
    # the text.
    s = state_for(["one"], "a.txt")
    s.mode = D::Mode::CMDLINE
    UI.open_prompt("test", "", "Rename to: ")
    s.cmdline = "a.rb"
    f = draw(s, 6, 40)
    t.assert_equal(["Rename to: a.rb", 5, 15], [f.row_text(5), f.cursor_row, f.cursor_col], "the prompt row and the cursor after it")
    UI.close_prompt
    f = draw(s, 6, 40)
    t.assert_equal([":a.rb", 5], [f.row_text(5), f.cursor_col], "an ex command line keeps its colon")

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
    s.window.anchor = D::Position.new(row: 0, col: 1)
    s.cursor.move_to(1, 1)
    s.cursor.want_col = -1
    f = draw(s, 6, 20)
    t.assert_equal([NOR, VIS, VIS, VIS], highlights(f, 0, 4), "after $ the block reaches every row's end")
    t.assert_equal([NOR, NOR, NOR], highlights(f, 1, 3), "a shorter row ends at its line end, under the cursor here")
    s = state_for(["abcd", "a", "abcd"], "a.txt")
    s.mode = D::Mode::VISUAL_BLOCK
    s.window.anchor = D::Position.new(row: 0, col: 2)
    s.cursor.move_to(2, 3)
    f = draw(s, 6, 20)
    t.assert_equal([NOR, NOR], highlights(f, 1, 2), "a row ending before the block draws nothing")
    s.mode = D::Mode::NORMAL
    f = draw(s, 6, 20)
    t.assert_equal([NOR, NOR, NOR, NOR], highlights(f, 0, 4), "normal mode draws no selection")

    # Two windows on one buffer: only the current one draws its selection.
    s = state_for(["one", "two", "three"], "a.txt")
    draw(s, 9, 14)
    s.tab.layout.split(0, false, 0, 5)
    s.mode = D::Mode::VISUAL_LINE
    s.window.anchor = D::Position.new(row: 0, col: 0)
    s.cursor.move_to(1, 0)
    f = draw(s, 9, 14)
    t.assert_equal([VIS, VIS, VIS], highlights(f, 4, 3), "the current window, at the bottom, draws its selection")
    t.assert_equal([NOR, NOR, NOR], highlights(f, 0, 3), "the other window on the same buffer draws none")
    t.assert_equal([NOR, NOR, NOR], highlights(f, 1, 3), "on any row")

    # Search matches: the Search group on every non-empty match while
    # hlsearch is on and the matches are shown, IncSearch on the preview.
    sea = D::Highlight::SEARCH
    s = state_for(["a ba", "xyz"], "a.txt")
    f = draw(s, 6, 20)
    t.assert_equal([NOR, NOR, NOR, NOR], highlights(f, 0, 4), "nothing is highlighted before a search")
    LAST.remember(D::VimPattern.compile("a", false, false), true)
    f = draw(s, 6, 20)
    t.assert_equal([sea, NOR, NOR, sea], highlights(f, 0, 4), "every match is in the Search group")
    t.assert_equal(true, f.dirty[0] == 1, "the row is repainted when the highlight appears")
    LAST.hide
    f = draw(s, 6, 20)
    t.assert_equal([NOR, NOR, NOR, NOR], highlights(f, 0, 4), "a hidden highlight is not drawn")
    LAST.show
    s.options.hlsearch = false
    f = draw(s, 6, 20)
    t.assert_equal([NOR, NOR, NOR, NOR], highlights(f, 0, 4), "nohlsearch draws nothing")
    s.options.hlsearch = true
    LAST.remember(D::VimPattern.compile("x*", false, false), true)
    f = draw(s, 6, 20)
    t.assert_equal([sea, NOR, NOR], highlights(f, 1, 3), "an empty match is not drawn, a longer one is")
    LAST.preview_at(D::VimPattern.compile("y", false, false), 1, 1, 2)
    f = draw(s, 6, 20)
    t.assert_equal([NOR, D::Highlight::INC_SEARCH, NOR], highlights(f, 1, 3), "the previewed match is in the IncSearch group")
    LAST.end_preview
    LAST.hide
    PROMPT.open(false, D::Mode::NORMAL, 0, 0, 0, 0)
    s.mode = D::Mode::CMDLINE
    s.cmdline = "ab"
    f = draw(s, 6, 20)
    t.assert_equal("?ab", f.row_text(5), "a backward search prompt shows a question mark")
    PROMPT.close

    # The cursor line: the cursor's row of the current window, from the
    # end of the gutter to the window's edge, follows the cursor, the
    # focus, and the option.
    t.table([
      ["the cursor's row of the current window is lit", "on", [0, 1, 0, 0]],
      ["the blanks after the text are lit to the window's edge", "the blanks after the text", [0, 1, 0, 0]],
      ["the gutter is not lifted", "the gutter", [0, 0, 0, 0]],
      ["with the option off no row is lit", "off", [0, 0, 0, 0]],
      ["the lit row follows j", "j", [0, 1, 0, 0]],
      ["turning the option off repaints the row", "turned off", [0, 0, 0, 0]],
      ["only the current window, at the bottom, is lit", "stacked", [0, 0, 0, 0, 1, 0, 0, 0]],
      ["focus moves the lit row to the top window", "stacked, top focused", [1, 0, 0, 0, 0, 0, 0, 0]],
      ["side by side, only the right window's row is lit, to its edge", "side by side", [0, 0, 1, 1]]
    ]) { |name| cursor_line(name.to_s) }
    s = state_for(["one", "two", "three"], "a.txt")
    s.options.cursorline = true
    s.cursor.move_to(1, 0)
    f = draw(s, 6, 14)
    t.assert_equal([D::Highlight::LINE_NUMBER, D::Highlight::CURSOR_LINE_NUMBER, D::Highlight::LINE_NUMBER], [f.cell(0, 2).hl, f.cell(1, 2).hl, f.cell(2, 2).hl], "the cursor line's number is in CursorLineNr")
    t.assert_equal([NOR + LIT, NOR + LIT, D::Highlight::STATUS_MODE_NORMAL], [f.cell(1, 4).hl, f.cell(1, 13).hl, f.cell(4, 4).hl], "the text takes its group on the layer, the status bar keeps its own")
    s = state_for(["abc", "def"], "a.txt")
    s.options.cursorline = true
    s.mode = D::Mode::VISUAL
    s.window.anchor = D::Position.new(row: 0, col: 0)
    s.cursor.move_to(0, 2)
    f = draw(s, 6, 20)
    t.assert_equal([VIS + LIT, VIS + LIT, NOR + LIT, NOR + LIT], highlights(f, 0, 4), "a selection on the cursor line keeps the Visual group on the layer, the cursor cell its own")

    # The cursor shape per mode.
    t.table([
      ["a block in normal mode", "normal", :block],
      ["a bar in insert mode", "insert", :bar],
      ["an underline in replace mode", "replace", :underline],
      ["a block in visual mode", "visual", :block],
      ["a block in visual line mode", "visual_line", :block],
      ["a block in visual block mode", "visual_block", :block],
      ["a block while an operator waits", "operator_pending", :block],
      ["a block on the command line", "cmdline", :block]
    ]) { |mode| shape_in(mode.to_s) }

    t.finish
  end
end

AdaptersFramePresenterTest.main if __FILE__ == $0
