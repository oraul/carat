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
    editor_with(text, candidates, "")
  end

  # The same editor with more configuration lines, and "b.txt" reading
  # "fi" to switch to.
  def self.editor_with(text, candidates, lines)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", text.to_s)
    files.put("b.txt", "fi\n")
    config = Carat::Doubles::FixedConfig.with("option.icons ascii\n" + lines.to_s)
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

    # Leaving the word's row or buffer with a key that is not typed text.
    h = editor_with("_tail\nfi_x\n", three, "keymap.insert <C-j> cursor.down\n")
    h.type("ifi<C-j>")
    t.assert_equal([1, 2, false, 0, 1], [h.state.cursor.row, h.state.cursor.col, h.assembly.completion_menu.showing?, h.state.tab.floats.count, h.completions.asked], "a cursor binding moving to another row closes the popup without asking the source")
    h = editor("_tail\nfi_x\n", three)
    h.type("ifi<PageDown>")
    t.assert_equal([1, false, 0], [h.state.cursor.row, h.assembly.completion_menu.showing?, h.state.tab.floats.count], "PageDown to another row closes the popup")
    h = editor_with("_tail\n", three, "keymap.insert <C-l> buffer.next\n")
    h.open("b.txt")
    h.type("A<Esc>")
    h.open("a.txt")
    h.type("ifi<C-s><C-l>")
    t.assert_equal(["b.txt", 0, 1, false, 0], [h.state.buffer.path.to_s, h.state.cursor.row, h.state.cursor.col, h.assembly.completion_menu.showing?, h.state.tab.floats.count], "switching to another buffer after a word closes the popup")

    # No ready source: typing behaves as without completion.
    h = editor("_tail\n", [])
    h.type("ifi<C-n>")
    t.assert_equal([["fi_tail"], 0, 0, false], [h.lines.dup, h.state.tab.floats.count, h.completions.asked, h.assembly.completion_menu.showing?], "with no ready source no popup opens, the source is not asked, and Ctrl-N inserts nothing")

    # A row's cells and groups.
    h = editor("_tail\n", three)
    h.type("ifi<C-p>")
    float = h.state.tab.floats.at(0)
    t.assert_equal(["v file_name  String", "f filter     Array ", "k final            "], [float.window.buffer.line(2), float.window.buffer.line(1), float.window.buffer.line(0)], "each row is the kind icon, the label, and the detail on the right")
    t.assert_equal(["  1 fi_tail", " k final", " f filter     Array", " v file_name  String"], [h.row(0), h.row(1)[1, 21].to_s.rstrip, h.row(2)[1, 21].to_s.rstrip, h.row(3)[1, 21].to_s.rstrip], "the popup stands under the line, its labels under the word")
    t.assert_equal([D::Highlight::POPUP_MENU, D::Highlight::POPUP_MENU_SELECTED], [h.frame.hl_at(1, 3), h.frame.hl_at(3, 3)], "the rows are drawn in Pmenu and the selected one in PmenuSel")
    # Scenario: The popup pads one column: the float's padding on each
    # side of the text, the icon right after the box's left edge.
    t.assert_equal([1, 1, "v"], [float.window.col - float.box_left, float.box_right - float.window.col - float.window.width, h.row(3)[float.box_left + 1, 1].to_s], "The popup pads one column on each side, its icon after the box's left edge")
    # Scenario: The selected row spans the padding.
    t.assert_equal([0, D::Highlight::POPUP_MENU_SELECTED, D::Highlight::POPUP_MENU_SELECTED, D::Highlight::POPUP_MENU], [float.edge, h.frame.hl_at(3, float.box_left), h.frame.hl_at(3, float.box_right - 1), h.frame.hl_at(1, float.box_left)], "the popup has no border and its selected row is in PmenuSel across its padding")
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
    t.assert_equal(["T red_x  ", true, 80], [first[0, 9], first.rstrip.end_with?("  Int"), menu.candidates.at(1).label.bytesize], "escape sequences are dropped, an unknown kind reads as text, and a long label is cut to 80 bytes")
    t.assert_equal(false, h.screen.join("\n").include?("\e"), "no escape reaches the screen")
    many = []
    300.times { |i| many << ["w#{i}", "text", ""] }
    h = editor("\n", many)
    h.type("iw")
    float = h.state.tab.floats.at(0)
    t.assert_equal([200, 200, 10], [h.assembly.completion_menu.candidates.count, h.assembly.completion_menu.matches.length, float.window.height], "200 candidates are kept and ten rows show")
    h.type("<C-p>")
    t.assert_equal([199, 190], [float.selected, float.window.top], "the popup scrolls to the selected row")


    # The documentation beside the popup.
    h = editor("_tail\n", three)
    h.completions.document(2, "# final\n\nEnds the **block**.")
    h.type("ifi")
    floats = h.state.tab.floats
    menu = h.assembly.completion_menu
    t.assert_equal([2, "final"], [floats.count, menu.chosen.label], "the selected item's documentation opens a second float")
    docs = floats.at(floats.index_of(menu.docs_float_id))
    popup = floats.at(floats.index_of(menu.float_id))
    t.assert_equal([["final", "", "Ends the block."], 1, popup.spec.col + popup.spec.width + 2, 15, 3], [docs.window.buffer.lines.dup, docs.spec.row, docs.spec.col, docs.spec.width, docs.spec.height], "the float shows the markdown as plain rows at the popup's rows on its right")
    t.assert_equal(["final", "Ends the block."], [h.row(1)[23, 5].to_s, h.row(3)[23, 15].to_s], "the documentation is drawn beside the list")
    hd = Carat::Domain::Highlight
    t.assert_equal([hd::MARKUP_STRONG + hd::FLOAT_LAYER, hd::NORMAL_FLOAT, hd::MARKUP_HEADING + hd::FLOAT_LAYER], [h.frame.hl_at(3, 33), h.frame.hl_at(3, 24), h.frame.hl_at(1, 24)], "a strong word and the heading are drawn in their groups over the float, the rest in NormalFloat")
    t.assert_equal(true, docs.spec.z < popup.spec.z, "the documentation stands under the popup")
    shown = h.screen
    h.resize(12, 40)
    t.assert_equal(shown, h.screen, "the popup and its documentation equal a full repaint")
    h.type("<C-n>")
    t.assert_equal([1, 0], [floats.count, menu.docs_float_id], "an item without documentation shows no float")
    h.type("<C-p>")
    t.assert_equal([2, "final"], [floats.count, floats.at(floats.index_of(menu.docs_float_id)).window.buffer.line(0)], "the float follows the selection back")
    h.type("n")
    t.assert_equal([2, menu.float_id], [floats.count, menu.docs_beside], "filtering moves the float with the popup")
    h.type("<Esc>")
    t.assert_equal([0, 0, :insert], [floats.count, menu.docs_float_id, h.mode], "Esc closes the documentation with the popup")
    ["<CR>", " "].each do |key|
      h = editor("_tail\n", three)
      h.completions.document(2, "Ends the block.")
      h.type("ifi" + key.to_s)
      t.assert_equal(0, h.state.tab.floats.count, "#{key} closes the documentation with the popup")
    end

    # Placement: above the word, on the left, and wrapped.
    h = editor("a\nb\nc\nd\ne\nf\ng\nh\ni\n_tail\n", three)
    h.completions.document(2, "Ends the block.")
    h.type("10Gifi")
    menu = h.assembly.completion_menu
    docs = h.state.tab.floats.at(h.state.tab.floats.index_of(menu.docs_float_id))
    t.assert_equal([-1, 8], [docs.spec.row, docs.box_top], "above the word the float ends on the row above the cursor")
    h = editor(" " * 24 + "\n", three)
    h.completions.document(2, "Ends the block.")
    h.type("Afi")
    menu = h.assembly.completion_menu
    floats = h.state.tab.floats
    docs = floats.at(floats.index_of(menu.docs_float_id))
    popup = floats.at(floats.index_of(menu.float_id))
    t.assert_equal(popup.spec.col - 15 - 2, docs.spec.col, "with no room on the right the float stands on the popup's left")
    h = editor("_tail\n", three)
    h.completions.document(2, "abcdefghi " * 30)
    h.type("ifi")
    menu = h.assembly.completion_menu
    docs = h.state.tab.floats.at(h.state.tab.floats.index_of(menu.docs_float_id))
    t.assert_equal([59, 5, "abcdefghi abcdefghi abcdefghi abcdefghi abcdefghi abcdefghi"], [docs.spec.width, docs.window.buffer.line_count, docs.window.buffer.line(4)], "a long paragraph wraps at word boundaries within 60 columns")

    # Untrusted documentation.
    h = editor("_tail\n", three)
    h.completions.document(2, "\e[31mred\e[0m\e]0;title\a" + "\n" + ">" * 10_000 + "x")
    h.type("ifi")
    menu = h.assembly.completion_menu
    docs = h.state.tab.floats.at(h.state.tab.floats.index_of(menu.docs_float_id))
    t.assert_equal(["red", "│ │ │ │ x"], [docs.window.buffer.line(0), docs.window.buffer.line(1)], "escape sequences are dropped and nesting is capped at four levels")
    t.assert_equal(false, h.screen.join("\n").include?("\e"), "no escape of the documentation reaches the screen")
    t.finish
  end
end

EditorCompletionTest.main if __FILE__ == $0
