require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# The git_signs plugin over FakeProcesses: git is installed and its
# answers scripted per command, or left out so it cannot start.
module EditorGitSignsTest
  BRANCH = "git symbolic-ref --short -q HEAD"
  COUNTS = "git rev-list --left-right --count HEAD...@{upstream}"

  # The plugin's segment, "" for none.
  #: (Carat::Doubles::EditorHarness) -> String
  def self.segment(h)
    segments = h.assembly.plugin_ui.segments
    segments.key?("git_signs") ? segments["git_signs"].to_s : ""
  end

  # An editor over a.txt with the plugin registered.
  #: () -> Carat::Doubles::EditorHarness
  def self.editor
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\n")
    files.put("b.txt", "two\n")
    Carat::Doubles::EditorHarness.with_plugins(files, 24, 80, [Carat::Plugins::GitSigns::Plugin.new])
  end

  def self.main
    t = Carat::Testing.new("editor_git_signs")

    # Scenario "The branch and both counts show".
    h = editor
    h.processes.install("git")
    h.processes.script(BRANCH, "main\n")
    h.processes.script(COUNTS, "1\t2\n")
    h.open("a.txt")
    t.assert_equal("± main ↑1 ↓2", segment(h), "the branch and both counts show as the plugin's segment")
    t.assert_equal(true, h.status_row.include?(" ± main ↑1 ↓2 "), "and the status bar shows it")
    t.assert_equal([BRANCH, COUNTS], h.processes.captured, "git is asked for the branch, then the counts")

    # Scenario "The segment under ascii icons".
    h.assembly.state.options.icons = "ascii"
    h.type(":w<CR>")
    t.assert_equal("g main +1 -2", segment(h), "the segment under ascii icons is all ASCII")
    t.assert_equal(true, segment(h).bytes.all? { |byte| byte < 128 }, "every character of it")

    # Scenario "The segment follows a branch change on save".
    h.processes.script(BRANCH, "topic\n")
    h.processes.script(COUNTS, "0\t0\n")
    h.type(":w<CR>")
    t.assert_equal("g topic", segment(h), "the segment follows a branch change on save, no zero count shown")

    # Scenario "A branch without an upstream shows alone".
    h = editor
    h.processes.install("git")
    h.processes.script(BRANCH, "topic\n")
    h.open("a.txt")
    t.assert_equal("± topic", segment(h), "a branch without an upstream shows alone")

    # Scenario "Control characters in the branch are dropped".
    h = editor
    h.processes.install("git")
    h.processes.script(BRANCH, "ma\e[31min\tx\nsecond\n")
    h.open("a.txt")
    t.assert_equal("± ma[31minx", segment(h), "control characters in the branch are dropped, the first line only")
    h.processes.script(BRANCH, "#{"b" * 80}\n")
    h.open("b.txt")
    t.assert_equal(62, segment(h).length, "the name is cut to 60 characters")

    # Scenario "A count that is not digits reads as zero".
    h = editor
    h.processes.install("git")
    h.processes.script(BRANCH, "main\n")
    h.processes.script(COUNTS, "x\t2\n")
    h.open("a.txt")
    t.assert_equal("± main ↓2", segment(h), "a count that is not digits reads as zero")

    # Scenario "Outside a repository nothing shows".
    h = editor
    h.processes.install("git")
    h.open("a.txt")
    t.assert_equal(["", ["git symbolic-ref --short -q HEAD"]], [segment(h), h.processes.captured], "outside a repository nothing shows and the counts are not asked")
    t.assert_equal(false, h.message.include?("git"), "and no message names git")

    # Scenario "Without git nothing shows".
    h = editor
    h.open("a.txt")
    t.assert_equal(["", [], true], [segment(h), h.processes.captured, h.assembly.plugins.enabled?("git_signs")], "without git nothing shows and the plugin stays enabled")
    t.assert_equal(false, h.message.include?("git"), "and no error reaches the message row")

    t.finish
  end
end

EditorGitSignsTest.main if __FILE__ == $0
