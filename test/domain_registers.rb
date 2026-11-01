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
r.write("a", block)
r.write("A", D::RegisterEntry.charwise("e"))
t.assert_equal(["ab\ncd\ne", :blockwise], [r.read("a").text, r.read("a").kind], "appending to a block register adds a row")

# Names.
t.table([
  ["the quote", "\"", true],
  ["a lowercase letter", "a", true],
  ["z", "z", true],
  ["an uppercase letter", "Q", true],
  ["a digit", "1", false],
  ["the black hole", "_", false],
  ["a percent sign", "%", false],
  ["two letters", "ab", false],
  ["empty", "", false]
]) do |name|
  D::Registers.valid_name?(name)
end

# Reads and writes.
r = D::Registers.new
t.assert_equal(nil, r.read(""), "the unnamed register starts empty")
t.assert_equal(nil, r.read("a"), "a named register starts empty")
r.write("", entry("x", false))
t.assert_equal("x", r.read("").text, "writing with no name fills the unnamed register")
t.assert_equal("x", r.read("\"").text, "the quote reads the unnamed register")
t.assert_equal(nil, r.read("a"), "and no named register")
r.write("a", entry("one", true))
t.assert_equal(["one", "one"], [r.read("a").text, r.read("").text], "a named write fills the name and the unnamed register")
r.write("A", entry("two", true))
t.assert_equal(["one\ntwo", "two"], [r.read("a").text, r.read("").text], "an uppercase write appends and the unnamed register holds the new text")
t.assert_equal("one\ntwo", r.read("A").text, "an uppercase read is the lowercase register")
r.write("B", entry("b", false))
t.assert_equal(["b", false], [r.read("b").text, r.read("b").linewise?], "appending to an empty register stores the entry")
r.write("\"", entry("q", false))
t.assert_equal(["q", "b"], [r.read("").text, r.read("b").text], "writing the quote register writes only the unnamed register")
r.write("b", entry("new", false))
t.assert_equal("new", r.read("b").text, "a lowercase write replaces")

t.finish
