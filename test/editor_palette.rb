require_relative "../carat/test_support"
require_relative "../carat/testing"

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

    h = session("<Space>pvertically")
    t.assert_equal([true, true], [row_of(h, "window.vsplit") != "", row_of(h, ":vsplit") != ""], "a description matches")

    h = session("<Space>psplit<C-n><C-n><C-p>")
    t.assert_equal(name_at(h, 1), selected_name(h), "Ctrl-N and Ctrl-P move the selection")
    h.type("<C-p><C-p>")
    t.assert_equal(name_at(h, 0), selected_name(h), "the selection stops at the top")

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

    h = session("<Space>p<Esc>:")
    t.assert_equal(":", h.message_row[0, 1], "the colon prompt returns after the palette")

    t.finish
  end
end

EditorPaletteTest.main if __FILE__ == $0
