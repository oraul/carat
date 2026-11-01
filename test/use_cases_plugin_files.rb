require_relative "../carat/test_support"
require_relative "../carat/testing"

t = Carat::Testing.new("use_cases_plugin_files")
P = Carat::PluginApi::Paths

# A test plugin that keeps its host and records every input it receives.
class Fs < Carat::PluginApi::Plugin
  attr_reader :inputs #: Array[String]

  # @rbs @link: Carat::PluginApi::Host?

  #: () -> void
  def initialize
    @link = nil
    @inputs = []
  end

  # Returns the manifest.
  # @rbs skip
  def manifest
    Carat::PluginApi::Manifest.new("fs", "1.0.0", "1.2", { "plugin.fs.list" => "Open the list" }, {}, { "normal" => { "<leader>fl" => "plugin.fs.list" } }, [], {}, {})
  end

  #: (Carat::PluginApi::Host) -> void
  def activate(host)
    @link = host
  end

  #: (String, Carat::PluginApi::Context) -> void
  def on_action(name, context)
    host.open_scratch("list", "left", 20, ["x", "y"], nil)
  end

  #: (Carat::PluginApi::Input) -> void
  def on_input(input)
    @inputs << "#{input.id} #{input.text.inspect} #{input.cancelled}"
  end

  # The host as never nil.
  #: () -> Carat::PluginApi::Host
  def host
    h = @link
    h.nil? ? Carat::PluginApi::Host.new : h
  end
end

# A file system under /w: a.txt, b.txt, lib/x.rb, and the empty
# directory empty; the editor runs there on a.txt with the fs plugin.
def editor
  files = Carat::Doubles::MemoryFiles.new
  files.move_to("/w")
  files.put("a.txt", "one\n")
  files.put("b.txt", "two\n")
  files.put("lib/x.rb", "x\n")
  files.mkdir("/w/empty")
  plugin = Fs.new
  h = Carat::Doubles::EditorHarness.with_plugins(files, 24, 80, [plugin])
  h.open("a.txt")
  [h, plugin]
end

# Paths: rows are [label, value, expected].
t.table([
  ["normalize resolves dot and dot-dot", P.normalize("/w/./lib/../a.txt"), "/w/a.txt"],
  ["normalize stops at the root", P.normalize("/../../etc"), "/etc"],
  ["normalize keeps a leading dot-dot of a relative path", P.normalize("../x//y/"), "../x/y"],
  ["join adds one slash", P.join("/w", "a"), "/w/a"],
  ["join after the root", P.join("/", "a"), "/a"],
  ["dirname of a root entry", P.dirname("/a"), "/"],
  ["dirname of a bare name", P.dirname("a"), "."],
  ["basename", P.basename("/w/lib/x.rb"), "x.rb"],
  ["absolute resolves against the working directory", P.absolute("/w", "lib/../b.txt"), "/w/b.txt"],
  ["relative below the working directory", P.relative("/w", "/w/lib/x.rb"), "lib/x.rb"],
  ["relative outside it stays absolute", P.relative("/w", "/v/x"), "/v/x"],
  ["inside is strict", [P.inside?("/w", "/w/a"), P.inside?("/w", "/w"), P.inside?("/w", "/wx/a"), P.inside?("/", "/a")], [true, false, false, true]]
]) do |value|
  value
end

# The in-memory file system lists entry names and knows directories.
files = Carat::Doubles::MemoryFiles.new
files.move_to("/w")
files.put("lib/x.rb", "x")
files.put("b.txt", "b")
files.put("a.txt", "a")
t.assert_equal(["a.txt", "b.txt", "lib"], files.list("/w"), "list answers the sorted entry names")
t.assert_equal([true, true, false], [files.exist?("lib"), files.directory?("/w/lib"), files.directory?("a.txt")], "putting a file makes its directories")
t.assert_raises(ArgumentError, "listing a missing directory raises") { files.list("/nope") }
t.assert_raises(ArgumentError, "deleting a non-empty directory raises") { files.delete("lib") }
t.assert_raises(ArgumentError, "making an existing directory raises") { files.mkdir("lib") }
files.rename("lib", "src")
t.assert_equal([nil, "x"], [files.get("lib/x.rb"), files.get("src/x.rb")], "renaming a directory moves what is under it")
files.link("src")
t.assert_equal(true, files.stat("src").symlink, "a path marked as a link stats as one")

