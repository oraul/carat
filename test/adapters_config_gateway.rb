require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module AdaptersConfigGatewayTest
  D = Carat::Domain
  USER = "/home/user/.config/carat/caratrc"
  PROJECT = "/project/.caratrc"

  # A file system whose project file is there but raises on read.
  class UnreadableFiles < Carat::Doubles::MemoryFiles
    # Raises for the project file and reads the others.
    # @rbs path: String
    def read(path)
      raise ArgumentError, "Permission denied" if path == PROJECT
      super(path)
    end
  end

  # The configuration the gateway reads over the files.
  def self.load(files)
    Carat::Adapters::RcConfigGateway.new(files: files).load
  end

  # The tabstop the configuration sets and its problems.
  def self.tabstop(files)
    config = load(files)
    [D::Options.from_config(config).tabstop, config.report]
  end

  def self.main
    t = Carat::Testing.new("adapters_config_gateway")

    files = Carat::Doubles::MemoryFiles.new
    t.assert_equal([2, []], tabstop(files), "with no user or project file the shipped defaults apply cleanly")
    files.put(USER, "option.tabstop 4\n")
    t.assert_equal([4, []], tabstop(files), "the user file overrides the defaults")
    files.put(PROJECT, "option.tabstop 3\n")
    t.assert_equal([3, []], tabstop(files), "the project file overrides the user file")
    files.put(PROJECT, "option.tabstop 3\noption.tabstop 5\n")
    t.assert_equal([5, []], tabstop(files), "a later line of one file wins")

    # Problems carry the labels of their files and come in file order.
    files = Carat::Doubles::MemoryFiles.new
    files.put(PROJECT, "editor.font mono\n")
    files.put(USER, "# mine\neditor.size 9\n")
    t.assert_equal([2, ["~/.config/carat/caratrc:2: unknown setting editor.size", ".caratrc:1: unknown setting editor.font"]], tabstop(files), "the user file's problems come before the project file's")

    # Language commands: the user file may set them, the project file not.
    files = Carat::Doubles::MemoryFiles.new
    files.put(USER, "language.ruby.lsp ruby-lsp --debug\n")
    files.put(PROJECT, "language.ruby.lsp ./evil\n")
    config = load(files)
    t.assert_equal([["ruby-lsp", "--debug"], [".caratrc:1: language commands are not read from a project file"]], [config.last("language.ruby.lsp").words, config.report], "a project file cannot choose a program to run")

    # No home directory, a directory named .caratrc, an unreadable file.
    files = Carat::Doubles::MemoryFiles.new
    files.put(USER, "option.tabstop 4\n")
    files.move_home("")
    t.assert_equal([2, []], tabstop(files), "without a home directory the user file is skipped")
    files = Carat::Doubles::MemoryFiles.new
    files.mkdir(PROJECT)
    t.assert_equal([2, []], tabstop(files), "a directory named .caratrc is skipped")
    unreadable = UnreadableFiles.new
    unreadable.put(PROJECT, "option.tabstop 3\n")
    unreadable.put(USER, "option.tabstop 4\n")
    t.assert_equal([4, [".caratrc: cannot be read"]], tabstop(unreadable), "a file that cannot be read is reported and skipped")
    files = Carat::Doubles::MemoryFiles.new
    files.move_to("/work/app")
    files.move_home("/users/ada")
    files.put("/users/ada/.config/carat/caratrc", "option.tabstop 6\n")
    files.put("/work/app/.caratrc", "option.number false\n")
    config = load(files)
    t.assert_equal([6, false, []], [D::Options.from_config(config).tabstop, D::Options.from_config(config).number, config.report], "the files are found under the home and working directories the port names")

    # The whole editor: the first problem in file order after startup.
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\n")
    files.put(USER, "option.number false\noption.theme solarized\n")
    files.put(PROJECT, "keymap.normal zq foo.bar\noption.tabstop 3\n")
    clock = Carat::Doubles::ManualClock.new
    terminal = Carat::Doubles::FakeTerminal.new(clock: clock, rows: 10, cols: 60)
    editor = Carat::Adapters::EditorAssembly.new(terminal: terminal, clock: clock, files: files, config: Carat::Adapters::RcConfigGateway.new(files: files), plugin_list: [])
    editor.open("a.txt")
    t.assert_equal([3, false, "~/.config/carat/caratrc:2: unknown theme solarized (and 1 more)", true], [editor.state.options.tabstop, editor.state.options.number, editor.state.message, editor.state.message_error], "the editor applies the files and shows the first problem with the count of the others")

    t.finish
  end
end

AdaptersConfigGatewayTest.main if __FILE__ == $0
