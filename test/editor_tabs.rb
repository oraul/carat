require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorTabsTest
  D = Carat::Domain
  E37 = "E37: No write since last change (add ! to override)"
  E784 = "E784: Cannot close last tab page"

  # A 24 by 80 editor on "a.txt" (three lines) with "b.txt" and "c.txt" on
  # disk, after typing keys.
  def self.session(keys)
    session_with("", keys)
  end

  # The same editor with the project configuration lines given.
  def self.session_with(project, keys)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\ntwo\nthree\n")
    files.put("b.txt", "zz\n")
    files.put("c.txt", "cc\n")
    h = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with(project), rows: 24, cols: 80, plugins: [])
    h.open("a.txt")
    h.type(keys)
    h
  end

  # The path of the current window's buffer, "" for none.
  def self.current_path(h)
    path = h.buffer.path
    path.nil? ? "" : path
  end

  # The path shown by the current window of every tab page.
  def self.tab_paths(h)
    s = h.assembly.tabs
    out = []
    i = 0
    while i < s.tab_count
      path = s.tab_at(i).window.buffer.path
      out << (path.nil? ? "" : path)
      i += 1
    end
    out
  end

  def self.unsaved(name)
    "E37: No write since last change\nE162: No write since last change for buffer \"#{name}\""
  end

  def self.main
    t = Carat::Testing.new("editor_tabs")

    # Opening, closing, and moving: rows are [label, keys, [tab count, current tab, paths per tab]].
    t.table([
      [":tabnew opens a tab page after the current one", ":tabnew<CR>", [2, 2, ["a.txt", ""]]],
      [":tabe file opens a tab page on the file", ":tabe b.txt<CR>", [2, 2, ["a.txt", "b.txt"]]],
      [":tabedit file", ":tabedit b.txt<CR>", [2, 2, ["a.txt", "b.txt"]]],
      [":tabedit without a file opens an empty buffer", ":tabedit<CR>", [2, 2, ["a.txt", ""]]],
      [":tabe without a file opens an empty buffer", ":tabe<CR>", [2, 2, ["a.txt", ""]]],
      ["a new tab page goes after the current one", ":tabnew<CR>:tabnew<CR>:tabfir<CR>:tabe b.txt<CR>", [4, 2, ["a.txt", "b.txt", "", ""]]],
      [":tabclose closes the current tab page", ":tabnew<CR>:tabclose<CR>", [1, 1, ["a.txt"]]],
      [":tabc closes the current tab page", ":tabnew<CR>:tabc<CR>", [1, 1, ["a.txt"]]],
      ["closing the first of three makes the next one current", ":tabnew<CR>:tabe b.txt<CR>:tabfir<CR>:tabc<CR>", [2, 1, ["", "b.txt"]]],
      ["closing the last of three makes the one before it current", ":tabnew<CR>:tabe b.txt<CR>:tabc<CR>", [2, 2, ["a.txt", ""]]],
      [":tabclose on the last tab page stays", ":tabclose<CR>", [1, 1, ["a.txt"]]],
      [":tabonly keeps the current tab page", ":tabnew<CR>:tabe b.txt<CR>:tabonly<CR>", [1, 1, ["b.txt"]]],
      [":tabo keeps the current tab page", ":tabnew<CR>:tabnew<CR>:tabfir<CR>:tabo<CR>", [1, 1, ["a.txt"]]],
      [":q closes the tab page", ":tabnew<CR>:q<CR>", [1, 1, ["a.txt"]]],
      ["Ctrl-W c closes the tab page", ":tabnew<CR><C-w>c", [1, 1, ["a.txt"]]],
      ["Ctrl-W q closes the tab page", ":tabe b.txt<CR><C-w>q", [1, 1, ["a.txt"]]],
      ["Ctrl-PageDown goes to the next tab page", ":tabnew<CR>:tabfir<CR><C-PageDown>", [2, 2, ["a.txt", ""]]],
      ["Ctrl-PageDown and Ctrl-PageUp wrap: Ctrl-PageDown from the last", ":tabnew<CR><C-PageDown>", [2, 1, ["a.txt", ""]]],
      ["Ctrl-PageDown and Ctrl-PageUp wrap: Ctrl-PageUp back from the first", ":tabnew<CR><C-PageDown><C-PageUp>", [2, 2, ["a.txt", ""]]],
      ["Ctrl-PageUp wraps", ":tabnew<CR>:tabfir<CR><C-PageUp>", [2, 2, ["a.txt", ""]]],
      # Scenarios: Ex next and previous; First and last.
      [":tabn goes to the next tab page", ":tabnew<CR>:tabfir<CR>:tabn<CR>", [2, 2, ["a.txt", ""]]],
      [":tabnext wraps", ":tabnew<CR>:tabnext<CR>", [2, 1, ["a.txt", ""]]],
      [":tabp goes back", ":tabnew<CR>:tabp<CR>", [2, 1, ["a.txt", ""]]],
      [":tabprevious wraps", ":tabnew<CR>:tabfir<CR>:tabprevious<CR>", [2, 2, ["a.txt", ""]]],
      [":tabN goes back", ":tabnew<CR>:tabN<CR>", [2, 1, ["a.txt", ""]]],
      [":tabNext goes back", ":tabnew<CR>:tabNext<CR>", [2, 1, ["a.txt", ""]]],
      [":tabl goes to the last", ":tabnew<CR>:tabnew<CR>:tabfir<CR>:tabl<CR>", [3, 3, ["a.txt", "", ""]]],
      [":tablast goes to the last", ":tabnew<CR>:tabnew<CR>:tabfir<CR>:tablast<CR>", [3, 3, ["a.txt", "", ""]]],
      [":tabfir goes to the first", ":tabnew<CR>:tabnew<CR>:tabfir<CR>", [3, 1, ["a.txt", "", ""]]],
      [":tabfirst goes to the first", ":tabnew<CR>:tabnew<CR>:tabfirst<CR>", [3, 1, ["a.txt", "", ""]]],
      ["Counted Ctrl-PageDown: 3 goes to tab page 3", ":tabnew<CR>:tabnew<CR>:tabfir<CR>3<C-PageDown>", [3, 3, ["a.txt", "", ""]]],
      ["Counted Ctrl-PageDown: 2 goes to tab page 2", ":tabnew<CR>:tabnew<CR>:tabfir<CR>2<C-PageDown>", [3, 2, ["a.txt", "", ""]]],
      ["Counted Ctrl-PageDown: 5 with three tab pages does nothing", ":tabnew<CR>:tabnew<CR>:tabfir<CR>3<C-PageDown>5<C-PageDown>", [3, 3, ["a.txt", "", ""]]],
      ["Counted Ctrl-PageUp: 2 goes two back, wrapping", ":tabnew<CR>:tabnew<CR>:tabfir<CR>2<C-PageUp>", [3, 2, ["a.txt", "", ""]]],
      ["Counted Ctrl-PageUp: 1 goes one back", ":tabnew<CR>:tabnew<CR>1<C-PageUp>", [3, 2, ["a.txt", "", ""]]],
      ["Ctrl-PageDown with one tab page stays", "<C-PageDown>", [1, 1, ["a.txt"]]],
      ["g Tab goes to the last accessed tab page", ":tabnew<CR>:tabnew<CR>:tabfir<CR>g<Tab>", [3, 3, ["a.txt", "", ""]]],
      ["g Tab goes to the last accessed tab page, twice back again", ":tabnew<CR>:tabnew<CR>:tabfir<CR>g<Tab>g<Tab>", [3, 1, ["a.txt", "", ""]]],
      ["g Tab with two tab pages goes back after Ctrl-PageDown", ":tabnew<CR>:tabfir<CR><C-PageDown>g<Tab>", [2, 1, ["a.txt", ""]]],
      ["g Tab goes back after :tabnew", ":tabnew<CR>g<Tab>", [2, 1, ["a.txt", ""]]],
      ["g Tab keeps the last accessed tab page when an earlier one closes", ":tabnew<CR>:tabe b.txt<CR>:tabn 2<CR>:tabc 1<CR>g<Tab>", [2, 2, ["", "b.txt"]]],
      ["g Tab with no tab page to go back to does nothing: one tab page", "g<Tab>", [1, 1, ["a.txt"]]],
      ["g Tab with no tab page to go back to does nothing: after :tabnew and :tabclose", ":tabnew<CR>:tabclose<CR>g<Tab>", [1, 1, ["a.txt"]]],
      ["g Tab with no tab page to go back to does nothing: the last accessed one closed", ":tabnew<CR>:tabnew<CR>:tabfir<CR>:tabc 3<CR>g<Tab>", [2, 1, ["a.txt", ""]]]
    ]) do |keys|
      h = session(keys)
      [h.tab_count, h.tab_index, tab_paths(h)]
    end

    # Messages: rows are [label, keys, message].
    t.table([
      [":tabclose on the last tab page reports E784", ":tabclose<CR>", E784],
      [":tabc on the last tab page reports E784", ":tabc<CR>", E784],
      [":tabonly with one tab page says so", ":tabonly<CR>", "Already only one tab page"],
      [":tabo with one tab page says so", ":tabo<CR>", "Already only one tab page"],
      [":tabe file shows the opened message", ":tabe b.txt<CR>", "\"b.txt\" 1L, 3B"],
      [":tabnew shows nothing", ":tabnew<CR>", ""],
      ["g Tab with no tab page to go back to does nothing and shows no message", "g<Tab>", ""]
    ]) do |keys|
      session(keys).message_row
    end

    # gt and gT follow the buffer tabs under option.gt buffers, the
    # default, with one and two tab pages; the bracket keys move between
    # buffers. Rows are [label, keys, [tab count, current tab, current
    # path, message]].
    t.table([
      ["gt shows the next buffer tab, wrapping: once", ":e b.txt<CR>:bfirst<CR>gt", [1, 1, "b.txt", ""]],
      ["gt shows the next buffer tab, wrapping: twice", ":e b.txt<CR>:bfirst<CR>gtgt", [1, 1, "a.txt", ""]],
      ["gT shows the previous buffer tab, wrapping", ":e b.txt<CR>:bfirst<CR>gT", [1, 1, "b.txt", ""]],
      ["gT shows the previous buffer tab, twice back again", ":e b.txt<CR>:bfirst<CR>gTgT", [1, 1, "a.txt", ""]],
      ["Counted gt goes to that buffer tab: 3gt", ":e b.txt<CR>:e c.txt<CR>:bfirst<CR>3gt", [1, 1, "c.txt", ""]],
      ["Counted gt goes to that buffer tab: 5gt past the last does nothing", ":e b.txt<CR>:e c.txt<CR>:bfirst<CR>3gt5gt", [1, 1, "c.txt", ""]],
      ["Counted gt goes to that buffer tab: 2gT goes two back", ":e b.txt<CR>:e c.txt<CR>:bfirst<CR>3gt5gt2gT", [1, 1, "a.txt", ""]],
      ["1gt goes to the first buffer tab", ":e b.txt<CR>1gt", [1, 1, "a.txt", ""]],
      ["gt with one buffer tab stays", "gt", [1, 1, "a.txt", ""]],
      ["gt keeps the tab page", ":tabe b.txt<CR>gt", [2, 2, "a.txt", ""]],
      ["gT keeps the tab page", ":tabe b.txt<CR>gT", [2, 2, "a.txt", ""]],
      ["2gt keeps the tab page", ":tabe b.txt<CR>:tabfir<CR>2gt", [2, 1, "b.txt", ""]],
      ["gt refuses a modified buffer", ":e b.txt<CR>:bfirst<CR>xgt", [1, 1, "a.txt", E37]],
      ["Bracket b steps through the buffers: ]b", ":e b.txt<CR>:e c.txt<CR>:bfirst<CR>]b", [1, 1, "b.txt", ""]],
      ["Bracket b steps through the buffers: 2]b wraps", ":e b.txt<CR>:e c.txt<CR>:bfirst<CR>]b2]b", [1, 1, "a.txt", ""]],
      ["Bracket b steps through the buffers: [b wraps back", ":e b.txt<CR>:e c.txt<CR>:bfirst<CR>]b2]b[b", [1, 1, "c.txt", ""]],
      ["]b with two tab pages keeps the tab page", ":tabe b.txt<CR>]b", [2, 2, "a.txt", ""]],
      ["[b with two tab pages keeps the tab page", ":tabe b.txt<CR>[b", [2, 2, "a.txt", ""]],
      ["Bracket B goes to the first and the last buffer: ]B", ":e b.txt<CR>:e c.txt<CR>:bfirst<CR>]b]B", [1, 1, "c.txt", ""]],
      ["Bracket B goes to the first and the last buffer: [B", ":e b.txt<CR>:e c.txt<CR>:bfirst<CR>]b]B[B", [1, 1, "a.txt", ""]],
      ["[B with two tab pages keeps the tab page", ":tabe b.txt<CR>[B", [2, 2, "a.txt", ""]],
      ["]B with one buffer stays", "]B", [1, 1, "a.txt", ""]]
    ]) do |keys|
      h = session(keys)
      [h.tab_count, h.tab_index, current_path(h), h.message]
    end

    # option.gt tabpages gives gt and gT the tab pages back, as Vim; the
    # bracket keys still move between buffers. Rows are [label, keys,
    # [tab count, current tab, paths per tab]].
    t.table([
      ["option.gt tabpages gives gt and gT the tab pages back: gt", ":tabnew<CR>:tabnew<CR>:tabfir<CR>gt", [3, 2, ["a.txt", "", ""]]],
      ["option.gt tabpages gives gt and gT the tab pages back: 3gt", ":tabnew<CR>:tabnew<CR>:tabfir<CR>gt3gt", [3, 3, ["a.txt", "", ""]]],
      ["option.gt tabpages gives gt and gT the tab pages back: gT", ":tabnew<CR>:tabnew<CR>:tabfir<CR>gt3gtgT", [3, 2, ["a.txt", "", ""]]],
      ["option.gt tabpages gives gt and gT the tab pages back: 2gT wraps", ":tabnew<CR>:tabnew<CR>:tabfir<CR>gt3gtgT2gT", [3, 3, ["a.txt", "", ""]]],
      ["option.gt tabpages: gt wraps", ":tabnew<CR>gt", [2, 1, ["a.txt", ""]]],
      ["option.gt tabpages: 5gt with three tab pages does nothing", ":tabnew<CR>:tabnew<CR>:tabfir<CR>5gt", [3, 1, ["a.txt", "", ""]]],
      ["option.gt tabpages: gt with one tab page stays", ":e b.txt<CR>gt", [1, 1, ["b.txt"]]],
      ["option.gt tabpages: ]b still moves between buffers", ":tabe b.txt<CR>]b", [2, 2, ["a.txt", "a.txt"]]]
    ]) do |keys|
      h = session_with("option.gt tabpages\n", keys)
      [h.tab_count, h.tab_index, tab_paths(h)]
    end

    # The tab ex commands' argument, with one, two, and three tab pages.
    # Rows are [label, keys, [tab count, current tab, paths per tab,
    # message]].
    t.table([
      ["tabn N goes to tab page N", ":tabnew<CR>:tabnew<CR>:tabfir<CR>:tabn 3<CR>", [3, 3, ["a.txt", "", ""], ""]],
      [":tabnext N with two tab pages", ":tabnew<CR>:tabnext 1<CR>", [2, 1, ["a.txt", ""], ""]],
      [":tabn 1 with one tab page stays", ":tabn 1<CR>", [1, 1, ["a.txt"], ""]],
      ["tabp N goes N tab pages back", ":tabnew<CR>:tabnew<CR>:tabfir<CR>:tabp 2<CR>", [3, 2, ["a.txt", "", ""], ""]],
      [":tabN N with two tab pages wraps", ":tabnew<CR>:tabN 3<CR>", [2, 1, ["a.txt", ""], ""]],
      [":tabprevious N with one tab page stays", ":tabprevious 2<CR>", [1, 1, ["a.txt"], ""]],
      ["tabc N closes tab page N", ":tabnew<CR>:tabe b.txt<CR>:tabc 1<CR>", [2, 2, ["", "b.txt"], ""]],
      [":tabclose N with two tab pages closes the other one", ":tabe b.txt<CR>:tabclose 1<CR>", [1, 1, ["b.txt"], ""]],
      [":tabc N of the current tab page", ":tabe b.txt<CR>:tabc 2<CR>", [1, 1, ["a.txt"], ""]],
      ["tabo N keeps only tab page N", ":tabnew<CR>:tabe b.txt<CR>:tabfir<CR>:tabo 2<CR>", [1, 1, [""], ""]],
      [":tabonly N with two tab pages", ":tabe b.txt<CR>:tabonly 1<CR>", [1, 1, ["a.txt"], ""]],
      ["A tab argument that names no tab page is refused: tabn 4", ":tabnew<CR>:tabnew<CR>:tabn 4<CR>", [3, 3, ["a.txt", "", ""], "E475: Invalid argument: 4"]],
      ["A tab argument that names no tab page is refused: tabo x", ":tabnew<CR>:tabnew<CR>:tabo x<CR>", [3, 3, ["a.txt", "", ""], "E475: Invalid argument: x"]],
      ["A tab argument that names no tab page is refused: tabc 0", ":tabnew<CR>:tabnew<CR>:tabc 0<CR>", [3, 3, ["a.txt", "", ""], "E16: Invalid range"]],
      ["A tab argument that names no tab page is refused: tabp 0", ":tabnew<CR>:tabnew<CR>:tabp 0<CR>", [3, 3, ["a.txt", "", ""], "E475: Invalid argument: 0"]],
      ["A tab argument that names no tab page is refused: tabl x", ":tabnew<CR>:tabnew<CR>:tabl x<CR>", [3, 3, ["a.txt", "", ""], "E488: Trailing characters: x"]],
      [":tabn 0 is an invalid range", ":tabnew<CR>:tabn 0<CR>", [2, 2, ["a.txt", ""], "E16: Invalid range"]],
      [":tabn 3 with two tab pages is refused", ":tabnew<CR>:tabn 3<CR>", [2, 2, ["a.txt", ""], "E475: Invalid argument: 3"]],
      [":tabc 3 with two tab pages is refused", ":tabnew<CR>:tabc 3<CR>", [2, 2, ["a.txt", ""], "E475: Invalid argument: 3"]],
      [":tabo 0 with two tab pages is an invalid range", ":tabnew<CR>:tabo 0<CR>", [2, 2, ["a.txt", ""], "E16: Invalid range"]],
      [":tabn with a sign is refused", ":tabnew<CR>:tabn +1<CR>", [2, 2, ["a.txt", ""], "E475: Invalid argument: +1"]],
      [":tabp x is refused", ":tabnew<CR>:tabp x<CR>", [2, 2, ["a.txt", ""], "E475: Invalid argument: x"]],
      [":tabn with a long number is refused", ":tabnew<CR>:tabn 12345678901<CR>", [2, 2, ["a.txt", ""], "E475: Invalid argument: 12345678901"]],
      [":tabfir x is refused", ":tabnew<CR>:tabfir x<CR>", [2, 2, ["a.txt", ""], "E488: Trailing characters: x"]],
      [":tabn 2 with one tab page is refused", ":tabn 2<CR>", [1, 1, ["a.txt"], "E475: Invalid argument: 2"]],
      ["One tab page answers before reading the argument: tabc 2", ":tabc 2<CR>", [1, 1, ["a.txt"], E784]],
      ["One tab page answers before reading the argument: tabo x", ":tabo x<CR>", [1, 1, ["a.txt"], "Already only one tab page"]]
    ]) do |keys|
      h = session(keys)
      [h.tab_count, h.tab_index, tab_paths(h), h.message]
    end

    # The new tab page's window shows the buffer from its start.
    h = session("jj:tabe b.txt<CR>")
    t.assert_equal([["zz"], [0, 0], "b.txt"], [h.lines, h.cursor, h.buffer.path], "the new tab page shows the file at the top")
    t.assert_equal("  1 zz", h.row(1), "the text starts under the tab line")
    t.assert_equal([2, 0], [h.assembly.tabs.tab_at(0).window.cursor.row, h.assembly.tabs.tab_at(0).window.cursor.col], "the first tab page kept its cursor")
    h = session(":tabnew<CR>")
    t.assert_equal([[""], nil, false], [h.lines, h.buffer.path, h.buffer.modified?], ":tabnew shows an unnamed empty buffer")
    t.assert_equal([["a.txt", ""], 2], [h.buffer_paths, h.assembly.tabs.total_windows], "both buffers are listed and each tab page has a window")

    # Hidden buffers after closing tab pages.
    h = session(":tabe b.txt<CR>x:tabclose<CR>:qa<CR>")
    t.assert_equal([false, unsaved("b.txt"), ["a.txt", "b.txt"], "b.txt"], [h.quit?, h.message, h.buffer_paths, h.buffer.path], "a modified buffer in a closed tab page stays hidden and blocks :qa, which shows it")
    h = session(":tabe b.txt<CR>x:tabfir<CR>:tabonly<CR>")
    t.assert_equal([1, ["a.txt", "b.txt"]], [h.tab_count, h.buffer_paths], ":tabonly keeps the modified buffer hidden")
    h.type(":qa!<CR>")
    t.assert_equal(true, h.quit?, ":qa! ends the editor")
    h = session(":tabe b.txt<CR>:tabclose<CR>")
    t.assert_equal(["a.txt", "b.txt"], h.buffer_paths, "a clean buffer stays listed, hidden, when its tab page closes")
    h = session(":tabe b.txt<CR>x<C-PageDown>:qa<CR>")
    t.assert_equal([false, unsaved("b.txt"), 2], [h.quit?, h.message, h.tab_index], ":qa is refused by a modified buffer in another tab page and goes there")
    h = session(":tabe b.txt<CR>x<C-PageDown>x:wa<CR>")
    t.assert_equal(["ne\ntwo\nthree\n", "z\n", false], [h.files.get("a.txt"), h.files.get("b.txt"), h.assembly.buffers.any_modified?], ":wa writes the buffers of every tab page")
    h = session("x:tabe b.txt<CR>x:wqa<CR>")
    t.assert_equal(["ne\ntwo\nthree\n", "z\n", true], [h.files.get("a.txt"), h.files.get("b.txt"), h.quit?], ":wqa writes every tab page's buffer and quits")
    h = session("<C-w>s:tabnew<CR>:qa<CR>")
    t.assert_equal(true, h.quit?, ":qa quits with several windows and tab pages")

    # Each tab page keeps its own layout. Scenario: Layouts are independent.
    h = session("<C-w>s:tabnew<CR>")
    t.assert_equal([1, 2], [h.window_count, h.tab_index], "the new tab page has one window")
    h.type("<C-PageDown>")
    t.assert_equal([2, 1], [h.window_count, h.tab_index], "the first tab page still has two")
    h.type("<C-w>j:tabnew<CR><C-PageUp>")
    t.assert_equal(2, h.window_index, "the first tab page remembers its current window")

    # The buffer tabs row: a tab per listed file, the current window's
    # selected, and the tab-page numbers at its right end.
    h = session(":tabe b.txt<CR>")
    row = h.row(0)
    t.assert_equal([" \u{F016} a.txt    \u{F016} b.txt", " 1  2"], [row[0, 19], row[-5, 5]], "the tabs row lists the files and numbers the tab pages at its right end")
    t.assert_equal([D::Highlight::TAB_LINE, D::Highlight::TAB_LINE_SELECTED, D::Highlight::TAB_LINE_FILL, D::Highlight::TAB_LINE, D::Highlight::TAB_LINE_SELECTED], [h.frame.cell(0, 0).hl, h.frame.cell(0, 11).hl, h.frame.cell(0, 30).hl, h.frame.cell(0, 75).hl, h.frame.cell(0, 78).hl], "the current file and tab page selected, the rest plain or filled")
    t.assert_equal([1, 0, 21, 80], h.windows[0][0, 4], "the window starts under the tabs row with one row less")
    t.assert_equal("b.txt", h.row(22)[9, 5], "the status bar is above the message row")
    t.assert_equal([1, 4], [h.frame.cursor_row, h.frame.cursor_col], "the cursor is under the tabs row")
    h.type("<C-PageDown>x")
    t.assert_equal(" \u{F016} a.txt \u{F111}  \u{F016} b.txt", h.row(0)[0, 19], "a modified buffer is marked in its tab")
    t.assert_equal([D::Highlight::TAB_LINE_SELECTED, D::Highlight::TAB_LINE, D::Highlight::TAB_LINE_SELECTED], [h.frame.cell(0, 0).hl, h.frame.cell(0, 11).hl, h.frame.cell(0, 75).hl], "the first file and tab page are now selected")
    h = session(":tabnew<CR>")
    t.assert_equal([" \u{F016} [No Name]", " 1  2"], [h.row(0)[11, 12], h.row(0)[-5, 5]], "an unnamed buffer shows as [No Name]")
    h.type(":tabclose<CR>")
    t.assert_equal([" \u{F016} [No Name]", "]"], [h.row(0)[11, 12], h.row(0)[-1, 1]], "the listed empty buffer keeps the row, without tab-page numbers")
    h = session("")
    t.assert_equal(["  1 one", [0, 0, 22, 80]], [h.row(0), h.windows[0][0, 4]], "one file in one tab page has no tabs row")
    files = Carat::Doubles::MemoryFiles.new
    files.put("dir/sub/deep.txt", "d\n")
    h = Carat::Doubles::EditorHarness.default(files, 24, 80)
    h.open("dir/sub/deep.txt")
    h.type(":tabnew<CR>")
    t.assert_equal(" \u{F016} deep.txt ", h.row(0)[0, 12], "a tab shows the file name without its directory")
    t.assert_equal("dir/sub/deep.txt", h.assembly.tabs.tab_at(0).window.buffer.path, "the path is untouched")

    t.finish
  end
end

EditorTabsTest.main if __FILE__ == $0
