require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("domain_buffer")
D = Carat::Domain

def pos(row, col)
  Carat::Domain::Position.new(row, col)
end

def range(r1, c1, r2, c2)
  Carat::Domain::Range.charwise(pos(r1, c1), pos(r2, c2))
end

# Loading: rows are [label, text, expected lines].
t.table([
  ["trailing newline", "one\ntwo\n", ["one", "two"]],
  ["no trailing newline", "one\ntwo", ["one", "two"]],
  ["empty text", "", [""]],
  ["only a newline", "\n", [""]],
  ["blank line in the middle", "a\n\nb\n", ["a", "", "b"]],
  ["windows endings", "a\r\nb\r\n", ["a", "b"]]
]) { |text| D::Buffer.from_text(text, nil).lines }

t.table([
  ["unix ending", "a\nb\n", "\n"],
  ["windows ending", "a\r\nb\r\n", "\r\n"],
  ["no terminator", "a", "\n"]
]) { |text| D::Buffer.from_text(text, nil).line_ending }

t.table([
  ["windows round trip", "a\r\nb\r\n", "a\r\nb\r\n"],
  ["missing final newline added", "a\nb", "a\nb\n"],
  ["empty becomes one newline", "", "\n"]
]) { |text| D::Buffer.from_text(text, nil).to_text }

fresh = D::Buffer.from_text("x\n", "f.txt")
t.assert_equal(false, fresh.modified, "loaded buffer is unmodified")
t.assert_equal("f.txt", fresh.path, "loaded buffer keeps its path")
t.assert_equal(1, fresh.line_count, "line count")
t.assert_equal("", fresh.line(5), "line outside the buffer is empty")
t.assert_equal(2, fresh.byte_count, "byte count includes the newline")

# Insert: rows are [label, [lines, row, col, text], expected lines].
t.table([
  ["insert within a line", [["xy"], 0, 1, "ab"], ["xaby"]],
  ["insert a newline", [["xy"], 0, 1, "\n"], ["x", "y"]],
  ["insert multi-line text", [["xy"], 0, 1, "1\n2\n3"], ["x1", "2", "3y"]],
  ["insert at line end", [["xy"], 0, 2, "z"], ["xyz"]],
  ["insert past line end clamps", [["xy"], 0, 9, "z"], ["xyz"]],
  ["insert empty text", [["xy"], 0, 1, ""], ["xy"]],
  ["insert on second line", [["a", "b"], 1, 0, "z"], ["a", "zb"]]
]) do |input|
  b = D::Buffer.new(input[0], nil, "\n")
  b.insert(pos(input[1], input[2]), input[3])
  b.lines
end

b = D::Buffer.new(["xy"], nil, "\n")
b.insert(pos(0, 1), "a")
t.assert_true(b.modified, "insert marks the buffer modified")

# Delete: rows are [label, [lines, r1, c1, r2, c2], expected lines].
t.table([
  ["delete within a line", [["abcd"], 0, 1, 0, 3], ["ad"]],
  ["delete across lines", [["ab", "cd", "ef"], 0, 1, 2, 1], ["af"]],
  ["delete a line break", [["ab", "cd"], 0, 2, 1, 0], ["abcd"]],
  ["delete reversed range", [["abcd"], 0, 3, 0, 1], ["ad"]],
  ["delete nothing", [["abcd"], 0, 2, 0, 2], ["abcd"]],
  ["delete whole buffer", [["ab", "cd"], 0, 0, 1, 2], [""]]
]) do |input|
  b = D::Buffer.new(input[0], nil, "\n")
  b.delete(range(input[1], input[2], input[3], input[4]))
  b.lines
end

inclusive = D::Range.new(pos(0, 1), pos(0, 2), :charwise, true)
b = D::Buffer.new(["abcd"], nil, "\n")
b.delete(inclusive)
t.assert_equal(["ad"], b.lines, "inclusive range deletes its end character")

# Replace.
b = D::Buffer.new(["abcd"], nil, "\n")
b.replace(range(0, 1, 0, 3), "XYZ")
t.assert_equal(["aXYZd"], b.lines, "replace within a line")
b = D::Buffer.new(["ab", "cd"], nil, "\n")
b.replace(range(0, 1, 1, 1), "-\n-")
t.assert_equal(["a-", "-d"], b.lines, "replace across lines")

# Set lines: rows are [label, [lines, from, to, new lines], expected lines].
t.table([
  ["replace two lines with one", [["a", "b", "c"], 0, 2, ["z"]], ["z", "c"]],
  ["insert lines without removing", [["a", "b"], 1, 1, ["x", "y"]], ["a", "x", "y", "b"]],
  ["remove every line leaves one", [["a", "b"], 0, 2, []], [""]],
  ["append at the end", [["a"], 1, 1, ["b"]], ["a", "b"]]
]) do |input|
  b = D::Buffer.new(input[0], nil, "\n")
  b.set_lines(input[1], input[2], input[3])
  b.lines
