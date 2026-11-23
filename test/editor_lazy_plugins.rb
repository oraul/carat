require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorLazyPluginsTest
  ROOT = "/home/ada/proj"
  H = Carat::Domain::Highlight
  NAMES = ["explorer", "finder", "ruby", "git_signs"]

  # /home/ada/proj with a markdown file, a ruby file, and a lib directory.
  def self.disk
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("a.md", "alpha\n")
    files.put("b.rb", "puts 1\n")
    files.put("lib/c.rb", "c = 2\n")
    files
  end

  # An editor with the registry's plugins over the disk, 120 columns wide
  # so the finder shows its preview, after its first frame on path.
  def self.editor_on(path)
    h = Carat::Doubles::EditorHarness.new(files: disk, config: Carat::Doubles::FixedConfig.with("option.icons ascii\n"), rows: 24, cols: 120, plugins: Carat::Plugins::Registry.all)
    h.open(path)
    h
  end

  # Whether each plugin of NAMES is active, in that order.
  def self.active(h)
    list = [false]
    list.clear
    NAMES.each { |name| list << h.plugins.active?(name) }
    list
  end

  # Whether the frame's first rows have a syntax token in them.
  def self.tokens_on?(h, rows)
    frame = h.frame
    row = 0
    while row < rows
      col = 0
      while col < frame.cols
        return true if H.token?(H.base(frame.hl_at(row, col)))
        col += 1
      end
      row += 1
    end
    false
  end

  def self.main
    t = Carat::Testing.new("editor_lazy_plugins")

    # Scenario "No plugin is active at startup".
    h = editor_on("a.md")
    t.assert_equal([false, false, false, false], active(h), "no plugin is active at startup: the first frame is drawn with none activated")
    h.wait
    t.assert_equal([false, false, false, true], active(h), "after the first idle only git_signs, which declares no trigger, is active")
    h.type("jkl")
    t.assert_equal([false, false, false], active(h)[0, 3], "keys that trigger none of them leave the explorer, finder, and ruby plugins inactive")

    # Scenario "The explorer activates on its key".
    h = editor_on("a.md")
    h.type(" e")
    t.assert_equal([true, 2, "explorer", [1, 0]], [h.plugins.active?("explorer"), h.window_count, h.state.window.buffer.title, h.cursor], "the explorer activates on its key and opens focused on the current file")
    t.assert_equal([" + lib", "|m a.md", " r b.rb"], h.lines, "the tree marks the file the editor was on before the explorer loaded")
    h.type("j<CR>")
    t.assert_equal([2, "b.rb"], [h.window_count, h.buffer.path_text], "and works as before: Enter opens the file in the editing window")

    # Scenario "The explorer activates on its ex command".
    h = editor_on("a.md")
    h.type(":Explorer<CR>")
    t.assert_equal([true, 2, "explorer", [1, 0]], [h.plugins.active?("explorer"), h.window_count, h.state.window.buffer.title, h.cursor], "the explorer activates on its ex command and opens its window")

    # Scenario "The finder activates on its key".
    h = editor_on("a.md")
    h.type(" ff")
    t.assert_equal([true, :cmdline, 2], [h.plugins.active?("finder"), h.mode, h.state.tab.floats.count], "the finder activates on its key and opens its list and, on a wide screen it heard of at activation, its preview")
    h.type("c.rb<CR>")
    t.assert_equal(["lib/c.rb", :normal], [h.buffer.path_text, h.mode], "and works as before: Enter opens the match")

    # Scenario "The ruby plugin activates on its first ruby buffer".
    h = editor_on("a.md")
    h.wait
    t.assert_equal([false, false], [h.plugins.active?("ruby"), tokens_on?(h, 3)], "the ruby plugin is not active over a markdown file")
    h.type(":e b.rb<CR>")
    t.assert_equal([true, true], [h.plugins.active?("ruby"), tokens_on?(h, 3)], "the ruby plugin activates on its first ruby buffer, whose lines are highlighted")

    t.finish
  end
end

EditorLazyPluginsTest.main if __FILE__ == $0
