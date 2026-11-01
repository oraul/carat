require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("domain_registers")
D = Carat::Domain

def entry(text, linewise)
  Carat::Domain::RegisterEntry.new(text, linewise ? :linewise : :charwise)
end

# Entries.
t.assert_equal(["ab", false], [entry("ab", false).text, entry("ab", false).linewise?], "a charwise entry")
t.assert_equal(["a\nb", true], [D::RegisterEntry.lines(["a", "b"]).text, D::RegisterEntry.lines(["a", "b"]).linewise?], "lines joins with newlines")
t.assert_equal([""], entry("", true).lines, "an empty linewise entry is one empty line")
t.assert_equal(["", ""], entry("\n", true).lines, "two empty lines")
t.assert_equal(["a", "b"], entry("a\nb", true).lines, "lines splits the text")
t.assert_equal(["abcd", false], [D::RegisterEntry.joined(entry("ab", false), entry("cd", false)).text, D::RegisterEntry.joined(entry("ab", false), entry("cd", false)).linewise?], "charwise onto charwise joins")
t.assert_equal(["a\nb", true], [D::RegisterEntry.joined(entry("a", true), entry("b", true)).text, D::RegisterEntry.joined(entry("a", true), entry("b", true)).linewise?], "linewise onto linewise adds lines")
t.assert_equal(["a\nb", true], [D::RegisterEntry.joined(entry("a", false), entry("b", true)).text, D::RegisterEntry.joined(entry("a", false), entry("b", true)).linewise?], "linewise onto charwise becomes linewise")
t.assert_equal(["a\nb", true], [D::RegisterEntry.joined(entry("a", true), entry("b", false)).text, D::RegisterEntry.joined(entry("a", true), entry("b", false)).linewise?], "charwise onto linewise becomes linewise")
t.assert_true(entry("a", false) == entry("a", false), "entries are equal by value")

# Blockwise entries and their joins.
block = D::RegisterEntry.block(["ab", "cd"])
t.assert_equal(["ab\ncd", :blockwise, true, false], [block.text, block.kind, block.blockwise?, block.linewise?], "a block joins its rows with newlines")
t.assert_equal(["ab", "cd"], block.lines, "a block's lines are its rows")
t.assert_equal(["ab\ncd\ne", :blockwise], [D::RegisterEntry.joined(block, entry("e", false)).text, D::RegisterEntry.joined(block, entry("e", false)).kind], "charwise onto a block adds a row")
t.assert_equal(["e\nab\ncd", :blockwise], [D::RegisterEntry.joined(entry("e", false), block).text, D::RegisterEntry.joined(entry("e", false), block).kind], "a block onto charwise becomes a block")
t.assert_equal(:linewise, D::RegisterEntry.joined(block, entry("e", true)).kind, "linewise onto a block becomes linewise")
r = D::Registers.new
r.yank("a", block)
r.yank("A", D::RegisterEntry.charwise("e"))
t.assert_equal(["ab\ncd\ne", :blockwise], [r.read("a").text, r.read("a").kind], "appending to a block register adds a row")

# Names.
t.table([
  ["the quote", "\"", true],
  ["a lowercase letter", "a", true],
  ["z", "z", true],
  ["an uppercase letter", "Q", true],
  ["a digit", "1", true],
  ["the black hole", "_", true],
  ["the small delete register", "-", true],
  ["the read-only registers", ".", true],
  ["a percent sign", "%", true],
  ["the search register", "/", true],
  ["an unknown sign", "#", false],
  ["two letters", "ab", false],
  ["empty", "", false]
]) do |name|
  D::Registers.valid_name?(name)
end

# Reads and writes.
r = D::Registers.new
t.assert_equal(nil, r.read(""), "the unnamed register starts empty")
t.assert_equal(nil, r.read("a"), "a named register starts empty")
r.yank("", entry("x", false))
t.assert_equal("x", r.read("").text, "a yank with no name fills the unnamed register")
t.assert_equal("x", r.read("\"").text, "the quote reads the unnamed register")
t.assert_equal(nil, r.read("a"), "and no named register")
r.yank("a", entry("one", true))
t.assert_equal(["one", "one"], [r.read("a").text, r.read("").text], "a named write fills the name and the unnamed register")
r.yank("A", entry("two", true))
t.assert_equal(["one\ntwo", "two"], [r.read("a").text, r.read("").text], "an uppercase write appends and the unnamed register holds the new text")
t.assert_equal("one\ntwo", r.read("A").text, "an uppercase read is the lowercase register")
r.yank("B", entry("b", false))
t.assert_equal(["b", false], [r.read("b").text, r.read("b").linewise?], "appending to an empty register stores the entry")
r.yank("\"", entry("q", false))
t.assert_equal(["q", "b"], [r.read("").text, r.read("b").text], "writing the quote register writes only the unnamed register")
r.yank("b", entry("new", false))
t.assert_equal("new", r.read("b").text, "a lowercase write replaces")

# Numbered, small delete, and read-only registers.
r = D::Registers.new
r.yank("", entry("y", false))
t.assert_equal(["y", "y"], [r.read("0").text, r.read("").text], "a yank with no name fills register 0")
r.yank("a", entry("z", false))
t.assert_equal(["y", "z"], [r.read("0").text, r.read("").text], "a named yank leaves register 0")
r.delete("", entry("d1", true), true)
r.delete("", entry("d2", true), true)
t.assert_equal(["d2", "d1", "d2"], [r.read("1").text, r.read("2").text, r.read("").text], "big deletes shift down through the numbered registers")
r.delete("", entry("s", false), false)
t.assert_equal(["s", "d2", "s"], [r.read("-").text, r.read("1").text, r.read("").text], "a small delete fills register - and leaves the numbered ones")
r.delete("b", entry("n", false), false)
t.assert_equal(["n", "s"], [r.read("b").text, r.read("-").text], "a small named delete leaves register -")
r.delete("b", entry("N", true), true)
t.assert_equal(["N", "N", "d2"], [r.read("b").text, r.read("1").text, r.read("2").text], "a big named delete fills register 1 too")
i = 0
while i < 9
  r.delete("", entry("k#{i}", true), true)
  i += 1
end
t.assert_equal(["k8", "k0"], [r.read("1").text, r.read("9").text], "register 9 drops the oldest")
before = r.read("").text
r.delete("_", entry("gone", true), true)
r.yank("_", entry("gone", false))
t.assert_equal([before, "k8", nil], [r.read("").text, r.read("1").text, r.read("_")], "the black hole takes nothing")
t.assert_equal([nil, nil, nil, nil], [r.read("."), r.read(":"), r.read("%"), r.read("/")], "the read-only registers start empty")
r.inserted = "typed"
r.command_line = "w"
t.assert_equal(["typed", "w", "a.txt", nil], [r.read(".").text, r.read(":").text, r.read_with_file("%", "a.txt").text, r.read_with_file("%", "")], "they read the inserted text, the command line, and the file name")
t.assert_equal([true, true, true, true, false, false], [D::Registers.read_only?("."), D::Registers.read_only?(":"), D::Registers.read_only?("%"), D::Registers.read_only?("/"), D::Registers.read_only?("a"), D::Registers.read_only?("")], "which names are read-only")

t.finish
