require_relative "../carat/test_support"
require_relative "../carat/testing"

t = Carat::Testing.new("plugins_explorer")
E = Carat::Plugins::Explorer

# A fake host over an in-memory file system: it answers the listing,
# stat, and icon requests the tree model makes, in the icon set given.
class FakeHost < Carat::PluginApi::Host
  # @rbs @files: Carat::Doubles::MemoryFiles
  # @rbs @set: String

  #: (Carat::Doubles::MemoryFiles, String) -> void
  def initialize(files, set)
    @files = files
    @set = set
  end

  # Returns a Response with the entry names.
  # @rbs path: String
  def list_dir(path)
    names = []
    begin
      names = @files.list(path)
    rescue StandardError => error
      return Carat::PluginApi::Response.failure(error.message)
    end
    Carat::PluginApi::Response.listing(names)
  end

  # Returns a FileInfo.
  # @rbs path: String
  def stat(path)
    info = @files.stat(path)
    Carat::PluginApi::FileInfo.new(info.exists, info.size, 0, info.directory, info.symlink)
  end

  # Returns a TextResponse with the glyph.
  # @rbs name: String
  def icon(name)
    Carat::PluginApi::TextResponse.success(Carat::Domain::Icons.glyph(name, @set))
  end
end

# /home/ada/proj with files, directories, hidden and ignored entries.
def disk
  files = Carat::Doubles::MemoryFiles.new
  files.move_to("/home/ada/proj")
  files.put("b.rb", "")
  files.put("a.md", "")
  files.put("Lib/z.c", "")
  files.put("docs/guide.md", "")
  files.put("docs/deep/x.rb", "")
  files.put(".env", "")
  files.put(".git/HEAD", "")
  files.put("build/out", "")
  files.put("Makefile", "")
  files
end

def tree_over(files)
  E::Tree.new("/home/ada/proj", false, [".git", "build", "tmp"])
end

files = disk
host = FakeHost.new(files, "ascii")
tree = tree_over(files)
tree.build(host)
t.assert_equal([" - proj", "   + docs", "   + Lib", "   m a.md", "   r b.rb", "   M Makefile"], tree.lines(host), "the root, then directories, then files, each sorted ignoring case")
tree.expand("/home/ada/proj/docs")
tree.build(host)
t.assert_equal([" - proj", "   - docs", "     + deep", "     m guide.md", "   + Lib", "   m a.md", "   r b.rb", "   M Makefile"], tree.lines(host), "an expanded directory lists its entries two spaces deeper")
t.assert_equal([1, 0, 1, -1], [tree.row_of("/home/ada/proj/docs"), tree.parent_row(1), tree.parent_row(3), tree.parent_row(0)], "rows and parents")
tree.collapse("/home/ada/proj/docs")
tree.build(host)
t.assert_equal(6, tree.count, "collapsing hides the entries again")
tree.toggle("/home/ada/proj/Lib")
tree.build(host)
t.assert_equal("     c z.c", tree.node(3).depth == 2 ? tree.lines(host)[3] : "", "toggle expands a collapsed directory")

# Hidden and ignored entries.
tree = tree_over(files)
tree.toggle_hidden
tree.build(host)
names = []
i = 0
while i < tree.count
  names << tree.node(i).name
  i += 1
end
t.assert_equal(["proj", "docs", "Lib", ".env", "a.md", "b.rb", "Makefile"], names, "hidden entries show when toggled, ignored ones never")

# Reveal and the marker.
tree = tree_over(files)
t.assert_equal(false, tree.reveal("/etc/passwd"), "a path outside the root reveals nothing")
t.assert_equal(true, tree.reveal("/home/ada/proj/docs/deep/x.rb"), "a path inside the root is revealed")
tree.mark("/home/ada/proj/docs/deep/x.rb")
tree.build(host)
t.assert_equal(">      r x.rb", tree.lines(host)[3], "every directory above it is expanded and its line marked")
t.assert_equal(3, tree.row_of(tree.marked), "the marked row")

# Renames move the expanded directories and the mark.
tree.moved("/home/ada/proj/docs", "/home/ada/proj/doc")
t.assert_equal([true, false, "/home/ada/proj/doc/deep/x.rb"], [tree.expanded?("/home/ada/proj/doc/deep"), tree.expanded?("/home/ada/proj/docs/deep"), tree.marked], "a rename moves the expanded set and the mark")

# Moving the root.
tree = tree_over(files)
tree.reroot("/home/ada")
tree.expand("/home/ada/proj")
tree.build(host)
t.assert_equal([" - ada", "   - proj", "     + docs"], tree.lines(host)[0, 3], "the parent as root keeps the old root expanded")
tree.reroot("/home/ada/proj/docs")
tree.build(host)
t.assert_equal(" - docs", tree.lines(host)[0], "a directory as root")

# Symbolic links.
files = disk
files.link("docs")
files.link("b.rb")
tree = tree_over(files)
tree.build(host = FakeHost.new(files, "ascii"))
t.assert_equal(["   ~ docs", "   ~ b.rb"], [tree.lines(host)[1], tree.lines(host)[4]], "a link uses the symlink icon")
t.assert_equal(true, tree.node(1).directory, "a link to a directory still sorts and expands as one")

# Icon names: rows are [label, name, directory, expanded, symlink, icon].
t.table([
  ["ruby", ["a.rb", false, false, false], "ruby"],
  ["json", ["a.json", false, false, false], "json"],
  ["markdown", ["README.md", false, false, false], "markdown"],
  ["toml", ["spin.toml", false, false, false], "toml"],
  ["makefile", ["Makefile", false, false, false], "makefile"],
  ["shell", ["run.sh", false, false, false], "shell"],
  ["c source", ["a.c", false, false, false], "c"],
  ["c header", ["a.h", false, false, false], "c"],
  ["yml", ["ci.yml", false, false, false], "yaml"],
  ["yaml", ["a.yaml", false, false, false], "yaml"],
  ["gitignore", [".gitignore", false, false, false], "git"],
  ["lock", ["Gemfile.lock", false, false, false], "lock"],
  ["unknown extension", ["a.xyz", false, false, false], "default"],
  ["no extension", ["LICENSE", false, false, false], "default"],
  ["dot file", [".env", false, false, false], "default"],
  ["closed folder", ["lib", true, false, false], "folder_closed"],
  ["open folder", ["lib", true, true, false], "folder_open"],
  ["symlink", ["lib", true, false, true], "symlink"]
]) do |args|
  E::FileIcons.name_for(args[0], args[1], args[2], args[3])
end

# The same tree in every icon set.
files = disk
t.table([
  ["ascii", "ascii", [" - proj", "   + docs", "   r b.rb", "   M Makefile"]],
  ["unicode", "unicode", [" ▾ proj", "   ▸ docs", "   ◈ b.rb", "   ▤ Makefile"]],
  ["nerd", "nerd", [" \u{F07C} proj", "   \u{F07B} docs", "   \u{E791} b.rb", "   \u{E779} Makefile"]]
]) do |set|
  h = FakeHost.new(files, set)
  tr = tree_over(files)
  tr.build(h)
  all = tr.lines(h)
  [all[0], all[1], all[4], all[5]]
end

t.finish
