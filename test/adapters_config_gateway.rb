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
    # @rbs limit: Integer
    def read(path, limit)
      raise ArgumentError, "Permission denied" if path == PROJECT
      super(path, limit)
    end
  end

  LIMIT = 1_048_576

  # A file system holding one hostile arrangement of the user and project
  # files, by name.
  def self.hostile(kind)
    files = Carat::Doubles::MemoryFiles.new
    case kind
    when "linked project"
      files.put(PROJECT, "option.tabstop 3\n")
      files.link(PROJECT)
    when "project linked to a device"
      files.special("/dev/zero")
      files.put(PROJECT, "")
      files.link_to(PROJECT, "/dev/zero")
    when "project FIFO"
      files.put(USER, "option.tabstop 4\n")
      files.special(PROJECT)
    when "user device"
      files.special(USER)
      files.put(PROJECT, "option.tabstop 3\n")
    when "huge user file"
      files.put(USER, "option.tabstop 4\n" + ("#" * LIMIT))
      files.put(PROJECT, "option.tabstop 3\n")
    when "user file at the limit"
      files.put(USER, "option.tabstop 4\n" + ("#" * (LIMIT - 17)))
    when "linked user file"
      files.put(USER, "option.tabstop 4\n")
      files.link(USER)
    when "illegal bytes in both files"
      files.put(USER, "option.tabstop 4\nkeymap.normal x a\xFF.b\n")
      files.put(PROJECT, "option.theme caf\xE9\noption.tabstop 999999999\n")
    end
    files
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

    # Key sequences: the user file may bind them, the project file not,
    # since a replay can write any file with :w.
    files = Carat::Doubles::MemoryFiles.new
    files.put(USER, "keymap.normal Q :w<CR>\n")
    files.put(PROJECT, "keymap.normal j :e<Space>.git/config<CR>\nkeymap.normal K cursor.down\n")
    config = load(files)
    bound = []
    i = 0
    while i < config.count
      line = config.line_at(i)
      bound << "#{line.source} #{line.words.join(" ")}" unless config.shipped?(line)
      i += 1
    end
    t.assert_equal([["~/.config/carat/caratrc Q :w<CR>", ".caratrc K cursor.down"], [".caratrc:1: key sequences are not read from a project file"]], [bound, config.report], "a project file cannot bind a key sequence, which could write any file")

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

    # Hostile files: rows are [label, arrangement, [tabstop, problems]].
    t.table([
      ["a linked project file is refused", "linked project", [2, [".caratrc: is a symbolic link, not read"]]],
      ["a project file linked to /dev/zero is refused", "project linked to a device", [2, [".caratrc: is a symbolic link, not read"]]],
      ["a FIFO project file is refused and the user file loads", "project FIFO", [4, [".caratrc: is not a regular file, not read"]]],
      ["a device user file is refused and the project file loads", "user device", [3, ["~/.config/carat/caratrc: is not a regular file, not read"]]],
      ["a file over the limit is refused", "huge user file", [3, ["~/.config/carat/caratrc: is larger than 1048576 bytes, not read"]]],
      ["a file of exactly the limit is read", "user file at the limit", [4, []]],
      ["a linked user file is read", "linked user file", [4, []]],
      ["illegal bytes and a huge tabstop are lines of their files", "illegal bytes in both files", [4, ["~/.config/carat/caratrc:2: illegal byte", ".caratrc:1: illegal byte", ".caratrc:2: option.tabstop takes a number from 1 to 9999"]]]
    ]) do |kind|
      tabstop(hostile(kind.to_s))
    end

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
    editor = Carat::Adapters::EditorAssembly.new(terminal: terminal, clock: clock, files: files, config: Carat::Adapters::RcConfigGateway.new(files: files), processes: Carat::Doubles::FakeProcesses.new, messages: Carat::Doubles::MemoryQueue.new, plugin_list: [])
    editor.open("a.txt")
    t.assert_equal([3, false, "~/.config/carat/caratrc:2: unknown theme solarized (and 1 more)", true], [editor.state.options.tabstop, editor.state.options.number, editor.state.message, editor.state.message_error], "the editor applies the files and shows the first problem with the count of the others")

    t.finish
  end
end

AdaptersConfigGatewayTest.main if __FILE__ == $0
