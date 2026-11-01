require_relative "../carat/test_support"
require_relative "../carat/testing"

t = Carat::Testing.new("editor_explorer")

ROOT = "/home/ada/proj"

# /home/ada/proj with two files, a docs directory, a nested lib
# directory, and hidden entries.
def disk
  files = Carat::Doubles::MemoryFiles.new
  files.move_to(ROOT)
  files.put("a.md", "alpha\n")
  files.put("b.rb", "puts 1\n")
  files.put("docs/guide.md", "guide\n")
  files.put("lib/deep/x.rb", "x\n")
  files.put(".env", "K=1\n")
  files.put(".git/HEAD", "ref\n")
  files
end

def config_with(icons)
  config = Carat::Doubles::FixedConfig.defaults
  config["options"]["icons"] = icons
  config
end

# An editor with the registry's plugins over the disk, on path, with the
# given configuration.
def editor_on(path, config)
  h = Carat::Doubles::EditorHarness.new(files: disk, config: config, rows: 24, cols: 80, plugins: Carat::Plugins::Registry.all)
  h.open(path)
  h
end

def session(keys)
  h = editor_on("a.md", config_with("ascii"))
  h.type(keys)
  h
end

# The lines of the tree's buffer, [] when it is not listed.
def tree_lines(h)
  s = h.assembly.buffers
  i = 0
  while i < s.count
    b = s.buffer_at(i)
    return b.lines if b.title == "explorer"
    i += 1
  end
  []
end

# Every window as [col, columns, name].
def shape(h)
  layout = h.state.tab.layout
  out = []
  layout.leaves.each do |id|
    w = layout.window_at(id)
    name = w.buffer.display_name
    out << [w.col, w.width, name.nil? ? "" : name]
  end
  out
end

TREE = [" - proj", "   + docs", "   + lib", ">  m a.md", "   r b.rb"]
OPEN = [[0, 30, "explorer"], [31, 49, "a.md"]]

# Opening, focusing, and closing: rows are [label, keys, [windows, current
# window, cursor]].
t.table([
  ["<leader>e opens the tree at the left, focused on the current file", " e", [OPEN, 1, [3, 0]]],
  ["<leader>e from the file window focuses the tree", " e<C-w>l e", [OPEN, 1, [3, 0]]],
  ["<leader>e in the tree closes it", " e e", [[[0, 80, "a.md"]], 1, [0, 0]]],
  [":Explorer opens the tree", ":Explorer<CR>", [OPEN, 1, [3, 0]]],
  [":Explorer twice closes it", ":Explorer<CR>:Explorer<CR>", [[[0, 80, "a.md"]], 1, [0, 0]]],
  ["q closes the tree", " eq", [[[0, 80, "a.md"]], 1, [0, 0]]],
  [":q in the tree closes only the tree", " e:q<CR>", [[[0, 80, "a.md"]], 1, [0, 0]]],
  ["Ctrl-W l and h move out of the tree and back", " e<C-w>l", [OPEN, 2, [0, 0]]],
  ["Ctrl-W h returns to the tree", " e<C-w>l<C-w>h", [OPEN, 1, [3, 0]]],
  ["Ctrl-W = leaves the tree's width alone", " e<C-w>l<C-w>v<C-w>=", [[[0, 30, "explorer"], [31, 24, "a.md"], [56, 24, "a.md"]], 2, [0, 0]]],
  ["j and k fall through to the normal keymap", " eggj", [OPEN, 1, [1, 0]]],
  ["G falls through too", " eG", [OPEN, 1, [4, 0]]]
]) do |keys|
  h = session(keys)
  [shape(h), h.window_index, h.cursor]
end

h = session(" e")
t.assert_equal(TREE, tree_lines(h), "the root, the directories, then the files, the current file marked")
t.assert_equal(["explorer", "30"], [h.status_row[0, 8], h.plugins.option("explorer", "width")], "the tree's status line shows its title and the width option is 30")
h.type("<C-w>l:q<CR>")
t.assert_equal(true, h.quit?, "quitting the last file window ends the editor with the tree open")

