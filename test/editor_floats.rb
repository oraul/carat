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

    # Placement, border, and title.
    h = editor
    id = open(h, options("editor", 2, 4, 2, 10, true, "doc", 50, false), ["one", "two"])
    t.assert_equal(2, id, "the float's window gets the next window id")
    t.assert_equal([
      "  2 line 2",
      "  3 ╭doc───────╮",
      "  4 │one       │",
      "  5 │two       │",
      "  6 ╰──────────╯",
      "  7 line 7"
    ], rows(h, 1, 6).map { |r| r.rstrip }, "a bordered float with its title over the window")
    t.assert_equal([D::Highlight::FLOAT_BORDER, D::Highlight::TITLE, D::Highlight::NORMAL_FLOAT, D::Highlight::NORMAL], [h.frame.hl_at(2, 4), h.frame.hl_at(2, 5), h.frame.hl_at(3, 5), h.frame.hl_at(1, 5)], "the border, the title, and the text have the float groups")
    t.assert_equal([1, 1, "a.txt"], [h.window_count, h.state.window.id, h.state.buffer.path_text], "the float is not a layout window and the file window stays current")

    # Closing repaints only the rows it covered.
    h.type("<Esc>")
    t.assert_equal("  3 line 3", h.row(2).rstrip, "Esc closes the topmost float")
    t.assert_equal([2, 3, 4, 5, 11], h.frame.dirty_rows, "closing dirties the rows it covered and the message row only")
    h.type("<Esc>")
    t.assert_equal(["", 1], [h.message, h.window_count], "Esc with no float does nothing")

    # Cursor anchor and clamping.
    h = editor
    h.type("3G4l")
    open(h, options("cursor", 1, 0, 1, 6, false, "", 50, false), ["hint"])
    t.assert_equal("  4 linehint", h.row(3)[0, 14], "a cursor float starts below the cursor cell")
    h = editor
    open(h, options("editor", 5, 50, 30, 100, true, "", 50, false), ["big"])
    t.assert_equal(["╭" + "─" * 38 + "╮", "│big"], [h.row(0), h.row(1)[0, 4]], "a float larger than the screen fills it above the message row")
    t.assert_equal("╰" + "─" * 38 + "╯", h.row(10), "its bottom border is on the row above the message row")

    # z order.
    h = editor
    open(h, options("editor", 1, 1, 1, 6, false, "", 50, false), ["high"])
    open(h, options("editor", 1, 3, 1, 6, false, "", 10, false), ["lowlow"])
    t.assert_equal(" high  ow2", h.row(1)[0, 10], "a higher z is drawn over a lower one opened later")
    h.type("<Esc>")
    t.assert_equal("  2lowlow2", h.row(1)[0, 10], "Esc closes the topmost, the higher z")

    # Focus into and out of a float, and scrolling it.
    h = editor
    id = open(h, options("editor", 2, 4, 3, 10, true, "", 50, true), numbered(10))
    t.assert_equal([id, 3, 5], [h.state.window.id, h.frame.cursor_row, h.frame.cursor_col], "entering makes the float current with the cursor in it")
    h.type("jjjj")
    t.assert_equal([4, "│item 4    │", "│item 6    │", "  1 line 1"], [h.cursor[0], h.row(3)[4, 12], h.row(5)[4, 12], h.row(0).rstrip], "j scrolls the float with scrolloff and the window under it stays")
    h.type("<C-w>p")
    t.assert_equal([1, "│item 4    │"], [h.state.window.id, h.row(3)[4, 12]], "Ctrl-W p goes back to the window under it, the float stays")
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
    h.type("gt")
    t.assert_equal(true, h.row(2).include?("mine"), "the first tab page shows its float again")

    # Scrolling under a float sends no scroll region.
    h = editor
    open(h, options("editor", 2, 4, 1, 10, false, "", 50, false), ["over"])
    h.type("11G")
    h.type("j")
    t.assert_equal([0, "over"], [h.frame.scroll_count, h.row(2)[4, 4]], "a window under a float scrolls by rows, the float stays")
    h.type("<Esc>j")
    t.assert_equal(1, h.frame.scroll_count, "with the float closed the next scroll is a region again")

    # Painting under a float: each frame equals a full repaint.
    h = editor
    open(h, options("editor", 1, 2, 2, 8, true, "t", 50, false), ["AAAA", "BBBB"])
    h.type("2Gx")
    t.assert_equal(["ine 2", "│AAAA"], [h.lines[1], h.row(2)[2, 5]], "an edit under a float keeps the float drawn")
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
    t.assert_equal([id, "one"], [h.state.window.id, h.row(1)[2, 3]], "a plugin's float shows its lines and is current")
    moved = h.plugins.window_requests.move_float("test", id, 4, 6).ok
    h.redraw
    t.assert_equal([true, "one"], [moved, h.row(4)[6, 3]], "a plugin moves its float")
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
    t.assert_equal("2.3", API::VERSION, "the plugin API is 2.3")

    t.finish
  end
end

EditorFloatsTest.main if __FILE__ == $0
