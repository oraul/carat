require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorFinderTest
  ROOT = "/p"

  # /p with three files the finder lists and the ignored .git, build, and
  # tmp directories.
  def self.disk
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("lib/alpha.rb", "a = 1\n")
    files.put("lib/beta.rb", "b = 2\n")
    files.put("docs/guide.md", "guide\n")
    files.put(".git/HEAD", "ref\n")
    files.put("build/out.o", "o\n")
    files.put("tmp/scratch.txt", "t\n")
    files
  end

  # An editor with the finder alone over the files, cols wide, on
  # lib/alpha.rb.
  def self.editor_on(files, cols)
    h = Carat::Doubles::EditorHarness.with_plugins(files, 24, cols, [Carat::Plugins::Finder::Plugin.new])
    h.open("lib/alpha.rb")
    h
  end

  def self.session(keys, cols)
    h = editor_on(disk, cols.to_i)
    h.type(keys.to_s)
    h
  end

  # Each float of the current tab page as its title, "|", and its lines.
  def self.floats(h)
    layer = h.state.tab.floats
    out = []
    i = 0
    while i < layer.count
      f = layer.at(i)
      out << "#{f.spec.title}|#{f.window.buffer.lines.join("\n")}"
      i += 1
    end
    out
  end

  # The mode, the command-line row, and the floats.
  def self.view(h)
    [h.mode, h.message_row.rstrip, floats(h)]
  end

  # The column of every window of the current tab page.
  def self.columns(h)
    out = []
    windows = h.windows
    i = 0
    while i < windows.length
      out << windows[i][1].to_i
      i += 1
    end
    out
  end

  # The first matching row's title for a path list typed into.
  def self.first_title(h)
    shown = floats(h)
    shown.empty? ? "" : shown[0].to_s.split("|")[0].to_s
  end

  def self.main
    t = Carat::Testing.new("editor_finder")

    # Rows are [label, [keys, columns], [mode, command line, floats]].
    t.table([
      # Space f f opens the finder
      ["Space f f opens the finder", ["<Space>ff", 80], [:cmdline, ">", ["Files 3/3|> docs/guide.md\n  lib/alpha.rb\n  lib/beta.rb"]]],
      # Ctrl-P opens the finder
      ["Ctrl-P opens the finder", ["<C-p>", 80], [:cmdline, ">", ["Files 3/3|> docs/guide.md\n  lib/alpha.rb\n  lib/beta.rb"]]],
      # Typing filters the files
      ["Typing filters the files", ["<Space>ffbet", 80], [:cmdline, "> bet", ["Files 1/3|> lib/beta.rb"]]],
      ["case is ignored", ["<Space>ffBET", 80], [:cmdline, "> BET", ["Files 1/3|> lib/beta.rb"]]],
      ["a backspace widens the match again", ["<Space>ffbet<BS><BS><BS>", 80], [:cmdline, ">", ["Files 3/3|> docs/guide.md\n  lib/alpha.rb\n  lib/beta.rb"]]],
      # No file matches
      ["No file matches", ["<Space>ffzzz", 80], [:cmdline, "> zzz", ["Files 0/3|No match"]]],
      # Ctrl-N and Ctrl-P move the highlight
      ["Ctrl-N and Ctrl-P move the highlight", ["<Space>ff<C-n><C-n><C-n><C-p>", 80], [:cmdline, ">", ["Files 3/3|  docs/guide.md\n> lib/alpha.rb\n  lib/beta.rb"]]],
      ["Down and Up move it too", ["<Space>ff<Down><Down><Up>", 80], [:cmdline, ">", ["Files 3/3|  docs/guide.md\n> lib/alpha.rb\n  lib/beta.rb"]]],
      ["the highlight stops at the first row", ["<Space>ff<C-p>", 80], [:cmdline, ">", ["Files 3/3|> docs/guide.md\n  lib/alpha.rb\n  lib/beta.rb"]]],
      ["typing returns the highlight to the first row", ["<Space>ff<C-n><C-n>a", 80], [:cmdline, "> a", ["Files 2/3|> lib/alpha.rb\n  lib/beta.rb"]]],
      # Esc closes the finder
      ["Esc closes the finder", ["<Space>ff<Esc>", 80], [:normal, "", []]],
      ["a backspace on the empty prompt closes it", ["<Space>ff<BS>", 80], [:normal, "", []]],
      # A wide screen shows the preview
      ["A wide screen shows the preview", ["<Space>ffbet", 120], [:cmdline, "> bet", ["Files 1/3|> lib/beta.rb", "lib/beta.rb|b = 2"]]],
      ["the preview follows the highlight", ["<Space>ff<C-n>", 120], [:cmdline, ">", ["Files 3/3|  docs/guide.md\n> lib/alpha.rb\n  lib/beta.rb", "lib/alpha.rb|a = 1"]]],
      ["no match shows no preview", ["<Space>ffzzz", 120], [:cmdline, "> zzz", ["Files 0/3|No match"]]],
      # A narrow screen shows no preview
      ["A narrow screen shows no preview", ["<Space>ffbet", 99], [:cmdline, "> bet", ["Files 1/3|> lib/beta.rb"]]]
    ]) do |row|
      view(session(row[0], row[1]))
    end

    # Rows are [label, keys, [mode, current path, window columns, tab
    # page, tab pages, floats]].
    t.table([
      # Enter opens the file
      ["Enter opens the file", "<Space>ffbet<CR>", [:normal, "lib/beta.rb", [0], 1, 1, 0]],
      # Ctrl-X opens it in a split
      ["Ctrl-X opens it in a split", "<Space>ffbet<C-x>", [:normal, "lib/beta.rb", [0, 0], 1, 1, 0]],
      ["Ctrl-S opens it in a split too", "<Space>ffbet<C-s>", [:normal, "lib/beta.rb", [0, 0], 1, 1, 0]],
      # Ctrl-V opens it in a vertical split
      ["Ctrl-V opens it in a vertical split", "<Space>ffbet<C-v>", [:normal, "lib/beta.rb", [0, 41], 1, 1, 0]],
      # Ctrl-T opens it in a tab page
      ["Ctrl-T opens it in a tab page", "<Space>ffbet<C-t>", [:normal, "lib/beta.rb", [0], 2, 2, 0]],
      # Enter with no match opens nothing
      ["Enter with no match opens nothing", "<Space>ffzzz<CR>", [:normal, "lib/alpha.rb", [0], 1, 1, 0]],
      ["Esc opens nothing", "<Space>ffbet<Esc>", [:normal, "lib/alpha.rb", [0], 1, 1, 0]],
      ["the finder opens again after a pick", "<Space>ffbet<CR><Space>ffgu<CR>", [:normal, "docs/guide.md", [0], 1, 1, 0]]
    ]) do |keys|
      h = session(keys, 80)
      [h.mode, h.buffer.path.to_s, columns(h), h.tab_index, h.tab_count, h.state.tab.floats.count]
    end

    # Ignored directories are not listed
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put(".git/HEAD", "ref\n")
    files.put("build/out.o", "o\n")
    files.put("a.rb", "a\n")
    h = editor_on(files, 80)
    h.type("<Space>ff")
    t.assert_equal(["Files 1/1|> a.rb"], floats(h), "Ignored directories are not listed")
    h = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with("plugin.finder.ignore build"), rows: 24, cols: 80, plugins: [Carat::Plugins::Finder::Plugin.new])
    h.open("a.rb")
    h.type("<Space>ff")
    t.assert_equal(["Files 2/2|> .git/HEAD\n  a.rb"], floats(h), "the configuration's ignore list replaces the default")

    # A link leaving the project is skipped; a linked directory is not
    # entered.
    files = disk
    files.put("/elsewhere/x.rb", "out\n")
    files.put("out.rb", "")
    files.link_to("/p/out.rb", "/elsewhere/x.rb")
    files.put("in.rb", "")
    files.link_to("/p/in.rb", "/p/lib/beta.rb")
    files.put("alias/x.rb", "x\n")
    files.link_to("/p/alias", "/p/lib")
    h = editor_on(files, 80)
    h.type("<Space>ff")
    t.assert_equal(["Files 4/4|> docs/guide.md\n  in.rb\n  lib/alpha.rb\n  lib/beta.rb"], floats(h), "A link leaving the project is skipped")
    t.assert_equal(false, floats(h)[0].to_s.include?("alias"), "A linked directory is not entered")

    # The file name match ranks first
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("plugins/finder/x.rb", "x\n")
    files.put("lib/plugin.rb", "p\n")
    h = editor_on(files, 80)
    h.type("<Space>ffplugin")
    t.assert_equal(["Files 2/2|> lib/plugin.rb\n  plugins/finder/x.rb"], floats(h), "The file name match ranks first")

    # Ten thousand files are listed and filtered
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    nines = 0
    i = 0
    while i < 10_000
      path = "d#{i / 100}/f#{i}.rb"
      files.put(path, "")
      at = path.index("9")
      nines += 1 if !at.nil? && !path.index("9", at + 1).nil?
      i += 1
    end
    h = editor_on(files, 80)
    h.type("<Space>ff")
    t.assert_equal("Files 10000/10000", first_title(h), "Ten thousand files are listed")
    h.type("99")
    t.assert_equal("Files #{nines}/10000", first_title(h), "Ten thousand files are listed and filtered")

    # The keys are the plugin's default bindings.
    h = Carat::Doubles::EditorHarness.new(files: disk, config: Carat::Doubles::FixedConfig.with("keymap.normal <C-p> none"), rows: 24, cols: 80, plugins: [Carat::Plugins::Finder::Plugin.new])
    h.open("lib/alpha.rb")
    h.type("<C-p>")
    t.assert_equal([:normal, 0], [h.mode, h.state.tab.floats.count], "the configuration removes the Ctrl-P binding")
    h.type("<Space>ff")
    t.assert_equal(:cmdline, h.mode, "and Space f f still opens the finder")

    t.finish
  end
end

EditorFinderTest.main if __FILE__ == $0
