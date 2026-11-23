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

  # The groups, without their layer, of the first count cells of the
  # float's text row.
  def self.float_groups(h, row, count)
    window = h.state.tab.floats.at(0).window
    out = []
    c = 0
    while c < count
      out << D::Highlight.base(h.frame.hl_at(window.row + row - window.top, window.col + c))
      c += 1
    end
    out
  end

  def self.ints(values)
    out = []
    values.each { |v| out << v.to_i }
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

    # Scenario: Refilled in place.
    h = editor
    id = open(h, options("editor", 2, 4, 2, 10, true, "old", 50, false), ["first", "rows"])
    h.redraw
    refilled = h.plugins.window_requests.set_float_lines("test", id, ["other"], "new")
    h.redraw
    float = h.state.tab.floats.at(0)
    t.assert_equal([true, 1, id, 2, 4, 2, 10], [refilled.ok, h.state.tab.floats.count, float.id, float.spec.row, float.spec.col, float.spec.height, float.spec.width], "Refilled in place: the float keeps its window id and box")
    t.assert_equal(["new", "new", "other"], [float.spec.title, float.window.buffer.title, float.window.buffer.lines.join("|")], "the refilled float holds the new lines and title")
    refilled_rows = rows(h, 2, 5)
    shown = h.screen
    h.resize(12, 40)
    t.assert_equal([true, true, false, shown], [refilled_rows[0].include?("new"), refilled_rows[1].include?("other"), refilled_rows.join("\n").include?("rows"), h.screen], "the refilled float shows the new title and lines and equals a full repaint")

    # Scenario: The current float refilled with 0.
    h = editor
    id = open(h, options("editor", 1, 2, 3, 8, false, "", 50, true), ["a", "b", "c"])
    h.type("j")
    before = h.state.window.cursor.row
    refilled = h.plugins.window_requests.set_float_lines("test", 0, ["only"], "")
    h.redraw
    t.assert_equal([1, true, id, true, 0, "only"], [before, refilled.ok, h.state.window.id, h.state.tab.floats.focused?, h.state.window.cursor.row, h.state.window.buffer.lines.join("|")], "The current float refilled with 0 shows the line, stays current, and its cursor goes to its first line")
    t.assert_equal("only", h.row(1)[3, 4], "the current float draws its new line")
    h.plugins.window_requests.set_float_lines("test", 0, ["a", "b", "c"], "")
    h.type("jvj")
    selecting = [h.state.window.anchor.row, h.state.window.cursor.row]
    h.plugins.window_requests.set_float_lines("test", 0, ["one"], "")
    h.redraw
    t.assert_equal([1, 2, 0, 0, "one"], [selecting[0], selecting[1], h.state.window.anchor.row, h.state.window.cursor.row, h.row(1)[3, 3]], "a float refilled during a selection in it puts the anchor and the cursor on its first line")

    # Scenario: Refilled with no lines.
    refilled = h.plugins.window_requests.set_float_lines("test", id, strings([]), "")
    t.assert_equal([true, 1, ""], [refilled.ok, h.state.window.buffer.lines.length, h.state.window.buffer.line(0)], "Refilled with no lines, the float shows one empty line")

    # Scenario: Another plugin's float is not refilled.
    h = editor
    id = open(h, options("editor", 2, 4, 1, 10, true, "mine", 50, false), ["kept"])
    other = h.plugins.window_requests.set_float_lines("other", id, ["taken"], "theirs")
    unknown = h.plugins.window_requests.set_float_lines("test", 999, ["taken"], "theirs")
    layout = h.plugins.window_requests.set_float_lines("test", 1, ["taken"], "theirs")
    float = h.state.tab.floats.at(0)
    t.assert_equal([false, "No float #{id}", "No float 999", "No float 1"], [other.ok, other.message, unknown.message, layout.message], "Another plugin's float is not refilled, nor an unknown id or a layout window")
    t.assert_equal(["kept", "mine", "line 1"], [float.window.buffer.lines.join("|"), float.spec.title, h.state.buffer.line(0)], "the float keeps its lines and title and the layout window its text")

    # Scenario: A float showing a scratch buffer is not refilled.
    h = editor
    h.plugins.window_requests.open_scratch("test", "notes", "left", 20, ["scratch"], nil)
    scratch = h.assembly.buffers.scratch_for("test", "notes")
    id = open(h, options("editor", 2, 4, 1, 10, true, "mine", 50, true), ["kept"])
    h.assembly.buffers.load(scratch)
    switched = h.plugins.window_requests.set_float_lines("test", id, ["taken"], "theirs")
    t.assert_equal([true, false, "No float #{id}", "scratch", "notes"], [h.state.window.buffer.equal?(scratch), switched.ok, switched.message, scratch.lines.join("|"), scratch.title], "A float showing a scratch buffer is not refilled and the scratch buffer keeps its lines and title")

    # Scenario: A row and spans styled.
    hl = D::Highlight
    sel = hl::POPUP_MENU_SELECTED
    menu = hl::POPUP_MENU
    match = hl::POPUP_MENU_MATCH
    plain = hl::NORMAL_FLOAT
    h = editor
    id = open(h, options("editor", 2, 4, 3, 10, true, "", 50, false), ["alpha", "beta", "gamma"])
    styled = h.plugins.window_requests.style_float("test", id, 1, ints([0, 0, 2, match, 1, 1, 2, match]))
    h.redraw
    h.redraw
    t.assert_equal([true, [match, match, menu, menu], [sel, hl::POPUP_MENU_MATCH_SELECTED, hl::POPUP_MENU_MATCH_SELECTED, sel], [menu, menu, menu, menu]], [styled.ok, float_groups(h, 0, 4), float_groups(h, 1, 4), float_groups(h, 2, 4)], "A row and spans styled: the selected row in PmenuSel, the others in Pmenu, the span in PmenuMatch and on the selected row in PmenuMatchSel")
    drawn = [float_groups(h, 0, 10), float_groups(h, 1, 10), float_groups(h, 2, 10)]
    shown = h.screen
    h.resize(12, 40)
    t.assert_equal([shown, drawn], [h.screen, [float_groups(h, 0, 10), float_groups(h, 1, 10), float_groups(h, 2, 10)]], "the styled float equals a full repaint")

    # Scenario: A restyle repaints.
    count = h.state.tab.floats.at(0).style_count
    h.plugins.window_requests.style_float("test", id, 1, ints([2, 1, 3, match]))
    h.redraw
    drawn = [float_groups(h, 0, 5), float_groups(h, 1, 5), float_groups(h, 2, 5)]
    t.assert_equal([count + 1, [menu, menu, menu, menu, menu], [sel, sel, sel, sel, sel], [menu, match, match, match, menu]], [h.state.tab.floats.at(0).style_count, drawn[0], drawn[1], drawn[2]], "A restyle repaints: the old spans are gone and the new one is drawn, with the lines and the selected row unchanged")
    h.resize(12, 40)
    t.assert_equal(drawn, [float_groups(h, 0, 5), float_groups(h, 1, 5), float_groups(h, 2, 5)], "the restyled float equals a full repaint")

    # Scenario: Spans without a selected row.
    styled = h.plugins.window_requests.style_float("test", id, -1, ints([0, 0, 2, sel, 2, 0, 3, hl::COMMENT, 2, 2, 1, sel]))
    h.redraw
    t.assert_equal([true, [sel, sel, plain, plain], [plain, plain, plain, plain], [hl::COMMENT, hl::COMMENT, sel, plain]], [styled.ok, float_groups(h, 0, 4), float_groups(h, 1, 4), float_groups(h, 2, 4)], "Spans without a selected row: the rows stay in NormalFloat, the spans in PmenuSel and Comment, a later span over an earlier one")

    # Scenario: Other UI groups are refused.
    float = h.state.tab.floats.at(0)
    count = float.style_count
    t.table([
      ["Visual is refused", hl::VISUAL, "No float group #{hl::VISUAL}"],
      ["PmenuMatchSel is refused", hl::POPUP_MENU_MATCH_SELECTED, "No float group #{hl::POPUP_MENU_MATCH_SELECTED}"],
      ["Normal is refused", hl::NORMAL, "No float group 0"],
      ["Folded, the last UI group, is refused", hl::FOLDED, "No float group #{hl::FOLDED}"],
      ["a negative id is refused", -1, "No float group -1"],
      ["an id past the last group is refused", hl::COUNT, "No float group #{hl::COUNT}"]
    ]) do |row|
      h.plugins.window_requests.style_float("test", id, 0, ints([0, 0, 1, row.to_i])).message
    end
    h.redraw
    t.assert_equal([count, -1, [sel, sel, plain, plain]], [float.style_count, float.selected, float_groups(h, 0, 4)], "Other UI groups are refused and the float keeps its previous style")

    # Scenario: Bad rows and spans are refused.
    t.cases([
      ["a selected row past the lines", [3, 0, 0, 1, match], "No row 3"],
      ["a selected row below -1", [-2, 0, 0, 1, match], "No row -2"],
      ["a span row past the lines", [-1, 3, 0, 1, match], "No row 3"],
      ["a negative span row", [-1, -1, 0, 1, match], "No row -1"],
      ["a negative column", [-1, 0, -1, 2, match], "No span at column -1 length 2"],
      ["a length of zero", [-1, 0, 0, 0, match], "No span at column 0 length 0"]
    ]) do |row|
      values = ints(row)
      h.plugins.window_requests.style_float("test", id, values[0], values[1, 4]).message
    end
    five = h.plugins.window_requests.style_float("test", id, -1, ints([0, 0, 1, match, 0]))
    t.assert_equal([false, "Spans are row, column, length, and group", count, -1], [five.ok, five.message, float.style_count, float.selected], "Bad rows and spans are refused: five integers are not quadruples, and the float keeps its previous style")

    # Scenario: An empty style clears it.
    cleared = h.plugins.window_requests.style_float("test", id, -1, ints([]))
    h.redraw
    t.assert_equal([true, false, [plain, plain, plain], [plain, plain, plain]], [cleared.ok, float.window.buffer.styled?, float_groups(h, 0, 3), float_groups(h, 2, 3)], "An empty style clears it: every row in NormalFloat again")

    # Scenario: The selected row's mark and label groups style a span.
    mark = hl::POPUP_MENU_MARK_SELECTED
    label = hl::POPUP_MENU_LABEL_SELECTED
    styled = h.plugins.window_requests.style_float("test", id, 0, ints([0, 0, 1, mark, 0, 1, 4, label]))
    h.redraw
    window = float.window
    t.assert_equal([true, [mark, label, label, label, label, sel], sel], [styled.ok, float_groups(h, 0, 6), hl.base(h.frame.hl_at(window.row, window.col - 1))], "The selected row's mark and label groups style a span: the first cell in PmenuMarkSel, the rest of alpha in PmenuLabelSel, the padding in PmenuSel")
    h.plugins.window_requests.style_float("test", id, -1, ints([]))

    # Scenario: Selected row spans under NO_COLOR.
    bare = configured("", 12, 40)
    bare.terminal.no_color = true
    bare.open("a.txt")
    bare_id = open(bare, options("editor", 2, 4, 3, 10, true, "", 50, false), ["alpha", "beta", "gamma"])
    styled = bare.plugins.window_requests.style_float("test", bare_id, -1, ints([0, 0, 1, mark, 0, 1, 2, label, 1, 0, 2, hl::COMMENT, 2, 0, 2, match]))
    bare.redraw
    t.assert_equal([true, [mark, label, label, plain], [plain, plain, plain], [plain, plain, plain]], [styled.ok, float_groups(bare, 0, 4), float_groups(bare, 1, 3), float_groups(bare, 2, 3)], "Selected row spans under NO_COLOR: the PmenuMarkSel and PmenuLabelSel spans are drawn, the Comment and PmenuMatch spans are not")

    # Scenario: A refill drops the style.
    h.plugins.window_requests.style_float("test", id, 0, ints([1, 0, 2, match]))
    h.redraw
    styled_before = float_groups(h, 1, 2)
    h.plugins.window_requests.set_float_lines("test", id, ["alpha", "beta", "gamma"], "")
    h.redraw
    t.assert_equal([[match, match], -1, false, [plain, plain], [plain, plain]], [styled_before, float.selected, float.window.buffer.styled?, float_groups(h, 0, 2), float_groups(h, 1, 2)], "A refill drops the style: the rows are drawn in NormalFloat with no span")

    # A span counts code points, and one past the line's end is cut there.
    h.plugins.window_requests.set_float_lines("test", id, ["äbc", "x"], "")
    multi = h.plugins.window_requests.style_float("test", id, -1, ints([0, 1, 1, match, 1, 0, 1 << 40, match]))
    h.redraw
    t.assert_equal([true, [plain, match, plain, plain], [match, plain, plain]], [multi.ok, float_groups(h, 0, 4), float_groups(h, 1, 3)], "a span over a multi-byte line counts code points, and a span past the line's end is cut there")

    # Scenario: Another plugin's float is not styled.
    other = h.plugins.window_requests.style_float("other", id, 0, ints([]))
    unknown = h.plugins.window_requests.style_float("test", 999, 0, ints([]))
    layout = h.plugins.window_requests.style_float("test", 1, 0, ints([]))
    t.assert_equal(["No float #{id}", "No float 999", "No float 1", -1], [other.message, unknown.message, layout.message, float.selected], "Another plugin's float is not styled, nor an unknown id or a layout window")
    h = editor
    h.plugins.window_requests.open_scratch("test", "notes", "left", 20, ["scratch"], nil)
    scratch = h.assembly.buffers.scratch_for("test", "notes")
    id = open(h, options("editor", 2, 4, 1, 10, true, "mine", 50, true), ["kept"])
    current = h.plugins.window_requests.style_float("test", 0, 0, ints([0, 0, 1, match]))
    h.assembly.buffers.load(scratch)
    switched = h.plugins.window_requests.style_float("test", id, 0, ints([]))
    t.assert_equal([true, "No float #{id}", false], [current.ok, switched.message, scratch.styled?], "the current float is styled with 0, and a float switched to a listed scratch buffer is not styled")
    bordered = h.plugins.window_requests.set_float_border("test", id, "double")
    t.assert_equal([true, "double"], [bordered.ok, h.state.tab.floats.at(0).border_style], "but its border is: the border belongs to the window, as in Bad border requests are refused")

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
    # Scenario: Refused requests.
    t.cases([
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
    t.assert_equal("2.16", API::VERSION, "the plugin API is 2.16")

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
      name = Carat::Json.element(row, 0).to_s
      g = strings(Carat::Json.element(row, 2))
      small = configured(Carat::Json.element(row, 1).to_s, 12, 40)
      open(small, options("editor", 2, 4, 2, 10, true, "doc", 50, false), ["one", "two"])
      expected = [g[0] + g[4] * 3 + " doc " + g[4] * 4 + g[1], g[5] + " one        " + g[5], g[5] + " two        " + g[5], g[2] + g[4] * 12 + g[3]]
      got = [cells(small, 2, 4, 14), cells(small, 3, 4, 14), cells(small, 4, 4, 14), cells(small, 5, 4, 14)]
      t.assert_equal(expected, got, "frame #{name} at 40 by 12: #{got.join(" / ")}")
      large = configured(Carat::Json.element(row, 1).to_s, 36, 120)
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


    # A float's own border style (set_float_border, API 2.13). Scenario:
    # Each float border style, under the shipped rounded border.
    own_frames = [
      ["single", ["┌", "┐", "└", "┘", "─", "│"]],
      ["double", ["╔", "╗", "╚", "╝", "═", "║"]],
      ["solid", [" ", " ", " ", " ", " ", " "]],
      ["rounded", ["╭", "╮", "╰", "╯", "─", "│"]]
    ]
    own_frames.each do |row|
      name = Carat::Json.element(row, 0).to_s
      g = strings(Carat::Json.element(row, 1))
      h = editor
      id = open(h, options("editor", 2, 4, 2, 10, true, "doc", 50, false), ["one", "two"])
      set = h.plugins.window_requests.set_float_border("test", id, name)
      h.redraw
      expected = [g[0] + g[4] * 3 + " doc " + g[4] * 4 + g[1], g[5] + " one        " + g[5], g[5] + " two        " + g[5], g[2] + g[4] * 12 + g[3]]
      got = [cells(h, 2, 4, 14), cells(h, 3, 4, 14), cells(h, 4, 4, 14), cells(h, 5, 4, 14)]
      t.assert_equal([true, expected], [set.ok, got], "Each float border style: #{name} #{got.join(" / ")}")
    end
    h = editor
    id = open(h, options("editor", 2, 4, 2, 10, true, "doc", 50, false), ["one", "two"])
    h.plugins.window_requests.set_float_border("test", id, "double")
    h.redraw
    t.assert_equal("╔═══ doc ════╗", cells(h, 2, 4, 14), "the highlighted float draws its own double border")
    t.assert_equal([D::Highlight::FLOAT_BORDER, D::Highlight::FLOAT_TITLE, D::Highlight::FLOAT_BORDER, D::Highlight::FLOAT_BORDER], [h.frame.hl_at(2, 4), h.frame.hl_at(2, 8), h.frame.hl_at(3, 4), h.frame.hl_at(5, 17)], "a float's own double border is in FloatBorder and its title in FloatTitle: #{cells(h, 2, 4, 14)}")
    # Scenario: A float border style in ASCII.
    h = configured("option.icons ascii\n", 12, 40)
    id = open(h, options("editor", 2, 4, 2, 10, true, "doc", 50, false), ["one", "two"])
    h.plugins.window_requests.set_float_border("test", id, "double")
    h.redraw
    got = [cells(h, 2, 4, 14), cells(h, 3, 4, 14), cells(h, 5, 4, 14)]
    t.assert_equal(["+--- doc ----+", "| one        |", "+------------+"], got, "A float border style in ASCII: double under option.icons ascii #{got.join(" / ")}")
    h = configured("", 12, 40)
    h.terminal.no_color = true
    h.open("a.txt")
    id = open(h, options("editor", 2, 4, 2, 10, true, "doc", 50, false), ["one", "two"])
    h.plugins.window_requests.set_float_border("test", id, "single")
    h.redraw
    got = [cells(h, 2, 4, 14), cells(h, 3, 4, 14), cells(h, 5, 4, 14)]
    t.assert_equal(["+--- doc ----+", "| one        |", "+------------+"], got, "and single under NO_COLOR #{got.join(" / ")}")
    # Scenario: A float border style of none.
    h = editor
    id = open(h, options("editor", 2, 4, 2, 10, true, "doc", 50, false), ["one", "two"])
    h.plugins.window_requests.set_float_border("test", id, "none")
    h.redraw
    shown = h.screen
    t.assert_equal(["  2 line 2", "  3  one        ", "  4  two        ", "  5 line 5"], [h.row(1).rstrip, cells(h, 2, 0, 16), cells(h, 3, 0, 16), h.row(4).rstrip], "A float border style of none: no edge and no title, the padding kept")
    h.resize(12, 40)
    t.assert_equal(shown, h.screen, "the float without its edge equals a full repaint")
    # Scenario: A float opened without a border gets one.
    h = editor
    id = open(h, options("editor", 2, 4, 2, 10, false, "doc", 50, false), ["one", "two"])
    h.plugins.window_requests.set_float_border("test", id, "double")
    h.redraw
    t.assert_equal(["╔═══ doc ════╗", "║ one        ║", "╚════════════╝"], [cells(h, 2, 4, 14), cells(h, 3, 4, 14), cells(h, 5, 4, 14)], "A float opened without a border gets one: double")
    h = editor
    open(h, options("editor", 2, 4, 2, 10, true, "doc", 50, true), ["one", "two"])
    current = h.plugins.window_requests.set_float_border("test", 0, "single")
    h.redraw
    t.assert_equal([true, "┌"], [current.ok, cells(h, 2, 4, 1)], "window 0 is the plugin's current float")
    # Scenario: The empty style follows winborder.
    h = configured("option.winborder single\n", 12, 40)
    id = open(h, options("editor", 2, 4, 2, 10, true, "doc", 50, false), ["one", "two"])
    open(h, options("editor", 7, 24, 1, 4, true, "", 50, false), ["x"])
    h.plugins.window_requests.set_float_border("test", id, "double")
    h.redraw
    corners = [cells(h, 2, 4, 1), cells(h, 7, 24, 1)]
    h.plugins.window_requests.set_float_border("test", id, "")
    h.redraw
    t.assert_equal([["╔", "┌"], ["┌", "┌"], ""], [corners, [cells(h, 2, 4, 1), cells(h, 7, 24, 1)], h.state.tab.floats.at(0).border_style], "The empty style follows winborder: double, then single again, the other float single throughout")
    # Scenario: A restyled border repaints.
    h = editor
    id = open(h, options("editor", 2, 4, 2, 10, true, "doc", 50, false), ["one", "two"])
    count = h.state.tab.floats.at(0).style_count
    h.plugins.window_requests.set_float_border("test", id, "double")
    h.redraw
    shown = h.screen
    restyled = [cells(h, 2, 4, 1), cells(h, 3, 4, 1), count + 1 == h.state.tab.floats.at(0).style_count]
    h.resize(12, 40)
    t.assert_equal([["╔", "║", true], shown], [restyled, h.screen], "A restyled border repaints: the double corner with the box unchanged, equal to a full repaint")
    # Scenario: Bad border requests are refused.
    float = h.state.tab.floats.at(0)
    count = float.style_count
    bad = [
      h.plugins.window_requests.set_float_border("test", id, "thick"),
      h.plugins.window_requests.set_float_border("other", id, "single"),
      h.plugins.window_requests.set_float_border("test", 999, "single")
    ]
    t.assert_equal([[false, "No border style thick: none, single, double, rounded, or solid"], [false, "No float #{id}"], [false, "No float 999"], "double", count], [[bad[0].ok, bad[0].message], [bad[1].ok, bad[1].message], [bad[2].ok, bad[2].message], float.border_style, float.style_count], "Bad border requests are refused: an unknown style, another plugin's float, an unknown id, the border kept")
    h.plugins.window_requests.set_float_lines("test", id, ["new"], "doc")
    h.redraw
    t.assert_equal(["double", "╔"], [float.border_style, cells(h, 2, 4, 1)], "a refill keeps the border style")
    t.finish
  end
end

EditorFloatsTest.main if __FILE__ == $0
