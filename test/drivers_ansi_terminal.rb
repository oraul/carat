require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# AnsiTerminal over two real pipes, one for the key bytes the terminal
# sends and one for the screen: the OSC 11 query on enter, the answer
# taken out of the key bytes, and the background it reports.
module DriversAnsiTerminalTest
  B = Carat::Domain::TerminalBackground

  # A terminal reading keys from the first pipe and writing to the second.
  #: (IO, IO) -> Carat::Drivers::AnsiTerminal
  def self.made(input, output)
    Carat::Drivers::AnsiTerminal.new(input: input, output: output)
  end

  # What one read answers without waiting, "nil" for nil.
  #: (Carat::Drivers::AnsiTerminal) -> String
  def self.read(term)
    bytes = term.read_key(0.0)
    return "nil" if bytes.nil?
    bytes.to_s
  end

  # Sends bytes as the terminal would, then reads once.
  #: (Carat::Drivers::AnsiTerminal, IO, String) -> String
  def self.send_and_read(term, sender, bytes)
    sender.write(bytes)
    sender.flush
    read(term)
  end

  # Everything written to the screen so far.
  #: (IO) -> String
  def self.screen_text(io)
    return "" if IO.select([io], nil, nil, 0.0).nil?
    io.readpartial(4096).to_s
  end

  def self.main
    t = Carat::Testing.new("drivers_ansi_terminal")
    dark = "\e]11;rgb:1e1e/1e1e/2e2e\e\\"
    light = "\e]11;rgb:ffff/ffff/ffff\a"

    # The first frame waits for no reply: enter writes the query and reads
    # nothing, a key typed before it is still the next read.
    keys = IO.pipe
    screen = IO.pipe
    term = made(keys[0], screen[1])
    keys[1].write("j")
    keys[1].flush
    term.enter
    term.write("frame")
    t.assert_equal(B::QUERY + "frame", screen_text(screen[0]), "The first frame waits for no reply: the query, then the frame")
    t.assert_equal("", term.background, "The first frame waits for no reply: the background is unknown")
    t.assert_equal("j", read(term), "The first frame waits for no reply: enter read no key")

    # Before enter nothing is asked, so nothing is taken out.
    keys = IO.pipe
    screen = IO.pipe
    term = made(keys[0], screen[1])
    t.assert_equal(light, send_and_read(term, keys[1], light), "before enter an answer's bytes are keys")
    t.assert_equal(["", ""], [term.background, screen_text(screen[0])], "before enter nothing is asked")

    # A dark reply.
    keys = IO.pipe
    term = made(keys[0], IO.pipe[1])
    term.enter
    t.assert_equal("jk", send_and_read(term, keys[1], "j" + dark + "k"), "A dark reply: only the typed keys arrive")
    t.assert_equal("dark", term.background, "A dark reply: the background is dark")
    t.assert_equal(light, send_and_read(term, keys[1], light), "after an answer a second one is keys")
    t.assert_equal("dark", term.background, "after an answer the background stays")

    # A light reply, whole and split across two reads.
    keys = IO.pipe
    term = made(keys[0], IO.pipe[1])
    term.enter
    t.assert_equal("nil", send_and_read(term, keys[1], light), "A light reply: a read of the answer alone has no keys")
    t.assert_equal("light", term.background, "A light reply: the background is light")

    keys = IO.pipe
    term = made(keys[0], IO.pipe[1])
    term.enter
    t.assert_equal("a", send_and_read(term, keys[1], "a\e]11;rgb:ff"), "A light reply split: the keys before it arrive, its start is held")
    t.assert_equal("x", send_and_read(term, keys[1], "ff/ffff/ffff\e\\x"), "A light reply split: the rest is taken out")
    t.assert_equal("light", term.background, "A light reply split: the background is light")

    keys = IO.pipe
    term = made(keys[0], IO.pipe[1])
    term.enter
    t.assert_equal("nil", send_and_read(term, keys[1], "\e]11;rgb:ffff/ffff/ffff\e"), "A light reply split inside ST: held")
    t.assert_equal("x", send_and_read(term, keys[1], "\\x"), "A light reply split inside ST: the backslash is taken out")
    t.assert_equal("light", term.background, "A light reply split inside ST: the background is light")

    # A malformed reply: too long, cut short, or in another format.
    rows = [
      ["too long", "\e]11;rgb:" + ("f" * 60) + "\e\\j", "j"],
      ["too long, never ended", "\e]11;rgb:" + ("f" * 60), "nil"],
      ["cut short by an arrow key", "\e]11;rgb:ff\e[A", "\e[A"],
      ["cut short by Enter", "\e]11;rgb:ff\rj", "\rj"],
      ["a hash color", "\e]11;#ffffff\aj", "j"],
      ["two channels", "\e]11;rgb:ffff/ffff\aj", "j"],
      ["bytes that are not UTF-8", "\e]11;rgb:\xff\xfe/ffff/ffff\aj", "j"]
    ]
    rows.each do |row|
      label = row[0].to_s
      keys = IO.pipe
      term = made(keys[0], IO.pipe[1])
      term.enter
      t.assert_equal(row[2].to_s, send_and_read(term, keys[1], row[1].to_s), "A malformed reply, #{label}: no reply byte arrives as a key")
      t.assert_equal("", term.background, "A malformed reply, #{label}: the background stays unknown")
      t.assert_equal(light, send_and_read(term, keys[1], light), "A malformed reply, #{label}: it ends the asking")
    end

    keys = IO.pipe
    term = made(keys[0], IO.pipe[1])
    term.enter
    t.assert_equal("nil", send_and_read(term, keys[1], "\e]11;rgb:ffff/"), "A malformed reply cut short before a timeout: held")
    t.assert_equal("nil", read(term), "A malformed reply cut short before a timeout: the timeout drops it")
    t.assert_equal(["j", ""], [send_and_read(term, keys[1], "j"), term.background], "A malformed reply cut short before a timeout: the next key arrives, the background unknown")

    # No reply: every key arrives unchanged, a lone escape included.
    keys = IO.pipe
    term = made(keys[0], IO.pipe[1])
    term.enter
    t.assert_equal("abc", send_and_read(term, keys[1], "abc"), "No reply: typed keys arrive")
    t.assert_equal("nil", read(term), "No reply: a read with nothing to read times out")
    t.assert_equal("\e[A", send_and_read(term, keys[1], "\e[A"), "No reply: a key sequence arrives")
    t.assert_equal("\e", send_and_read(term, keys[1], "\e"), "No reply: a lone escape arrives at once")
    t.assert_equal("\e]", send_and_read(term, keys[1], "\e]"), "No reply: the start of an OSC shorter than the introducer arrives")
    t.assert_equal("", term.background, "No reply: the background stays unknown")
    t.assert_equal("nil", send_and_read(term, keys[1], dark), "No reply yet: a late answer is taken out")
    t.assert_equal("dark", term.background, "No reply yet: a late answer is still read")

    fake = Carat::Doubles::FakeTerminal.new(clock: Carat::Doubles::ManualClock.new, rows: 24, cols: 80)
    t.assert_equal("", fake.background, "the double reports no background")

    t.finish
  end
end

DriversAnsiTerminalTest.main if __FILE__ == $0
