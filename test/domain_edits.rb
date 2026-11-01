require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("domain_edits")
D = Carat::Domain

def pos(row, col)
  Carat::Domain::Position.new(row, col)
end

def letters(n)
  out = []
  i = 0
  while i < n
    out << "l#{i}"
    i += 1
  end
  out
end

# A table row's values are untyped; the splice takes typed arrays.
#: (untyped) -> Array[String]
def strings(value)
  out = []
  i = 0
  while i < value.length
    out << value[i].to_s
    i += 1
  end
  out
end

# LineSplice.apply: rows are [label, [lines, from, to, new lines], expected].
t.table([
  ["same count overwrites", [["a", "b", "c"], 1, 2, ["x"]], ["a", "x", "c"]],
  ["grow by one", [["a", "b"], 1, 1, ["x"]], ["a", "x", "b"]],
  ["shrink by one", [["a", "b", "c"], 0, 1, []], ["b", "c"]],
  ["overwrite then grow", [["a", "b"], 0, 1, ["x", "y", "z"]], ["x", "y", "z", "b"]],
  ["overwrite then shrink", [["a", "b", "c", "d"], 0, 3, ["x"]], ["x", "d"]],
  ["append at the end", [["a"], 1, 1, ["b", "c"]], ["a", "b", "c"]],
  ["remove everything", [["a", "b"], 0, 2, []], []],
  ["grow above the threshold in the middle", [["a", "b"], 1, 1, letters(12)], ["a"] + letters(12) + ["b"]],
  ["shrink above the threshold in the middle", [["a"] + letters(12) + ["b"], 1, 13, []], ["a", "b"]],
  ["grow above the threshold at the start", [["a"], 0, 0, letters(10)], letters(10) + ["a"]],
  ["shrink above the threshold at the end", [["a"] + letters(10), 1, 11, []], ["a"]]
]) do |input|
  lines = strings(input[0])
  D::LineSplice.apply(lines, input[1].to_i, input[2].to_i, strings(input[3]))
  lines
end

# Every span of a 30-line array against plain array arithmetic, both
# below and above the threshold.
mismatches = 0
cases = 0
from = 0
while from <= 30
  to = from
  while to <= 30
    [0, 1, 3, 9, 20].each do |k|
      base = letters(30)
      fresh = []
      i = 0
      while i < k
        fresh << "n#{i}"
        i += 1
      end
      expected = base[0, from] + fresh + base[to, 30 - to]
      D::LineSplice.apply(base, from, to, fresh)
      mismatches += 1 unless base == expected
      cases += 1
    end
    to += 3
  end
  from += 3
end
t.assert_equal([0, 330], [mismatches, cases], "every span of a 30-line array splices like array arithmetic")

# Buffer splices keep at least one line.
b = D::Buffer.new(["a", "b"], nil, "\n")
b.set_lines(0, 2, [])
t.assert_equal([[""], [""]], [b.lines, b.last_transaction.record_at(0).inserted], "an edit that removes every line inserts one empty line, and its record says so")
b = D::Buffer.new(["a", "b"], nil, "\n")
b.set_lines(5, 9, ["z"])
t.assert_equal(["a", "b", "z"], b.lines, "rows past the end are clamped to an append")

