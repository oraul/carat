require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorFloatsTest
  D = Carat::Domain
  API = Carat::PluginApi

  # A 12 by 40 editor on "a.txt", forty lines "line 1" to "line 40".
  def self.editor
    files = Carat::Doubles::MemoryFiles.new
    text = +""
    i = 1
    while i <= 40
      text << "line #{i}\n"
      i += 1
    end
    files.put("a.txt", text)
    files.put("b.txt", "bee\n")
    h = Carat::Doubles::EditorHarness.default(files, 12, 40)
    h.open("a.txt")
    h
  end

  # The editor of editor with configuration lines over the defaults, at
  # rows by cols.
  def self.configured(lines, rows, cols)
    files = Carat::Doubles::MemoryFiles.new
    text = +""
    i = 1
    while i <= 40
      text << "line #{i}\n"
      i += 1
    end
    files.put("a.txt", text)
    config = Carat::Doubles::FixedConfig.with(lines.to_s)
    h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: rows, cols: cols, plugins: [])
    h.open("a.txt")
    h
  end

  # The n cells of screen row r from column from, blanks past its end.
  def self.cells(h, r, from, n)
    s = h.row(r)
    s += " " * (from + n - s.length) if s.length < from + n
    s[from, n].to_s
  end

  def self.strings(values)
    out = []
    values.each { |v| out << v.to_s }
    out
  end

  # Opens a float through the request family as the plugin "test" and
  # draws a frame; answers the window id, 0 when refused.
  def self.open(h, options, lines)
    response = h.plugins.window_requests.open_float("test", options, lines)
    h.redraw
    response.window
  end

  def self.options(anchor, row, col, height, width, border, title, z, enter)
    API::FloatOptions.new(anchor: anchor, row: row, col: col, height: height, width: width, border: border, title: title, z: z, enter: enter)
  end

  def self.numbered(count)
    out = []
    i = 1
    while i <= count
      out << "item #{i}"
      i += 1
    end
    out
  end

  def self.rows(h, from, to)
    out = []
    r = from
    while r <= to
      out << h.row(r)
      r += 1
    end
    out
  end

  def self.main
    t = Carat::Testing.new("editor_floats")

    # Placement, border, and title. Scenarios:
    # Editor-anchored float with a border and a title
    # The shipped border is rounded
    # Padding in NormalFloat
    # A centered title
    h = editor
    id = open(h, options("editor", 2, 4, 2, 10, true, "doc", 50, false), ["one", "two"])
    t.assert_equal(2, id, "the float's window gets the next window id")
    t.assert_equal([
      "  2 line 2",
      "  3 ╭─── doc ────╮",
      "  4 │ one        │",
      "  5 │ two        │",
      "  6 ╰────────────╯",
      "  7 line 7"
    ], rows(h, 1, 6).map { |r| r.rstrip }, "a bordered float with its title over the window")
    t.assert_equal([D::Highlight::FLOAT_BORDER, D::Highlight::FLOAT_TITLE, D::Highlight::FLOAT_TITLE, D::Highlight::NORMAL_FLOAT, D::Highlight::NORMAL_FLOAT, D::Highlight::NORMAL], [h.frame.hl_at(2, 4), h.frame.hl_at(2, 8), h.frame.hl_at(2, 9), h.frame.hl_at(3, 5), h.frame.hl_at(3, 16), h.frame.hl_at(1, 5)], "the border, the title with its blanks in FloatTitle, and the padding and the text in NormalFloat")
    t.assert_equal([1, 1, "a.txt"], [h.window_count, h.state.window.id, h.state.buffer.path_text], "the float is not a layout window and the file window stays current")

    # Closing repaints only the rows it covered.
    h.type("<Esc>")
    t.assert_equal("  3 line 3", h.row(2).rstrip, "Esc closes the topmost float")
    t.assert_equal([2, 3, 4, 5, 11], h.frame.dirty_rows, "closing dirties the rows it covered and the message row only")
    h.type("<Esc>")
    t.assert_equal(["", 1], [h.message, h.window_count], "Esc with no float does nothing")

    # Cursor anchor and clamping. Scenarios: Cursor-anchored float, and
    # A float too large for the screen is cut and moved in
    h = editor
    h.type("3G4l")
    open(h, options("cursor", 1, 0, 1, 6, false, "", 50, false), ["hint"])
    t.assert_equal("  4 line hint", h.row(3)[0, 14], "a cursor float starts below the cursor cell")
    h = editor
    open(h, options("editor", 5, 50, 30, 100, true, "", 50, false), ["big"])
    t.assert_equal(["╭" + "─" * 36 + "╮", "│ big"], [h.row(1)[1, 38], h.row(2)[1, 5]], "a float larger than the screen fills it less its margin")
    t.assert_equal(["╰" + "─" * 36 + "╯", "  1 line 1", false, " "], [h.row(9)[1, 38], h.row(0).rstrip, h.row(10).include?("─"), h.row(5)[0, 1]], "its bottom border is above the margin row, the top row, the status bar, and the first column left to the window")

    # z order.
    h = editor
    open(h, options("editor", 1, 1, 1, 6, false, "", 50, false), ["high"])
    open(h, options("editor", 1, 3, 1, 6, false, "", 10, false), ["lowlow"])
    t.assert_equal("  high   w", h.row(1)[0, 10], "a higher z is drawn over a lower one opened later")
    h.type("<Esc>")
    t.assert_equal("  2 lowlow", h.row(1)[0, 10], "Esc closes the topmost, the higher z")

    # Focus into and out of a float, and scrolling it.
    h = editor
    id = open(h, options("editor", 2, 4, 3, 10, true, "", 50, true), numbered(10))
    t.assert_equal([id, 3, 6], [h.state.window.id, h.frame.cursor_row, h.frame.cursor_col], "entering makes the float current with the cursor in it")
    h.type("jjjj")
    t.assert_equal([4, "│ item 4     │", "│ item 6     │", "  1 line 1"], [h.cursor[0], h.row(3)[4, 14], h.row(5)[4, 14], h.row(0).rstrip], "j scrolls the float with scrolloff and the window under it stays")
    h.type("<C-w>p")
    t.assert_equal([1, "│ item 4     │"], [h.state.window.id, h.row(3)[4, 14]], "Ctrl-W p goes back to the window under it, the float stays")
    t.assert_equal(true, h.plugins.window_requests.focus_window("test", id).ok, "a plugin focuses a float by id")
    t.assert_equal(id, h.state.window.id, "the float is current again")
    h.type(":q<CR>")
    t.assert_equal([false, 1, "  3 line 3"], [h.quit?, h.state.window.id, h.row(2).rstrip], ":q in a float closes only the float")
    id = open(h, options("editor", 2, 4, 3, 10, true, "", 50, true), ["x"])
    h.type("<C-w>c")
    t.assert_equal([1, 1, ""], [h.state.window.id, h.window_count, h.message], "Ctrl-W c in a float closes the float")
    open(h, options("editor", 2, 4, 3, 10, true, "", 50, true), ["x"])
    h.type("<C-w>v")
    t.assert_equal([2, false], [h.window_count, h.state.tab.floats.focused?], "a split leaves the float and splits the window under it")

    # Tab pages keep their floats.
    h = editor
    open(h, options("editor", 2, 4, 1, 10, false, "", 50, false), ["mine"])
    h.type(":tabnew<CR>")
    t.assert_equal(false, h.screen.join("\n").include?("mine"), "another tab page shows no float")
    h.type("<C-PageDown>")
    t.assert_equal(true, h.row(2).include?("mine"), "the first tab page shows its float again")

    # Scrolling under a float sends no scroll region.
    h = editor
    open(h, options("editor", 2, 4, 1, 10, false, "", 50, false), ["over"])
    h.type("11G")
    h.type("j")
    t.assert_equal([0, "over"], [h.frame.scroll_count, h.row(2)[5, 4]], "a window under a float scrolls by rows, the float stays")
    h.type("<Esc>j")
    t.assert_equal(1, h.frame.scroll_count, "with the float closed the next scroll is a region again")

    # Painting under a float: each frame equals a full repaint.
    h = editor
    open(h, options("editor", 1, 2, 2, 8, true, "t", 50, false), ["AAAA", "BBBB"])
    h.type("2Gx")
    t.assert_equal(["ine 2", "│ AAAA"], [h.lines[1], h.row(2)[2, 6]], "an edit under a float keeps the float drawn")
    h.type("jxkxu")
    shown = h.screen
    h.resize(12, 40)
    t.assert_equal(shown, h.screen, "after edits and moves under a float the screen equals a full repaint")
    h.type("<C-w>v")
    h.type("x")
    shown = h.screen
    h.resize(12, 40)
    t.assert_equal(shown, h.screen, "with two windows under a float the screen equals a full repaint")

    # Plugin requests.
    h = editor
    id = open(h, options("editor", 1, 2, 2, 8, false, "", 50, true), ["one", "two"])
    t.assert_equal([id, "one"], [h.state.window.id, h.row(1)[3, 3]], "a plugin's float shows its lines and is current")
    moved = h.plugins.window_requests.move_float("test", id, 4, 6).ok
    h.redraw
    t.assert_equal([true, "one"], [moved, h.row(4)[7, 3]], "a plugin moves its float")
    t.assert_equal("  2 line 2", h.row(1).rstrip, "the rows it left show the window again")
    t.assert_equal([false, "No float #{id}"], [h.plugins.window_requests.close_float("other", id).ok, h.plugins.window_requests.close_float("other", id).message], "another plugin's float cannot be closed")
    t.assert_equal(false, h.plugins.window_requests.move_float("other", id, 0, 0).ok, "nor moved")
    t.assert_equal(true, h.plugins.window_requests.close_float("test", 0).ok, "the plugin closes its current float with 0")
    t.assert_equal([1, 0], [h.state.window.id, h.state.tab.floats.count], "the window under it is current")
    id = open(h, options("editor", 1, 2, 2, 8, false, "", 50, true), ["pick"])
    opened = h.plugins.window_requests.open_file("test", 1, "b.txt")
    h.redraw
    float_window = h.state.tab.floats.at(0).window
    t.assert_equal([true, 1, "b.txt", "pick"], [opened.ok, h.state.window.id, h.state.buffer.path_text, float_window.buffer.line(0)], "a file opened in the layout window while a float is focused goes to that window")
    t.assert_equal(true, h.plugins.window_requests.close_float("test", id).ok, "the float it left is still the plugin's")

    # A float closed and replaced by another at the same box.
    h = editor
    open(h, options("editor", 2, 4, 2, 10, true, "one", 50, false), ["first", "rows"])
    h.redraw
    h.plugins.window_requests.close_float("test", h.state.tab.floats.at(0).id)
    open(h, options("editor", 2, 4, 2, 10, true, "two", 50, false), ["other", "text"])
    h.redraw
    reopened = rows(h, 2, 5)
    shown = h.screen
    h.resize(12, 40)
    t.assert_equal([true, shown], [reopened[1].include?("other") && reopened[0].include?("two"), h.screen], "a float reopened at the same box shows its own text and equals a full repaint")

    # A float showing a file keeps its cursor inside the text.
    h = editor
    open(h, options("editor", 1, 2, 3, 12, false, "", 50, true), ["x"])
    h.type(":e a.txt<CR>G")
    float_window = h.state.window
    t.assert_equal([true, 39], [h.state.tab.floats.focused?, float_window.cursor.row], "a float loads a file and goes to its last line")
    h.type("<C-w>pgg30dd")
    t.assert_equal([1, 9], [h.state.window.id, float_window.cursor.row], "lines deleted in the layout window pull the float's cursor onto the last line")
    shown = h.screen
    h.resize(12, 40)
    t.assert_equal(shown, h.screen, "the float's text equals a full repaint after the delete")
    t.table([
      ["an unknown anchor", ["window", 1, 1, 50], "No anchor window: editor or cursor"],
      ["no rows", ["editor", 0, 1, 50], "A float needs at least one row and one column"],
      ["a z out of range", ["editor", 1, 1, 2000], "No z order 2000: 0 to 1000"]
    ]) do |row|
      h.plugins.window_requests.open_float("test", options(row[0].to_s, 0, 0, row[1].to_i, row[2].to_i, false, "", row[3].to_i, false), ["x"]).message
    end
    i = 0
    while i < 16
      open(h, options("editor", 0, 0, 1, 1, false, "", 0, false), ["x"])
      i += 1
    end
    t.assert_equal("Too many floating windows", h.plugins.window_requests.open_float("test", API::FloatOptions.at(0, 0, 1, 1), ["x"]).message, "a tab page holds sixteen floats")
    t.assert_equal("2.6", API::VERSION, "the plugin API is 2.6")

    # Scenario: An offset out of range is refused.
    h = editor
    refused = h.plugins.window_requests.open_float("test", options("editor", 0, 10_001, 1, 4, true, "", 50, false), ["x"])
    t.assert_equal([false, "No offset 10001: -10000 to 10000", 0], [refused.ok, refused.message, h.state.tab.floats.count], "An offset out of range is refused when a float opens")
    id = open(h, options("editor", 1, 2, 1, 4, false, "", 50, false), ["x"])
    moved = h.plugins.window_requests.move_float("test", id, -10_001, 0)
    spec = h.state.tab.floats.at(0).spec
    t.assert_equal([false, "No offset -10001: -10000 to 10000", 1, 2], [moved.ok, moved.message, spec.row, spec.col], "and when it moves, the float staying where it was")

    # Scenario: The frame under each border.
    frames = [h.plugins.window_requests.float_frame("test", true)]
    h.state.options.winborder = "none"
    frames << h.plugins.window_requests.float_frame("test", true)
    frames << h.plugins.window_requests.float_frame("test", false)
    t.assert_equal([[true, 1, 1, 1, 14], [true, 0, 1, 1, 12], [true, 0, 1, 1, 12]], frames.map { |f| [f.ok, f.edge, f.padding, f.margin, f.box_width(10)] }, "The frame under each border: the edge, padding, margin, and a 10-column text's box")

    # The frame: each border style and the ASCII form at a small and a
    # large screen. Scenarios: Each border style, The ASCII border, No
    # border, A long title is cut, A notification follows the border style.
    frames = [
      ["rounded", "", ["╭", "╮", "╰", "╯", "─", "│"]],
      ["single", "option.winborder single\n", ["┌", "┐", "└", "┘", "─", "│"]],
      ["double", "option.winborder double\n", ["╔", "╗", "╚", "╝", "═", "║"]],
      ["solid", "option.winborder solid\n", [" ", " ", " ", " ", " ", " "]],
      ["ascii", "option.icons ascii\n", ["+", "+", "+", "+", "-", "|"]],
      ["ascii double", "option.icons ascii\noption.winborder double\n", ["+", "+", "+", "+", "-", "|"]]
    ]
    frames.each do |row|
      name = row[0].to_s
      g = strings(row[2])
      small = configured(row[1].to_s, 12, 40)
      open(small, options("editor", 2, 4, 2, 10, true, "doc", 50, false), ["one", "two"])
      expected = [g[0] + g[4] * 3 + " doc " + g[4] * 4 + g[1], g[5] + " one        " + g[5], g[5] + " two        " + g[5], g[2] + g[4] * 12 + g[3]]
      got = [cells(small, 2, 4, 14), cells(small, 3, 4, 14), cells(small, 4, 4, 14), cells(small, 5, 4, 14)]
      t.assert_equal(expected, got, "frame #{name} at 40 by 12: #{got.join(" / ")}")
      large = configured(row[1].to_s, 36, 120)
      open(large, options("editor", 10, 30, 3, 50, true, "a longer title", 50, false), ["one", "two", "three"])
      expected = [g[0] + g[4] * 18 + " a longer title " + g[4] * 18 + g[1], g[5] + " one" + " " * 48 + g[5], g[5] + " three" + " " * 46 + g[5], g[2] + g[4] * 52 + g[3]]
      got = [cells(large, 10, 30, 54), cells(large, 11, 30, 54), cells(large, 13, 30, 54), cells(large, 14, 30, 54)]
      t.assert_equal(expected, got, "frame #{name} at 120 by 36: #{got.join(" / ")}")
    end
    # Scenario: The ASCII border under NO_COLOR.
    h = configured("", 12, 40)
    h.terminal.no_color = true
    h.open("a.txt")
    open(h, options("editor", 2, 4, 2, 10, true, "doc", 50, false), ["one", "two"])
    got = [cells(h, 2, 4, 14), cells(h, 3, 4, 14), cells(h, 5, 4, 14)]
    t.assert_equal(["+--- doc ----+", "| one        |", "+------------+"], got, "frame rounded under NO_COLOR: #{got.join(" / ")}")
    h = configured("option.winborder none\n", 12, 40)
    open(h, options("editor", 2, 4, 2, 10, true, "doc", 50, false), ["one", "two"])
    t.assert_equal(["  2 line 2", "  3  one        ", "  4  two        ", "  5 line 5"], [h.row(1).rstrip, cells(h, 2, 0, 16), cells(h, 3, 0, 16), h.row(4).rstrip], "with winborder none a bordered float has no edge and no title, its padding kept")
    t.assert_equal([D::Highlight::NORMAL_FLOAT, D::Highlight::NORMAL_FLOAT, D::Highlight::NORMAL], [h.frame.hl_at(2, 4), h.frame.hl_at(2, 15), h.frame.hl_at(2, 16)], "the padding of a float without an edge is in NormalFloat")
    h = editor
    open(h, options("editor", 2, 4, 1, 4, true, "a long title", 50, false), ["abcd"])
    t.assert_equal(["╭ a lo ╮", "│ abcd │"], [h.row(2)[4, 8], h.row(3)[4, 8]], "a long title is cut between the corners with a blank on each side")
    h = configured("option.winborder double\n", 12, 60)
    h.assembly.notices.add("disk almost full", D::MessageHistory::WARNING, h.clock.now)
    h.redraw
    t.assert_equal(["╔════ Warning ═════╗", "║ disk almost full ║", "╚══════════════════╝"], [h.row(0)[39, 20], h.row(1)[39, 20], h.row(2)[39, 20]], "a notification box is drawn in the border style")
    # Scenario: A notification title is centered like a float title.
    t.assert_equal([D::Highlight::FLOAT_BORDER, D::Highlight::DIAGNOSTIC_WARN, D::Highlight::DIAGNOSTIC_WARN, D::Highlight::DIAGNOSTIC_WARN, D::Highlight::FLOAT_BORDER], [h.frame.hl_at(0, 43), h.frame.hl_at(0, 44), h.frame.hl_at(0, 48), h.frame.hl_at(0, 52), h.frame.hl_at(0, 53)], "A notification title is centered like a float title: the severity and its blanks in its group")

    t.finish
  end
end

EditorFloatsTest.main if __FILE__ == $0
