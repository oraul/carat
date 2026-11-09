require_relative "../carat/test_support"
require_relative "../carat/testing"

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

  def self.main
    t = Carat::Testing.new("editor_key_hints")

    # Rows are [label, [project lines, rows, keys, waits, text], [floats,
    # title, whether a hint row holds the text]].
    t.table([
      ["the leader hints show after the delay", ["", 24, "<Space>", 1, "w  windows"], [1, "<Space>", true]],
      ["the leader hints name the quit group", ["", 24, "<Space>", 1, "q  quit"], [1, "<Space>", true]],
      ["the leader hints name the docs group", ["", 24, "<Space>", 1, "d  docs"], [1, "<Space>", true]],
      ["the leader hints describe the palette", ["", 24, "<Space>", 1, "p  Command palette"], [1, "<Space>", true]],
      ["a group lists its actions", ["", 24, "<Space>w", 1, "s  Split window"], [1, "<Space>w", true]],
      ["a group lists the vertical split", ["", 24, "<Space>w", 1, "v  Split window vertically"], [1, "<Space>w", true]],
      ["g lists the tab keys", ["", 24, "g", 1, "t  Next tab page"], [1, "g", true]],
      ["Ctrl-W names its keys in notation", ["", 24, "<C-w>", 1, "<C-s>  Split window"], [1, "<C-w>", true]],
      ["no hint before the delay", ["", 24, "<Space>", 0, "w  windows"], [0, "", false]],
      ["a user names a group", ["keymap.group <leader>w panes", 24, "<Space>", 1, "w  panes"], [1, "<Space>", true]],
      ["a prefix without a group counts its bindings", ["keymap.normal <leader>xa cursor.up\nkeymap.normal <leader>xb cursor.down", 24, "<Space>", 1, "x  +2"], [1, "<Space>", true]],
      ["a delay of 0 shows no hints", ["option.keyhints.delay 0", 24, "<Space>", 3, "w  windows"], [0, "", false]],
      ["insert mode shows no hints", ["keymap.insert ab <Esc>", 24, "ia", 1, "b"], [0, "", false]]
    ]) do |row|
      h = session(row[0], row[1], row[2], row[3])
      [h.state.tab.floats.count, title(h), lists?(h, row[4])]
    end

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
    t.assert_equal([1, "<Space>w"], [h.state.tab.floats.count, title(h)], "the next level shows after the delay")

    h = session("", 12, "<C-w>", 1)
    floats = h.state.tab.floats
    t.assert_equal([1, 9, true], [floats.count, floats.at(0).window.height, floats.at(0).window.width > 40], "Ctrl-W hints fill several columns of the room")

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