# Change records: one per primitive, sharing the line strings.
b = D::Buffer.new(["a", "b", "c"], nil, "\n")
old = b.lines[1]
b.set_lines(1, 2, [])
rec = b.last_transaction.record_at(0)
t.assert_equal([0, 1, ["b"], [], -1], [rec.buffer_id, rec.row, rec.removed, rec.inserted, rec.delta], "deleting a line records its row and the removed line")
t.assert_true(rec.removed[0].equal?(old), "the removed line is the buffer's own string, not a copy")
t.assert_true(rec.frozen?, "a change record is frozen")
b.insert(pos(0, 1), "1\n2")
rec = b.last_transaction.record_at(0)
t.assert_equal([0, ["a"], ["a1", "2"]], [rec.row, rec.removed, rec.inserted], "a multi-line insert records the split line")
t.assert_true(rec.inserted[0].equal?(b.lines[0]) && rec.inserted[1].equal?(b.lines[1]), "the inserted lines are the strings the buffer holds")
b.insert(pos(0, 0), "x")
b.set_lines(0, 3, ["q"])
t.assert_equal([["a"], ["a1", "2"]], [rec.removed, rec.inserted], "later edits leave an earlier record unchanged: lines are never mutated in place")
b = D::Buffer.new(["ab", "cd"], nil, "\n")
before = b.changes
b.replace(D::Range.charwise(pos(0, 1), pos(1, 1)), "-\n-")
rec = b.last_transaction.record_at(0)
t.assert_equal([["a-", "-d"], 1, 0, ["ab", "cd"], ["a-", "-d"]], [b.lines, b.changes - before, rec.row, rec.removed, rec.inserted], "replace is one change with one record")
b.reload(["x"])
rec = b.last_transaction.record_at(0)
t.assert_equal([["x"], ["a-", "-d"], ["x"], false], [b.lines, rec.removed, rec.inserted, b.modified?], "reload records the whole text and leaves the buffer unmodified")

# The derived modified flag.
b = D::Buffer.from_text("one\n", "f.txt")
t.assert_equal(false, b.modified?, "a loaded buffer is unmodified")
b.insert(pos(0, 0), "x")
t.assert_equal(true, b.modified?, "an edit modifies it")
b.mark_saved
t.assert_equal(false, b.modified?, "a save clears it")
b.insert(pos(0, 0), "y")
b.delete(D::Range.charwise(pos(0, 0), pos(0, 1)))
t.assert_equal([["xone"], true], [b.lines, b.modified?], "editing the text back to the saved text leaves it modified")
b.reload(["one"])
t.assert_equal(false, b.modified?, "a reload clears it")
b.mark_unsaved
t.assert_equal(true, b.modified?, "a buffer whose saved text is gone is modified")

# Transactions group the records of one command.
b = D::Buffer.new(["a", "b", "c", "d"], nil, "\n")
t.assert_equal([true, false], [b.begin_transaction(pos(0, 0)), b.begin_transaction(pos(3, 0))], "a second open joins the first")
b.set_lines(0, 1, [])
b.set_lines(0, 1, [])
b.insert(pos(0, 0), "x")
t.assert_equal([0, true, true], [b.closed_count, b.last_transaction.nil?, b.transaction_open?], "records accumulate while the transaction is open")
b.commit_transaction(pos(0, 1))
tx = b.last_transaction
t.assert_equal([1, false, 3, [0, 0], [0, 1]], [b.closed_count, b.transaction_open?, tx.size, tx.before.to_a, tx.after.to_a], "closing keeps the transaction with its records and the cursor before and after")
t.assert_equal([["a"], ["b"], ["c"], ["xc"]], [tx.record_at(0).removed, tx.record_at(1).removed, tx.record_at(2).removed, tx.record_at(2).inserted], "the records are in the order of the edits")
b.begin_transaction(pos(0, 0))
b.commit_transaction(pos(0, 0))
t.assert_equal([1, true], [b.closed_count, b.last_transaction.equal?(tx)], "a transaction without records is dropped")
b.commit_transaction(pos(0, 0))
t.assert_equal(1, b.closed_count, "closing with none open does nothing")
b.insert(pos(0, 0), "y")
t.assert_equal([2, 1, [0, 0]], [b.closed_count, b.last_transaction.size, b.last_transaction.before.to_a], "an edit outside a transaction is a transaction of its own")

