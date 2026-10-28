# Runs build/bin/carat inside a pseudo-terminal: the usage and terminal
# checks, an insert-write-quit session, a quit refused then forced, and
# SIGTERM. Needs the binary that spin build produces; make test builds it
# first. Prints only the harness lines so the snapshot is stable.
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

t = Carat::Testing.new("smoke_editor")

BIN = "build/bin/carat"
DIR = "build/smoke"

unless File.exist?(BIN)
  t.assert_true(false, "#{BIN} exists; run spin build first")
  t.finish
end
Dir.mkdir(DIR) unless File.directory?(DIR)

# Reads until the editor produces nothing for quiet seconds, appending to
# out, so the next write lands while the editor is waiting on input.
def settle(reader, out, quiet)
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

# Reads until the editor closes the terminal, then reaps it.
def finish_session(reader, out, pid)
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

# Usage and terminal checks run without a pseudo-terminal.
_out, err, status = Open3.capture3(BIN)
t.assert_equal("usage: carat FILE\n", err, "no argument prints the usage")
t.assert_equal(1, status.exitstatus, "no argument exits with status 1")
_out, err, status = Open3.capture3(BIN, "#{DIR}/x.txt", stdin_data: "")
t.assert_equal("carat: standard input is not a terminal\n", err, "piped input is refused")
t.assert_equal(1, status.exitstatus, "piped input exits with status 1")

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
t.assert_true(out.end_with?("\e[?1049l"), "the output ends with leaving the alternate screen")

# Quit refused, then forced, on the existing file.
reader, writer, pid = PTY.spawn(BIN, path)
writer.winsize = [24, 80]
out = +"".b
settle(reader, out, 0.5)
t.assert_true(out.include?("1L, 6B"), "the editor shows the existing file message")
mark = out.bytesize
writer.write("x")
settle(reader, out, 0.5)
t.assert_true(out.byteslice(mark, out.bytesize - mark).include?("Not implemented: operator.delete_char"), "x reports itself as not implemented")
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

# SIGTERM ends a running editor cleanly.
reader, writer, pid = PTY.spawn(BIN, path)
writer.winsize = [24, 80]
out = +"".b
settle(reader, out, 0.5)
t.assert_true(out.include?("1L, 6B"), "the editor drew its first frame for the signal check")
Process.kill("TERM", pid)
code = finish_session(reader, out, pid)
t.assert_equal(0, code, "SIGTERM ends the editor with status 0")
t.assert_true(out.end_with?("\e[?1049l"), "SIGTERM leaves the alternate screen")

t.finish
