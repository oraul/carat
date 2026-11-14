require_relative "../carat/test_support"
require_relative "../carat/testing"
require_relative "../carat/plugins/hello/plugin"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorPaletteTest
  # A session on a.txt with the default configuration, the keys typed.
  def self.session(keys)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\ntwo\nthree\n")
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

  # The lines of the topmost float, none when no float shows.
  def self.lines(h)
    floats = h.state.tab.floats
    return [] if floats.count == 0
    floats.at(floats.count - 1).window.buffer.lines
  end

  # The first word of the float's row, "" past its end.
  def self.name_at(h, row)
    rows = lines(h)
    return "" if row >= rows.length
    rows[row].to_s.split(" ")[0].to_s
  end

  # The name of the selected row, "" when none is selected.
  def self.selected_name(h)
    floats = h.state.tab.floats
    return "" if floats.count == 0
    name_at(h, floats.at(floats.count - 1).selected)
  end

  # The row of the float that starts with the name, "" for none.
  def self.row_of(h, name)
    rows = lines(h)
    want = name.to_s + " "
    i = 0
    while i < rows.length
      return rows[i].to_s.rstrip if rows[i].to_s.start_with?(want)
      i += 1
    end
    ""
  end

  # The cells of the float's row that starts with the name and where its
  # description starts, past the name and key columns, [0, -1] for none.
  def self.cells_of(h, name, description)
    row = row_of(h, name)
    at = row.index(description.to_s)
    return [0, -1] if at.nil?
    [Carat::Domain::DisplayWidth.text_width(row, 0), Carat::Domain::DisplayWidth.text_width(row[0, at].to_s, 0)]
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

    # Rows are [label, keys, [floats, mode, title, first row's name]].
    t.table([
      ["leader p opens the palette", "<Space>p", [1, "cmdline", "Commands", "motion.repeat_find"]],
      ["F1 opens the palette", "<F1>", [1, "cmdline", "Commands", "motion.repeat_find"]],
      ["a fuzzy text picks the window split", "<Space>pwsp", [1, "cmdline", "Commands", "window.split"]],
      ["segment starts win", "<Space>pws", [1, "cmdline", "Commands", "window.split"]],
      ["an ex command is found", "<Space>pnohl", [1, "cmdline", "Commands", ":nohlsearch"]],
      ["a leading colon is ignored", "<Space>p:nohl", [1, "cmdline", "Commands", ":nohlsearch"]],
      ["nothing matches", "<Space>pzzzzqx", [1, "cmdline", "Commands", "No"]],
      ["backspace widens the list", "<Space>pzzzzqx<BS><BS><BS><BS><BS><BS>", [1, "cmdline", "Commands", "motion.repeat_find"]],
      ["Esc closes the palette", "<Space>psplit<Esc>", [0, "normal", "", ""]],
      ["Enter runs an action", "<Space>pwsp<CR>", [0, "normal", "", ""]]
    ]) do |keys|
      h = session(keys)
      floats = h.state.tab.floats
      [floats.count, h.mode.to_s, floats.count == 0 ? "" : floats.at(0).spec.title, name_at(h, 0)]
    end

    h = session("<Space>p")
    t.assert_equal(">", h.message_row[0, 1], "the prompt is >")
    t.assert_equal(h.assembly.actions.names[0], name_at(h, 0), "the first row is the first action registered")
    h = session("<Space>pwindow.split")
    t.assert_equal("window.split                <C-w>s      Split window", row_of(h, "window.split"), "a row holds the name, the key, and the description")
    h = session("<Space>ppalette.open")
    t.assert_equal("palette.open                <Space>p    Command palette", row_of(h, "palette.open"), "the palette shows its own key")

    # An enabled plugin's action is listed with its key and its manifest's
    # description; a disabled plugin's is not.
    h = plugin_session("", "<Space>pgreet")
    t.assert_equal("plugin.hello.greet          <Space>hh   Show a greeting", row_of(h, "plugin.hello.greet")[0, 55], "an enabled plugin's action shows its key and its manifest's description")
    h = plugin_session("plugin.hello.enabled false\n", "<Space>pgreet")
    t.assert_equal("", row_of(h, "plugin.hello.greet"), "a disabled plugin's action is left out")

    h = session("<Space>pvertically")
    t.assert_equal([true, true], [row_of(h, "window.vsplit") != "", row_of(h, ":vsplit") != ""], "a description matches")

    h = session("<Space>psplit<C-n><C-n><C-p>")
    t.assert_equal(name_at(h, 1), selected_name(h), "Ctrl-N and Ctrl-P move the selection")
    h.type("<C-p><C-p>")
    t.assert_equal(name_at(h, 0), selected_name(h), "the selection stops at the top")

    h = session("<Space>p" + "<C-n>" * 20)
    t.assert_equal([h.assembly.actions.names[20], 14], [selected_name(h), h.state.tab.floats.at(0).selected], "the list scrolls to keep the selection shown")

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

    # A bound key wider than its column, of wide or combining characters,
    # (insert.newline has no key of its own in normal mode) is cut by cells
    # and padded so the description starts at cell 40.
    # Rows are [label, project line, [the row's description column, the
    # editor still running]].
    t.table([
      ["a key of seven wide characters", "keymap.normal あいうえおかき insert.newline\n", [40, true]],
      ["a key of twelve wide characters", "keymap.normal あいうえおかきくけこさし insert.newline\n", [40, true]],
      ["a key of letters with combining marks", "keymap.normal a\u0301b\u0301c\u0301d\u0301e\u0301f\u0301g\u0301 insert.newline\n", [40, true]],
      ["a key of wide characters with combining marks", "keymap.normal あ\u0301い\u0301う\u0301え\u0301お\u0301か\u0301 insert.newline\n", [40, true]]
    ]) do |project|
      h = plugin_session(project, "<Space>pinsert.newline")
      [cells_of(h, "insert.newline", "Break line")[1], h.mode == :cmdline]
    end
    h = plugin_session("keymap.normal あいうえおかき insert.newline\n", "<Space>pinsert.newline")
    t.assert_equal(true, row_of(h, "insert.newline").include?("あいうえお "), "a wide key keeps the characters that fit its column")
    h = plugin_session("keymap.normal a\u0301b\u0301c\u0301 insert.newline\n", "<Space>pinsert.newline")
    t.assert_equal(true, row_of(h, "insert.newline").include?("a\u0301b\u0301c\u0301"), "a combining key keeps every mark with its letter")

    h = session("<Space>p<Esc>:")
    t.assert_equal(":", h.message_row[0, 1], "the colon prompt returns after the palette")

    # Scenario: The palette keeps its right border while the filter shrinks.
    [[36, 120], [24, 60], [24, 80]].each do |size|
      rows = size[0].to_i
      cols = size[1].to_i
      t.assert_equal([], shrinking("", rows, cols, "vsplitq"), "The palette keeps its right border while the filter shrinks at #{cols} by #{rows}")
      t.assert_equal([], shrinking("option.winborder none\n", rows, cols, "vsplitq"), "the palette shows every row whole under winborder none at #{cols} by #{rows}")
    end
    # Scenario: Without an edge the palette uses the border columns.
    h = sized("option.winborder none\n", 24, 60)
    h.type("<Space>p")
    floats = h.state.tab.floats
    t.assert_equal([58, 58], [floats.at(0).spec.width, floats.at(0).window.width], "Without an edge the palette uses the border columns")
    t.finish
  end
end

EditorPaletteTest.main if __FILE__ == $0