h, fs = editor
host = fs.host

# Working directory and window ids.
t.assert_equal("/w", host.working_directory.text, "the working directory is absolute")
t.assert_equal([0, 1], [host.scratch_window("list").window, host.editing_window.window], "no list is shown and the first window, id 1, edits a file")
h.type(" fl")
t.assert_equal([2, 1, 0], [host.scratch_window("list").window, host.editing_window.window, host.scratch_window("nope").window], "the list is window id 2 and the previously used window, id 1, edits")
h.type("<C-w>l<C-w>c")
t.assert_equal([1, 0], [h.window_count, host.editing_window.window], "with only the list left nothing edits")

# Creating files and directories.
h, fs = editor
host = fs.host
files = h.files
t.table([
  ["a file", host.make_file("/w", "/w/new.rb"), [true, ""]],
  ["a directory", host.make_dir("/w", "/w/pkg"), [true, ""]],
  ["a file in a subdirectory", host.make_file("/w", "/w/lib/y.rb"), [true, ""]],
  ["a relative path resolves against the working directory", host.make_file("/w", "lib/z.rb"), [true, ""]],
  ["outside the root", host.make_file("/w", "/w/../etc/x"), [false, "Outside the tree root: /etc/x"]],
  ["the root itself", host.make_dir("/w", "/w/lib/.."), [false, "Empty name"]],
  ["below a root that is not the working directory", host.make_file("/w/lib", "/w/a2.txt"), [false, "Outside the tree root: a2.txt"]],
  ["an empty name", host.make_file("/w", "/w/lib/"), [false, "Empty name"]],
  ["an existing file", host.make_file("/w", "/w/a.txt"), [false, "Already exists: a.txt"]],
  ["an existing directory", host.make_dir("/w", "/w/lib"), [false, "Already exists: lib"]],
  ["a missing parent", host.make_file("/w", "/w/no/x.rb"), [false, "No such directory: no"]]
]) do |r|
  [r.ok, r.message]
end
t.assert_equal(["", true, "", ""], [files.get("/w/new.rb"), files.directory?("/w/pkg"), files.get("/w/lib/y.rb"), files.get("/w/lib/z.rb")], "the created entries exist")
t.assert_equal([false, false, false], [files.exist?("/etc/x"), files.exist?("/w/a2.txt"), files.exist?("/w/no")], "the refused ones do not")

# Renaming.
h, fs = editor
host = fs.host
files = h.files
t.table([
  ["an empty name", host.rename_path("/w", "/w/b.txt", ""), [false, "Empty name"]],
  ["a path separator", host.rename_path("/w", "/w/b.txt", "x/c.txt"), [false, "Name contains a path separator: x/c.txt"]],
  ["dot-dot", host.rename_path("/w", "/w/b.txt", ".."), [false, "Invalid name: .."]],
  ["outside the root", host.rename_path("/w", "/w/../b.txt", "c.txt"), [false, "Outside the tree root: /b.txt"]],
  ["the root", host.rename_path("/w", "/w", "v"), [false, "Outside the tree root: /w"]],
  ["a missing entry", host.rename_path("/w", "/w/nope", "c.txt"), [false, "No such file or directory: nope"]],
  ["an existing target", host.rename_path("/w", "/w/b.txt", "a.txt"), [false, "Already exists: a.txt"]],
  ["a file", host.rename_path("/w", "/w/b.txt", "c.txt"), [true, ""]]
]) do |r|
  [r.ok, r.message]
