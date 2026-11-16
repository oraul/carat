require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# The git_signs plugin over FakeProcesses: git is installed and its
# answers scripted per command, or left out so it cannot start. The
# working directory, /project, is a trusted root unless a test says not.
module EditorGitSignsTest
  SAFE = "git -c protocol.ext.allow=never -c core.fsmonitor=false"
  BRANCH = "#{SAFE} symbolic-ref --short -q HEAD"
  COUNTS = "#{SAFE} rev-list --left-right --count HEAD...@{upstream}"

  # The plugin's segment, "" for none.
  #: (Carat::Doubles::EditorHarness) -> String
  def self.segment(h)
    segments = h.assembly.plugin_ui.segments
    segments.key?("git_signs") ? segments["git_signs"].to_s : ""
  end

  # The defaults with the working directory trusted.
  #: () -> Carat::Domain::Config
  def self.trusted
    Carat::Doubles::FixedConfig.with_user("language.trusted_roots /project\n")
  end

  # An editor over a.txt with the plugin registered, under a trusted root.
  #: () -> Carat::Doubles::EditorHarness
  def self.editor
    editor_with(trusted)
  end

  # An editor over a.txt with the plugin registered and the configuration.
  #: (Carat::Domain::Config) -> Carat::Doubles::EditorHarness
  def self.editor_with(config)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\n")
    files.put("b.txt", "two\n")
    Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 24, cols: 80, plugins: [Carat::Plugins::GitSigns::Plugin.new])
  end

  def self.main
    t = Carat::Testing.new("editor_git_signs")

    # Scenario "The branch and both counts show".
    # Scenario "Under a trusted root the branch and counts show".
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

    # Scenario "The segment follows a branch change on focus".
    h = editor
    h.processes.install("git")
    h.processes.script(BRANCH, "main\n")
    h.open("a.txt")
    h.type("<C-w>s")
    t.assert_equal("± main", segment(h), "a split keeps the branch")
    h.processes.script(BRANCH, "topic\n")
    h.type("<C-w>w")
    t.assert_equal("± topic", segment(h), "the segment follows a branch change on focus")

    # Scenario "The segment shows on activation".
    h = editor
    h.processes.install("git")
    h.processes.script(BRANCH, "main\n")
    h.plugins.activate_all(trusted)
    t.assert_equal(["± main", [BRANCH, COUNTS]], [segment(h), h.processes.captured], "the segment shows on activation, before any buffer opens")

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
    t.assert_equal(["", [BRANCH]], [segment(h), h.processes.captured], "outside a repository nothing shows and the counts are not asked")
    t.assert_equal(false, h.message.include?("git"), "and no message names git")

    # Scenario "Without git nothing shows".
    h = editor
    h.open("a.txt")
    t.assert_equal(["", [], true], [segment(h), h.processes.captured, h.assembly.plugins.enabled?("git_signs")], "without git nothing shows and the plugin stays enabled")
    t.assert_equal(false, h.message.include?("git"), "and no error reaches the message row")

    # Scenario "Outside a trusted root no git runs".
    h = editor_with(Carat::Doubles::FixedConfig.defaults)
    h.processes.install("git")
    h.processes.script(BRANCH, "main\n")
    h.processes.script(COUNTS, "1\t2\n")
    h.open("a.txt")
    h.type(":w<CR>")
    t.assert_equal(["", []], [segment(h), h.processes.captured], "outside a trusted root no git runs and no segment shows, with no trusted_roots line")
    t.assert_equal(false, h.message.include?("git") || h.message.include?("trusted"), "and no message names git or the trust")
    h = editor_with(Carat::Doubles::FixedConfig.with_user("language.trusted_roots /elsewhere ~/src\n"))
    h.processes.install("git")
    h.processes.script(BRANCH, "main\n")
    h.open("a.txt")
    t.assert_equal(["", []], [segment(h), h.processes.captured], "outside a trusted root no git runs, with roots that do not cover the directory")

    # Scenario "A promisor remote with a command runs nothing".
    # The canned partial clone: its promisor remote is an ext:: command
    # and the upstream commit is missing, so git answers no counts unless
    # it fetched, and it fetches, running the command, only when lazy
    # fetching is on and ext:: allowed. The double answers the branch and,
    # for the counts as the plugin sends them, nothing; were the command
    # sent without the refusals the canned "fetched" counts would show.
    h = editor
    h.processes.install("git")
    h.processes.script(BRANCH, "main\n")
    h.processes.script("git rev-list --left-right --count HEAD...@{upstream}", "7\t7\n")
    h.open("a.txt")
    t.assert_equal("± main", segment(h), "a promisor remote with a command runs nothing: the segment shows the branch alone")
    t.assert_equal([BRANCH, COUNTS], h.processes.captured, "each command refuses the ext:: transport and the fsmonitor hook on its command line")
    t.assert_equal(["GIT_NO_LAZY_FETCH=1", "GIT_NO_LAZY_FETCH=1"], h.processes.environments, "and runs with lazy fetching off")

    t.finish
  end
end

EditorGitSignsTest.main if __FILE__ == $0
