require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module AdaptersScreenPresenterTest
  D = Carat::Domain
  H = D::Highlight
  DARK = D::Themes.find("carat-dark")

  # A presenter with carat-dark at 256 colors, as on most terminals.
  def self.presenter(terminal)
    Carat::Adapters::ScreenPresenter.new(terminal: terminal, theme: DARK, colors: Carat::Domain::ColorDepth::COLORS_256)
  end

  # The sequence carat-dark gives a group at 256 colors.
  def self.sgr256(id)
    Carat::Adapters::SgrTable.sequence(DARK, id, Carat::Domain::ColorDepth::COLORS_256)
  end

  # A frame drawn from a line with C1 controls reaches the terminal as markers:
  # the only control byte in the output is the escape that starts the
  # presenter's own sequences.
  def self.only_escapes?(bytes)
    clean = true
    bytes.each_codepoint do |code|
      clean = false if code != 27 && Carat::Domain::DisplayWidth.control?(code)
    end
    clean
  end

  # Scroll regions: a full-width window scrolled by a line sends a scroll
  # region over its text rows and only the line that came into view.
  #: (String) -> bool
  def self.scroll_region?(bytes)
    bytes.match?(/\e\[\d+;\d+r/)
  end

  # Colors at each depth: truecolor components, the 256-color palette,
  # and the theme's own 16-color values.
  #: (Integer, String, Integer) -> String
  def self.written(colors, theme, id)
    clock = Carat::Doubles::ManualClock.new
    terminal = Carat::Doubles::FakeTerminal.new(clock: clock, rows: 1, cols: 6)
    screen = Carat::Adapters::ScreenPresenter.new(terminal: terminal, theme: Carat::Domain::Themes.find(theme), colors: colors)
    frame = Carat::Domain::Frame.new(rows: 1, cols: 6)
    frame.put(0, 0, "x", id)
    screen.present(frame)
    out = terminal.last_write
    at = out.index("x")
    start = out.rindex("\e[", at)
    out[start, at - start]
  end

  T = D::ColorDepth::TRUECOLOR
  C256 = D::ColorDepth::COLORS_256
  C16 = D::ColorDepth::COLORS_16

  def self.main
    t = Carat::Testing.new("adapters_screen_presenter")

    clock = Carat::Doubles::ManualClock.new
    terminal = Carat::Doubles::FakeTerminal.new(clock: clock, rows: 4, cols: 10)
    screen = presenter(terminal)

    screen.enter
    t.assert_equal(1, terminal.entered, "enter reaches the terminal")
    t.assert_equal("\e[?1049h\e[H\e[2J", terminal.last_write, "enter switches to the alternate screen and clears it")

    frame = D::Frame.new(rows: 3, cols: 6)
    frame.put(0, 0, "hello", D::Highlight::NORMAL)
    frame.put(1, 0, "two", D::Highlight::LINE_NUMBER)
    frame.cursor_row = 1
    frame.cursor_col = 2
    screen.present(frame)
    first = terminal.last_write
    t.assert_true(first.include?("\e[2J"), "first frame clears the screen")
    t.assert_true(first.include?("\e[1;1H\e[0mhello"), "first frame writes row 1 with the normal highlight")
    t.assert_true(first.include?("\e[2;1H#{sgr256(H::LINE_NUMBER)}two"), "line number highlight is emitted before the text")
    t.assert_equal("\e[0;38;5;243m", sgr256(H::LINE_NUMBER), "the line numbers are carat-dark's gray at 256 colors")
    t.assert_equal(false, first.include?("\e[3;1H"), "first frame skips a blank row, which the clear already drew")
    t.assert_true(first.end_with?("\e[2;3H\e[2 q\e[?25h"), "cursor position, block shape, and cursor shown last")
    t.assert_true(first.start_with?("\e[?25l"), "cursor hidden while drawing")

    same = D::Frame.new(rows: 3, cols: 6)
    same.put(0, 0, "hello", D::Highlight::NORMAL)
    same.put(1, 0, "two", D::Highlight::LINE_NUMBER)
    same.cursor_row = 1
    same.cursor_col = 2
    screen.present(same)
    second = terminal.last_write
    t.assert_equal(false, second.include?("hello"), "identical frame writes no cell text")
    t.assert_equal(false, second.include?("two"), "identical frame writes no second row")
    t.assert_true(second.include?("\e[2;3H"), "identical frame still positions the cursor")
    t.assert_equal(false, second.include?(" q"), "unchanged shape is not repeated")

    changed = D::Frame.new(rows: 3, cols: 6)
    changed.put(0, 0, "hello", D::Highlight::NORMAL)
    changed.put(1, 0, "two", D::Highlight::LINE_NUMBER)
    changed.put(2, 0, "three", D::Highlight::STATUS)
    changed.cursor_row = 1
    changed.cursor_col = 2
    changed.cursor_shape = :bar
    screen.present(changed)
    third = terminal.last_write
    t.assert_true(third.include?("\e[3;1H#{sgr256(H::STATUS)}three"), "changed row is written with its highlight")
    t.assert_equal(false, third.include?("hello"), "unchanged row is not written")
    t.assert_true(third.include?("\e[6 q"), "bar shape is emitted when it changes")

    resized = D::Frame.new(rows: 2, cols: 6)
    resized.put(0, 0, "hello", D::Highlight::NORMAL)
    screen.present(resized)
    fourth = terminal.last_write
    t.assert_true(fourth.include?("\e[2J"), "a size change clears the screen")
    t.assert_true(fourth.include?("hello"), "a size change repaints every row")

    wide = D::Frame.new(rows: 1, cols: 4)
    wide.put(0, 0, "日x", D::Highlight::NORMAL)
    screen.present(wide)
    t.assert_true(terminal.last_write.include?("日x"), "a wide character is written once and its continuation cell skipped")

    beyond = D::Frame.new(rows: 1, cols: 4)
    beyond.put(0, 0, "abcd", D::Highlight::NORMAL)
    beyond.put_code(0, 1, 0x110000, 1, D::Highlight::NORMAL)
    beyond.put_code(0, 2, 0xD800, 1, D::Highlight::NORMAL)
    screen.present(beyond)
    t.assert_true(terminal.last_write.include?("a\u{FFFD}\u{FFFD}d"), "a code above U+10FFFF or a surrogate in a cell is written as U+FFFD")

    buffer = D::Buffer.new(lines: ["a\u009Bb\u009Dc"], path: "a.txt", line_ending: "\n")
    options = D::Options.new
    options.number = false
    state = D::EditorState.new(tabs: D::TabList.new(window: D::Window.new(buffer: buffer)), options: options)
    cache = D::LineCache.new
    state.resize(3, 12)
    Carat::UseCases::ArrangeView.new(cache: cache).call(state)
    drawn = Carat::Adapters::FramePresenter.new(input: D::InputState.new, plugin_ui: D::PluginUi.new, cache: cache).call(state)
    screen.present(drawn)
    bytes = terminal.last_write
    t.assert_true(bytes.include?("a<9b>b<9d>c"), "C1 controls are written as markers")
    t.assert_true(only_escapes?(bytes), "the output holds no C0 or C1 code point outside the escape sequences")
    t.assert_equal(false, bytes.include?("\u009B"), "no raw CSI introducer is written")
    t.assert_equal(false, bytes.include?("\u009D"), "no raw OSC introducer is written")

    screen.leave
    t.assert_equal(1, terminal.left, "leave reaches the terminal")
    t.assert_true(terminal.output.end_with?("\e[0m\e[2 q\e[?25h\e[?1049l"), "leave restores the block cursor and the main screen last")
    t.assert_true(terminal.output.start_with?("\e[?1049h"), "output begins with the alternate screen")

    # The window and tab line highlights have their own sequences.
    colored = D::Frame.new(rows: 4, cols: 8)
    colored.put(0, 0, "nc", D::Highlight::STATUS_NC)
    colored.put(1, 0, "tab", D::Highlight::TAB_LINE)
    colored.put(2, 0, "sel", D::Highlight::TAB_LINE_SELECTED)
    colored.put(3, 0, "fill", D::Highlight::TAB_LINE_FILL)
    clock = Carat::Doubles::ManualClock.new
    terminal = Carat::Doubles::FakeTerminal.new(clock: clock, rows: 4, cols: 8)
    screen = presenter(terminal)
    screen.present(colored)
    out = terminal.last_write
    t.assert_true(out.include?("#{sgr256(H::STATUS_NC)}nc"), "inactive status lines have the theme's StatusLineNC")
    t.assert_true(out.include?("#{sgr256(H::TAB_LINE)}tab"), "tab line labels have TabLine")
    t.assert_true(out.include?("#{sgr256(H::TAB_LINE_SELECTED)}sel"), "the selected label has TabLineSel")
    t.assert_true(out.include?("#{sgr256(H::TAB_LINE_FILL)}fill"), "the tab line fill has TabLineFill")
    t.assert_equal(["\e[0;38;5;146;48;5;237m", "\e[0;1;38;5;189m", "\e[0;48;5;237m"], [sgr256(H::TAB_LINE), sgr256(H::TAB_LINE_SELECTED), sgr256(H::TAB_LINE_FILL)], "the tab line sequences at 256 colors")

    # The visual selection has the theme's Visual background.
    selected = D::Frame.new(rows: 1, cols: 8)
    selected.put(0, 0, "ab", D::Highlight::NORMAL)
    selected.put(0, 2, "cd", D::Highlight::VISUAL)
    clock = Carat::Doubles::ManualClock.new
    terminal = Carat::Doubles::FakeTerminal.new(clock: clock, rows: 1, cols: 8)
    screen = presenter(terminal)
    screen.present(selected)
    t.assert_true(terminal.last_write.include?("#{sgr256(H::VISUAL)}cd"), "the selection has the Visual background")

    # Changed runs: only the cells that differ are written, each run after a
    # cursor position.
    clock = Carat::Doubles::ManualClock.new
    terminal = Carat::Doubles::FakeTerminal.new(clock: clock, rows: 2, cols: 20)
    screen = presenter(terminal)
    before = D::Frame.new(rows: 2, cols: 20)
    before.put(0, 0, "hello world", D::Highlight::NORMAL)
    screen.present(before)
    after = D::Frame.new(rows: 2, cols: 20)
    after.put(0, 0, "hello there", D::Highlight::NORMAL)
    screen.present(after)
    out = terminal.last_write
    t.assert_true(out.include?("\e[1;7H\e[0mthere"), "only the changed part of a row is written, from its column")
    t.assert_equal(false, out.include?("hello"), "the unchanged part of the row is not written")
    t.assert_equal(false, out.include?("\e[2J"), "a later frame does not clear the screen")
    joined = D::Frame.new(rows: 2, cols: 20)
    joined.put(0, 0, "Xello Xhere", D::Highlight::NORMAL)
    screen.present(joined)
    t.assert_true(terminal.last_write.include?("Xello X"), "two changed cells a few cells apart are written as one run")
    screen.present(joined)
    t.assert_equal("\e[?25l\e[1;1H\e[?25h", terminal.last_write, "the same frame presented again writes only the cursor")
    wide_before = D::Frame.new(rows: 2, cols: 20)
    wide_before.put(0, 0, "中b", D::Highlight::NORMAL)
    screen.present(wide_before)
    wide_after = D::Frame.new(rows: 2, cols: 20)
    wide_after.put(0, 0, "ab", D::Highlight::NORMAL)
    screen.present(wide_after)
    out = terminal.last_write
    t.assert_true(out.include?("\e[1;1H\e[0mab"), "a wide character replaced by two narrow ones is rewritten from its first cell")
    narrow_after = D::Frame.new(rows: 2, cols: 20)
    narrow_after.put(0, 0, "a中", D::Highlight::NORMAL)
    screen.present(narrow_after)
    t.assert_true(terminal.last_write.include?("\e[1;2H\e[0m中"), "a wide character replacing a narrow one is written from its column")

    # Frames from the frame presenter: one not presented makes the next one
    # a full redraw, because the frame the terminal shows was repainted.
    lines = []
    i = 0
    while i < 6
      lines << "line #{i}"
      i += 1
    end
    options = D::Options.new
    state = D::EditorState.new(tabs: D::TabList.new(window: D::Window.new(buffer: D::Buffer.new(lines: lines, path: "a.txt", line_ending: "\n"))), options: options)
    cache = D::LineCache.new
    arrange = Carat::UseCases::ArrangeView.new(cache: cache)
    frames = Carat::Adapters::FramePresenter.new(input: D::InputState.new, plugin_ui: D::PluginUi.new, cache: cache)
    clock = Carat::Doubles::ManualClock.new
    terminal = Carat::Doubles::FakeTerminal.new(clock: clock, rows: 5, cols: 20)
    screen = presenter(terminal)
    state.resize(5, 20)
    arrange.call(state)
    screen.present(frames.call(state))
    state.cursor.move_to(1, 0)
    arrange.call(state)
    screen.present(frames.call(state))
    t.assert_equal(false, terminal.last_write.include?("\e[2J"), "a frame drawn after the presented one is written incrementally")
    t.assert_equal(false, terminal.last_write.include?("line"), "a cursor move writes no line text")
    state.cursor.move_to(2, 0)
    arrange.call(state)
    frames.call(state)
    state.cursor.move_to(3, 0)
    arrange.call(state)
    screen.present(frames.call(state))
    t.assert_true(terminal.last_write.include?("\e[2J"), "after a frame that was not presented the next one is drawn in full")
    t.assert_true(terminal.last_write.include?("line 3"), "and every row is written")

    files = Carat::Doubles::MemoryFiles.new
    text = +""
    i = 0
    while i < 30
      text << "line #{i}\n"
      i += 1
    end
    files.put("a.txt", text)
    h = Carat::Doubles::EditorHarness.default(files, 10, 40)
    h.open("a.txt")
    h.type("jjjj")
    t.assert_equal(false, scroll_region?(h.terminal.last_write), "a cursor move inside the window sends no scroll region")
    h.type("j")
    out = h.terminal.last_write
    t.assert_true(out.include?("\e[1;8r\e[1S\e[r"), "scrolling down a line sets the region over the text rows, scrolls it up by one, and resets it")
    t.assert_true(out.include?("line 8"), "the line that came into view at the bottom is written")
    t.assert_equal(false, out.include?("line 7"), "the lines that moved are not written again")
    h.type("k")
    t.assert_equal(false, scroll_region?(h.terminal.last_write), "moving up inside the window sends no scroll region")
    h.type("k")
    out = h.terminal.last_write
    t.assert_true(out.include?("\e[1;8r\e[1T\e[r"), "scrolling up a line scrolls the region down by one")
    t.assert_true(out.include?("line 0"), "the line that came into view at the top is written")
    t.assert_equal(false, out.include?("line 1"), "the lines that moved down are not written again")
    h.resize(8, 40)
    out = h.terminal.last_write
    t.assert_true(out.include?("\e[2J"), "the first frame after a resize is written in full")
    t.assert_equal(false, scroll_region?(out), "and sends no scroll region though the window scrolled")
    h.type(":vsplit<CR>")
    h.type("<C-w>lGgg")
    h.type("jjjj")
    h.type("j")
    out = h.terminal.last_write
    t.assert_equal(false, scroll_region?(out), "a window beside another scrolls by rows, without a region")
    t.assert_true(out.include?("line 6"), "and writes the rows that changed")

    # Bytes per j on a 200-column terminal with long lines.
    files = Carat::Doubles::MemoryFiles.new
    text = +""
    i = 0
    while i < 100
      text << "    def method_#{i}(arg, other) # some comment text here #{i} end" + " x" * 60 + "\n"
      i += 1
    end
    files.put("a.txt", text)
    h = Carat::Doubles::EditorHarness.default(files, 60, 200)
    h.open("a.txt")
    h.type("60G")
    h.type("j")
    out = h.terminal.last_write
    t.assert_true(scroll_region?(out), "j at the bottom scrolls the window with a region")
    t.assert_true(out.bytesize < 500, "and writes fewer than 500 bytes")
    h.type("l")
    out = h.terminal.last_write
    t.assert_equal(false, out.include?("method"), "l writes no buffer text")
    t.assert_true(out.match?(/\e\[59;\d+H\e\[0;1;38;5;189;48;5;239m2\e\[0m/), "l writes only the changed cell of the ruler")

    t.table([
      ["a truecolor comment", [T, "carat-dark", H::COMMENT], "\e[0;3;38;2;127;132;156m"],
      ["a 256-color comment", [C256, "carat-dark", H::COMMENT], "\e[0;3;38;5;103m"],
      ["a 16-color comment", [C16, "carat-dark", H::COMMENT], "\e[0;3;90m"],
      ["a truecolor status line", [T, "carat-dark", H::STATUS], "\e[0;1;38;2;205;214;244;48;2;69;71;90m"],
      ["a 16-color status line", [C16, "carat-dark", H::STATUS], "\e[0;1;30;47m"],
      ["a 16-color error message", [C16, "carat-dark", H::MESSAGE_ERROR], "\e[0;1;97;41m"],
      ["a truecolor string", [T, "carat-dark", H::STRING], "\e[0;38;2;166;227;161m"],
      ["a 16-color Todo", [C16, "carat-dark", H::TODO], "\e[0;1;30;103m"],
      ["carat-light's comment", [T, "carat-light", H::COMMENT], "\e[0;3;38;2;140;143;161m"],
      ["carat-light's string at 256 colors", [C256, "carat-light", H::STRING], "\e[0;38;5;70m"],
      ["Normal is a bare reset", [T, "carat-dark", H::NORMAL], "\e[0m"]
    ]) { |input| written(input[0].to_i, input[1].to_s, input[2].to_i) }
    t.assert_equal([16, 231, 232, 255, 103], [Carat::Adapters::SgrTable.index_256(0x000000), Carat::Adapters::SgrTable.index_256(0xffffff), Carat::Adapters::SgrTable.index_256(0x080808), Carat::Adapters::SgrTable.index_256(0xeeeeee), Carat::Adapters::SgrTable.index_256(0x7f849c)], "the nearest palette colors: cube corners and grays")
    t.assert_equal(Carat::Adapters::SgrTable.sequence(DARK, H::NORMAL, C256), Carat::Adapters::SgrTable.from_theme(DARK, C256).at(99), "an id out of range is drawn as Normal")

    t.finish
  end
end

AdaptersScreenPresenterTest.main if __FILE__ == $0
