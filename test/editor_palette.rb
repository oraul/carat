require_relative "../carat/test_support"
require_relative "../carat/testing"
require_relative "../carat/plugins/hello/plugin"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorPaletteTest
  H = Carat::Domain::Highlight

  # A plugin whose one action has a description that starts with wide
  # characters, three bytes each.
  class Wide < Carat::PluginApi::Plugin
    # Returns the manifest.
    # @rbs skip
    def manifest
      Carat::PluginApi::Manifest.new(name: "wide", version: "1.0.0", api_version: Carat::PluginApi::VERSION, actions: { "plugin.wide.go" => "\u65E5\u672C\u8A9E text" }, commands: {}, bindings: [], events: [], options: [], option_types: {}, filetypes: [])
    end
  end

  # A session on a.txt with the default configuration, the keys typed.
  def self.session(keys)
    session_on("one\ntwo\nthree\n", keys)
  end

  # The same session with a.txt holding text.
  def self.session_on(text, keys)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", text.to_s)
    h = Carat::Doubles::EditorHarness.default(files, 24, 80)
    h.open("a.txt")
    h.type(keys.to_s)
    h
  end

  # A session on a.txt with the hello plugin and the project lines, the
  # keys typed.
  def self.plugin_session(project, keys)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\ntwo\nthree\n")
    config = Carat::Doubles::FixedConfig.with(project.to_s)
    h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 24, cols: 80, plugins: [Carat::Plugins::Hello::Plugin.new])
    h.open("a.txt")
    h.type(keys.to_s)
    h
  end

  # The list rows of the topmost float, under its query row, none when
  # no float shows.
  def self.lines(h)
    floats = h.state.tab.floats
    return [] if floats.count == 0
    all = floats.at(floats.count - 1).window.buffer.lines
    all[1, all.length - 1].to_a
  end

  # The first word of a row's name column, which starts 42 cells before
  # the end of a row of the width; the row's first word when the row ends
  # before it ("No match").
  def self.name_in(line, width)
    text = line.to_s
    from = Carat::Domain::DisplayWidth.bytes_within(text, width.to_i - 42)
    return text.split(" ")[0].to_s if from >= text.bytesize
    text.byteslice(from, text.bytesize - from).to_s.split(" ")[0].to_s
  end

  # The name of the float's row, "" past its end.
  def self.name_at(h, row)
    rows = lines(h)
    return "" if row >= rows.length
    name_in(rows[row], width_of(h))
  end

  # The name of the selected row, "" when none is selected.
  def self.selected_name(h)
    floats = h.state.tab.floats
    return "" if floats.count == 0
    shown = floats.at(floats.count - 1).selected
    return "" if shown < 1
    name_at(h, shown - 1)
  end

  # The row of the float whose name column holds the name, "" for none.
  def self.row_of(h, name)
    at = index_of(h, name)
    return "" if at < 0
    lines(h)[at].to_s.rstrip
  end

  # The text width of the topmost float.
  def self.width_of(h)
    floats = h.state.tab.floats
    floats.at(floats.count - 1).window.width
  end

  # The cell where the text starts in the float's row of the name, -1
  # for none.
  def self.cell_of(h, name, text)
    row = row_of(h, name)
    at = row.index(text.to_s)
    return -1 if at.nil?
    Carat::Domain::DisplayWidth.text_width(row[0, at].to_s, 0)
  end

  # The index of the float's row whose name column holds the name, -1
  # for none.
  def self.index_of(h, name)
    rows = lines(h)
    width = width_of(h)
    i = 0
    while i < rows.length
      return i if name_in(rows[i], width) == name.to_s
      i += 1
    end
    -1
  end

  # The group, without its layer, of the cell at col of the list row of
  # the float, the row after the query row.
  def self.group_at(h, row, col)
    floats = h.state.tab.floats
    window = floats.at(floats.count - 1).window
    H.base(h.frame.hl_at(window.row + 1 + row - window.top, window.col + col))
  end

  # Whether a cell of the float's row from col to before stop is drawn in
  # PmenuMatch or PmenuMatchSel.
  def self.marked?(h, row, col, stop)
    c = col
    while c < stop
      g = group_at(h, row, c)
      return true if g == H::POPUP_MENU_MATCH || g == H::POPUP_MENU_MATCH_SELECTED
      c += 1
    end
    false
  end

  # The cells of the float's row of the name and where its description
  # starts, [0, -1] for none.
  def self.cells_of(h, name, description)
    row = row_of(h, name)
    at = row.index(description.to_s)
    return [0, -1] if at.nil?
    [Carat::Domain::DisplayWidth.text_width(row, 0), Carat::Domain::DisplayWidth.text_width(row[0, at].to_s, 0)]
  end

  # A session on a.txt with the Wide plugin, the keys typed.
  def self.wide_session(keys)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\ntwo\nthree\n")
    h = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with(""), rows: 24, cols: 80, plugins: [Wide.new])
    h.open("a.txt")
    h.type(keys.to_s)
    h
  end

  # Whether a cell of the float's row from col to before stop is drawn in
  # PmenuExtra or PmenuExtraSel.
  def self.extra?(h, row, col, stop)
    c = col
    while c < stop
      g = group_at(h, row, c)
      return true if g == H::POPUP_MENU_EXTRA || g == H::POPUP_MENU_EXTRA_SELECTED
      c += 1
    end
    false
  end

  # A rows by cols session on a.txt with the configuration lines over
  # the defaults.
  def self.sized(lines, rows, cols)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\ntwo\nthree\n")
    config = Carat::Doubles::FixedConfig.with(lines.to_s)
    h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: rows.to_i, cols: cols.to_i, plugins: [])
    h.open("a.txt")
    h
  end

  # What is wrong with the topmost float's frame, "" when nothing: a box
  # row whose last column is not the right border (when edged), a row
  # of its text not shown whole up to the padding, or a text area
  # narrower than the width the rows were laid out at.
  def self.frame_fault(h)
    floats = h.state.tab.floats
    return "no float" if floats.count == 0
    float = floats.at(floats.count - 1)
    window = float.window
    return "text area #{window.width} for rows of #{float.spec.width}" if window.width != float.spec.width
    r = float.box_top
    while r < float.box_bottom
      row = h.row(r)
      row += " " * (h.state.screen_cols - row.length) if row.length < h.state.screen_cols
      if float.edged?
        glyph = row[float.box_right - 1, 1].to_s
        return "row #{r} ends in #{glyph.inspect}" unless glyph == "│" || glyph == "╮" || glyph == "╯"
      end
      at = r - window.row
      if at >= 0 && at < window.height
        line = window.buffer.lines[at].to_s
        return "row #{r} shows #{row[window.col, line.length].to_s.inspect}" if row[window.col, line.length].to_s != line
        return "row #{r} has no padding" if row[window.col + window.width, 1].to_s != " "
      end
      r += 1
    end
    ""
  end

  # The frame faults after "<Space>p" and each key of the filter typed
  # one at a time, as "key: fault", empty when every frame is right.
  def self.shrinking(lines, rows, cols, filter)
    h = sized(lines, rows, cols)
    out = []
    h.type("<Space>p")
    fault = frame_fault(h)
    out << "<Space>p: #{fault}" unless fault.empty?
    filter.to_s.each_char do |key|
      h.type(key)
      fault = frame_fault(h)
      out << "#{key}: #{fault}" unless fault.empty?
    end
    out
  end

  def self.main
    t = Carat::Testing.new("editor_palette")

    # Scenarios: Open with the leader, Open with F1, and Ex commands are
    # listed (the rows "leader p opens the palette", "F1 opens the palette",
    # and "an ex command is found").
    # Rows are [label, keys, [floats, mode, title, first row's name]].
    t.table([
      ["leader p opens the palette", "<Space>p", [1, "cmdline", "Commands", "motion.repeat_find"]],
      ["F1 opens the palette", "<F1>", [1, "cmdline", "Commands", "motion.repeat_find"]],
      ["a fuzzy text picks the window split", "<Space>pwsp", [1, "cmdline", "Commands", "window.split"]],
      ["segment starts win", "<Space>pws", [1, "cmdline", "Commands", "window.split"]],
      ["an ex command is found", "<Space>pnohl", [1, "cmdline", "Commands", ":nohlsearch"]],
      ["a leading colon is ignored", "<Space>p:nohl", [1, "cmdline", "Commands", ":nohlsearch"]],
      # Edge cases: a text of colons alone is empty once they are dropped,
      # so every entry shows; a trailing blank is matched like any character.
      ["colons alone list every entry", "<Space>p::", [1, "cmdline", "Commands", "motion.repeat_find"]],
      ["a trailing blank is part of the text, so nothing matches", "<Space>pwsp ", [1, "cmdline", "Commands", "No"]],
      ["nothing matches", "<Space>pzzzzqx", [1, "cmdline", "Commands", "No"]],
      ["backspace widens the list", "<Space>pzzzzqx<BS><BS><BS><BS><BS><BS>", [1, "cmdline", "Commands", "motion.repeat_find"]],
      ["Esc closes the palette", "<Space>psplit<Esc>", [0, "normal", "", ""]],
      ["Enter runs an action", "<Space>pwsp<CR>", [0, "normal", "", ""]]
    ]) do |keys|
      h = session(keys)
      floats = h.state.tab.floats
      [floats.count, h.mode.to_s, floats.count == 0 ? "" : floats.at(0).spec.title.split(" ")[0].to_s, name_at(h, 0)]
    end

    h = session("<Space>p")
    t.assert_equal([true, "> "], [h.message_row.strip.empty?, h.state.tab.floats.at(0).window.buffer.lines[0].to_s], "the prompt is > on the float's first row, the command-line row blank")
    # Scenario: The query is the float's first row (the palette).
    # The float's first row is the prompt and the typed text, the cursor
    # stands after it as a bar, the command-line row is blank, and the
    # title carries the counts of the matches and the entries.
    h = session("<Space>pwsp")
    float = h.state.tab.floats.at(0)
    window = float.window
    palette = h.assembly.palette
    t.assert_equal(["> wsp", "> wsp", "Commands #{palette.matches.length}/#{palette.names.length}", true, [window.row, window.col + 5, :bar]], [window.buffer.lines[0], h.row(window.row)[window.col, 5].to_s, float.spec.title, h.message_row.strip.empty?, [h.frame.cursor_row, h.frame.cursor_col, h.frame.cursor_shape]], "The query is the float's first row: the text, the title counts, the cursor after the text")
    h.type("<Left>")
    t.assert_equal([window.row, window.col + 4], [h.frame.cursor_row, h.frame.cursor_col], "The query is the float's first row: the cursor follows the command line's cursor")
    h.type("x")
    t.assert_equal(["> wsxp", window.col + 5], [h.state.tab.floats.at(0).window.buffer.lines[0], h.frame.cursor_col], "The query is the float's first row: a character typed at the cursor")
    # Scenario: The query row selects the list's first row.
    h = session("<Space>p")
    t.assert_equal([1, h.assembly.actions.names[0]], [h.state.tab.floats.at(0).selected, selected_name(h)], "The query row selects the list's first row: the row after the query is highlighted")
    t.assert_equal(h.assembly.actions.names[0], name_at(h, 0), "the first row is the first action registered")
    # Scenario: A screen with no room for a list row. The palette has no
    # float and the prompt stays on the command-line row.
    h = sized("", 6, 40)
    h.type("<Space>pab")
    t.assert_equal([0, "> ab", 5, 4], [h.state.tab.floats.count, h.message_row.rstrip, h.frame.cursor_row, h.frame.cursor_col], "With no room for a list row the prompt stays on the command line")
    h = session("<Space>p")
    # Edge case: the palette over an empty buffer lists the same entries
    # and Esc leaves the buffer's one empty line as it was.
    empty = session_on("", "<Space>p")
    count = empty.state.tab.floats.count
    top = name_at(empty, 0)
    same = lines(empty).length == lines(h).length
    empty.type("<Esc>")
    t.assert_equal([1, h.assembly.actions.names[0], true, 0, [""]], [count, top, same, empty.state.tab.floats.count, empty.lines], "the palette over an empty buffer lists every entry and Esc leaves the buffer empty")
    # Scenario: The label first, the key in caret notation on the right.
    # The description leads from cell 0, the name's 30-cell column
    # follows 42 cells before the row's end, and the key stands in the
    # last 12 cells.
    h = session("<Space>pwindow.split")
    t.assert_equal([0, width_of(h) - 42, width_of(h) - 12, true], [cells_of(h, "window.split", "Split window")[1], cell_of(h, "window.split", "window.split"), cell_of(h, "window.split", "^Ws"), row_of(h, "window.split").end_with?("^Ws")], "The label first, the key in caret notation on the right: the description, the name, and the key")
    h = session("<Space>ppalette.open")
    t.assert_equal([0, width_of(h) - 12], [cells_of(h, "palette.open", "Command palette")[1], cell_of(h, "palette.open", "<Space>p")], "the palette shows its own key")
    # Scenario: A 29-character name is whole.
    h = session("<Space>pinner_single")
    at = index_of(h, "textobject.inner_single_quote")
    row = at < 0 ? "" : lines(h)[at].to_s
    t.assert_equal([width_of(h) - 42, " "], [cell_of(h, "textobject.inner_single_quote", "textobject.inner_single_quote"), row[width_of(h) - 42 + 29, 1].to_s], "A 29-character name is whole, a space after it")
    # Scenario: A cut description is marked. At 80 columns the label's
    # column keeps width less 42 cells; a longer description keeps two
    # cells less and ends in the mark, the name still in its column.
    h = session("<Space>pcompletion.replace")
    row = row_of(h, "completion.replace")
    room = width_of(h) - 42
    label = Carat::Domain::DisplayWidth.cut(row, room).rstrip
    t.assert_equal([room - 1, true, "Replace the word with completion".start_with?(label[0, label.length - 1].to_s), width_of(h) - 42], [Carat::Domain::DisplayWidth.text_width(label, 0), label.end_with?("\u2026"), true, cell_of(h, "completion.replace", "completion.replace")], "A cut description is marked: cut at a character, its last shown cell the mark, the name in its column")
    t.assert_equal(false, row_of(h, "completion.replace").include?("Replace the word with completion"), "the cut description is not shown whole")
    # Scenario: An ascii cut mark.
    h = sized("option.icons ascii\n", 24, 80)
    h.type("<Space>pcompletion.replace")
    label = Carat::Domain::DisplayWidth.cut(row_of(h, "completion.replace"), width_of(h) - 42).rstrip
    t.assert_equal([true, false], [label.end_with?(">"), label.include?("\u2026")], "An ascii cut mark: the last shown cell is >")

    # An enabled plugin's action is listed with its key and its manifest's
    # description; a disabled plugin's is not.
    h = plugin_session("", "<Space>pgreet")
    t.assert_equal([0, width_of(h) - 12], [cells_of(h, "plugin.hello.greet", "Show a greeting")[1], cell_of(h, "plugin.hello.greet", "<Space>hh")], "an enabled plugin's action shows its key and its manifest's description")
    h = plugin_session("plugin.hello.enabled false\n", "<Space>pgreet")
    t.assert_equal("", row_of(h, "plugin.hello.greet"), "a disabled plugin's action is left out")

    h = session("<Space>pvertically")
    t.assert_equal([true, true], [row_of(h, "window.vsplit") != "", row_of(h, ":vsplit") != ""], "a description matches")

    h = session("<Space>psplit<C-n><C-n><C-p>")
    t.assert_equal(name_at(h, 1), selected_name(h), "Ctrl-N and Ctrl-P move the selection")
    h.type("<C-p><C-p>")
    t.assert_equal(name_at(h, 0), selected_name(h), "the selection stops at the top")

    h = session("<Space>p" + "<C-n>" * 20)
    t.assert_equal([h.assembly.actions.names[20], 15], [selected_name(h), h.state.tab.floats.at(0).selected], "the list scrolls to keep the selection shown")

    h = session("<Space>pwsp<CR>")
    t.assert_equal([2, :normal], [h.window_count, h.mode], "Enter runs the selected action")

    h = session("<Space>psplit<Esc>")
    t.assert_equal(1, h.window_count, "Esc runs nothing")

    h = session("x<Space>p:write<CR>")
    t.assert_equal("ne\ntwo\nthree\n", h.files.get("a.txt").to_s, "Enter runs an ex command as typed after a colon")

    h = session("<F1>operator.delete<CR>j")
    t.assert_equal(["three"], h.lines, "an operator from the palette waits for its motion")

    h = session("<Space>pzzzzqx<CR>")
    t.assert_equal([0, :normal, 1], [h.state.tab.floats.count, h.mode, h.window_count], "Enter with nothing selected only closes")

    # Scenarios: A key of wide characters, A key with combining marks. A
    # bound key wider than its column (insert.newline has no key of its
    # own in normal mode) is cut by cells and marked; the description
    # starts at cell 0 and the key 12 cells before the row's end.
    # Rows are [label, project line, [the row's description column, the
    # key's column from the row's end, the editor still running]].
    t.table([
      ["a key of seven wide characters", "keymap.normal あいうえおかき insert.newline\n", [0, 12, true]],
      ["a key of twelve wide characters", "keymap.normal あいうえおかきくけこさし insert.newline\n", [0, 12, true]],
      ["a key of letters with combining marks", "keymap.normal a\u0301b\u0301c\u0301d\u0301e\u0301f\u0301g\u0301 insert.newline\n", [0, 12, true]],
      ["a key of wide characters with combining marks", "keymap.normal あ\u0301い\u0301う\u0301え\u0301お\u0301か\u0301 insert.newline\n", [0, 12, true]]
    ]) do |project|
      h = plugin_session(project, "<Space>pinsert.newline")
      key = project.to_s.split(" ")[1].to_s
      [cells_of(h, "insert.newline", "Break line")[1], width_of(h) - cell_of(h, "insert.newline", key[0, 2].to_s), h.mode == :cmdline]
    end
    h = plugin_session("keymap.normal あいうえおかき insert.newline\n", "<Space>pinsert.newline")
    t.assert_equal([true, false], [row_of(h, "insert.newline").end_with?("あいうえお\u2026"), row_of(h, "insert.newline").include?("か")], "A key of wide characters: it keeps the characters that fit its column, then the cut mark")
    h = plugin_session("keymap.normal a\u0301b\u0301c\u0301 insert.newline\n", "<Space>pinsert.newline")
    t.assert_equal(true, row_of(h, "insert.newline").include?("a\u0301b\u0301c\u0301"), "A key with combining marks: every mark stays with its letter")

    # Scenario: The selected row's match in PmenuMatchSel. On the
    # selected window.split row "wsp" marks the w, s, and p of the name,
    # whose column starts 42 cells before the row's end.
    h = session("<Space>pwsp")
    at = index_of(h, "window.split")
    n = width_of(h) - 42
    h.type("<C-n>" * at)
    t.assert_equal([H::POPUP_MENU_MATCH_SELECTED, H::POPUP_MENU_MATCH_SELECTED, H::POPUP_MENU_MATCH_SELECTED, H::POPUP_MENU_EXTRA_SELECTED, H::POPUP_MENU_SELECTED], [group_at(h, at, n), group_at(h, at, n + 7), group_at(h, at, n + 8), group_at(h, at, n + 1), group_at(h, at, 0)], "The selected row's match in PmenuMatchSel, the other name characters in PmenuExtraSel, the description in PmenuSel")
    # Scenario: A matched name's letters in PmenuMatch.
    h.type(at == 0 ? "<C-n>" : "<C-p>")
    t.assert_equal([H::POPUP_MENU_MATCH, H::POPUP_MENU_MATCH, H::POPUP_MENU_MATCH, H::POPUP_MENU_EXTRA, H::POPUP_MENU], [group_at(h, at, n), group_at(h, at, n + 7), group_at(h, at, n + 8), group_at(h, at, n + 1), group_at(h, at, 0)], "A matched name's letters in PmenuMatch, the other name characters in PmenuExtra, the description in Pmenu")
    # Scenario: A description match is marked in its column.
    h = session("<Space>pvertically")
    at = index_of(h, "window.vsplit")
    t.assert_equal([true, false], [marked?(h, at, 0, width_of(h) - 42), marked?(h, at, width_of(h) - 42, width_of(h) - 12)], "A description match is marked in its column, not in the name's")
    h = session("<Space>p")
    t.assert_equal(false, marked?(h, 0, 0, width_of(h)), "with an empty text nothing is marked")
    # A multibyte query marks whole characters: the one wide character it
    # matched, two cells, and not the two that follow it.
    h = wide_session("<Space>p\u65E5")
    at = index_of(h, "plugin.wide.go")
    t.assert_equal([true, true, false, false], [marked?(h, at, 0, 1), marked?(h, at, 1, 2), marked?(h, at, 2, 4), marked?(h, at, 4, 6)], "a multibyte query marks only the character it matched")
    # Scenario: A narrow palette leaves the name out.
    h = sized("option.winborder none\n", 24, 46)
    h.type("<Space>pwindow.split")
    at = -1
    narrow = lines(h)
    narrow.each_with_index { |line, i| at = i if at < 0 && line.to_s.start_with?("Split window ") }
    row = at < 0 ? "" : narrow[at].to_s.rstrip
    t.assert_equal([42, 30, false, false], [width_of(h), row.index("^Ws").to_i, row.include?("window.split"), at < 0 || extra?(h, at, 0, width_of(h))], "A narrow palette leaves the name out: the key follows the label and no cell is in PmenuExtra")
    # Scenario: A palette at the smallest screen shows a label. Under 24
    # cells of text the key is left out and the label takes the row; at
    # 24 the key keeps its 12 cells. The first row is window.split's.
    # Rows are [label, [project lines, screen columns], [the text width,
    # the first row, where ^Ws starts or -1]].
    t.cases([
      ["the smallest screen under the default border", ["", 8], [2, "S", -1]],
      ["the smallest screen without a border", ["option.winborder none\n", 8], [4, "Sp…", -1]],
      ["a text of 14 cells", ["option.winborder none\n", 18], [14, "Split window", -1]],
      ["a text of 23 cells", ["option.winborder none\n", 27], [23, "Split window", -1]],
      ["a text of 24 cells keeps the key", ["option.winborder none\n", 28], [24, "Split wind… ^Ws", 12]]
    ]) do |size|
      h = sized(size[0].to_s, 24, size[1].to_i)
      h.type("<Space>pwindow.split")
      first = lines(h)[0].to_s.rstrip
      at = first.index("^Ws")
      [width_of(h), first, at.nil? ? -1 : Carat::Domain::DisplayWidth.text_width(first[0, at].to_s, 0)]
    end

    h = session("<Space>p<Esc>:")
    t.assert_equal(":", h.message_row[0, 1], "the colon prompt returns after the palette")

    # Scenario: The palette keeps its right border while the filter shrinks.
    [[36, 120], [24, 60], [24, 80]].each do |size|
      rows = Carat::Json.element(size, 0).to_i
      cols = Carat::Json.element(size, 1).to_i
      t.assert_equal([], shrinking("", rows, cols, "vsplitq"), "The palette keeps its right border while the filter shrinks at #{cols} by #{rows}")
      t.assert_equal([], shrinking("option.winborder none\n", rows, cols, "vsplitq"), "the palette shows every row whole under winborder none at #{cols} by #{rows}")
    end
    # Scenario: Without an edge the palette uses the border columns.
    h = sized("option.winborder none\n", 24, 60)
    h.type("<Space>p")
    floats = h.state.tab.floats
    t.assert_equal([56, 56], [floats.at(0).spec.width, floats.at(0).window.width], "Without an edge the palette uses the border columns, the screen less its margin and its padding")
    # Scenario: The palette is centered without a border.
    float = floats.at(0)
    t.assert_equal([1, 1, false], [float.box_left, 60 - float.box_right, float.edged?], "The palette is centered without a border: as many columns left of its box as right")
    # Scenario: The palette is centered again after a resize.
    h = sized("", 36, 120)
    h.type("<Space>p")
    float = h.state.tab.floats.at(0)
    wide = [float.box_left, 120 - float.box_right]
    h.resize(30, 100)
    float = h.state.tab.floats.at(0)
    t.assert_equal([[13, 13], [3, 3], 1], [wide, [float.box_left, 100 - float.box_right], h.state.tab.floats.count], "The palette is centered again after a resize: centered at 120 columns and at 100")
    t.finish
  end
end

EditorPaletteTest.main if __FILE__ == $0
