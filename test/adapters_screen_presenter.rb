require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module AdaptersScreenPresenterTest
  D = Carat::Domain
  H = D::Highlight
  DARK = D::Themes.find("one_dark", "terminal")

  # A presenter with one_dark at 256 colors, as on most terminals.
  # A buffer list with no file buffer, so the frame has no tabs row.
  def self.listed_none
    D::BufferList.new(tabs: D::TabList.new(window: D::Window.new(buffer: D::Buffer.new(lines: [""], path: nil, line_ending: "\n"))))
  end

  def self.presenter(terminal)
    Carat::Adapters::ScreenPresenter.new(terminal: terminal, theme: DARK, colors: Carat::Domain::ColorDepth::COLORS_256)
  end

  # The sequence one_dark gives a group at 256 colors.
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
    screen = Carat::Adapters::ScreenPresenter.new(terminal: terminal, theme: Carat::Domain::Themes.find(theme, "terminal"), colors: colors)
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
    t.assert_equal("\e[0;38;5;247m", sgr256(H::LINE_NUMBER), "the line numbers are one_dark's gray at 256 colors")
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
    changed.cursor_shape = :underline
    changed.serial += 1
    screen.present(changed)
    t.assert_true(terminal.last_write.include?("\e[4 q"), "the underline shape is emitted when it changes")
    screen.present(changed)
    t.assert_equal(false, terminal.last_write.include?(" q"), "an unchanged underline is not repeated")
    changed.cursor_shape = :bar
    changed.serial += 1
    screen.present(changed)

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

    again = D::Frame.new(rows: 1, cols: 4)
    again.put(0, 0, "é日", D::Highlight::NORMAL)
    again.put_code(0, 3, 0xD800, 1, D::Highlight::NORMAL)
    screen.present(again)
    t.assert_true(terminal.last_write.include?("é日\u{FFFD}"), "a code point written before is written again from its kept text, a surrogate still as U+FFFD")

    buffer = D::Buffer.new(lines: ["a\u009Bb\u009Dc"], path: "a.txt", line_ending: "\n")
    options = D::Options.new
    options.number = false
    state = D::EditorState.new(tabs: D::TabList.new(window: D::Window.new(buffer: buffer)), options: options)
    cache = D::LineCache.new
    state.resize(3, 12)
    Carat::UseCases::ArrangeView.new(cache: cache, buffers: listed_none).call(state)
    drawn = Carat::Adapters::FramePresenter.new(input: D::InputState.new, plugin_ui: D::PluginUi.new, cache: cache, last_search: D::LastSearch.new, search_prompt: D::SearchPrompt.new, palette: D::Palette.new, start_screen: D::StartScreen.new, status_bar: Carat::Adapters::StatusBar.new(plugin_ui: D::PluginUi.new, slots: D::StatusSlots.new), tab_bar: Carat::Adapters::TabBar.new(buffers: listed_none), winbar: Carat::Adapters::Winbar.new(symbols: Carat::Domain::SymbolRequest.new), notices: Carat::Domain::Notices.new(history: Carat::Domain::MessageHistory.new)).call(state)
    screen.present(drawn)
    bytes = terminal.last_write
    t.assert_true(bytes.include?("a<9b>b<9d>c"), "C1 controls are written as markers")
    t.assert_true(only_escapes?(bytes), "the output holds no C0 or C1 code point outside the escape sequences")
    t.assert_equal(false, bytes.include?("\u009B"), "no raw CSI introducer is written")
    t.assert_equal(false, bytes.include?("\u009D"), "no raw OSC introducer is written")

    screen.leave
    t.assert_equal(1, terminal.left, "leave reaches the terminal")
    t.assert_true(terminal.output.end_with?("\e[0m\e[0 q\e[?25h\e[?1049l"), "leave restores the terminal's own cursor shape, shows it, and restores the main screen last")
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
    t.assert_equal(["\e[0;38;5;247;48;5;235m", "\e[0;1;38;5;236;48;5;75m", "\e[0;48;5;235m"], [sgr256(H::TAB_LINE), sgr256(H::TAB_LINE_SELECTED), sgr256(H::TAB_LINE_FILL)], "the tab line sequences at 256 colors, the selected one bold on the accent")

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
    arrange = Carat::UseCases::ArrangeView.new(cache: cache, buffers: listed_none)
    frames = Carat::Adapters::FramePresenter.new(input: D::InputState.new, plugin_ui: D::PluginUi.new, cache: cache, last_search: D::LastSearch.new, search_prompt: D::SearchPrompt.new, palette: D::Palette.new, start_screen: D::StartScreen.new, status_bar: Carat::Adapters::StatusBar.new(plugin_ui: D::PluginUi.new, slots: D::StatusSlots.new), tab_bar: Carat::Adapters::TabBar.new(buffers: listed_none), winbar: Carat::Adapters::Winbar.new(symbols: Carat::Domain::SymbolRequest.new), notices: Carat::Domain::Notices.new(history: Carat::Domain::MessageHistory.new))
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
    h.type(":set nocul<CR>60G")
    h.type("j")
    out = h.terminal.last_write
    t.assert_true(scroll_region?(out), "j at the bottom scrolls the window with a region")
    t.assert_true(out.bytesize < 500, "and writes fewer than 500 bytes")
    h.type(":set cul<CR>k")
    h.type("j")
    out = h.terminal.last_write
    t.assert_true(out.bytesize < 1500, "with the cursor line j also rewrites the two lines it moves between, fewer than 1500 bytes")
    h.type(":set nocul<CR>")
    h.type("l")
    out = h.terminal.last_write
    t.assert_equal(false, out.include?("method"), "l writes no buffer text")
    t.assert_true(out.match?(/\e\[59;\d+H\e\[0;1;38;5;253;48;5;238m2\e\[0m/), "l writes only the changed cell of the ruler")

    # The theme's background: the Normal sequence is in effect when the
    # screen is cleared and when a region scrolls, so the terminal fills
    # the cleared cells with the palette's background.
    lines_text = +""
    i = 0
    while i < 30
      lines_text << "line #{i}\n"
      i += 1
    end
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", lines_text)
    painted = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with("option.background theme\n"), rows: 10, cols: 40, plugins: [])
    normal = Carat::Adapters::SgrTable.sequence(D::Themes.find("one_dark", "theme"), H::NORMAL, C256)
    painted.open("a.txt")
    t.assert_equal("\e[0;38;5;249;48;5;236m", normal, "the painted Normal is one_dark's text color on its background")
    t.assert_true(painted.terminal.last_write.include?("#{normal}\e[2J"), "the screen is cleared after the painted Normal sequence")
    first = painted.terminal.last_write
    t.assert_true(first.include?("#{normal}line 0") || first.include?("#{normal} line 0"), "a Normal cell is written in the palette's colors")
    painted.type("jjjjjjjj")
    t.assert_true(painted.terminal.last_write.include?("#{normal}\e[1;8r\e[1S"), "a region scrolls after the painted Normal sequence")
    h = Carat::Doubles::EditorHarness.default(files, 10, 40)
    h.open("a.txt")
    t.assert_equal(false, h.terminal.last_write.include?("\e[0m\e[2J"), "the terminal's background clears the screen as before")
    h.type("jjjjjjjj")
    t.assert_true(h.terminal.last_write.include?("\e[0m\e[1;8r\e[1S"), "and scrolls after the bare reset as before")

    t.table([
      ["a truecolor comment", [T, "one_dark", H::COMMENT], "\e[0;3;38;2;149;156;168m"],
      ["a 256-color comment, the nearest index", [C256, "one_dark", H::COMMENT], "\e[0;3;38;5;247m"],
      ["a 16-color comment", [C16, "one_dark", H::COMMENT], "\e[0;3;90m"],
      ["a truecolor status line", [T, "one_dark", H::STATUS], "\e[0;1;38;2;215;218;224;48;2;62;68;82m"],
      ["a 16-color status line", [C16, "one_dark", H::STATUS], "\e[0;1;30;47m"],
      ["a 16-color error message", [C16, "one_dark", H::MESSAGE_ERROR], "\e[0;1;91m"],
      ["a truecolor string", [T, "one_dark", H::STRING], "\e[0;38;2;152;195;121m"],
      ["a 16-color Todo", [C16, "one_dark", H::TODO], "\e[0;1;30;103m"],
      ["a 16-color selection is reverse video", [C16, "one_dark", H::VISUAL], "\e[0;7m"],
      ["a 16-color cursor line is underlined", [C16, "one_dark", H::CURSOR_LINE], "\e[0;4m"],
      ["a 256-color search", [C256, "one_dark", H::SEARCH], "\e[0;38;5;236;48;5;180m"],
      ["carat-light is one_light's comment", [T, "carat-light", H::COMMENT], "\e[0;3;38;2;105;108;119m"],
      ["one_light's string at its own 256-color index", [C256, "one_light", H::STRING], "\e[0;38;5;22m"],
      ["dark_plus's comment at its own 256-color index", [C256, "dark_plus", H::COMMENT], "\e[0;3;38;5;71m"],
      ["dark_plus's keyword", [T, "dark_plus", H::KEYWORD], "\e[0;38;2;86;156;214m"],
      ["light_plus's comment", [T, "light_plus", H::COMMENT], "\e[0;3;38;2;0;128;0m"],
      ["a file-icon group", [T, "one_dark", H::ICON_RUBY], "\e[0;38;2;232;117;126m"],
      ["Normal is a bare reset", [T, "one_dark", H::NORMAL], "\e[0m"],
      ["Normal on the cursor line takes its background", [T, "one_dark", H::NORMAL + H::CURSOR_LINE_LAYER], "\e[0;48;2;44;49;60m"],
      ["a comment on the cursor line keeps its color", [T, "one_dark", H::COMMENT + H::CURSOR_LINE_LAYER], "\e[0;3;38;2;149;156;168;48;2;44;49;60m"],
      ["a 256-color comment on the cursor line", [C256, "one_dark", H::COMMENT + H::CURSOR_LINE_LAYER], "\e[0;3;38;5;247;48;5;236m"],
      ["a 16-color comment on the cursor line is underlined", [C16, "one_dark", H::COMMENT + H::CURSOR_LINE_LAYER], "\e[0;3;4;90m"],
      ["a selection on the cursor line keeps its background", [T, "one_dark", H::VISUAL + H::CURSOR_LINE_LAYER], "\e[0;48;2;62;68;82m"],
      ["a 16-color selection on the cursor line is not underlined", [C16, "one_dark", H::VISUAL + H::CURSOR_LINE_LAYER], "\e[0;7m"]
    ]) { |input| written(input[0].to_i, input[1].to_s, input[2].to_i) }
    t.assert_equal([16, 231, 232, 255, 103], [Carat::Adapters::SgrTable.index_256(0x000000), Carat::Adapters::SgrTable.index_256(0xffffff), Carat::Adapters::SgrTable.index_256(0x080808), Carat::Adapters::SgrTable.index_256(0xeeeeee), Carat::Adapters::SgrTable.index_256(0x7f849c)], "the nearest palette colors: cube corners and grays")
    t.assert_equal(Carat::Adapters::SgrTable.sequence(DARK, H::NORMAL, C256), Carat::Adapters::SgrTable.from_theme(DARK, C256).at(H::LIMIT), "an id out of range is drawn as Normal")

    t.finish
  end
end

AdaptersScreenPresenterTest.main if __FILE__ == $0
