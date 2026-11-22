require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module AdaptersConfigGatewayTest
  D = Carat::Domain
  USER = "/home/user/.config/carat/caratrc"
  PROJECT = "/project/.caratrc"

  # The keymap lines a configuration kept from files other than the
  # defaults, as "source mode keys action".
  #: (Carat::Domain::Config) -> Array[String]
  def self.project_bindings(config)
    bound = []
    i = 0
    while i < config.count
      line = config.line_at(i)
      bound << "#{line.source} #{line.name} #{line.words.join(" ")}" if line.scope == "keymap" && !config.shipped?(line) && line.source == ".caratrc"
      i += 1
    end
    bound
  end

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

  # A file system whose project file is checked as a regular file and is
  # a link by the time it is read, as when it is swapped between the two.
  class SwappedFiles < Carat::Doubles::MemoryFiles
    # Answers the project file's stat from before the swap.
    # @rbs path: String
    def stat(path)
      info = super(path)
      return info unless path == PROJECT
      D::PathInfo.new(exists: info.exists, size: info.size, mtime: info.mtime, directory: info.directory, symlink: false, regular: info.regular)
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
    # Scenarios: Language command in the project file,
    # Language command in the user file, Root command in the project file.
    files = Carat::Doubles::MemoryFiles.new
    files.put(USER, "language.ruby.lsp ruby-lsp --debug\n")
    files.put(PROJECT, "language.ruby.lsp ./evil\n")
    config = load(files)
    t.assert_equal([["ruby-lsp", "--debug"], [".caratrc:1: language commands are not read from a project file"]], [config.last("language.ruby.lsp").words, config.report], "a project file cannot choose a program to run")
    files = Carat::Doubles::MemoryFiles.new
    files.put(USER, "language.ruby.lsp.root /work docker compose exec app ruby-lsp\n")
    files.put(PROJECT, "language.ruby.lsp.root / ./evil\n")
    config = load(files)
    t.assert_equal([["/work", "docker", "compose", "exec", "app", "ruby-lsp"], [".caratrc:1: language commands are not read from a project file"]], [config.last("language.ruby.lsp.root").words, config.report], "a project file cannot choose a root command")

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
    # Scenario: A project file swapped for a link after the check.
    swapped = SwappedFiles.new
    swapped.put(PROJECT, "option.tabstop 3\n")
    swapped.link(PROJECT)
    t.assert_equal([2, [".caratrc: cannot be read"]], tabstop(swapped), "a project file swapped for a link after the check is not read")

    # Scenario: A write or quit binding in the project file.
    # Scenario: A command-line binding in any mode.
    # Scenario: The user file binds a write, the project file unbinds one.
    files = Carat::Doubles::MemoryFiles.new
    files.put(USER, "keymap.normal Q quit.all\n")
    files.put(PROJECT, "keymap.normal j file.save\nkeymap.insert x quit.write_all\nkeymap.cmdline <Space> cmdline.execute\nkeymap.normal k cmdline.history_older\nkeymap.visual q window.quit\nkeymap.normal ZZ none\nkeymap.normal K cursor.down\nkeymap.normal ; mode.cmdline\n")
    config = load(files)
    bound = []
    i = 0
    while i < config.count
      line = config.line_at(i)
      bound << "#{line.source} #{line.name} #{line.words.join(" ")}" unless config.shipped?(line)
      i += 1
    end
    refused = "is not bound from a project file"
    t.assert_equal([["~/.config/carat/caratrc normal Q quit.all", ".caratrc normal ZZ none", ".caratrc normal K cursor.down", ".caratrc normal ; mode.cmdline"], [".caratrc:1: file.save #{refused}", ".caratrc:2: quit.write_all #{refused}", ".caratrc:3: cmdline.execute #{refused}", ".caratrc:4: cmdline.history_older #{refused}", ".caratrc:5: window.quit #{refused}"]], [bound, config.report], "a project file cannot bind a write, a quit, or the command line")

    # Scenario: A plugin's file action in the project file.
    # Scenario: The project file unbinds the command line.
    # Only the allowlist binds: a plugin's actions, a family no entry
    # names, and window.quit are refused, the other window actions kept.
    files = Carat::Doubles::MemoryFiles.new
    files.put(PROJECT, "keymap.normal x plugin.explorer.delete\nkeymap.normal : none\nkeymap.visual_block : cursor.down\nkeymap.normal y plugin.finder.open\nkeymap.normal gz future.thing\nkeymap.normal <C-w>z window.only\n")
    config = load(files)
    t.assert_equal([".caratrc normal <C-w>z window.only"], project_bindings(config), "a project file keeps only the allowlist's bindings")
    t.assert_equal([".caratrc:1: plugin.explorer.delete #{refused}", ".caratrc:2: : runs mode.cmdline, which a project file may not unbind or rebind", ".caratrc:3: : runs mode.cmdline, which a project file may not unbind or rebind", ".caratrc:4: plugin.finder.open #{refused}", ".caratrc:5: future.thing #{refused}"], config.report, "a project file cannot bind a plugin's file action or unbind the command line")

    # Scenario: The project file takes the user's quit or the leader's save.
    # Keys compare by their codes under the leader, so <Space>fs is the
    # defaults' <leader>fs, and the user's key sequence is held too.
    files = Carat::Doubles::MemoryFiles.new
    files.put(USER, "keymap.normal Q quit.all\nkeymap.normal gw :w<CR>\n")
    files.put(PROJECT, "keymap.normal Q none\nkeymap.normal <Space>fs cursor.down\nkeymap.normal <C-S> none\nkeymap.normal gw none\nkeymap.insert <C-s> cursor.left\nkeymap.cmdline <CR> none\n")
    config = load(files)
    held = "which a project file may not unbind or rebind"
    t.assert_equal([[], [".caratrc:1: Q runs quit.all, #{held}", ".caratrc:2: <Space>fs runs file.save, #{held}", ".caratrc:3: <C-S> runs file.save, #{held}", ".caratrc:4: gw runs :w<CR>, #{held}", ".caratrc:5: <C-s> runs file.save, #{held}", ".caratrc:6: <CR> runs cmdline.execute, #{held}"]], [project_bindings(config), config.report], "a project file cannot take the user's quit or the leader's save")

    # Scenario: A key the user freed.
    # A key the user unbound or bound to a plain action is the project's.
    files = Carat::Doubles::MemoryFiles.new
    files.put(USER, "keymap.normal <C-s> none\nkeymap.normal <leader>qq cursor.up\n")
    files.put(PROJECT, "keymap.normal <C-s> cursor.down\nkeymap.normal <Space>qq none\nkeymap.visual : none\n")
    config = load(files)
    t.assert_equal([[".caratrc normal <C-s> cursor.down", ".caratrc normal <Space>qq none"], [".caratrc:3: : runs mode.cmdline, #{held}"]], [project_bindings(config), config.report], "a key the user freed is the project's to bind")

    # Scenario: A project leader leaves the leader bindings where they were.
    files = Carat::Doubles::MemoryFiles.new
    files.put(USER, "keymap.leader ,\n")
    files.put(PROJECT, "keymap.leader d\n")
    config = load(files)
    t.assert_equal([",", [".caratrc:1: keymap.leader is not read from a project file"]], [D::Keymap.leader_from(config), config.report], "a project leader leaves <leader>fs and <leader>qw on the user's leader")
    files = Carat::Doubles::MemoryFiles.new
    files.put(PROJECT, "keymap.leader f\n")
    config = load(files)
    t.assert_equal(["<Space>", [".caratrc:1: keymap.leader is not read from a project file"]], [D::Keymap.leader_from(config), config.report], "a project leader leaves the default leader")

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
    editor = Carat::Adapters::EditorAssembly.new(terminal: terminal, clock: clock, files: files, config: Carat::Adapters::RcConfigGateway.new(files: files), processes: Carat::Doubles::FakeProcesses.new, messages: Carat::Doubles::MemoryQueue.new, completions: Carat::Doubles::FixedCompletions.new, plugin_list: [])
    editor.open("a.txt")
    t.assert_equal([3, false, "~/.config/carat/caratrc:2: unknown theme solarized (and 1 more)", true], [editor.state.options.tabstop, editor.state.options.number, editor.state.message, editor.state.message_error], "the editor applies the files and shows the first problem with the count of the others")

    # The refused lines leave the keys as they were: : opens the command
    # line and x deletes a character.
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\n")
    h = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with("keymap.normal : none\nkeymap.normal x plugin.explorer.delete\n"), rows: 10, cols: 60, plugins: [])
    h.open("a.txt")
    h.type(":")
    opened = h.mode
    h.type("<Esc>x")
    t.assert_equal([:cmdline, ["ne"]], [opened, h.lines], "a refused project line leaves : on the command line and x on delete")

    t.finish
  end
end

AdaptersConfigGatewayTest.main if __FILE__ == $0
