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

  # The paths of the listed buffers, comma separated.
  def self.listed(h)
    list = h.assembly.buffers
    out = []
    i = 0
    while i < list.count
      out << list.buffer_at(i).path.to_s
      i += 1
    end
    out.join(",")
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

  # An 80-column editor on lib/alpha.rb holding text, over the same
  # files, the keys typed.
  def self.word_session(text, keys)
    files = disk
    files.put("lib/alpha.rb", text.to_s)
    h = editor_on(files, 80)
    h.type(keys.to_s)
    h
  end

  # The prompt row and the first float's title, as one string.
  def self.prompt_and_title(h)
    "#{h.message_row.rstrip}|#{first_title(h)}"
  end

  # The prompt row and the first word of the first float's title: Files,
  # Grep, Buffers, or Recent.
  def self.prompt_and_kind(h)
    "#{h.message_row.rstrip}|#{first_title(h).split(" ")[0]}"
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
      out << Carat::Json.element(windows[i], 1).to_i
      i += 1
    end
    out
  end

  # A 24 by cols editor with the finder over the files, the configuration
  # lines over the defaults, the keys typed.
  def self.configured(lines, keys, cols)
    config = Carat::Doubles::FixedConfig.with(lines.to_s)
    h = Carat::Doubles::EditorHarness.new(files: disk, config: config, rows: 24, cols: cols.to_i, plugins: [Carat::Plugins::Finder::Plugin.new])
    h.open("lib/alpha.rb")
    h.type(keys.to_s)
    h
  end

  # The first and the after-last column of each float's box.
  def self.boxes(h)
    layer = h.state.tab.floats
    out = []
    i = 0
    while i < layer.count
      out << layer.at(i).box_left
      out << layer.at(i).box_right
      i += 1
    end
    out
  end

  # The first matching row's title for a path list typed into.
  def self.first_title(h)
    shown = floats(h)
    shown.empty? ? "" : shown[0].to_s.split("|")[0].to_s
  end

  # The window id of each float of the current tab page.
  def self.float_ids(h)
    layer = h.state.tab.floats
    out = []
    i = 0
    while i < layer.count
      out << layer.at(i).id
      i += 1
    end
    out
  end

  def self.main
    t = Carat::Testing.new("editor_finder")

    # Rows are [label, [keys, columns], [mode, command line, floats]].
    t.cases([
      # Space f f opens the finder
      ["Space f f opens the finder", ["<Space>ff", 80], [:cmdline, ">", ["Files 3/3|> docs/guide.md\n  lib/alpha.rb\n  lib/beta.rb"]]],
      # Ctrl-P opens the finder
      ["Ctrl-P opens the finder", ["<C-p>", 80], [:cmdline, ">", ["Files 3/3|> docs/guide.md\n  lib/alpha.rb\n  lib/beta.rb"]]],
      # Typing filters the files
      ["Typing filters the files", ["<Space>ffbet", 80], [:cmdline, "> bet", ["Files 1/3|> lib/beta.rb"]]],
      ["case is ignored", ["<Space>ffBET", 80], [:cmdline, "> BET", ["Files 1/3|> lib/beta.rb"]]],
      ["two terms match in any order", ["<Space>ffbeta lib", 80], [:cmdline, "> beta lib", ["Files 1/3|> lib/beta.rb"]]],
      ["two terms match in the other order", ["<Space>fflib beta", 80], [:cmdline, "> lib beta", ["Files 1/3|> lib/beta.rb"]]],
      ["a term that matches nothing leaves no match", ["<Space>fflib zzz", 80], [:cmdline, "> lib zzz", ["Files 0/3|No match"]]],
      ["initials match", ["<Space>ffla", 80], [:cmdline, "> la", ["Files 1/3|> lib/alpha.rb"]]],
      ["a run that starts mid-word does not match", ["<Space>ffibh", 80], [:cmdline, "> ibh", ["Files 0/3|No match"]]],
      ["a query of spaces lists every file in listing order", ["<Space>ff  ", 80], [:cmdline, ">", ["Files 3/3|> docs/guide.md\n  lib/alpha.rb\n  lib/beta.rb"]]],
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
      # Enter with no match keeps the finder open
      ["Enter with no match keeps the finder open", ["<C-p>zzqx<CR>", 80], [:cmdline, "> zzqx", ["Files 0/3|No match"]]],
      ["Enter with no match on a wide screen still shows no preview", ["<C-p>zzqx<CR>", 120], [:cmdline, "> zzqx", ["Files 0/3|No match"]]],
      ["typing after Enter with no match filters again", ["<C-p>zzqx<CR><BS><BS><BS><BS>bet", 80], [:cmdline, "> bet", ["Files 1/3|> lib/beta.rb"]]],
      # A narrow screen shows no preview
      ["A narrow screen shows no preview", ["<Space>ffbet", 99], [:cmdline, "> bet", ["Files 1/3|> lib/beta.rb"]]],
      # Space f b lists the open buffers
      ["Space f b lists the open buffers", [":e lib/beta.rb<CR><Space>fb", 80], [:cmdline, ">", ["Buffers 2/2|> lib/alpha.rb\n  lib/beta.rb"]]],
      # The buffer picker filters and opens the pick (its open row is in the table below)
      ["The buffer picker filters and opens the pick: typing filters", [":e lib/beta.rb<CR><Space>fbalp", 80], [:cmdline, "> alp", ["Buffers 1/2|> lib/alpha.rb"]]],
      ["the buffer picker previews on a wide screen", [":e lib/beta.rb<CR><Space>fb<C-n>", 120], [:cmdline, ">", ["Buffers 2/2|  lib/alpha.rb\n> lib/beta.rb", "lib/beta.rb|b = 2"]]],
      # Unnamed buffers are not listed
      ["Unnamed buffers are not listed", [":new<CR><Space>fb", 80], [:cmdline, ">", ["Buffers 1/1|> lib/alpha.rb"]]],
      # A deleted buffer leaves the buffer picker
      ["A deleted buffer leaves the buffer picker", [":e lib/beta.rb<CR>:bd<CR><Space>fb", 80], [:cmdline, ">", ["Buffers 1/1|> lib/alpha.rb"]]],
      # Space f r lists the recent files most recent first
      ["Space f r lists the recent files most recent first", [":e lib/beta.rb<CR>:e docs/guide.md<CR><Space>fr", 80], [:cmdline, ">", ["Recent 3/3|> docs/guide.md\n  lib/beta.rb\n  lib/alpha.rb"]]],
      # A file shown again moves to the top
      ["A file shown again moves to the top", [":e lib/beta.rb<CR>:e docs/guide.md<CR>:e lib/alpha.rb<CR><Space>fr", 80], [:cmdline, ">", ["Recent 3/3|> lib/alpha.rb\n  docs/guide.md\n  lib/beta.rb"]]],
      # A deleted buffer stays recent (its Enter row is in the table below)
      ["A deleted buffer stays recent", [":e lib/beta.rb<CR>:bd<CR><Space>fr", 80], [:cmdline, ">", ["Recent 2/2|> lib/alpha.rb\n  lib/beta.rb"]]],
      ["the recent files filter", [":e lib/beta.rb<CR><Space>frbet", 80], [:cmdline, "> bet", ["Recent 1/2|> lib/beta.rb"]]],
      # Space f R resumes the file finder after Esc
      ["Space f R resumes the file finder after Esc", ["<Space>ffa<C-n><Esc><Space>fR", 80], [:cmdline, "> a", ["Files 2/3|  lib/alpha.rb\n> lib/beta.rb"]]],
      ["Space f R resumes the file finder after Esc on an empty prompt", ["<Space>ff<Esc><Space>fR", 80], [:cmdline, ">", ["Files 3/3|> docs/guide.md\n  lib/alpha.rb\n  lib/beta.rb"]]],
      # Space f R resumes after a pick
      ["Space f R resumes after a pick", [":e lib/beta.rb<CR><Space>fbalp<CR><Space>fR", 80], [:cmdline, "> alp", ["Buffers 1/2|> lib/alpha.rb"]]],
      ["Space f R resumes after a split pick, the text typed kept", ["<Space>ffbet<C-x><Space>fR", 80], [:cmdline, "> bet", ["Files 1/3|> lib/beta.rb"]]],
      # The resumed highlight is clamped
      ["The resumed highlight is clamped", [":e lib/beta.rb<CR><Space>fb<C-n><Esc>:bd<CR><Space>fR", 80], [:cmdline, ">", ["Buffers 1/1|> lib/alpha.rb"]]],
      # Nothing to resume
      ["Nothing to resume", ["<Space>fR", 80], [:normal, "No search to resume", []]]

    ]) do |row|
      view(session(row[0], row[1]))
    end

    # Scenario: Typing keeps the list float.
    h = editor_on(disk, 80)
    h.type("<Space>ff")
    opened = float_ids(h)
    h.type("bet")
    typed = float_ids(h)
    typed_title = first_title(h)
    h.type("<BS><BS><BS>")
    t.assert_equal([1, opened[0], opened[0], 1], [opened.length, typed[0], float_ids(h)[0], float_ids(h).length], "Typing keeps the list float: one float, the one the finder opened with")
    t.assert_equal(["Files 1/3", "Files 3/3"], [typed_title, first_title(h)], "the kept list float shows each key's title")

    # Scenario: Moving the highlight keeps both floats.
    h = editor_on(disk, 120)
    h.type("<Space>ff")
    opened = float_ids(h)
    h.type("<C-n>")
    t.assert_equal([2, opened[0], opened[1]], [opened.length, float_ids(h)[0], float_ids(h)[1]], "Moving the highlight keeps both floats")
    t.assert_equal("lib/alpha.rb|a = 1", floats(h)[1], "the kept preview float shows the highlighted file")

    # Scenario: The preview closes and returns.
    h = editor_on(disk, 120)
    h.type("<Space>ff")
    opened = float_ids(h)
    h.type("zzz")
    gone = float_ids(h)
    h.type("<BS><BS><BS>")
    back = float_ids(h)
    t.assert_equal([1, opened[0], 2, opened[0]], [gone.length, gone[0], back.length, back[0]], "The preview closes and returns beside the list float the finder opened with")
    t.assert_equal("docs/guide.md|guide", floats(h)[1], "the returned preview shows the highlighted file")

    # Scenario: A resize opens the floats at the new size.
    h = editor_on(disk, 120)
    h.type("<Space>ff")
    h.resize(24, 80)
    narrow = editor_on(disk, 80)
    narrow.type("<Space>ff")
    t.assert_equal([1, boxes(narrow)], [h.state.tab.floats.count, boxes(h)], "A resize opens the floats at the new size, the list as wide as on an 80-column screen")

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
      # Ctrl-T opens a buffer tab (option.gt buffers, the default)
      ["Ctrl-T opens a buffer tab", "<Space>ffbet<C-t>", [:normal, "lib/beta.rb", [0], 1, 1, 0]],
      # Enter with no match opens nothing
      ["Enter with no match opens nothing", "<Space>ffzzz<CR>", [:cmdline, "lib/alpha.rb", [0], 1, 1, 1]],
      # The query is kept for a correction
      ["The query is kept for a correction", "<C-p>zzqx<CR><BS><BS><BS><BS>bet<CR>", [:normal, "lib/beta.rb", [0], 1, 1, 0]],
      ["Esc after Enter with no match closes the finder", "<C-p>zzqx<CR><Esc>", [:normal, "lib/alpha.rb", [0], 1, 1, 0]],
      ["Esc opens nothing", "<Space>ffbet<Esc>", [:normal, "lib/alpha.rb", [0], 1, 1, 0]],
      ["the finder opens again after a pick", "<Space>ffbet<CR><Space>ffgu<CR>", [:normal, "docs/guide.md", [0], 1, 1, 0]],
      # The buffer picker filters and opens the pick
      ["The buffer picker filters and opens the pick", ":e lib/beta.rb<CR><Space>fbalp<CR>", [:normal, "lib/alpha.rb", [0], 1, 1, 0]],
      ["the buffer picker opens its pick in a vertical split", ":e lib/beta.rb<CR><Space>fbalp<C-v>", [:normal, "lib/alpha.rb", [0, 41], 1, 1, 0]],
      # A deleted buffer stays recent: Enter on it opens it again
      ["A deleted buffer stays recent: Enter opens it again", ":e lib/beta.rb<CR>:bd<CR><Space>fr<C-n><CR>", [:normal, "lib/beta.rb", [0], 1, 1, 0]],
      ["Esc closes the recent files picker", ":e lib/beta.rb<CR><Space>fr<Esc>", [:normal, "lib/beta.rb", [0], 1, 1, 0]]

    ]) do |keys|
      h = session(keys, 80)
      [h.mode, h.buffer.path.to_s, columns(h), h.tab_index, h.tab_count, h.state.tab.floats.count]
    end

    # Ctrl-T opens it in a tab page (option.gt tabpages)
    h = configured("option.gt tabpages\n", "<Space>ffbet<C-t>", 80)
    t.assert_equal([:normal, "lib/beta.rb", [0], 2, 2, 0], [h.mode, h.buffer.path.to_s, columns(h), h.tab_index, h.tab_count, h.state.tab.floats.count], "Ctrl-T opens it in a tab page")
    h = configured("", "<Space>ffbet<C-t>", 80)
    t.assert_equal("lib/alpha.rb,lib/beta.rb", listed(h), "Ctrl-T opens a buffer tab: the file before it stays listed")

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

    # A scattered path is not listed, and explorer ranks a file name, then a directory, then initials
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("ezzzxpzzzlzzzozzzrzzezrrr", "z\n")
    files.put("tools/explain_pl_or_err.sh", "x\n")
    files.put("carat/plugins/explorer/plugin.rb", "p\n")
    files.put("test/editor_explorer.rb", "e\n")
    h = editor_on(files, 80)
    h.type("<Space>ffexplorer")
    t.assert_equal(["Files 3/4|> test/editor_explorer.rb\n  carat/plugins/explorer/plugin.rb\n  tools/explain_pl_or_err.sh"], floats(h), "A scattered path is not listed: a file name match, a directory match, then initials")

    # A multi-byte path matches by its bytes
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("src/caf\u00e9.rb", "c\n")
    files.put("src/cafe.rb", "c\n")
    h = editor_on(files, 80)
    h.type("<Space>ffcaf\u00e9")
    t.assert_equal(["Files 1/2|> src/caf\u00e9.rb"], floats(h), "A multi-byte path matches by its bytes")

    # Ten thousand files are listed and filtered
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    nines = 0
    i = 0
    while i < 10_000
      path = "d#{i / 100}/f#{i}.rb"
      files.put(path, "")
      nines += 1 if path.include?("99")
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

    # Scenario: The finder boxes share an edge.
    h = configured("", "<Space>ffbet", 120)
    top = h.row(1)
    t.assert_equal([[1, 60, 60, 119], "╮╭"], [boxes(h), top[59, 2].to_s], "The finder boxes share an edge: the list from column 1, the preview from the column after it to one before the right edge")
    # Scenario: The finder boxes share an edge without a border.
    h = configured("option.winborder none\n", "<Space>ffbet", 120)
    t.assert_equal([1, 60, 60, 119], boxes(h), "The finder boxes share an edge without a border: the host's frame closes the gap")
    # Scenario: Space f R resumes the grep picker.
    h = session("<Space>fgb<Esc><Space>fR", 80)
    t.assert_equal([:cmdline, "> b", true], [h.mode, h.message_row.rstrip, floats(h)[0].to_s.include?("lib/beta.rb")], "Space f R resumes the grep picker: the prompt keeps b and the matching line of lib/beta.rb is listed")

    # Scenario: The buffer picker's rows in both themes.
    shown = []
    ["carat-dark", "carat-light"].each do |name|
      h = configured("option.theme #{name}\n", ":e lib/beta.rb<CR><Space>fb", 80)
      theme = Carat::Domain::Themes.find(name, "theme")
      top = h.row(1)
      at = top.index("Buffers").to_i
      shown << "#{top}\n#{h.row(2)}\n#{h.row(3)}\n#{h.row(20)}"
      t.assert_equal([theme.fg(Carat::Domain::Highlight::FLOAT_BORDER), theme.fg(Carat::Domain::Highlight::FLOAT_TITLE)], [theme.fg(h.frame.cell(1, 1).hl), theme.fg(h.frame.cell(1, at).hl)], "The buffer picker's rows in both themes: the edge in FloatBorder and the title in FloatTitle under #{name}")
    end
    rounded = " ╭#{"─" * 31} Buffers 2/2 #{"─" * 32}╮\n~│ > lib/alpha.rb#{" " * 61}│\n~│   lib/beta.rb#{" " * 62}│\n~╰#{"─" * 76}╯"
    t.assert_equal([rounded, rounded], shown, "The buffer picker's rows in both themes: the same rows, the title on the top edge")
    # Scenario: The recent files picker's rows in ASCII.
    h = configured("option.icons ascii\n", ":e lib/beta.rb<CR><Space>fr", 80)
    t.assert_equal(" +#{"-" * 32} Recent 2/2 #{"-" * 32}+\n~| > lib/beta.rb#{" " * 62}|\n~|   lib/alpha.rb#{" " * 61}|\n~+#{"-" * 76}+", "#{h.row(1)}\n#{h.row(2)}\n#{h.row(3)}\n#{h.row(20)}", "The recent files picker's rows in ASCII: + and - on the edges, | at the sides")

    # Scenario: Ctrl-G switches the file finder to the grep picker.
    h = session("<Space>ffb<C-g>", 80)
    t.assert_equal([:cmdline, "> b|Grep"], [h.mode, prompt_and_kind(h)], "Ctrl-G switches the file finder to the grep picker: the prompt keeps b and the float is the grep picker's")
    t.assert_equal(true, floats(h)[0].to_s.include?("lib/beta.rb"), "and the grep rows list the line of lib/beta.rb that holds b")
    # Scenario: Ctrl-G switches the grep picker to the file finder.
    h = session("<Space>fgb<C-g>", 80)
    t.assert_equal([:cmdline, "> b|Files 2/3"], [h.mode, prompt_and_title(h)], "Ctrl-G switches the grep picker to the file finder: the prompt keeps b and the files matching it are listed")
    # Scenario: Ctrl-G switches back and forth keeping the query.
    h = session("<Space>ffbet<C-g><C-g>", 80)
    t.assert_equal([:cmdline, "> bet|Files 1/3"], [h.mode, prompt_and_title(h)], "Ctrl-G switches back and forth keeping the query: two switches return to the file finder on bet")
    t.assert_equal(1, h.state.tab.floats.count, "and one float is open, the switch leaving no float behind")
    # Scenario: Ctrl-G with the empty prompt keeps it empty.
    h = session("<Space>ff<C-g>", 80)
    t.assert_equal([:cmdline, ">|Grep"], [h.mode, prompt_and_kind(h)], "Ctrl-G with the empty prompt opens the grep picker on the empty prompt")
    # Scenario: Ctrl-G from the buffer picker opens the grep picker.
    h = session("<Space>fbbet<C-g>", 80)
    t.assert_equal([:cmdline, "> bet|Grep"], [h.mode, prompt_and_kind(h)], "Ctrl-G from the buffer picker opens the grep picker on its text")
    # Scenario: The switched picker is picked from as any other.
    h = session("<Space>ffbet<C-g><C-g><CR>", 80)
    t.assert_equal([:normal, "lib/beta.rb"], [h.mode, h.buffer.path.to_s], "A switched picker is picked from as any other: Enter opens lib/beta.rb")
    # Scenario: A switched picker is the one resumed.
    h = session("<Space>ffbet<C-g><Esc><Space>fR", 80)
    t.assert_equal([:cmdline, "> bet|Grep"], [h.mode, prompt_and_kind(h)], "Space f R resumes the grep picker the switch ended on, with its text")

    # Scenario: Space f w on a word opens the grep picker with it.
    h = word_session("hello world\n", "w<Space>fw")
    t.assert_equal([:cmdline, "> world|Grep"], [h.mode, prompt_and_kind(h)], "Space f w on a word opens the grep picker with the word on the prompt")
    t.assert_equal(true, floats(h)[0].to_s.include?("lib/alpha.rb"), "and the grep rows list the line of the word")
    # Scenario: Space f w takes the whole word.
    h = word_session("hello world\n", "<Space>fw")
    t.assert_equal("> hello", prompt_and_title(h).split("|")[0].to_s, "Space f w on the first character of a word takes the whole word")
    # Scenario: Space f w on a multi-byte word.
    h = word_session("caf\u00e9 x\n", "3l<Space>fw")
    t.assert_equal("> caf\u00e9", prompt_and_title(h).split("|")[0].to_s, "Space f w on a multi-byte character takes the word by code point columns")
    # Scenario: Space f w keeps underscores in the word.
    h = word_session("foo_bar baz\n", "<Space>fw")
    t.assert_equal("> foo_bar", prompt_and_title(h).split("|")[0].to_s, "Space f w takes the underscore as part of the word")
    # Scenario: Space f w on a blank opens the grep picker empty.
    h = word_session("hello world\n", "5l<Space>fw")
    t.assert_equal([:cmdline, ">|Grep"], [h.mode, prompt_and_kind(h)], "Space f w on a blank opens the grep picker on the empty prompt")
    # Scenario: Space f w in an empty buffer or on an empty line.
    h = word_session("", "<Space>fw")
    t.assert_equal([:cmdline, ">|Grep"], [h.mode, prompt_and_kind(h)], "Space f w in an empty buffer opens the grep picker on the empty prompt")
    h = word_session("hello\n\nworld\n", "j<Space>fw")
    t.assert_equal([:cmdline, ">|Grep"], [h.mode, prompt_and_kind(h)], "Space f w on an empty line opens the grep picker on the empty prompt")
    # Scenario: Space f w on the last character of the last line.
    h = word_session("hello world\n", "$<Space>fw")
    t.assert_equal("> world", prompt_and_title(h).split("|")[0].to_s, "Space f w on the last character of the last line takes the word")
    # Scenario: Ctrl-G after Space f w switches on the word.
    h = word_session("hello world\n", "<Space>fw<C-g>")
    t.assert_equal([:cmdline, "> hello|Files 0/3"], [h.mode, prompt_and_title(h)], "Ctrl-G after Space f w switches to the file finder on the word")
    t.finish
  end
end

EditorFinderTest.main if __FILE__ == $0
