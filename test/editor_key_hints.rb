require_relative "../carat/test_support"
require_relative "../carat/testing"
require_relative "../carat/plugins/hello/plugin"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorKeyHintsTest
  # A session on a.txt with the default configuration and the project
  # lines, the keys typed, then waits passes with no key.
  def self.session(project, rows, keys, waits)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\ntwo\nthree\n")
    h = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with(project.to_s), rows: rows.to_i, cols: 80, plugins: [])
    h.open("a.txt")
    h.type(keys.to_s)
    i = 0
    while i < waits.to_i
      h.wait
      i += 1
    end
    h
  end

  # A session on a.txt with the hello plugin and the project lines, the
  # keys typed, then one wait passes with no key.
  def self.plugin_session(project, keys)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\ntwo\nthree\n")
    config = Carat::Doubles::FixedConfig.with(project.to_s)
    h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 24, cols: 80, plugins: [Carat::Plugins::Hello::Plugin.new])
    h.open("a.txt")
    h.type(keys.to_s)
    h.wait
    h
  end

  # The lines of the topmost float, none when no float shows.
  def self.hint_lines(h)
    floats = h.state.tab.floats
    return [] if floats.count == 0
    floats.at(floats.count - 1).window.buffer.lines
  end

  def self.title(h)
    floats = h.state.tab.floats
    return "" if floats.count == 0
    floats.at(floats.count - 1).spec.title
  end

  # Whether a line of the hints holds the text.
  def self.lists?(h, text)
    lines = hint_lines(h)
    want = text.to_s
    i = 0
    while i < lines.length
      return true if lines[i].include?(want)
      i += 1
    end
    false
  end

  # A session of rows by cols on a.txt with the project lines, the keys
  # typed, then one wait passes with no key.
  def self.sized_session(project, rows, cols, keys)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\ntwo\nthree\n")
    h = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with(project.to_s), rows: rows.to_i, cols: cols.to_i, plugins: [])
    h.open("a.txt")
    h.type(keys.to_s)
    h.wait
    h
  end

  # How many times the text shows in the hint lines.
  def self.shown(h, text)
    lines = hint_lines(h)
    want = text.to_s
    count = 0
    i = 0
    while i < lines.length
      at = lines[i].index(want)
      while at
        count += 1
        at = lines[i].index(want, at + want.length)
      end
      i += 1
    end
    count
  end

  # The project lines of nine groups under <leader>x, each hint
  # "k  group-k" ten cells wide.
  def self.nine_groups
    text = +""
    keys = "abcdefghi"
    i = 0
    while i < keys.length
      k = keys[i].to_s
      text << "keymap.normal <leader>x" + k + "z cursor.up\n"
      text << "keymap.group <leader>x" + k + " group-" + k + "\n"
      i += 1
    end
    text
  end

  # The cells of the float's widest row.
  def self.widest(h)
    lines = hint_lines(h)
    most = 0
    i = 0
    while i < lines.length
      w = Carat::Domain::DisplayWidth.text_width(lines[i].to_s, 0)
      most = w if w > most
      i += 1
    end
    most
  end

  def self.main
    t = Carat::Testing.new("editor_key_hints")

    # Rows are [label, [project lines, rows, keys, waits, text], [floats,
    # title, whether a hint row holds the text]].
    t.table([
      ["the leader hints show after the delay", ["", 24, "<Space>", 1, "w  windows"], [1, "<Space>", true]],
      ["the leader hints name the quit group", ["", 24, "<Space>", 1, "q  quit"], [1, "<Space>", true]],
      ["the leader hints name the docs group", ["", 24, "<Space>", 1, "d  docs"], [1, "<Space>", true]],
      ["the leader hints describe the palette", ["", 24, "<Space>", 1, "p  Command palette"], [1, "<Space>", true]],
      ["a group lists its actions", ["", 24, "<Space>w", 1, "s  Split window"], [1, "<Space>w windows", true]],
      ["a group lists the vertical split", ["", 24, "<Space>w", 1, "v  Split window vertically"], [1, "<Space>w windows", true]],
      ["g lists the tab keys", ["", 24, "g", 1, "t  Next buffer tab or tab page"], [1, "g goto", true]],
      ["Ctrl-W names its keys in notation", ["", 24, "<C-w>", 1, "<C-s>  Split window"], [1, "<C-w> window", true]],
      ["no hint before the delay", ["", 24, "<Space>", 0, "w  windows"], [0, "", false]],
      ["a user names a group", ["keymap.group <leader>w panes", 24, "<Space>", 1, "w  panes"], [1, "<Space>", true]],
      ["a prefix without a group counts its bindings", ["keymap.normal <leader>xa cursor.up\nkeymap.normal <leader>xb cursor.down", 24, "<Space>", 1, "x  +2"], [1, "<Space>", true]],
      ["a delay of 0 shows no hints", ["option.keyhints.delay 0", 24, "<Space>", 3, "w  windows"], [0, "", false]],
      ["insert mode shows no hints", ["keymap.insert ab <Esc>", 24, "ia", 1, "b"], [0, "", false]]
    ]) do |row|
      h = session(row[0], row[1], row[2], row[3])
      [h.state.tab.floats.count, title(h), lists?(h, row[4])]
    end

    h = plugin_session("", "<Space>h")
    t.assert_equal([1, "<Space>h", true], [h.state.tab.floats.count, title(h), lists?(h, "h  Show a greeting")], "a plugin's binding shows its manifest's description")
    h = plugin_session("plugin.hello.enabled false\n", "<Space>h")
    t.assert_equal(0, h.state.tab.floats.count, "a disabled plugin's prefix shows no hints")

    h = session("", 24, "<Space>", 1)
    h.type("ws")
    t.assert_equal([0, 2], [h.state.tab.floats.count, h.window_count], "a key completes the binding and closes the hints")

    h = session("", 24, "<Space>", 1)
    h.type("<Esc>")
    t.assert_equal([0, false, :normal], [h.state.tab.floats.count, h.assembly.input.pending?, h.mode], "Esc closes the hints and cancels the keys")

    h = session("", 24, "<Space>", 1)
    h.type("w")
    t.assert_equal(0, h.state.tab.floats.count, "the next key closes the hints at once")
    h.wait
    t.assert_equal([1, "<Space>w windows"], [h.state.tab.floats.count, title(h)], "the next level shows after the delay")

    h = session("", 12, "<C-w>", 1)
    floats = h.state.tab.floats
    t.assert_equal([1, 7, true], [floats.count, floats.at(0).window.height, floats.at(0).window.width > 40], "Ctrl-W hints fill several columns of the room")

    # A hint row of wide or combining characters is cut to the float's
    # width in cells, a wide character that would pass it dropped (73 of
    # 74 cells after "y  "); a group name is the text, since a project file
    # reads no remap. Rows are [label, the group name of <leader>xy,
    # [the widest row's cells, the float's width, floats]].
    t.table([
      ["a group name of fifty wide characters", "あ" * 50, [73, 74, 1]],
      ["a group name of wide characters with combining marks", "あ\u0301" * 50, [73, 74, 1]],
      ["a group name of letters with combining marks fits whole", "e\u0301" * 30, [33, 33, 1]]
    ]) do |name|
      h = session("keymap.normal <leader>xya cursor.up\nkeymap.normal <leader>xb cursor.down\nkeymap.group <leader>xy " + name.to_s, 24, "<Space>x", 1)
      [widest(h), h.state.tab.floats.count == 0 ? 0 : h.state.tab.floats.at(0).window.width, h.state.tab.floats.count]
    end

    # Scenario "The key hints use the border columns without an edge": on
    # a 38 by 8 screen the hints have 3 rows of room (the screen less the
    # message row, the margin, and the border) and 32 columns of text
    # under rounded, 34 under none (the screen less the margin and the
    # frame), so nine ten-cell entries fit 2 columns
    # (22 cells, 6 entries shown) or 3 (34 cells, all 9), and a long group
    # name is cut to the text width (31 or 33 cells of wide characters).
    # Rows are [label, [border, project lines], [the float's width, the
    # widest row's cells, entries shown]].
    long = "keymap.normal <leader>xya cursor.up\nkeymap.normal <leader>xbz cursor.up\nkeymap.group <leader>xy " + "あ" * 50 + "\nkeymap.group <leader>xb group-b\n"
    t.table([
      ["rounded fits two columns of ten-cell hints", ["rounded", nine_groups], [22, 22, 6]],
      ["none fits three columns of ten-cell hints", ["none", nine_groups], [34, 34, 9]],
      ["rounded cuts a long hint to 32 columns", ["rounded", long], [32, 31, 1]],
      ["none cuts a long hint to 34 columns", ["none", long], [34, 33, 1]]
    ]) do |row|
      h = sized_session("option.winborder " + row[0].to_s + "\n" + row[1].to_s, 8, 38, "<Space>x")
      floats = h.state.tab.floats
      [floats.count == 0 ? 0 : floats.at(0).window.width, widest(h), shown(h, "group-")]
    end

    h = session("keymap.normal <leader>x cursor.down\nkeymap.normal <leader>xa cursor.up", 24, "<Space>x", 1)
    t.assert_equal([0, 1], [h.state.tab.floats.count, h.state.window.cursor.row], "a prefix that is also bound shows no hints and timeoutlen resolves it")

    h = session("option.keyhints.delay 20000", 24, "", 0)
    t.assert_equal(".caratrc:1: option.keyhints.delay takes a number from 0 to 10000", h.assembly.config_errors[0].to_s, "a delay out of range is reported")
    t.assert_equal(300, h.state.options.keyhints_delay, "the delay stays the default")

    h = session("keymap.group <leader>w", 24, "", 0)
    t.assert_equal(".caratrc:1: keymap.group takes keys and a name", h.assembly.config_errors[0].to_s, "a group line without a name is reported")

    t.finish
  end
end

EditorKeyHintsTest.main if __FILE__ == $0