# The configuration: the right side, and disabled.
config = config_with("ascii")
config["plugins"]["explorer"]["options"]["side"] = "right"
h = editor_on("a.md", config)
h.type(" e")
t.assert_equal([[[0, 49, "a.md"], [50, 30, "explorer"]], 2], [shape(h), h.window_index], "the side option puts the tree at the right")
config = config_with("ascii")
config["plugins"]["explorer"] = { "enabled" => false }
h = editor_on("a.md", config)
h.type(" e:Explorer<CR>")
t.assert_equal([1, "E492: Not an editor command: Explorer"], [h.window_count, h.message], "a disabled explorer opens nothing")
config = config_with("ascii")
config["plugins"]["explorer"]["options"]["show_hidden"] = true
h = editor_on("a.md", config)
h.type(" e")
t.assert_equal("   . .env", tree_lines(h)[3], "show_hidden lists dot files but not ignored names")

# Follow: the current file is revealed and marked.
h = editor_on("lib/deep/x.rb", config_with("ascii"))
h.type(" e")
t.assert_equal([[" - proj", "   + docs", "   - lib", "     - deep", ">      r x.rb", "   m a.md", "   r b.rb"], [4, 0]], [tree_lines(h), h.cursor], "the directories above the current file are expanded on open and the cursor is on it")
h = session(" e<C-w>l:e docs/guide.md<CR>")
t.assert_equal([" - proj", "   - docs", ">    m guide.md", "   + lib", "   m a.md", "   r b.rb"], tree_lines(h), "the tree follows another file")
h.type(":e b.rb<CR>")
t.assert_equal(">  r b.rb", tree_lines(h)[5], "and the next one")
h = session(" e<C-w>l:e lib/deep/x.rb<CR><C-w>hggjjh<C-w>l:ExplorerFind<CR>")
t.assert_equal([1, [4, 0], "     - deep"], [h.window_index, h.cursor, tree_lines(h)[3]], ":ExplorerFind reveals the current file, focuses the tree, and puts the cursor on it")
h = session(":ExplorerFind<CR>")
t.assert_equal([1, [3, 0], 2], [h.window_index, h.cursor, h.window_count], ":ExplorerFind opens a closed tree")

# Opening files and directories: rows are [label, keys, [windows, current
# window, tab pages, current buffer, message]].
t.table([
  ["Enter opens the file in the editing window", " ej<CR>", [[[0, 30, "explorer"], [31, 49, "b.rb"]], 2, 1, "b.rb", "\"b.rb\" 1L, 7B"]],
  ["l opens it too", " ejl", [[[0, 30, "explorer"], [31, 49, "b.rb"]], 2, 1, "b.rb", "\"b.rb\" 1L, 7B"]],
  ["o on a file opens it too", " ejo", [[[0, 30, "explorer"], [31, 49, "b.rb"]], 2, 1, "b.rb", "\"b.rb\" 1L, 7B"]],
  ["s opens it in a horizontal split", " ejs", [[[0, 30, "explorer"], [31, 49, "b.rb"], [31, 49, "a.md"]], 2, 1, "b.rb", "\"b.rb\" 1L, 7B"]],
  ["v opens it in a vertical split", " ejv", [[[0, 30, "explorer"], [31, 24, "b.rb"], [56, 24, "a.md"]], 2, 1, "b.rb", "\"b.rb\" 1L, 7B"]],
  ["t opens it in a new tab page", " ejt", [[[0, 80, "b.rb"]], 1, 2, "b.rb", "\"b.rb\" 1L, 7B"]],
  ["s on a directory does nothing", " eggjs", [OPEN, 1, 1, "explorer", ""]],
  ["with only the tree left the file gets a new window", " e<C-w>l<C-w>cj<CR>", [[[0, 30, "explorer"], [31, 49, "b.rb"]], 2, 1, "b.rb", "\"b.rb\" 1L, 7B"]]
]) do |keys|
  h = session(keys)
  name = h.buffer.display_name
  [shape(h), h.window_index, h.tab_count, name.nil? ? "" : name, h.message]
end
h = session(" e<C-w>l<C-w>v<C-w>l1<C-w>wj<CR>")
t.assert_equal([3, "b.rb", "a.md"], [h.window_index, h.state.tab.layout.window_at(h.state.tab.layout.leaves[2]).buffer.path, h.state.tab.layout.window_at(h.state.tab.layout.leaves[1]).buffer.path], "Enter opens in the window used before the tree")
h = session(" e<C-w>l<C-w>cj<CR>")
t.assert_equal([true, false], [h.state.tab.layout.window_at(h.state.tab.layout.leaves[0]).fixed_width, h.state.window.fixed_width], "the new tree is fixed-width and the file window is not")

