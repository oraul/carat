# Runs the editor binary inside a pseudo-terminal: the usage and terminal
# checks, an insert-write-quit session, Ctrl-S and <leader>qq, a quit
# refused then forced, split windows and a tab page, the file tree, a
# linewise visual delete, a Ruby file in colors, a file that is not UTF-8, a hostile project and
# home directory, and SIGTERM and SIGINT, each exit restoring the cursor.
# Runs build/bin/carat, the release binary make test builds first, or the
# binary CARAT_BIN names (CI runs the development build of make dev-build
# on pull requests). Prints only the harness lines so the snapshot is
# stable.
#
# Between sending keys the test drains the editor's output until it goes
# quiet, so the editor has finished drawing and is waiting on input before
# the next keys are sent. That makes the session deterministic without any
# fixed sleeps: a real terminal has a large input buffer, but a pseudo
# terminal can wedge if keys are written while the first frame is still
# being flushed.
require "pty"
require "open3"
require "io/console"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module SmokeEditorTest
  BIN = ENV["CARAT_BIN"] || "build/bin/carat"
  DIR = "build/smoke"
  # The last bytes of every exit: the terminal's own cursor shape, the
  # cursor shown, and the main screen.
  RESTORED = "\e[0 q\e[?25h\e[?1049l"

  # Reads until the editor produces nothing for quiet seconds, appending to
  # out, so the next write lands while the editor is waiting on input.
  def self.settle(reader, out, quiet)
    loop do
      ready = IO.select([reader], nil, nil, quiet)
      return if ready.nil?
      begin
        out << reader.readpartial(4096)
      rescue EOFError, Errno::EIO
        return
      end
    end
  end

  # Makes dir and the directories above it.
  def self.make_dirs(dir)
    return if File.directory?(dir)
    make_dirs(File.dirname(dir))
    Dir.mkdir(dir)
  end

  # Writes path afresh, removing a link or file already there.
  def self.fresh(path)
    File.delete(path) if File.symlink?(path) || File.exist?(path)
  end

  # Starts the editor on a.txt in the project directory with HOME set to
  # home, and answers the output of its first frame after :q! and its
  # exit status.
  def self.hostile_session(project, home)
    bin = File.expand_path(BIN)
    here = Dir.pwd
    Dir.chdir(project)
    reader, writer, pid = PTY.spawn({ "HOME" => home }, bin, "a.txt")
    Dir.chdir(here)
    writer.winsize = [24, 80]
    out = +"".b
    settle(reader, out, 0.5)
    writer.write(":q!\r")
    code = finish_session(reader, out, pid)
    HostileRun.new(out: out, code: code)
  end

  # What a hostile session drew and how it ended.
  class HostileRun < Struct.new(:out, :code, keyword_init: true)
  end

  # Reads until the editor closes the terminal, then reaps it.
  def self.finish_session(reader, out, pid)
    loop do
      ready = IO.select([reader], nil, nil, 20.0)
      break if ready.nil?
      begin
        out << reader.readpartial(4096)
      rescue EOFError, Errno::EIO
        break
      end
    end
    pair = Process.waitpid2(pid)
    pair[1].exitstatus
  end

  def self.main
    t = Carat::Testing.new("smoke_editor")

    unless File.exist?(BIN)
      t.assert_true(false, "#{BIN} exists; run spin build first")
      t.finish
    end
    Dir.mkdir(DIR) unless File.directory?(DIR)

    # Usage and terminal checks run without a pseudo-terminal.
    _out, err, status = Open3.capture3(BIN, "a.txt", "b.txt")
    t.assert_equal("usage: carat [FILE]\n", err, "two arguments print the usage")
    t.assert_equal(1, status.exitstatus, "two arguments exit with status 1")
    _out, err, status = Open3.capture3(BIN, "#{DIR}/x.txt", stdin_data: "")
    t.assert_equal("carat: standard input is not a terminal\n", err, "piped input is refused")
    t.assert_equal(1, status.exitstatus, "piped input exits with status 1")

    # No argument: the start screen, then :q.
    reader, writer, pid = PTY.spawn(BIN)
    writer.winsize = [24, 80]
    out = +"".b
    settle(reader, out, 0.5)
    t.assert_true(out.include?("insert text"), "no argument shows the start screen with its hints")
    writer.write(":q\r")
    code = finish_session(reader, out, pid)
    t.assert_equal(0, code, "the editor started without a file exits with status 0 after :q")
    t.assert_true(out.end_with?(RESTORED), "after :q the output ends with the terminal's cursor restored and the alternate screen left")

    # Insert, write, quit on a new file.
    path = "#{DIR}/fresh.txt"
    File.delete(path) if File.exist?(path)
    reader, writer, pid = PTY.spawn(BIN, path)
    writer.winsize = [24, 80]
    out = +"".b
    settle(reader, out, 0.5)
    t.assert_true(out.include?("\e[?1049h"), "the editor enters the alternate screen")
    t.assert_true(out.include?("[New]"), "the editor shows the new file message")
    mark = out.bytesize
    writer.write("ihello")
    settle(reader, out, 0.5)
    drawn = out.byteslice(mark, out.bytesize - mark)
    t.assert_true(drawn.include?("hello"), "typed text is drawn")
    t.assert_true(drawn.include?("\e[6 q"), "insert mode uses the bar cursor")
    mark = out.bytesize
    writer.write("\e")
    settle(reader, out, 0.5)
    t.assert_true(out.byteslice(mark, out.bytesize - mark).include?("\e[2 q"), "escape returns to the block cursor")
    writer.write(":wq\r")
    code = finish_session(reader, out, pid)
    t.assert_equal(0, code, "the editor exits with status 0 after :wq")
    t.assert_equal("hello\n", File.read(path), "the file holds the typed text")
    t.assert_true(out.end_with?(RESTORED), "after :wq the output ends with the terminal's cursor restored and the alternate screen left")

    # Ctrl-S, the flow-control stop byte 0x13, reaches the editor in raw
    # mode and writes in insert mode; <leader>qq then quits.
    saved = "#{DIR}/saved.txt"
    File.delete(saved) if File.exist?(saved)
    reader, writer, pid = PTY.spawn(BIN, saved)
    writer.winsize = [24, 80]
    out = +"".b
    settle(reader, out, 0.5)
    writer.write("isaved")
    settle(reader, out, 0.5)
    mark = out.bytesize
    writer.write("\x13")
    settle(reader, out, 0.5)
    t.assert_true(out.byteslice(mark, out.bytesize - mark).include?("written"), "Ctrl-S in insert mode shows the written message")
    t.assert_equal("saved\n", File.exist?(saved) ? File.read(saved) : "", "Ctrl-S in insert mode writes the typed text")
    writer.write("\e")
    settle(reader, out, 0.5)
    writer.write(" qq")
    code = finish_session(reader, out, pid)
    t.assert_equal(0, code, "the editor exits with status 0 after <leader>qq")
    t.assert_true(out.end_with?(RESTORED), "after <leader>qq the output ends with the terminal's cursor restored and the alternate screen left")

    # Quit refused, then forced, on the existing file.
    reader, writer, pid = PTY.spawn(BIN, path)
    writer.winsize = [24, 80]
    out = +"".b
    settle(reader, out, 0.5)
    t.assert_true(out.include?("1L, 6B"), "the editor shows the existing file message")
    mark = out.bytesize
    writer.write("x")
    settle(reader, out, 0.5)
    t.assert_true(out.byteslice(mark, out.bytesize - mark).include?("\u{F111}".b), "x deletes a character and the status bar marks the buffer modified")
    writer.write("A!")
    settle(reader, out, 0.5)
    writer.write("\e")
    settle(reader, out, 0.5)
    writer.write(":q\r")
    settle(reader, out, 0.5)
    t.assert_true(out.include?("E37: No write since last change (add ! to override)"), "quit is refused with E37")
    writer.write(":q!\r")
    code = finish_session(reader, out, pid)
    t.assert_equal(0, code, "the editor exits with status 0 after :q!")
    t.assert_equal("hello\n", File.read(path), "the forced quit did not write")

    # A vertical split, a tab page, and the quits that close them: the tab
    # page first, then one of the two windows, then the last window.
    reader, writer, pid = PTY.spawn(BIN, path)
    writer.winsize = [24, 80]
    out = +"".b
    settle(reader, out, 0.5)
    t.assert_true(out.include?("1L, 6B"), "the editor drew its first frame for the windows check")
    mark = out.bytesize
    writer.write(":vsplit\r")
    settle(reader, out, 0.5)
    t.assert_true(out.byteslice(mark, out.bytesize - mark).include?("\u2502".b), "vsplit draws the separator column")
    mark = out.bytesize
    writer.write(":tabnew\r")
    settle(reader, out, 0.5)
    t.assert_true(out.byteslice(mark, out.bytesize - mark).include?("[No Name] ".b), "tabnew draws the new buffer's tab")
    writer.write(":q\r")
    settle(reader, out, 0.5)
    writer.write(":q\r")
    settle(reader, out, 0.5)
    writer.write(":q\r")
    code = finish_session(reader, out, pid)
    t.assert_equal(0, code, "the editor exits with status 0 after closing the tab page, a window, and the last window")
    t.assert_true(out.end_with?(RESTORED), "closing the last window restores the cursor and leaves the alternate screen")

    # <C-w> waits for its second key past timeoutlen (500 ms in the
    # shipped configuration): after a vertical split, <C-w>, a pause, and
    # l put the cursor in the right window, at column 46 behind its
    # four-column number gutter, instead of one column right in the left.
    reader, writer, pid = PTY.spawn(BIN, path)
    writer.winsize = [24, 80]
    out = +"".b
    settle(reader, out, 0.5)
    t.assert_true(out.include?("1L, 6B"), "the editor drew its first frame for the slow window move")
    writer.write(":vsplit\r")
    settle(reader, out, 0.5)
    writer.write("\x17")
    settle(reader, out, 1.0)
    mark = out.bytesize
    writer.write("l")
    settle(reader, out, 0.5)
    t.assert_true(out.byteslice(mark, out.bytesize - mark).include?("\e[1;46H"), "<C-w>, a pause past timeoutlen, and l move to the right window")
    writer.write(":q\r")
    settle(reader, out, 0.5)
    writer.write(":q\r")
    code = finish_session(reader, out, pid)
    t.assert_equal(0, code, "the editor exits with status 0 after the slow window move")

    # The file tree opens with <leader>e at the left, and :q in the file
    # window ends the editor while the tree is open.
    reader, writer, pid = PTY.spawn(BIN, path)
    writer.winsize = [24, 80]
    out = +"".b
    settle(reader, out, 0.5)
    t.assert_true(out.include?("1L, 6B"), "the editor drew its first frame for the tree check")
    mark = out.bytesize
    writer.write(" e")
    settle(reader, out, 0.5)
    drawn = out.byteslice(mark, out.bytesize - mark)
    t.assert_true(drawn.include?("explorer"), "<leader>e opens the tree, titled explorer")
    t.assert_true(drawn.include?("\u{F07C}".b), "the tree's root line has the open folder icon")
    writer.write("\x17l")
    settle(reader, out, 0.5)
    writer.write(":q\r")
    code = finish_session(reader, out, pid)
    t.assert_equal(0, code, "the editor exits with status 0 after :q in the file window beside the tree")
    t.assert_true(out.end_with?(RESTORED), "quitting beside the tree restores the cursor and leaves the alternate screen")

    # PageDown, as the terminal sends it, scrolls a page: the window's 22
    # text rows show lines 1 to 22, and a page of 20 rows later lines 21
    # to 42.
    long_path = "#{DIR}/long.txt"
    long = +""
    n = 1
    while n <= 100
      long << "line #{n}\n"
      n += 1
    end
    File.write(long_path, long)
    reader, writer, pid = PTY.spawn(BIN, long_path)
    writer.winsize = [24, 80]
    out = +"".b
    settle(reader, out, 0.5)
    t.assert_true(out.include?("100L, 792B"), "the editor drew its first frame for the page check")
    t.assert_true(!out.include?("line 42"), "line 42 is not shown before the page")
    mark = out.bytesize
    writer.write("\e[6~")
    settle(reader, out, 0.5)
    t.assert_true(out.byteslice(mark, out.bytesize - mark).include?("line 42"), "PageDown scrolls a page down")
    writer.write(":q\r")
    code = finish_session(reader, out, pid)
    t.assert_equal(0, code, "the editor exits with status 0 after the page check")

    # Linewise visual mode: Vj selects two lines, d deletes them, :wq writes.
    visual_path = "#{DIR}/visual.txt"
    File.write(visual_path, "one\ntwo\nthree\n")
    reader, writer, pid = PTY.spawn(BIN, visual_path)
    writer.winsize = [24, 80]
    out = +"".b
    settle(reader, out, 0.5)
    t.assert_true(out.include?("3L, 14B"), "the editor drew its first frame for the visual check")
    mark = out.bytesize
    writer.write("Vj")
    settle(reader, out, 0.5)
    t.assert_true(out.byteslice(mark, out.bytesize - mark).include?("-- VISUAL LINE --"), "V and j show the linewise visual mode")
    writer.write("d")
    settle(reader, out, 0.5)
    writer.write(":wq\r")
    code = finish_session(reader, out, pid)
    t.assert_equal(0, code, "the editor exits with status 0 after Vjd and :wq")
    t.assert_equal("three\n", File.read(visual_path), "Vjd deleted the first two lines")

    # A Ruby file is drawn in colors: the keyword and the string are each
    # preceded by a color sequence, whatever depth the terminal's environment
    # gives, and :syntax off draws them plain again.
    ruby_path = "#{DIR}/colors.rb"
    File.write(ruby_path, "def go\n  \"hi\"\nend\n")
    reader, writer, pid = PTY.spawn(BIN, ruby_path)
    writer.winsize = [24, 80]
    out = +"".b
    settle(reader, out, 0.5)
    t.assert_true(out.include?("3L, 18B"), "the editor drew its first frame for the color check")
    t.assert_true(out.match?(/\e\[0;[0-9;]+mdef/), "def is written after a color sequence")
    t.assert_true(out.match?(/\e\[0;[0-9;]+m"hi"/), "the string is written after a color sequence")
    writer.write(":set nocul\r")
    settle(reader, out, 0.5)
    mark = out.bytesize
    writer.write(":syntax off\r")
    settle(reader, out, 0.5)
    t.assert_true(out.byteslice(mark, out.bytesize - mark).include?("\e[0mdef"), ":syntax off writes def in the normal group")
    writer.write(":q\r")
    code = finish_session(reader, out, pid)
    t.assert_equal(0, code, "the editor exits with status 0 after the color check")

    # A file that is not UTF-8 opens with its first illegal line named,
    # each illegal byte drawn as U+FFFD, and is written back byte for byte;
    # yanking and putting such a line raises nothing.
    hostile_path = "#{DIR}/latin1.txt"
    hostile = "ok\ncaf\xE9 \xF4\x90\x80\x80\n\xC0\xAF\n".b
    File.binwrite(hostile_path, hostile)
    reader, writer, pid = PTY.spawn(BIN, hostile_path)
    writer.winsize = [24, 80]
    out = +"".b
    settle(reader, out, 0.5)
    t.assert_true(out.include?("[ILLEGAL BYTE in line 2] 3L, 16B"), "a file that is not UTF-8 opens with its first illegal line named")
    t.assert_true(out.include?("caf\u{FFFD} \u{FFFD}\u{FFFD}\u{FFFD}\u{FFFD}".b), "each illegal byte is drawn as one replacement character")
    writer.write(":w\r")
    settle(reader, out, 0.5)
    t.assert_equal(hostile, File.binread(hostile_path), "writing the unedited file gives back its bytes")
    writer.write("jyyp")
    settle(reader, out, 0.5)
    writer.write(":q!\r")
    code = finish_session(reader, out, pid)
    t.assert_equal(0, code, "the editor exits with status 0 after yanking and putting an illegal line")

    # A hostile project: a .caratrc linked to /dev/zero is refused, not
    # read, and the editor starts, says why, and quits. Then a .caratrc
    # with a huge tabstop and a byte that is not UTF-8, under a home whose
    # user file binds a value holding one, which once stopped startup.
    base = "#{Dir.pwd}/#{DIR}/hostile"
    empty_home = "#{base}/empty-home"
    linked = "#{base}/linked"
    make_dirs(empty_home)
    make_dirs(linked)
    fresh("#{linked}/.caratrc")
    File.symlink("/dev/zero", "#{linked}/.caratrc")
    run = hostile_session(linked, empty_home)
    t.assert_true(run.out.include?(".caratrc: is a symbolic link, not read"), "a project .caratrc linked to /dev/zero is refused and the editor says so")
    t.assert_equal(0, run.code, "the editor exits with status 0 after a linked .caratrc")
    bytes = "#{base}/bytes"
    home = "#{base}/home"
    make_dirs(bytes)
    make_dirs("#{home}/.config/carat")
    File.binwrite("#{bytes}/.caratrc", "option.tabstop 999999999\nkeymap.normal \xE9 cursor.down\n".b)
    File.binwrite("#{home}/.config/carat/caratrc", "keymap.normal x a\xFF.b\n".b)
    run = hostile_session(bytes, home)
    t.assert_true(run.out.include?("~/.config/carat/caratrc:1: illegal byte (and 2 more)"), "illegal bytes and a huge tabstop are reported, the user file's first")
    t.assert_equal(0, run.code, "the editor exits with status 0 after hostile configuration lines")

    # SIGTERM ends a running editor cleanly.
    reader, writer, pid = PTY.spawn(BIN, path)
    writer.winsize = [24, 80]
    out = +"".b
    settle(reader, out, 0.5)
    t.assert_true(out.include?("1L, 6B"), "the editor drew its first frame for the signal check")
    Process.kill("TERM", pid)
    code = finish_session(reader, out, pid)
    t.assert_equal(0, code, "SIGTERM ends the editor with status 0")
    t.assert_true(out.end_with?(RESTORED), "SIGTERM restores the cursor and leaves the alternate screen")

    # SIGINT, sent from outside since raw mode reads Ctrl-C as a key, ends
    # it the same way, from insert mode with the bar cursor.
    reader, writer, pid = PTY.spawn(BIN, path)
    writer.winsize = [24, 80]
    out = +"".b
    settle(reader, out, 0.5)
    writer.write("i")
    settle(reader, out, 0.5)
    t.assert_true(out.include?("\e[6 q"), "the editor shows the bar cursor before the interrupt")
    Process.kill("INT", pid)
    code = finish_session(reader, out, pid)
    t.assert_equal(0, code, "SIGINT ends the editor with status 0")
    t.assert_true(out.end_with?(RESTORED), "SIGINT restores the cursor and leaves the alternate screen")

    t.finish
  end
end

SmokeEditorTest.main if __FILE__ == $0
