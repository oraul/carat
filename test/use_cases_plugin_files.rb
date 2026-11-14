require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module UseCasesPluginFilesTest
  P = Carat::PluginApi::Paths

  # A test plugin that keeps its host and records every input it
  # receives, every change of a live prompt, and every action but list.
  class Fs < Carat::PluginApi::Plugin
    attr_reader :inputs #: Array[String]
    attr_reader :changes #: Array[String]
    attr_reader :actions #: Array[String]

    # @rbs @link: Carat::PluginApi::Host?

    #: () -> void
    def initialize
      @link = nil
      @inputs = []
      @changes = []
      @actions = []
    end

    # Returns the manifest.
    # @rbs skip
    def manifest
      Carat::PluginApi::Manifest.new(name: "fs", version: "1.0.0", api_version: "2.0", actions: { "plugin.fs.list" => "Open the list", "plugin.fs.next" => "Next", "plugin.fs.close" => "Close the prompt" }, commands: {}, bindings: ["keymap.normal <leader>fl plugin.fs.list"], events: [], options: [], option_types: {}, filetypes: [])
    end

    #: (Carat::PluginApi::Host) -> void
    def activate(host)
      @link = host
    end

    #: (String, Carat::PluginApi::Context) -> void
    def on_action(name, context)
      if name == "plugin.fs.list"
        host.open_scratch("list", "left", 20, ["x", "y"], nil)
        return
      end
      @actions << "#{name} #{context.count}"
      host.close_prompt if name == "plugin.fs.close"
    end

    #: (Carat::PluginApi::Input) -> void
    def on_prompt_change(input)
      @changes << "#{input.id} #{input.text}"
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

  # What editor builds. An object, not an array: destructured from an
  # array inside a method, the two values lost their types on the pinned
  # Spinel.
  class Session
    attr_reader :harness #: Carat::Doubles::EditorHarness
    attr_reader :plugin #: Fs

    #: (Carat::Doubles::EditorHarness, Fs) -> void
    def initialize(harness, plugin)
      @harness = harness
      @plugin = plugin
    end
  end

  # A file system under /w: a.txt, b.txt, lib/x.rb, and the empty
  # directory empty; the editor runs there on a.txt with the fs plugin.
  def self.editor
    files = Carat::Doubles::MemoryFiles.new
    files.move_to("/w")
    files.put("a.txt", "one\n")
    files.put("b.txt", "two\n")
    files.put("lib/x.rb", "x\n")
    files.mkdir("/w/empty")
    plugin = Fs.new
    h = Carat::Doubles::EditorHarness.with_plugins(files, 24, 80, [plugin])
    h.open("a.txt")
    Session.new(h, plugin)
  end

  def self.main
    t = Carat::Testing.new("use_cases_plugin_files")

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

    session = editor

    h, fs = session.harness, session.plugin
    host = fs.host

    # Working directory and window ids.
    t.assert_equal("/w", host.working_directory.text, "the working directory is absolute")
    t.assert_equal([0, 1], [host.scratch_window("list").window, host.editing_window.window], "no list is shown and the first window, id 1, edits a file")
    h.type(" fl")
    t.assert_equal([2, 1, 0], [host.scratch_window("list").window, host.editing_window.window, host.scratch_window("nope").window], "the list is window id 2 and the previously used window, id 1, edits")
    h.type("<C-w>l<C-w>c")
    t.assert_equal([1, 0], [h.window_count, host.editing_window.window], "with only the list left nothing edits")

    # Creating files and directories.
    session = editor
    h, fs = session.harness, session.plugin
    host = fs.host
    files = h.files
    files.mkdir("/elsewhere")
    files.mkdir("/w/out")
    files.link_to("/w/out", "/elsewhere")
    files.mkdir("/w/alias")
    files.link_to("/w/alias", "/w/lib")
    files.mkdir("/r")
    files.mkdir("/real")
    files.link_to("/r", "/real")
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
      ["a missing parent", host.make_file("/w", "/w/no/x.rb"), [false, "No such directory: no"]],
      ["a file below a link leading out of the root", host.make_file("/w", "/w/out/x.rb"), [false, "Outside the tree root: out/x.rb"]],
      ["a directory below a link leading out of the root", host.make_dir("/w", "/w/out/pkg"), [false, "Outside the tree root: out/pkg"]],
      ["a file below a link that stays inside", host.make_file("/w", "/w/alias/x.rb"), [true, ""]],
      ["a file below a linked root", host.make_file("/r", "/r/new.rb"), [true, ""]]
    ]) do |r|
      [r.ok, r.message]
    end
    t.assert_equal(["", true, "", ""], [files.get("/w/new.rb"), files.directory?("/w/pkg"), files.get("/w/lib/y.rb"), files.get("/w/lib/z.rb")], "the created entries exist")
    t.assert_equal([false, false, false, false, false], [files.exist?("/etc/x"), files.exist?("/w/a2.txt"), files.exist?("/w/no"), files.exist?("/w/out/x.rb"), files.exist?("/w/out/pkg")], "the refused ones do not")

    # Renaming.
    session = editor
    h, fs = session.harness, session.plugin
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
    session = editor
    h, fs = session.harness, session.plugin
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

    # Renaming and deleting through links: "/w/out" and "/w/ext" lead out
    # of the root, "/w/alias" stays inside it, and the root "/r" is a link.
    session = editor
    h, fs = session.harness, session.plugin
    host = fs.host
    files = h.files
    files.mkdir("/elsewhere")
    files.put("/elsewhere/x.rb", "out\n")
    files.mkdir("/w/out")
    files.put("/w/out/x.rb", "out\n")
    files.link_to("/w/out", "/elsewhere")
    files.mkdir("/w/ext")
    files.link_to("/w/ext", "/elsewhere")
    files.mkdir("/w/alias")
    files.put("/w/alias/x.rb", "in\n")
    files.link_to("/w/alias", "/w/lib")
    files.mkdir("/real")
    files.mkdir("/r")
    files.put("/r/a.rb", "r\n")
    files.link_to("/r", "/real")
    t.table([
      ["a rename below a link leading out of the root", host.rename_path("/w", "/w/out/x.rb", "y.rb"), [false, "Outside the tree root: out/x.rb"]],
      ["a delete below a link leading out of the root", host.delete_path("/w", "/w/out/x.rb"), [false, "Outside the tree root: out/x.rb"]],
      ["a missing entry below a link leading out keeps its message", host.delete_path("/w", "/w/out/nope.rb"), [false, "No such file or directory: out/nope.rb"]],
      ["a rename below a link that stays inside", host.rename_path("/w", "/w/alias/x.rb", "y.rb"), [true, ""]],
      ["a delete below a link that stays inside", host.delete_path("/w", "/w/alias/y.rb"), [true, ""]],
      ["a rename below a linked root", host.rename_path("/r", "/r/a.rb", "b.rb"), [true, ""]],
      ["a delete below a linked root", host.delete_path("/r", "/r/b.rb"), [true, ""]],
      ["a rename of the link leading out itself", host.rename_path("/w", "/w/ext", "away"), [true, ""]],
      ["a delete of the link leading out itself", host.delete_path("/w", "/w/away"), [true, ""]]
    ]) do |r|
      [r.ok, r.message]
    end
    t.assert_equal(["out\n", "out\n", false, true, false, false, false], [files.get("/w/out/x.rb"), files.get("/elsewhere/x.rb"), files.exist?("/w/out/y.rb"), files.directory?("/elsewhere"), files.exist?("/w/alias/y.rb"), files.exist?("/r/b.rb"), files.exist?("/w/away")], "nothing below a link leading out changed, and the accepted ones did")

    # Symbolic links through stat.
    session = editor
    h, fs = session.harness, session.plugin
    h.files.link("/w/lib")
    info = fs.host.stat("/w/lib")
    t.assert_equal([true, true, true], [info.ok, info.directory, info.symlink], "a link to a directory stats as both")

    # The prompt.
    session = editor
    h, fs = session.harness, session.plugin
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

    # list_files and read_file (API 2.5).
    session = editor
    h, fs = session.harness, session.plugin
    files = h.files
    files.put(".git/HEAD", "ref\n")
    files.put("lib/deep/c.rb", "c\n")
    files.put("/elsewhere/x.rb", "out\n")
    files.put("out.rb", "")
    files.link_to("/w/out.rb", "/elsewhere/x.rb")
    files.put("in.rb", "")
    files.link_to("/w/in.rb", "/w/a.txt")
    files.put("alias/x.rb", "x\n")
    files.link_to("/w/alias", "/w/lib")
    files.put("three.txt", "one\r\ntwo\nthree\n")
    t.table([
      # list_files lists the files below the root, list_files skips ignored names, list_files skips a link that leaves the root, list_files does not enter a linked directory
      ["list_files lists the files below the root", fs.host.list_files("/w", [".git"]), [true, "", ["a.txt", "b.txt", "in.rb", "lib/deep/c.rb", "lib/x.rb", "three.txt"]]],
      ["list_files skips ignored names", fs.host.list_files("/w/lib", ["deep"]), [true, "", ["x.rb"]]],
      ["without an ignore list the .git files are listed", fs.host.list_files("/w/.git", []), [true, "", ["HEAD"]]],
      ["list_files fails for a missing root", fs.host.list_files("/nowhere", []), [false, "No such file or directory: /nowhere", []]],
      ["read_file answers the first rows", fs.host.read_file("/w/three.txt", 2), [true, "", ["one", "two"]]],
      ["read_file answers fewer rows of a short file", fs.host.read_file("/w/three.txt", 9), [true, "", ["one", "two", "three"]]],
      ["read_file refuses a directory", fs.host.read_file("/w/lib", 2), [false, "Is a directory", []]],
      ["read_file refuses no rows", fs.host.read_file("/w/a.txt", 0), [false, "rows must be 1 to 1000", []]],
      ["read_file refuses a missing file", fs.host.read_file("/w/none.txt", 2).ok, false]
    ]) do |r|
      r.is_a?(Carat::PluginApi::Response) ? [r.ok, r.message, r.lines] : r
    end
    files.put("binary.bin", "a\n\x80b\n")
    r = fs.host.read_file("/w/binary.bin", 2)
    t.assert_equal([true, ["a", "\x80b"]], [r.ok, r.lines], "read_file reads a line that starts with a continuation byte")

    # The live prompt and close_prompt (API 2.5).
    session = editor
    h, fs = session.harness, session.plugin
    r = fs.host.live_prompt("live", "> ", "", ["keymap.cmdline <C-n> plugin.fs.next", "keymap.cmdline <C-x> plugin.fs.close"])
    h.type("ab")
    t.assert_equal([true, :cmdline, ["live a", "live ab"], "> ab"], [r.ok, h.mode, fs.changes, h.message_row.rstrip], "a live prompt delivers each changed text")
    h.type("<C-n>")
    t.assert_equal([["plugin.fs.next 0"], :cmdline, 2], [fs.actions, h.mode, fs.changes.length], "a live prompt's binding runs the plugin's action")
    t.assert_equal(false, fs.host.live_prompt("again", "x", "", []).ok, "a second live prompt is refused while one is open")
    h.type("<BS>")
    t.assert_equal("live a", fs.changes[2], "a backspace is a change")
    h.type("x<CR>")
    t.assert_equal([["live \"ax\" false"], :normal], [fs.inputs, h.mode], "Enter ends a live prompt with an answer")
    h.type(":")
    t.assert_equal(:cmdline, h.mode, "the next command line is an ex command again")
    h.type("<C-n><Esc>")
    t.assert_equal(1, fs.actions.length, "its bindings went with it")
    fs.host.live_prompt("live", "> ", "", ["keymap.cmdline <C-x> plugin.fs.close"])
    h.type("<C-x>")
    t.assert_equal([:normal, 1, ""], [h.mode, fs.inputs.length, h.message_row.rstrip], "close_prompt closes the plugin's prompt")
    t.assert_equal([false, "No prompt is open"], [fs.host.close_prompt.ok, fs.host.close_prompt.message], "close_prompt without a prompt fails")

    t.finish
  end
end

UseCasesPluginFilesTest.main if __FILE__ == $0
