require_relative "../carat/test_support"
require_relative "../carat/testing"

t = Carat::Testing.new("drivers_main_loop")

def editor
  files = Carat::Doubles::MemoryFiles.new
  files.put("a.txt", "one\ntwo\n")
  h = Carat::Doubles::EditorHarness.default(files, 10, 40)
  h.open("a.txt")
  h
end

def loop_over(h, signals)
  Carat::Drivers::MainLoop.new(assembly: h.assembly, terminal: h.terminal, signals: signals)
end

# Without a signal the loop draws once and pumps until the poll limit.
h = editor
signals = Carat::Doubles::ManualSignals.new
signals.terminate_after(4)
writes = h.terminal.writes.length
loop_over(h, signals).run
t.assert_equal([1, 4, 0, false], [h.terminal.writes.length - writes, signals.polls, signals.acknowledged, h.quit?], "the loop draws the first frame and ends at the terminate signal")

# A resize tripped while the loop runs is acknowledged and redrawn.
h = editor
signals = Carat::Doubles::ManualSignals.new
signals.resize_after(2)
signals.terminate_after(4)
writes = h.terminal.writes.length
loop_over(h, signals).run
t.assert_equal([2, 1], [h.terminal.writes.length - writes, signals.acknowledged], "the resize draws a second frame")
t.assert_true(h.terminal.last_write.start_with?("\e[?25l"), "the redraw is a frame")

# A terminate before the loop starts ends it without drawing.
h = editor
signals = Carat::Doubles::ManualSignals.new
signals.terminate
writes = h.terminal.writes.length
loop_over(h, signals).run
t.assert_equal([0, 1], [h.terminal.writes.length - writes, signals.polls], "a terminated loop draws nothing")

# :q typed through the terminal ends the loop through the state.
h = editor
signals = Carat::Doubles::ManualSignals.new
signals.terminate_after(100)
codes = Carat::Domain::KeyNotation.parse(":q<CR>", "").codes
i = 0
while i < codes.length
  h.terminal.push(Carat::Adapters::KeyDecoder.encode(codes[i]))
  i += 1
end
loop_over(h, signals).run
t.assert_equal([true, true], [h.quit?, signals.polls < 100], ":q ends the loop before the poll limit")

# The driver: its handlers set the flags the port reports.
real = Carat::Drivers::Signals.new
t.assert_equal([false, false], [real.terminated?, real.resized?], "no signal at first")
real.install
Process.kill("WINCH", Process.pid)
i = 0
while i < 2000 && !real.resized?
  sleep 0.001
  i += 1
end
t.assert_equal(true, real.resized?, "WINCH sets the resize flag")
real.acknowledge_resize
t.assert_equal(false, real.resized?, "acknowledging clears it")
Process.kill("TERM", Process.pid)
i = 0
while i < 2000 && !real.terminated?
  sleep 0.001
  i += 1
end
t.assert_equal(true, real.terminated?, "TERM sets the terminate flag")

t.finish