# Directories: rows are [label, keys, [tree lines, cursor]].
t.table([
  ["Enter expands a directory", " eggj<CR>", [[" - proj", "   - docs", "     m guide.md", "   + lib", ">  m a.md", "   r b.rb"], [1, 0]]],
  ["l expands it too", " eggjl", [[" - proj", "   - docs", "     m guide.md", "   + lib", ">  m a.md", "   r b.rb"], [1, 0]]],
  ["Enter leaves an expanded directory expanded", " eggj<CR><CR>", [[" - proj", "   - docs", "     m guide.md", "   + lib", ">  m a.md", "   r b.rb"], [1, 0]]],
  ["o toggles it closed again", " eggjoo", [TREE, [1, 0]]],
  ["h collapses an expanded directory", " eggjlh", [TREE, [1, 0]]],
  ["h on a file goes to its parent", " eggjljh", [[" - proj", "   - docs", "     m guide.md", "   + lib", ">  m a.md", "   r b.rb"], [1, 0]]],
  ["h on a top-level entry goes to the root line", " eh", [TREE, [0, 0]]],
  ["h on the root line does nothing", " eggh", [TREE, [0, 0]]],
  ["Enter on the root line does nothing", " egg<CR>", [TREE, [0, 0]]],
  ["H shows hidden files but not ignored ones", " eH", [[" - proj", "   + docs", "   + lib", "   . .env", ">  m a.md", "   r b.rb"], [3, 0]]],
  ["H again hides them", " eHH", [TREE, [3, 0]]],
  ["- moves the root up and keeps the old root expanded", " e-", [[" - ada", "   - proj", "     + docs", "     + lib", ">    m a.md", "     r b.rb"], [1, 0]]],
  ["C makes the directory under the cursor the root", " eggjC", [[" - docs", "   m guide.md"], [0, 0]]],
  ["C on a file makes its directory the root", " eC", [TREE, [0, 0]]]
]) do |keys|
  h = session(keys)
  [tree_lines(h), h.cursor]
end

h = session(" e")
h.files.put("z.rb", "")
h.type("R")
t.assert_equal("   r z.rb", tree_lines(h)[5], "R lists the directories again")
h.type("?")
t.assert_equal("<CR>/l open", h.message[0, 11], "? shows the keys in the message row")

# Create: rows are [label, keys, [tree lines, cursor, message, mode]].
t.table([
  ["a on the root line creates a file there", " egga" + "new.rb<CR>", [[" - proj", "   + docs", "   + lib", ">  m a.md", "   r b.rb", "   r new.rb"], [5, 0], "Created new.rb", :normal]],
  ["a trailing slash creates a directory", " egga" + "pkg/<CR>", [[" - proj", "   + docs", "   + lib", "   + pkg", ">  m a.md", "   r b.rb"], [3, 0], "Created pkg", :normal]],
  ["a on a directory creates inside it", " eggja" + "n.md<CR>", [[" - proj", "   - docs", "     m guide.md", "     m n.md", "   + lib", ">  m a.md", "   r b.rb"], [3, 0], "Created docs/n.md", :normal]],
  ["a on a file creates next to it", " ea" + "c.c<CR>", [[" - proj", "   + docs", "   + lib", ">  m a.md", "   r b.rb", "   c c.c"], [5, 0], "Created c.c", :normal]],
  ["Escape cancels", " ea" + "x<Esc>", [TREE, [3, 0], "", :normal]],
  ["an empty name creates nothing", " ea<CR>", [TREE, [3, 0], "", :normal]],
  ["an existing name is refused", " ea" + "b.rb<CR>", [TREE, [3, 0], "Already exists: b.rb", :normal]],
  ["a name leaving the root is refused", " egga" + "../x.rb<CR>", [TREE, [0, 0], "Outside the tree root: /home/ada/x.rb", :normal]]
]) do |keys|
  h = session(keys)
  [tree_lines(h), h.cursor, h.message, h.mode]
end
h = session(" egga")
t.assert_equal("Create in proj/: ", h.message_row.rstrip + " ", "the prompt names the directory")
h = session(" egga" + "pkg/<CR>")
t.assert_equal([true, nil], [h.files.directory?("pkg"), h.files.get("pkg")], "the directory exists on disk and no file was made")
h = session(" ea" + "b.rb<CR>")
t.assert_equal(true, h.state.message_error, "a refusal is an error")