end
t.assert_equal([nil, "two\n", "one\n"], [files.get("b.txt"), files.get("c.txt"), files.get("a.txt")], "only the accepted rename changed the disk")
r = host.rename_path("/w", "/w/a.txt", "d.txt")
t.assert_equal([true, "d.txt", false], [r.ok, h.buffer.path, h.buffer.modified?], "the open buffer follows a renamed file")
h.type(":e lib/x.rb<CR>")
r = host.rename_path("/w", "lib", "src")
t.assert_equal([true, "src/x.rb", "x\n"], [r.ok, h.buffer.path, files.get("src/x.rb")], "a buffer under a renamed directory follows it")
h.type(":e /w/src/x.rb<CR>")
host.rename_path("/w", "/w/src", "lib")
t.assert_equal("/w/lib/x.rb", h.buffer.path, "an absolute path stays absolute")

# Deleting.
h, fs = editor
host = fs.host
files = h.files
t.table([
  ["outside the root", host.delete_path("/w", "/w/../etc"), [false, "Outside the tree root: /etc"]],
  ["the root", host.delete_path("/w", "/w"), [false, "Outside the tree root: /w"]],
  ["a missing entry", host.delete_path("/w", "/w/nope"), [false, "No such file or directory: nope"]],
  ["a non-empty directory", host.delete_path("/w", "/w/lib"), [false, "Directory not empty: lib"]],
  ["an empty directory", host.delete_path("/w", "/w/empty"), [true, ""]],
  ["a file", host.delete_path("/w", "/w/b.txt"), [true, ""]]
]) do |r|
  [r.ok, r.message]
end
t.assert_equal([true, false, false], [files.exist?("/w/lib/x.rb"), files.exist?("/w/empty"), files.exist?("/w/b.txt")], "only the accepted deletes changed the disk")
host.delete_path("/w", "/w/a.txt")
t.assert_equal([["a.txt"], true, ["one"]], [h.buffer_paths, h.buffer.modified?, h.lines], "the open buffer of a deleted file stays and becomes modified")
h.type(":q<CR>")
t.assert_equal([false, "E37: No write since last change (add ! to override)"], [h.quit?, h.message], "and quitting asks for a write")

# Symbolic links through stat.
h, fs = editor
h.files.link("/w/lib")
info = fs.host.stat("/w/lib")
t.assert_equal([true, true, true], [info.ok, info.directory, info.symlink], "a link to a directory stats as both")

# The prompt.
h, fs = editor
r = fs.host.prompt("ask", "Name: ", "a")
h.type("bc")
t.assert_equal([true, :cmdline, "Name: abc"], [r.ok, h.mode, h.message_row.rstrip], "the prompt shows its text and the edited value")
t.assert_equal([23, 9], [h.frame.cursor_row, h.frame.cursor_col], "the cursor is after the value")
t.assert_equal(false, fs.host.prompt("again", "x", "").ok, "a second prompt is refused while one is open")
h.type("<CR>")
t.assert_equal([["ask \"abc\" false"], :normal, ""], [fs.inputs, h.mode, h.message], "Enter delivers the text")
fs.host.prompt("ask", "Name: ", "")
h.type("<Esc>")
t.assert_equal(["ask \"\" true", :normal], [fs.inputs[1], h.mode], "Escape delivers a cancel")
fs.host.prompt("ask", "Name: ", "z")
h.type("<BS><BS>")
t.assert_equal(["ask \"\" true", :normal], [fs.inputs[2], h.mode], "a backspace on an empty line cancels")
fs.host.prompt("ask", "Name: ", "")
h.type("q<CR>")
t.assert_equal([false, "ask \"q\" false"], [h.quit?, fs.inputs[3]], "the text is not run as an ex command")
h.type(":q<CR>")
t.assert_equal([true, 4], [h.quit?, fs.inputs.length], "the next command line is an ex command again")

t.finish
