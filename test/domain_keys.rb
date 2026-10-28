require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("domain_keys")
K = Carat::Domain::Key
N = Carat::Domain::KeyNotation

# Parsing: rows are [label, notation, expected codes], leader " ".
t.table([
  ["plain characters", "abc", [97, 98, 99]],
  ["sequence with named keys", ":w<CR>", [58, 119, 13]],
  ["escape", "<Esc>", [27]],
  ["case-insensitive name", "<esc>", [27]],
  ["control key", "<C-r>", [18]],
  ["control uppercase letter", "<C-R>", [18]],
  ["control bracket", "<C-[>", [27]],
  ["alt key", "<A-x>", [120 | K::ALT]],
  ["meta spelling", "<M-x>", [120 | K::ALT]],
  ["leader expands", "<leader>w", [32, 119]],
  ["space", "<Space>", [32]],
  ["tab and backspace", "<Tab><BS>", [9, 127]],
  ["arrows", "<Up><Down><Left><Right>", [K::UP, K::DOWN, K::LEFT, K::RIGHT]],
  ["home end del", "<Home><End><Del>", [K::HOME, K::END_KEY, K::DELETE]],
  ["page keys and insert", "<PageUp><PageDown><Insert>", [K::PAGE_UP, K::PAGE_DOWN, K::INSERT]],
  ["function keys", "<F1><F12>", [K::F1, K::F12]],
  ["lt and bar", "<lt><Bar>", [60, 124]],
  ["unicode character", "é", [233]],
  ["empty", "", []]
]) { |text| N.parse(text, " ").codes }

bad = N.parse("<Nope>", " ")
t.assert_equal(false, bad.ok?, "malformed notation is not ok")
t.assert_equal("unknown key <Nope>", bad.error, "malformed notation names the key")
t.assert_equal([], bad.codes, "malformed notation yields no codes")
unclosed = N.parse("<C-", " ")
t.assert_equal([60, 67, 45], unclosed.codes, "an unclosed bracket is the less-than character itself")
no_leader = N.parse("<leader>", "")
t.assert_equal(false, no_leader.ok?, "leader with no leader configured is an error")
nested = N.parse("<leader>x", "<Space>")
t.assert_equal([32, 120], nested.codes, "leader written in notation")

# Formatting: rows are [label, code, expected notation].
t.table([
  ["up", K::UP, "<Up>"],
  ["enter", 13, "<CR>"],
  ["escape", 27, "<Esc>"],
  ["control c", 3, "<C-c>"],
  ["letter", 97, "a"],
  ["space", 32, "<Space>"],
  ["less than", 60, "<lt>"],
  ["alt x", 120 | K::ALT, "<A-x>"],
  ["nul", 0, "<C-@>"],
  ["delete", K::DELETE, "<Del>"],
  ["f5", K::F5, "<F5>"]
]) { |code| N.format(code) }

t.table([
  ["letter is printable", 97, true],
  ["space is printable", 32, true],
  ["unicode is printable", 0x65E5, true],
  ["control is not printable", 3, false],
  ["backspace is not printable", 127, false],
  ["special is not printable", K::UP, false],
  ["alt is not printable", 120 | K::ALT, false]
]) { |code| K.printable?(code) }

t.assert_equal(120, K.base(120 | K::ALT), "base strips the alt flag")
t.assert_equal(true, K.alt?(120 | K::ALT), "alt? sees the flag")
t.assert_equal("日", K.char(0x65E5), "char encodes a code point")

t.finish
