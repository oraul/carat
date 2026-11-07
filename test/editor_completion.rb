require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorCompletionTest
  D = Carat::Domain

  # A 12 by 40 editor on "a.txt" with the text, the ascii icons, and the
  # source holding the given [label, kind, detail] candidates.
  def self.editor(text, candidates)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", text.to_s)
    config = Carat::Doubles::FixedConfig.with("option.icons ascii\n")
    h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 12, cols: 40, plugins: [])
    candidates.each { |c| h.completions.add(c[0].to_s, c[1].to_s, c[2].to_s, "") }
    h.open("a.txt")
    h
  end

  def self.three
    [["file_name", "variable", "String"], ["filter", "function", "Array"], ["final", "keyword", ""]]
  end

  # What a key sequence left: the lines, the cursor column, whether the
  # popup shows, the selected label ("" for none), the matches, the mode.
  def self.after(text, keys)
    h = editor(text, three)
    h.type(keys.to_s)
    menu = h.assembly.completion_menu
    showing = menu.showing?
    [h.lines.dup, h.state.cursor.col, showing, showing ? menu.chosen.label : "", menu.matches.length, h.mode]
  end

  def self.main
    t = Carat::Testing.new("editor_completion")

    # Rows are [label, [text, keys], [lines, cursor col, showing, selected, matches, mode]];
    # the source holds file_name, filter, and final.
    t.table([
      ["typing opens the popup, the best first", ["_tail\n", "ifi"], [["fi_tail"], 2, true, "final", 3, :insert]],
      ["Ctrl-N selects the next row", ["_tail\n", "ifi<C-n>"], [["fi_tail"], 2, true, "filter", 3, :insert]],
      ["Down selects the next row", ["_tail\n", "ifi<Down>"], [["fi_tail"], 2, true, "filter", 3, :insert]],
      ["Ctrl-P wraps to the last row", ["_tail\n", "ifi<C-p>"], [["fi_tail"], 2, true, "file_name", 3, :insert]],
      ["Up selects the previous row", ["_tail\n", "ifi<C-n><Up>"], [["fi_tail"], 2, true, "final", 3, :insert]],
      ["Ctrl-N wraps to the first row", ["_tail\n", "ifi<C-n><C-n><C-n>"], [["fi_tail"], 2, true, "final", 3, :insert]],
      ["Enter puts the item over the typed part", ["_tail\n", "ifi<C-p><CR>"], [["file_name_tail"], 9, false, "", 0, :insert]],
      ["Tab puts the item over the whole word", ["_tail\n", "ifi<C-p><Tab>"], [["file_name"], 9, false, "", 0, :insert]],
      ["Tab keeps what follows the word", ["_tail x\n", "ifi<C-p><Tab>"], [["file_name x"], 9, false, "", 0, :insert]],
      ["Esc closes the popup and stays in insert mode", ["_tail\n", "ifi<Esc>"], [["fi_tail"], 2, false, "", 0, :insert]],
      ["a second Esc leaves insert mode", ["_tail\n", "ifi<Esc><Esc>"], [["fi_tail"], 1, false, "", 0, :normal]],
      ["Enter without a popup splits the line", ["_tail\n", "ifi<Esc><CR>"], [["fi", "_tail"], 0, false, "", 0, :insert]],
      ["typing narrows, a prefix first", ["_tail\n", "ifil"], [["fil_tail"], 3, true, "filter", 3, :insert]],
      ["typing narrows further", ["_tail\n", "ifile"], [["file_tail"], 4, true, "file_name", 2, :insert]],
      ["Backspace filters again", ["_tail\n", "ifil<BS>"], [["fi_tail"], 2, true, "final", 3, :insert]],
      ["a space closes the popup", ["_tail\n", "ifi<Space>"], [["fi _tail"], 3, false, "", 0, :insert]],
      ["a typed part matching nothing closes it", ["_tail\n", "ifz"], [["fz_tail"], 2, false, "", 0, :insert]],
      ["Left filters on the part before the cursor", ["_tail\n", "ifil<Left>"], [["fil_tail"], 2, true, "final", 3, :insert]],
      ["fn_na finds file_name", ["\n", "ifn_na"], [["fn_na"], 5, true, "file_name", 1, :insert]],
      ["fn_na then Enter", ["\n", "ifn_na<CR>"], [["file_name"], 9, false, "", 0, :insert]],
      ["a key bound only in insert mode keeps the popup", ["_tail\n", "ifi<C-s>"], [["fi_tail"], 2, true, "final", 3, :insert]]
    ]) do |row|
      after(row[0], row[1])
    end

    # No ready source: typing behaves as without completion.
    h = editor("_tail\n", [])
    h.type("ifi<C-n>")
    t.assert_equal([["fi_tail"], 0, 0, false], [h.lines.dup, h.state.tab.floats.count, h.completions.asked, h.assembly.completion_menu.showing?], "with no ready source no popup opens, the source is not asked, and Ctrl-N inserts nothing")

    # A row's cells and groups.
    h = editor("_tail\n", three)
    h.type("ifi<C-p>")
    float = h.state.tab.floats.at(0)
    t.assert_equal([" v file_name  String ", " f filter     Array  ", " k final             "], [float.window.buffer.line(2), float.window.buffer.line(1), float.window.buffer.line(0)], "each row is the kind icon, the label, and the detail on the right")
    t.assert_equal(["  1 fi_tail", " k final", " f filter     Array", " v file_name  String"], [h.row(0), h.row(1)[1, 21].to_s.rstrip, h.row(2)[1, 21].to_s.rstrip, h.row(3)[1, 21].to_s.rstrip], "the popup stands under the line, its labels under the word")
    t.assert_equal([D::Highlight::POPUP_MENU, D::Highlight::POPUP_MENU_SELECTED], [h.frame.hl_at(1, 3), h.frame.hl_at(3, 3)], "the rows are drawn in Pmenu and the selected one in PmenuSel")
    t.assert_equal(1, h.completions.asked, "the source is asked once for the word")
    h.type("l<BS>")
    t.assert_equal(1, h.completions.asked, "filtering asks the source no more")
    shown = h.screen
    h.resize(12, 40)
    t.assert_equal(shown, h.screen, "the popup equals a full repaint")
    h.type("<Esc>")
    t.assert_equal([0, "~", "~"], [h.state.tab.floats.count, h.row(1), h.row(3)], "closing removes the float and repaints its rows")

    # Above the word on the last text row.
    h = editor("a\nb\nc\nd\ne\nf\ng\nh\ni\n_tail\n", three)
    h.type("10Gifi")
    float = h.state.tab.floats.at(0)
    t.assert_equal([9, 6, 9], [h.state.tab.layout_window.row + h.state.cursor.row - h.state.tab.layout_window.top, float.box_top, float.box_bottom], "on the last text row the popup ends on the row above the cursor")

    # The insert session: undo, the dot command, and the . register.
    h = editor("one\ntwo\n", three)
    h.type("ofi<C-p><CR><Esc>")
    t.assert_equal([["one", "file_name", "two"], "file_name"], [h.lines.dup, h.assembly.registers.read(".").text], "the item joins the typed text and the . register reads as the line")
    h.type("j.")
    t.assert_equal(["one", "file_name", "two", "file_name"], h.lines.dup, "the dot command repeats the session with the item's text")
    h.type("u")
    t.assert_equal(["one", "file_name", "two"], h.lines.dup, "undo removes the repeat")
    h.type("u")
    t.assert_equal(["one", "two"], h.lines.dup, "undo removes the typed text and the item together")

    # Untrusted text.
    h = editor("\n", [["\e[31mred\e[0m\e]0;title\a_x", "bogus", "\e[1mInt\e[0m"], ["r" * 500, "text", ""]])
    h.type("ir")
    menu = h.assembly.completion_menu
    first = h.state.tab.floats.at(0).window.buffer.line(0)
    t.assert_equal([" T red_x ", true, 80], [first[0, 9], first.rstrip.end_with?("  Int"), menu.candidates.at(1).label.bytesize], "escape sequences are dropped, an unknown kind reads as text, and a long label is cut to 80 bytes")
    t.assert_equal(false, h.screen.join("\n").include?("\e"), "no escape reaches the screen")
    many = []
    300.times { |i| many << ["w#{i}", "text", ""] }
    h = editor("\n", many)
    h.type("iw")
    float = h.state.tab.floats.at(0)
    t.assert_equal([200, 200, 10], [h.assembly.completion_menu.candidates.count, h.assembly.completion_menu.matches.length, float.window.height], "200 candidates are kept and ten rows show")
    h.type("<C-p>")
    t.assert_equal([199, 190], [float.selected, float.window.top], "the popup scrolls to the selected row")

    t.finish
  end
end

EditorCompletionTest.main if __FILE__ == $0