# A transaction's span merges its records over the text before it:
# [first row, rows removed, rows inserted].
b = D::Buffer.new(["a", "b", "c", "d", "e"], nil, "\n")
b.begin_transaction(pos(0, 0))
b.set_lines(3, 4, [])
b.set_lines(1, 1, ["x", "y"])
b.commit_transaction(pos(0, 0))
t.assert_equal([[1, 3, 4], ["a", "x", "y", "b", "c", "e"]], [b.last_transaction.span, b.lines], "two records widen the span to cover both, unchanged rows between included")
b.set_lines(2, 3, ["Y"])
t.assert_equal([2, 1, 1], b.last_transaction.span, "one record is its own span")
b.begin_transaction(pos(0, 0))
b.set_lines(4, 5, [])
b.set_lines(0, 1, [])
b.commit_transaction(pos(0, 0))
t.assert_equal([0, 5, 3], b.last_transaction.span, "a record above an earlier one moves the span's start")

# A transaction joined by records of another cause is the editor's.
b = D::Buffer.new(["a"], nil, "\n")
b.begin_transaction(pos(0, 0))
b.last_transaction
tx = b.transaction
tx.add(D::ChangeRecord.new(0, 0, [], []), "probe")
t.assert_equal("probe", tx.cause, "the first record gives the cause")
tx.add(D::ChangeRecord.new(0, 0, [], []), "probe")
t.assert_equal("probe", tx.cause, "records of the same cause keep it")
tx.add(D::ChangeRecord.new(0, 0, [], []), "")
t.assert_equal("", tx.cause, "a record of another cause makes it the editor's")

# revert_to undoes the open transaction's records after a count.
b = D::Buffer.new(["one", "two", "three"], nil, "\n")
b.place_sign("p", 0, 2, "S")
b.begin_transaction(pos(0, 0))
b.insert(pos(0, 0), "x")
mark = b.transaction_size
changes = b.changes
b.set_lines(1, 2, [])
b.insert(pos(0, 0), "a\nb")
b.revert_to(mark)
t.assert_equal([["xone", "two", "three"], 1, changes, "S"], [b.lines, b.transaction_size, b.changes, b.sign_at(2)], "the later records are undone, the earlier kept, and the signs moved back")
b.commit_transaction(pos(0, 0))

# Signs move with their lines, one layer per plugin in priority order.
b = D::Buffer.new(["a", "b", "c", "d"], nil, "\n")
b.place_sign("git", 1, 2, "G")
b.set_lines(0, 0, ["new"])
t.assert_equal(["", "G"], [b.sign_at(2), b.sign_at(3)], "a line inserted above moves the sign down")
b.insert(pos(3, 0), "x")
t.assert_equal("G", b.sign_at(3), "editing the line keeps its sign")
b.insert(pos(3, 1), "\nsplit")
t.assert_equal(["G", ""], [b.sign_at(3), b.sign_at(4)], "splitting the line keeps the sign on its first part")
b.set_lines(0, 2, [])
t.assert_equal("G", b.sign_at(1), "lines deleted above move it up")
b.set_lines(1, 2, [])
t.assert_equal([false, ""], [b.sign_at(1) == "G", b.sign_at(0)], "deleting its line removes it")
b = D::Buffer.new(["a", "b"], nil, "\n")
b.place_sign("second", 5, 0, "2")
b.place_sign("first", 1, 0, "1")
b.place_sign("first", 1, 0, "!")
t.assert_equal(["!", "first"], [b.sign_at(0), b.layer_at(0).owner], "the higher priority shows and a plugin replaces only its own sign")
t.assert_equal([1, "2"], [b.clear_signs("first"), b.sign_at(0)], "clearing one plugin's signs shows the other's")
t.assert_equal(0, b.clear_signs("nobody"), "clearing signs never placed counts none")
marks = [0, 1, 0, 2, 0, 0, 0, 0, 0, 0, 3]
D::LineSplice.shift_marks(marks, 1, 0, 10)
t.assert_equal([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0, 0, 0, 3], marks, "a large insertion moves the tail in one pass")
D::LineSplice.shift_marks(marks, 2, 12, 0)
t.assert_equal([0, 0, 0, 0, 0, 0, 0, 0, 3], marks, "a large deletion closes the gap")

t.finish
