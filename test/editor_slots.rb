require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorSlotsTest
  ROOT = "/home/ada/proj"
  H = Carat::Domain::Highlight

  # /home/ada/proj with two files and a directory.
  def self.disk
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("a.md", "alpha\n")
    files.put("b.rb", "puts 1\n")
    files.put("docs/guide.md", "guide\n")
    files
  end

  # An editor on a.md with the registry's plugins, the ascii icons, and
  # the further configuration lines.
  def self.editor(more)
    config = Carat::Doubles::FixedConfig.with("option.icons ascii\n#{more}")
    h = Carat::Doubles::EditorHarness.new(files: disk, config: config, rows: 24, cols: 80, plugins: Carat::Plugins::Registry.all)
    h.open("a.md")
    h
  end

  # Every window as [col, columns, name].
  def self.shape(h)
    layout = h.state.tab.layout
    out = []
    layout.leaves.each do |id|
      w = layout.window_at(id)
      name = w.buffer.display_name
      out << [w.col, w.width, name.nil? ? "" : name]
    end
    out
  end

  # The windows, the current window's name, its cursor, and the message
  # after the keys.
  def self.after(more, keys)
    h = editor(more.to_s)
    h.type(keys.to_s)
    name = h.state.window.buffer.display_name
    [shape(h), name.nil? ? "" : name, h.state.cursor.to_a, h.message]
  end

  OPEN = [[0, 30, "explorer"], [31, 49, "a.md"]]
  FILE = [[0, 80, "a.md"]]

  def self.main
    t = Carat::Testing.new("editor_slots")

    # The slot toggles over the explorer: rows are [label, [configuration,
    # keys], [windows, current window, its cursor, message]].
    t.table([
      ["<leader>ls hides the explorer and the file window is current", ["", " e ls"], [FILE, "a.md", [0, 0], ""]],
      ["<leader>ls again shows it with its cursor, the focus staying", ["", " ek<C-w>l ls ls"], [OPEN, "a.md", [0, 0], ""]],
      ["the shown tree keeps its cursor", ["", " ek<C-w>l ls ls<C-w>h"], [OPEN, "explorer", [1, 0], ""]],
      ["<leader>e shows a hidden explorer again, focused", ["", " e ls e"], [OPEN, "explorer", [2, 0], ""]],
      ["an empty left sidebar says so", ["", " ls"], [FILE, "a.md", [0, 0], "No view in the left sidebar"]],
      ["an empty right sidebar says so", ["", " lr"], [FILE, "a.md", [0, 0], "No view in the right sidebar"]],
      ["an empty panel says so", ["", " lp"], [FILE, "a.md", [0, 0], "No view in the panel"]],
      ["the explorer on the right toggles with <leader>lr", ["plugin.explorer.side right", " e lr"], [FILE, "a.md", [0, 0], ""]],
      ["the configured width wins over plugin.explorer.width", ["option.layout.left_width 24", " e"], [[[0, 24, "explorer"], [25, 55, "a.md"]], "explorer", [2, 0], ""]],
      ["the explorer alone cannot be hidden", ["", " e:only<CR> ls"], [[[0, 80, "explorer"]], "explorer", [2, 0], "E444: Cannot close last window"]]
    ]) do |input|
      after(input[0], input[1])
    end

    # The header row and the tree under it.
    h = editor("")
    h.type(" e")
    t.assert_equal([" explorer", H::TAB_LINE_SELECTED, H::TAB_LINE_FILL, " - proj"], [h.row(0)[0, 30].rstrip, h.frame.hl_at(0, 1), h.frame.hl_at(0, 20), h.row(1)[0, 30].rstrip], "the left sidebar's header names the explorer, the tree under it")
    h.type(" ls")
    t.assert_equal(["alpha", true], [h.row(0)[4, 5], h.assembly.buffers.scratch_for("explorer", "explorer").nil? == false], "hidden, the file takes the row and the tree's buffer stays listed")

    # A hidden slot of a closed tab page lets go of its view.
    h = editor("")
    h.type(":tabnew<CR> e ls:tabclose<CR>")
    t.assert_equal([1, true], [h.state.tabs.tab_count, h.assembly.buffers.scratch_for("explorer", "explorer").nil?], "closing the tab page lets go of the hidden explorer")

    t.finish
  end
end

EditorSlotsTest.main if __FILE__ == $0
