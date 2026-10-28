require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("adapters_key_decoder")
K = Carat::Domain::Key
Decoder = Carat::Adapters::KeyDecoder

# One read each: rows are [label, bytes, expected codes].
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
  ["modified arrow", "\e[1;5C", [K::RIGHT]],
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

# Encode is the inverse of feed.
t.table([
  ["letter", 97, "a"],
  ["escape", 27, "\e"],
  ["up", K::UP, "\e[A"],
  ["delete", K::DELETE, "\e[3~"],
  ["f1", K::F1, "\eOP"],
  ["f12", K::F12, "\e[24~"],
  ["alt x", 120 | K::ALT, "\ex"],
  ["unicode", 0x65E5, "日"]
]) { |code| Decoder.encode(code) }

round = [97, 13, 27, 3, K::UP, K::DOWN, K::LEFT, K::RIGHT, K::HOME, K::END_KEY, K::INSERT, K::DELETE, K::PAGE_UP, K::PAGE_DOWN, K::F1, K::F4, K::F5, K::F11, K::F12, 233, 120 | K::ALT]
decoded = []
round.each do |code|
  d = Decoder.new
  got = d.feed(Decoder.encode(code))
  got = d.flush if got.empty?
  decoded.concat(got)
end
t.assert_equal(round, decoded, "every key round-trips through encode and feed")

t.finish