end

b = D::Buffer.new(["a", "b"], nil, "\n")
b.set_lines(0, 2, [])
t.assert_true(b.modified, "set_lines marks the buffer modified")

# Modified flag across load, edit, save.
b = D::Buffer.from_text("one\n", "f.txt")
t.assert_equal(false, b.modified, "unmodified after load")
b.insert(pos(0, 0), "x")
t.assert_equal(true, b.modified, "modified after insert")
b.modified = false
t.assert_equal(false, b.modified, "unmodified after save")

# Data semantics the domain relies on: value equality, hashing, immutability.
p1 = pos(2, 3)
p2 = pos(2, 3)
t.assert_true(p1 == p2, "positions are equal by value")
t.assert_true(p1.eql?(p2), "positions are eql by value")
t.assert_equal(p1.hash, p2.hash, "equal positions hash alike")
t.assert_equal("here", { p1 => "here" }[p2], "a position works as a hash key by value")
t.assert_true(p1.frozen?, "positions are frozen")
t.assert_equal([2, 4], p1.with(col: 4).to_a, "with copies a position")
t.assert_equal([2, 3], p1.to_a, "with leaves the original unchanged")
r1 = D::Range.charwise(pos(0, 0), pos(0, 2))
r2 = D::Range.new(pos(0, 0), pos(0, 2), :charwise, false)
t.assert_true(r1 == r2, "ranges are equal by value")
t.assert_true(r1.frozen?, "ranges are frozen")

# Struct semantics the mutable records rely on: positional construction,
# readers and writers, members, and the constructor defaults.
c = D::Cursor.new(2, 3)
t.assert_equal([2, 3, 3], [c.row, c.col, c.want_col], "a cursor starts wanting its column")
c.col = 5
t.assert_equal(5, c.col, "a cursor member has a writer")
c.move_to(4, 1)
t.assert_equal([4, 1], c.to_a, "to_a is the position pair without want_col")
t.assert_equal([:row, :col, :want_col], D::Cursor.members, "cursor members in constructor order")
t.assert_equal(false, c.frozen?, "records are not frozen")
w = D::Window.new
t.assert_equal([0, 0, 0], [w.top, w.left, w.height], "a window starts at the origin with no height")
w.top = 7
t.assert_equal(7, w.top, "a window member has a writer")
t.assert_equal([:lines, :path, :line_ending, :modified], D::Buffer.members, "buffer members in constructor order")
t.assert_equal([:code, :width, :hl], D::Cell.members, "cell members")
o = D::Options.new
t.assert_equal([false, 8, 0], [o.number, o.tabstop, o.scrolloff], "options start with Vim's defaults")

# Read helpers for operators: rows are [label, [lines, range], expected].
def rng(r1, c1, r2, c2, inclusive)
  D::Range.new(D::Position.new(r1, c1), D::Position.new(r2, c2), :charwise, inclusive)
end
t.table([
  ["text of a range on one line", [["abcdef"], rng(0, 1, 0, 4, false)], "bcd"],
  ["text of an inclusive range", [["abcdef"], rng(0, 1, 0, 4, true)], "bcde"],
  ["text of a backward range", [["abcdef"], rng(0, 4, 0, 1, false)], "bcd"],
  ["text of a range over lines", [["ab", "cd", "ef"], rng(0, 1, 2, 1, false)], "b\ncd\ne"],
  ["text of a range to a line end", [["ab", "cd"], rng(0, 1, 0, 2, false)], "b"],
  ["text of an empty range", [["ab"], rng(0, 1, 0, 1, false)], ""]
]) do |input|
  D::Buffer.new(input[0], nil, "\n").text_of(input[1])
end
b = D::Buffer.new(["  ab", "cd", "", "\tef"], nil, "\n")
t.assert_equal(["cd", ""], b.lines_of(1, 2), "lines_of copies the rows")
copy = b.lines_of(0, 0)
copy << "x"
t.assert_equal(4, b.line_count, "lines_of does not share the array")
t.assert_equal([2, 0, 0, 1], [b.first_nonblank(0), b.first_nonblank(1), b.first_nonblank(2), b.first_nonblank(3)], "first_nonblank per row")
t.assert_equal(["  ", "", "", "\t"], [b.indent_of(0), b.indent_of(1), b.indent_of(2), b.indent_of(3)], "indent_of per row")
t.assert_equal("", b.line(9), "a row outside the buffer reads as empty")

t.finish
