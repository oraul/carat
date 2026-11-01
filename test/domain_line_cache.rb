require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("domain_line_cache")
D = Carat::Domain

# The code points of a decoded line and the display column where each
# starts, with one more column, the width of the line, through the
# readers, which a plain line answers without arrays.
#: (Carat::Domain::DecodedLine) -> Array[untyped]
def layout_of(decoded)
  codes = []
  cols = []
  i = 0
  while i < decoded.size
    codes << decoded.code(i)
    cols << decoded.col(i)
    i += 1
  end
  cols << decoded.col(i)
  [codes, cols]
end

# Decoding: the code points and the display column where each starts,
# with one more column, the width of the line.
t.table([
  ["ASCII", "ab", [[97, 98], [0, 1, 2]]],
  ["an accented letter is one code point", "é", [[0xE9], [0, 1]]],
  ["a wide character takes two columns", "a中b", [[97, 0x4E2D, 98], [0, 1, 3, 4]]],
  ["a tab reaches the next tabstop", "a\tb", [[97, 9, 98], [0, 1, 4, 5]]],
  ["a C0 control takes two columns as ^X", "a\u0001", [[97, 1], [0, 1, 3]]],
  ["delete and C1 controls take four as <xx>", "\u007F\u009B", [[0x7F, 0x9B], [0, 4, 8]]],
  ["a four-byte character", "\u{1F600}x", [[0x1F600, 120], [0, 2, 3]]],
  ["an empty line", "", [[], [0]]]
]) do |text|
  layout_of(D::DecodedLine.decode(text, 4))
end
t.assert_equal([true, false, false], [D::DecodedLine.decode("ab c", 4).plain, D::DecodedLine.decode("a\tb", 4).plain, D::DecodedLine.decode("é", 4).plain], "a line of printable ASCII is plain, a tab or a UTF-8 character is not")
t.assert_equal([0, 0], [D::DecodedLine.decode("ab c", 4).codes.length, D::DecodedLine.decode("ab c", 4).cols.length], "a plain line keeps no arrays")
t.assert_equal([2, 4, 4], [D::DecodedLine.decode("ab c", 4).index_at(2), D::DecodedLine.decode("ab c", 4).index_at(9), D::DecodedLine.decode("ab c", 4).width], "a plain line's columns are its indexes")
malformed = "a\xFFb".b.force_encoding("UTF-8")
decoded = D::DecodedLine.decode(malformed, 4)
t.assert_equal([malformed.length, D::Utf8::REPLACEMENT], [decoded.size, decoded.code(1)], "a malformed byte is one code point, U+FFFD")
t.assert_equal(D::Utf8.codes("é中x"), [0xE9, 0x4E2D, 120], "the code points of a line")
long = "é" + "a" * 9_999
decoded = D::DecodedLine.decode(long, 4)
t.assert_equal([10_000, 9_999, 10_000], [decoded.size, decoded.col(9_999), decoded.width], "a long UTF-8 line has a column per code point")
t.assert_equal(D::DisplayWidth.column(long, 9_999, 4), decoded.col(9_999), "DisplayWidth.column agrees with the decoded columns")
t.assert_equal(9_999, D::DisplayWidth.col_at(long, 9_999, 4), "col_at on a long UTF-8 line")

# The code point covering a display column.
wide = D::DecodedLine.decode("a中b\tc", 4)
t.assert_equal([0, 1, 1, 2, 3, 3, 4, 5], [wide.index_at(0), wide.index_at(1), wide.index_at(2), wide.index_at(3), wide.index_at(4), wide.index_at(7), wide.index_at(8), wide.index_at(20)], "index_at finds the code point whose cells cover a column")
t.assert_equal([0, 1, 3, 4, 8, 9], [wide.col(0), wide.col(1), wide.col(2), wide.col(3), wide.col(4), wide.col(99)], "col gives the start column, the width past the end")

# The cache: a hit by identity, a miss for a copy, eviction after two
# turns without a fetch, an edited line decoded again.
cache = D::LineCache.new
line = +"def method(arg)"
first = cache.fetch(line, 4)
t.assert_true(cache.fetch(line, 4).equal?(first), "the same line object is a hit")
copy = line.dup
t.assert_equal(false, cache.fetch(copy, 4).equal?(first), "an equal line that is another object is decoded on its own")
t.assert_equal(false, cache.fetch(line, 8).equal?(first), "another tabstop decodes the line again")
cache.fetch(line, 4)
cache.turn
t.assert_true(cache.holds?(line), "a line fetched before a turn is kept one generation")
again = cache.fetch(line, 4)
cache.turn
t.assert_true(cache.fetch(line, 4).equal?(again), "a line fetched in every generation stays")
cache.turn
cache.turn
t.assert_equal(false, cache.holds?(line), "a line not fetched for two turns is evicted")
t.assert_equal(false, cache.holds?(copy), "and so is every other line that left the view")

buffer = D::Buffer.new(["one", "two"], "a.txt", "\n")
before = buffer.line(0)
decoded_before = cache.fetch(before, 4)
buffer.insert(D::Position.new(0, 3), "!")
after = buffer.line(0)
t.assert_equal(false, after.equal?(before), "an edit replaces the line string")
t.assert_equal("one", before, "and leaves the old string unchanged")
t.assert_equal([[111, 110, 101, 33], [0, 1, 2, 3, 4]], layout_of(cache.fetch(after, 4)), "the edited line is decoded again")
t.assert_true(cache.fetch(before, 4).equal?(decoded_before), "the old string still finds its own entry")
t.assert_true(cache.fetch(buffer.line(1), 4).equal?(cache.fetch(buffer.line(1), 4)), "an untouched row is still a hit")

# Many lines grow the table and every one is still found.
lines = []
i = 0
while i < 600
  lines << "line #{i}"
  i += 1
end
entries = []
i = 0
while i < lines.length
  entries << cache.fetch(lines[i], 4)
  i += 1
end
found = 0
i = 0
while i < lines.length
  found += 1 if cache.fetch(lines[i], 4).equal?(entries[i])
  i += 1
end
t.assert_equal(600, found, "a table grown past its capacity finds every line")

# Motions classify code points: a word motion over UTF-8 text.
t.assert_equal([0, 2, 1, 2], [D::Motions.code_class(32, false), D::Motions.code_class(0xE9, false), D::Motions.code_class(40, false), D::Motions.code_class(95, false)], "code classes of a blank, an accented letter, punctuation, and underscore")
t.assert_equal(1, D::Motions.code_class(40, true), "every non-blank is one class for WORDs")
indented = D::Buffer.new(["  \tété", "    "], nil, "\n")
t.assert_equal([3, 3], [indented.first_nonblank(0), indented.first_nonblank(1)], "first_nonblank by bytes before UTF-8 text and on a blank line")
t.assert_equal("  \t", indented.indent_of(0), "indent_of by bytes")

t.finish
