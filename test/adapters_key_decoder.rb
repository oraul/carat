require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module AdaptersKeyDecoderTest
  K = Carat::Domain::Key
  Decoder = Carat::Adapters::KeyDecoder

  def self.main
    t = Carat::Testing.new("adapters_key_decoder")

    # One read each: rows are [label, bytes, expected codes]. They prove the
    # key-input scenarios "Arrow keys", "Tilde-terminated keys", "SS3 form",
    # "Modified arrow", and
    # "Ctrl-PageDown and Ctrl-PageUp decode to their own keys".
    t.table([
      ["ascii letter", "a", [97]],
      ["several letters", "abc", [97, 98, 99]],
      ["multi-byte character", "é", [233]],
      ["enter and ctrl-c", "\r\x03", [13, 3]],
      ["backspace", "\x7f", [127]],
      ["arrow up", "\e[A", [K::UP]],
      ["arrow down", "\e[B", [K::DOWN]],
      ["arrow right", "\e[C", [K::RIGHT]],
      ["arrow left", "\e[D", [K::LEFT]],
      ["delete", "\e[3~", [K::DELETE]],
      ["page up", "\e[5~", [K::PAGE_UP]],
      ["ss3 home", "\eOH", [K::HOME]],
      ["ss3 f1", "\eOP", [K::F1]],
      ["csi f5", "\e[15~", [K::F5]],
      ["modified arrow: Alt is ignored", "\e[1;3C", [K::RIGHT]],
      ["Ctrl and Shift arrows decode to their own keys: ctrl left", "\e[1;5D", [K::CTRL_LEFT]],
      ["Ctrl and Shift arrows decode to their own keys: ctrl right", "\e[1;5C", [K::CTRL_RIGHT]],
      ["Ctrl and Shift arrows decode to their own keys: shift left", "\e[1;2D", [K::SHIFT_LEFT]],
      ["Ctrl and Shift arrows decode to their own keys: shift right", "\e[1;2C", [K::SHIFT_RIGHT]],
      ["ctrl shift left is ctrl left", "\e[1;6D", [K::CTRL_LEFT]],
      ["shift alt right is shift right", "\e[1;4C", [K::SHIFT_RIGHT]],
      ["Shift-Tab decodes to its own key", "\e[Z", [K::SHIFT_TAB]],
      ["ctrl page down", "\e[6;5~", [K::CTRL_PAGE_DOWN]],
      ["ctrl page up", "\e[5;5~", [K::CTRL_PAGE_UP]],
      ["ctrl shift page down is ctrl page down", "\e[6;6~", [K::CTRL_PAGE_DOWN]],
      ["shift page down is page down", "\e[6;2~", [K::PAGE_DOWN]],
      ["ctrl delete is delete", "\e[3;5~", [K::DELETE]],
      ["alt x", "\ex", [120 | K::ALT]],
      ["alt multi-byte", "\eé", [233 | K::ALT]],
      ["double escape leaves one pending", "\e\e", [27]],
      ["arrow then letter", "\e[Ax", [K::UP, 120]],
      ["unknown csi", "\e[99z", [K::UNKNOWN]],
      ["invalid utf-8 byte", "\xff", [0xFFFD]]
    ]) { |bytes| Decoder.new.feed(bytes) }

    # Split reads.
    d = Decoder.new
    first = d.feed("\xc3".b)
    second = d.feed("\xa9".b)
    t.assert_equal([], first, "first byte of a character produces nothing")
    t.assert_equal([233], second, "second byte completes the character")
    t.assert_equal(false, d.pending?, "nothing pending after the character")

    d = Decoder.new
    t.assert_equal([], d.feed("\e"), "lone escape waits")
    t.assert_equal(true, d.pending?, "escape is pending")
    t.assert_equal([27], d.flush, "flush turns the lone escape into the escape key")
    t.assert_equal(false, d.pending?, "nothing pending after flush")

    d = Decoder.new
    d.feed("\e")
    t.assert_equal([K::UP], d.feed("[A"), "escape followed by a sequence in the next read")

    d = Decoder.new
    d.feed("\e[")
    t.assert_equal([27, 91], d.flush, "flush of a partial sequence yields escape and the bracket")

    d = Decoder.new
    d.feed("\xe6".b)
    t.assert_equal([], d.flush, "flush drops an incomplete character")
    t.assert_equal(false, d.pending?, "nothing pending after dropping")

    # Bracketed paste: rows are [label, bytes, expected codes]. The text
    # between the marks is flagged as pasted and never decoded as keys.
    # They prove the key-input scenarios "Escape and colon in a paste are text"
    # (the escape and colon rows), "Newlines in a paste" (the LF, CR, and CRLF rows),
    # and "A paste split across reads" (with the split reads below).
    pa = K::PASTED
    t.table([
      ["paste: plain text", "\e[200~ab\e[201~", [97 | pa, 98 | pa]],
      ["paste: an Escape and a colon are text, not keys", "\e[200~a\e:w!\e[201~", [97 | pa, 0x3A | pa, 119 | pa, 0x21 | pa]],
      ["paste: a lone Escape before the end mark is dropped", "\e[200~\e\e[201~", []],
      ["paste: an empty paste", "\e[200~\e[201~", []],
      ["paste: keys before and after", "x\e[200~y\e[201~z", [120, 121 | pa, 122]],
      ["paste: a key after the paste is a key again", "\e[200~a\e[201~\e[A", [97 | pa, K::UP]],
      ["paste: two pastes in one read", "\e[200~a\e[201~\e[200~b\e[201~", [97 | pa, 98 | pa]],
      ["paste: an arrow sequence inside is text", "\e[200~\e[A\e[201~", [0x5B | pa, 65 | pa]],
      ["paste: LF is a newline", "\e[200~a\nb\e[201~", [97 | pa, 13 | pa, 98 | pa]],
      ["paste: CR is a newline", "\e[200~a\rb\e[201~", [97 | pa, 13 | pa, 98 | pa]],
      ["paste: CRLF is one newline", "\e[200~a\r\nb\e[201~", [97 | pa, 13 | pa, 98 | pa]],
      ["paste: two blank lines are two newlines", "\e[200~\n\n\e[201~", [13 | pa, 13 | pa]],
      ["paste: a tab is kept", "\e[200~\t\e[201~", [9 | pa]],
      ["paste: other control bytes and DEL are dropped", "\e[200~a\x01\x03\x7fb\e[201~", [97 | pa, 98 | pa]],
      ["paste: a multi-byte character", "\e[200~é日\e[201~", [233 | pa, 0x65E5 | pa]],
      ["paste: an illegal byte is U+FFFD", "\e[200~\xff\e[201~", [0xFFFD | pa]],
      ["paste: a lead byte does not swallow the end mark", "\e[200~\xc3\e[201~z", [0xFFFD | pa, 122]],
      ["paste: trailing blanks are kept", "\e[200~a  \e[201~", [97 | pa, 32 | pa, 32 | pa]],
      ["paste: the end mark outside a paste is an unknown key", "\e[201~", [K::UNKNOWN]]
    ]) { |bytes| Decoder.new.feed(bytes) }

    # A paste split across reads, at the start mark, inside a character,
    # inside the end mark, and with a pause (flush) between the reads.
    d = Decoder.new
    got = d.feed("\e[20")
    got.concat(d.feed("0~a\xc3".b))
    got.concat(d.feed("\xa9\e[2".b))
    got.concat(d.flush)
    t.assert_equal([97 | pa, 233 | pa], got, "paste: a paste split inside the mark and a character, flushed mid-mark, keeps its text")
    t.assert_equal([122], d.feed("01~z"), "paste: the end mark finished in the next read ends the paste")
    t.assert_equal(false, d.pending?, "paste: nothing pending after the paste")

    d = Decoder.new
    d.feed("\e[200~a\e")
    t.assert_equal([], d.flush, "paste: flush does not turn a pasted Escape into the Escape key")
    t.assert_equal([98 | pa], d.feed("b\e[201~"), "paste: the text goes on after a pause; the Escape not starting the end mark is dropped")

    d = Decoder.new
    d.feed("\e[200~a\r")
    t.assert_equal([], d.feed("\n\e[201~"), "paste: a LF after a CR read apart is no second newline")

    d = Decoder.new
    d.feed("\e[200~\xe6".b)
    t.assert_equal([], d.flush, "paste: flush keeps an incomplete character of a paste")
    t.assert_equal(true, d.pending?, "paste: the incomplete character stays pending")

    # Encode is the inverse of feed.
    t.table([
      ["letter", 97, "a"],
      ["escape", 27, "\e"],
      ["up", K::UP, "\e[A"],
      ["delete", K::DELETE, "\e[3~"],
      ["f1", K::F1, "\eOP"],
      ["f12", K::F12, "\e[24~"],
      ["ctrl page down", K::CTRL_PAGE_DOWN, "\e[6;5~"],
      ["ctrl left", K::CTRL_LEFT, "\e[1;5D"],
      ["shift right", K::SHIFT_RIGHT, "\e[1;2C"],
      ["Shift-Tab decodes to its own key: encode", K::SHIFT_TAB, "\e[Z"],
      ["alt x", 120 | K::ALT, "\ex"],
      ["unicode", 0x65E5, "日"],
      ["pasted letter", 97 | K::PASTED, "\e[200~a\e[201~"]
    ]) { |code| Decoder.encode(code) }

    round = [97, 13, 27, 3, K::UP, K::DOWN, K::LEFT, K::RIGHT, K::HOME, K::END_KEY, K::INSERT, K::DELETE, K::PAGE_UP, K::PAGE_DOWN, K::F1, K::F4, K::F5, K::F11, K::F12, K::CTRL_PAGE_UP, K::CTRL_PAGE_DOWN, K::SHIFT_LEFT, K::SHIFT_RIGHT, K::CTRL_LEFT, K::CTRL_RIGHT, K::SHIFT_TAB, 233, 120 | K::ALT, 97 | K::PASTED, 13 | K::PASTED]
    decoded = []
    round.each do |code|
      d = Decoder.new
      got = d.feed(Decoder.encode(code))
      got = d.flush if got.empty?
      decoded.concat(got)
    end
    t.assert_equal(round, decoded, "every key round-trips through encode and feed")

    t.finish
  end
end

AdaptersKeyDecoderTest.main if __FILE__ == $0