# Rename.
h = session(" ej<CR><C-w>hr")
t.assert_equal("Rename to: b.rb", h.message_row.rstrip, "the prompt starts with the current name")
h.type("<BS><BS><BS><BS>c.rb<CR>")
t.assert_equal([nil, "puts 1\n", ["", "c.rb"], "Renamed b.rb to c.rb"], [h.files.get("b.rb"), h.files.get("c.rb"), h.buffer_paths, h.message], "a rename changes the disk and the open buffer follows")
t.assert_equal([">  r c.rb", [4, 0]], [tree_lines(h)[4], h.cursor], "the tree lists the new name, still marked, with the cursor on it")
h = session(" er<BS><BS><BS><BS>x/y.md<CR>")
t.assert_equal(["Name contains a path separator: x/y.md", "alpha\n"], [h.message, h.files.get("a.md")], "a separator is refused")
h = session(" eggr")
t.assert_equal(["Cannot rename the root", :normal], [h.message, h.mode], "the root is not renamed")
h = session(" er<Esc>")
t.assert_equal(["", "alpha\n"], [h.message, h.files.get("a.md")], "Escape renames nothing")

# Delete.
h = session(" ejd")
t.assert_equal("Delete b.rb? (y/n): ", h.message_row.rstrip + " ", "the confirmation names the entry")
h.type("y<CR>")
t.assert_equal([false, ["   + lib", ">  m a.md"], "Deleted b.rb"], [h.files.exist?("b.rb"), tree_lines(h)[2, 2], h.message], "yes deletes the file")
t.assert_equal(4, tree_lines(h).length, "and it is no longer listed")
t.table([
  ["n declines", " ejd" + "n<CR>", [true, "Delete cancelled"]],
  ["Escape declines", " ejd<Esc>", [true, "Delete cancelled"]],
  ["YES confirms", " ejd" + "YES<CR>", [false, "Deleted b.rb"]]
]) do |keys|
  h = session(keys)
  [h.files.exist?("b.rb"), h.message]
end
h = session(" eggjd" + "y<CR>")
t.assert_equal([true, "Directory not empty: docs", true], [h.files.exist?("docs/guide.md"), h.message, h.state.message_error], "a directory with entries is refused")
h = session(" ed" + "y<CR>")
t.assert_equal([false, ["a.md", ""], true], [h.files.exist?("a.md"), h.buffer_paths, h.assembly.buffers.buffer_at(0).modified?], "deleting the open file keeps its buffer, modified")
h.type("<C-w>l:q<CR>")
t.assert_equal([false, "E37: No write since last change (add ! to override)"], [h.quit?, h.message], "and :q asks for a write")
h = session(" eggd")
t.assert_equal(["Cannot delete the root", :normal], [h.message, h.mode], "the root is not deleted")

# The tree window in every icon set, as the presenter draws it.
t.table([
  ["ascii", "ascii", [" - proj", "   + docs", "   + lib", ">  m a.md", "   r b.rb"]],
  ["unicode", "unicode", [" ▾ proj", "   ▸ docs", "   ▸ lib", "›  ¶ a.md", "   ◈ b.rb"]],
  ["nerd", "nerd", [" \u{F07C} proj", "   \u{F07B} docs", "   \u{F07B} lib", "\u{F054}  \u{E73E} a.md", "   \u{E791} b.rb"]]
]) do |set|
  h = editor_on("a.md", config_with(set))
  h.type(" e")
  rows = []
  i = 0
  while i < 5
    rows << h.row(i)[0, 30].rstrip
    i += 1
  end
  rows
end
h = editor_on("a.md", config_with("ascii"))
h.type(" e")
t.assert_equal(["│", "~"], [h.row(0)[30, 1], h.row(5)[0, 1]], "the tree has no line numbers and a separator at its right")

# Names with a space or a bar open as named, never parsed as an ex
# command line.
h = session(" e")
h.files.put("my notes.md", "spaced\n")
h.files.put("a|b.md", "barred\n")
h.type("R")
t.assert_equal(["   m a|b.md", "   m my notes.md"], [tree_lines(h)[4], tree_lines(h)[6]], "the tree lists both names")
h.type("7Gs")
t.assert_equal([3, "my notes.md", ["spaced"]], [h.window_count, h.buffer.path, h.lines], "s opens a name with a space in a split")
h = session(" e")
h.files.put("a|b.md", "barred\n")
h.type("R5Gt")
t.assert_equal([2, "a|b.md", ["barred"]], [h.tab_count, h.buffer.path, h.lines], "t opens a name with a bar in a tab page")
h = session(" e")
h.files.put("my notes.md", "spaced\n")
h.type("R6Gv")
t.assert_equal([3, "my notes.md", ["spaced"]], [h.window_count, h.buffer.path, h.lines], "v opens a name with a space in a vertical split")

t.finish
