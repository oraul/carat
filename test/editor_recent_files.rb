require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# The recent files persist: the editor writes them when it ends and reads
# them when it starts, over one MemoryFiles standing for the disk and the
# home directory, and moving its working directory stands in for :cd.
module EditorRecentFilesTest
  STATE = "/home/user/.local/state/carat/recent_files"

  # /p with the files of an earlier session and /q, another project.
  def self.disk
    files = Carat::Doubles::MemoryFiles.new
    files.move_to("/p")
    files.put("lib/alpha.rb", "a = 1\n")
    files.put("lib/beta.rb", "b = 2\n")
    files.put("docs/guide.md", "guide\n")
    files.put("/q/x.rb", "x = 9\n")
    files
  end

  # An editor with the finder over the files, started on path.
  def self.start(files, path)
    h = Carat::Doubles::EditorHarness.with_plugins(files, 24, 80, [Carat::Plugins::Finder::Plugin.new])
    h.open(path.to_s)
    h
  end

  # The first float as its title, "|", and its rows without the query.
  def self.picker(h)
    layer = h.state.tab.floats
    return "none" if layer.count == 0
    f = layer.at(0)
    lines = f.window.buffer.lines
    "#{f.spec.title}|#{lines[1, lines.length - 1].to_a.join("\n")}"
  end

  # The recent files picker's float after Space f r.
  def self.recent(h)
    h.type("<Space>fr")
    picker(h)
  end

  # A session over the files that ends after opening each path in turn.
  def self.session(files, first, others)
    h = start(files, first)
    i = 0
    while i < others.length
      h.type(":e #{others[i]}<CR>")
      i += 1
    end
    h.assembly.close
    h
  end

  def self.main
    t = Carat::Testing.new("editor_recent_files")

    # Scenario: The recent files survive a restart.
    files = disk
    session(files, "lib/alpha.rb", ["lib/beta.rb"])
    t.assert_equal("/p/lib/beta.rb\n/p/lib/alpha.rb\n", files.get(STATE).to_s, "The recent files survive a restart: ending the editor writes the absolute paths, most recent first, under the home directory")
    h = start(files, "docs/guide.md")
    t.assert_equal("Recent 3/3|▎ docs/guide.md\n  lib/beta.rb\n  lib/alpha.rb", recent(h), "The recent files survive a restart: a new editor lists the earlier files after the one it opened")
    t.assert_equal(nil, files.get("/p/recent_files"), "the state file is never put in the project directory")

    # Scenario: The recent files keep naming their files after the working directory changes.
    files = disk
    session(files, "lib/alpha.rb", ["lib/beta.rb"])
    files.move_to("/q")
    h = start(files, "x.rb")
    t.assert_equal("Recent 3/3|▎ x.rb\n  /p/lib/beta.rb\n  /p/lib/alpha.rb", recent(h), "The recent files keep naming their files after the working directory changes: a restart elsewhere lists each earlier file by its absolute path")
    h.type("<C-n><CR>")
    t.assert_equal(["/p/lib/beta.rb", "b = 2"], [h.state.buffer.path_text, h.state.buffer.line(0)], "the pick opens the file it named, not one of that name in the new directory")
    files = disk
    h = start(files, "lib/alpha.rb")
    files.move_to("/q")
    h.type(":e x.rb<CR>")
    t.assert_equal("Recent 2/2|▎ x.rb\n  /p/lib/alpha.rb", recent(h), "the recent files keep naming their files after a working directory change inside one session")
    h.assembly.close
    t.assert_equal("/q/x.rb\n/p/lib/alpha.rb\n", files.get(STATE).to_s, "the paths written are absolute whatever the directory was when each file opened")

    # Scenario: A path inside the working directory is shown relative.
    files = disk
    session(files, "lib/alpha.rb", [])
    files.move_to("/p/lib")
    h = start(files, "beta.rb")
    t.assert_equal("Recent 2/2|▎ beta.rb\n  alpha.rb", recent(h), "A path inside the working directory is shown relative to it: a restart inside /p/lib shows both files by their names there")

    # Scenario: A missing or unreadable state file is read as empty.
    files = disk
    h = start(files, "lib/alpha.rb")
    t.assert_equal("Recent 1/1|▎ lib/alpha.rb", recent(h), "A missing or unreadable state file is read as empty: no file")
    files = disk
    files.put("#{STATE}/entry", "")
    h = start(files, "lib/alpha.rb")
    t.assert_equal("Recent 1/1|▎ lib/alpha.rb", recent(h), "a directory in the state file's place is read as empty")
    files = disk
    files.put(STATE, "/p/lib/beta.rb\n")
    files.pad(STATE, 2000000)
    h = start(files, "lib/alpha.rb")
    t.assert_equal("Recent 1/1|▎ lib/alpha.rb", recent(h), "a state file over 1 MiB is read as empty")
    files = disk
    files.put(STATE, "lib/relative.rb\n/p/lib/beta.rb\n/p/lib/ev\u001b[31mil.rb\n/p/lib/c\u0085.rb\n\n/\n/p/lib/beta.rb\r\n")
    h = start(files, "lib/alpha.rb")
    t.assert_equal("Recent 2/2|▎ lib/alpha.rb\n  lib/beta.rb", recent(h), "a relative path, a path with a control character, an empty line, the root, and a repeat are dropped, a carriage return ended a line")
    files = disk
    files.move_home("")
    session(files, "lib/alpha.rb", ["lib/beta.rb"])
    t.assert_equal(false, files.exist?("/.local"), "with no home directory nothing is written")
    h = start(files, "docs/guide.md")
    t.assert_equal("Recent 1/1|▎ docs/guide.md", recent(h), "with no home directory nothing is read")

    # Scenario: A state file that cannot be written does not stop the editor.
    files = disk
    files.unwritable << STATE
    h = session(files, "lib/alpha.rb", ["lib/beta.rb"])
    t.assert_equal([nil, true], [files.get(STATE), h.state.buffer.path_text == "lib/beta.rb"], "A state file that cannot be written does not stop the editor: the write is skipped, the session is intact")
    files = disk
    files.put("/home/user/.local", "a file, not a directory\n")
    session(files, "lib/alpha.rb", [])
    t.assert_equal("a file, not a directory\n", files.get("/home/user/.local").to_s, "a home whose .local is a file loses the write and nothing else")

    # Scenario: The recent files stay bounded across restarts.
    files = disk
    text = +""
    i = 1
    while i <= 150
      text << "/old/f#{i}.rb\n"
      i += 1
    end
    files.put(STATE, text)
    h = session(files, "lib/alpha.rb", [])
    lines = files.get(STATE).to_s.split("\n")
    t.assert_equal([100, "/p/lib/alpha.rb", "/old/f1.rb", "/old/f99.rb"], [lines.length, lines[0].to_s, lines[1].to_s, lines[99].to_s], "The recent files stay bounded across restarts: 150 earlier paths and one new one keep 100, the new first and the oldest dropped")

    # An empty list writes nothing: the editor started on no file.
    files = disk
    h = start(files, "")
    h.assembly.close
    t.assert_equal(nil, files.get(STATE), "an editor that opened no file writes no state file")

    # RecentFilesText: the usable lines, the parse, and the render.
    rules = Carat::Domain::RecentFilesText
    t.assert_equal([true, false, false, false, false, false, true, false], [rules.usable?("/a"), rules.usable?("/"), rules.usable?("a/b"), rules.usable?("/a\tb"), rules.usable?("/a\u007f"), rules.usable?("/a\u0080"), rules.usable?("/éあ"), rules.usable?("/a#{"b" * 4096}")], "usable paths are absolute, longer than the root, without controls, and at most 4096 bytes, multi-byte text kept")
    t.assert_equal(["/a", "/b"], rules.parse("/a\n\n/b\r\n/a\nx\n/c\n", 2), "parse keeps usable lines once, in order, up to the limit")
    t.assert_equal([["/a", "/b"], []], [rules.parse("/a\n/b", 5), rules.parse("", 5)], "parse reads a last line with no line feed and an empty text as no paths")
    t.assert_equal(["/a\n/b\n", ""], [rules.render(["/a", "rel", "/b", "/x\ny"]), rules.render([])], "render writes the usable paths, one per line, nothing for none")
    t.assert_equal(["", "/home/user/.local/state/carat/recent_files"], [rules.location(""), rules.location("/home/user")], "the state file lives under the home directory, nowhere with none")

    t.finish
  end
end

EditorRecentFilesTest.main if __FILE__ == $0
