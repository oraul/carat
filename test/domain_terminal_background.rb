require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# TerminalBackground over the terminal's answers to OSC 11: where an
# answer ends in the input and which background it names.
module DomainTerminalBackgroundTest
  B = Carat::Domain::TerminalBackground

  # A typed helper: a table value is untyped, and an untyped argument
  # widens the library method it reaches for every test (docs/spinel-notes.md).
  def self.parse(text)
    B.parse(text.to_s)
  end

  def self.reply_size(text)
    B.reply_size(text.to_s)
  end

  def self.main
    t = Carat::Testing.new("domain_terminal_background")

    long = "\e]11;rgb:" + ("f" * 60) + "\e\\"

    # A dark reply, A light reply, A malformed reply: the parse.
    t.table([
      ["a dark reply: black, ended by ST", "\e]11;rgb:0000/0000/0000\e\\", "dark"],
      ["a dark reply: a dark grey blue, ended by BEL", "\e]11;rgb:1e1e/1e1e/2e2e\a", "dark"],
      ["a dark reply: just under half", "\e]11;rgb:7f7f/7f7f/7f7f\a", "dark"],
      ["a dark reply: full red is dark", "\e]11;rgb:ffff/0000/0000\a", "dark"],
      ["a light reply: white, ended by BEL", "\e]11;rgb:ffff/ffff/ffff\a", "light"],
      ["a light reply: just over half", "\e]11;rgb:8080/8080/8080\e\\", "light"],
      ["a light reply: two digits a channel", "\e]11;rgb:fd/f6/e3\e\\", "light"],
      ["a light reply: one digit a channel, upper case", "\e]11;rgb:F/F/E\a", "light"],
      ["a light reply: three digits a channel", "\e]11;rgb:fff/fff/fff\a", "light"],
      ["a light reply: rgba, alpha ignored", "\e]11;rgba:ffff/ffff/ffff/0000\e\\", "light"],
      ["a dark reply: rgba, alpha ignored", "\e]11;rgba:0000/0000/0000/ffff\a", "dark"],
      ["a malformed reply: too long", long, ""],
      ["a malformed reply: cut short, no terminator", "\e]11;rgb:ffff/ffff/ffff", ""],
      ["a malformed reply: cut short, two channels", "\e]11;rgb:ffff/ffff\a", ""],
      ["a malformed reply: rgba with three channels", "\e]11;rgba:ffff/ffff/ffff\a", ""],
      ["a malformed reply: four channels for rgb", "\e]11;rgb:ffff/ffff/ffff/ffff\a", ""],
      ["a malformed reply: five digits", "\e]11;rgb:fffff/ffff/ffff\a", ""],
      ["a malformed reply: an empty channel", "\e]11;rgb:/ffff/ffff\a", ""],
      ["a malformed reply: not a hex digit", "\e]11;rgb:gggg/ffff/ffff\a", ""],
      ["a malformed reply: a byte after the channels", "\e]11;rgb:ffff/ffff/ffffx\a", ""],
      ["a malformed reply: a hash color", "\e]11;#ffffff\a", ""],
      ["a malformed reply: the query echoed", "\e]11;?\e\\", ""],
      ["a malformed reply: bytes that are not UTF-8", "\e]11;rgb:\xff\xfe/ffff/ffff\a", ""],
      ["a malformed reply: another OSC", "\e]10;rgb:ffff/ffff/ffff\a", ""],
      ["a malformed reply: the introducer alone", "\e]11;", ""],
      ["a malformed reply: ended by a lone backslash", "\e]11;rgb:ffff/ffff/ffff\\", ""]
    ]) do |text|
      parse(text)
    end

    # Where a reply ends in the bytes of a read: its size through the
    # terminator, the keys after an answer cut short, 0 to hold it.
    t.table([
      ["ends after BEL", "\e]11;rgb:0/0/0\ajk", 15],
      ["ends after ESC \\", "\e]11;rgb:0/0/0\e\\jk", 16],
      ["cut short by a key sequence: ends before its ESC", "\e]11;rgb:ff\e[A", 11],
      ["cut short by Enter: ends before the control byte", "\e]11;rgb:ff\rj", 11],
      ["cut short by DEL: ends before it", "\e]11;rgb:ff\x7f", 11],
      ["not ended, short: held", "\e]11;rgb:ffff/", 0],
      ["ends on ESC, short: held for the backslash", "\e]11;rgb:0/0/0\e", 0],
      ["the introducer alone: held", "\e]11;", 0],
      ["too long with its terminator in the read: through it", long + "j", long.bytesize],
      ["too long and not ended: the whole read", "\e]11;rgb:" + ("f" * 60), 69]
    ]) do |text|
      reply_size(text)
    end

    t.assert_equal("\e]11;?\e\\", B::QUERY, "the query is OSC 11 with ? ended by ST")

    t.finish
  end
end

DomainTerminalBackgroundTest.main if __FILE__ == $0
