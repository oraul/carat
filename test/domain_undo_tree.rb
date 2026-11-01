require_relative "../carat/test_support"
require_relative "../carat/testing"

t = Carat::Testing.new("domain_undo_tree")
D = Carat::Domain

# A buffer with one edit per call: x at the start of row 0, each closed
# as a transaction of its own and so an undo state.
def buffer_of(lines)
  D::Buffer.new(lines, nil, "\n")
end

def cut(b)
  b.begin_transaction(D::Position.new(0, 0))
  b.delete(D::Range.charwise(D::Position.new(0, 0), D::Position.new(0, 1)))
  b.commit_transaction(D::Position.new(0, 0))
end

def undo(b)
  tree = b.undo
  b.begin_history(D::Position.new(0, 0))
  b.revert(tree.undo_step)
  b.commit_transaction(D::Position.new(0, 0))
  b.settle_saved
end

def go(b, target)
  tree = b.undo
  path = tree.path_to(target)
  b.begin_history(D::Position.new(0, 0))
  i = 0
  while i < path.length
    step = path[i]
    if step < 0
      b.revert(tree.undo_step)
    else
      b.reapply(tree.redo_to(step))
    end
    i += 1
  end
  b.commit_transaction(D::Position.new(0, 0))
  b.settle_saved
end

# Every closed transaction is a state, numbered in time order.
b = buffer_of(["abcd"])
cut(b)
cut(b)
tree = b.undo
t.assert_equal([2, 2, 2, ["cd"]], [tree.last, tree.current, tree.live, b.lines], "two edits make states 1 and 2, and 2 is current")
t.assert_equal([1, 0], [tree.parent_of(2), tree.parent_of(1)], "each state is made on the one before")

# Undo goes to the parent and redo comes back.
undo(b)
t.assert_equal([1, ["bcd"], 2], [tree.current, b.lines, tree.redo_seq], "undo moves to the parent and redo would come back")
b.begin_history(D::Position.new(0, 0))
b.reapply(tree.redo_to(tree.redo_seq))
b.commit_transaction(D::Position.new(0, 0))
t.assert_equal([2, ["cd"]], [tree.current, b.lines], "redo applies the state again")

# History transactions are no states.
t.assert_equal([2, true], [tree.last, b.last_transaction.history], "undo and redo make no state, and their transaction is marked")

# Branching: a change after undo starts a new branch.
b = buffer_of(["abc"])
cut(b)
undo(b)
b.delete(D::Range.charwise(D::Position.new(0, 2), D::Position.new(0, 3)))
tree = b.undo
t.assert_equal([2, 0, ["ab"], 2], [tree.current, tree.parent_of(2), b.lines, tree.root_head], "the new change is state 2 beside state 1, and redo from the root follows it")
t.assert_equal([1, 2], tree.leaves, "both branches end in a leaf")

# g- and g+ order: the path crosses branches in number order.
t.assert_equal([-2, 1], tree.path_to(1), "from 2 to 1: undo 2, redo 1")
go(b, 1)
t.assert_equal([1, ["bc"]], [tree.current, b.lines], "state 1 is reached across the branch")
t.assert_equal([1, 1], [tree.root_head, tree.redo_seq < 0 ? 1 : 0], "the root's head follows the branch walked")
go(b, 0)
t.assert_equal(["abc"], b.lines, "the root is the original text")
go(b, 2)
t.assert_equal(["ab"], b.lines, "and state 2 is reached again")
t.assert_equal([1, 0, -1], [tree.nearest(1, true), tree.nearest(0, true), tree.nearest(3, false)], "nearest finds kept states and the root")

# Trimming at the levels: the oldest state merges into the root when it
# is on the way to the current state.
b = buffer_of(["abcdef"])
tree = b.undo
f = D::BufferFeed.new
f.undolevels = 3
b.feed = f
i = 0
while i < 5
  cut(b)
  i += 1
end
t.assert_equal([3, 2, 3, 5, ["f"]], [tree.live, tree.root, tree.parents.length, tree.current, b.lines], "five states at three levels keep 3 to 5 over the root 2")
t.assert_equal(2, tree.root_depth, "the root counts the changes merged into it")
undo(b)
undo(b)
undo(b)
t.assert_equal([2, -1, ["cdef"]], [tree.current, tree.undo_seq, b.lines], "undo stops at the root, the text after state 2")

# Trimming drops a branch that is not on the way to the current state.
b = buffer_of(["abcd"])
f = D::BufferFeed.new
f.undolevels = 2
b.feed = f
cut(b)
cut(b)
tree = b.undo
undo(b)
undo(b)
b.insert(D::Position.new(0, 0), "X")
t.assert_equal([3, 1, 3, -1, ["Xabcd"]], [tree.current, tree.live, tree.root_head, tree.slot(1), b.lines], "the old branch from the root is dropped with its states")

# Levels of 0 keep nothing to undo.
b = buffer_of(["ab"])
f = D::BufferFeed.new
f.undolevels = 0
b.feed = f
cut(b)
t.assert_equal([0, -1, 1], [b.undo.live, b.undo.undo_seq, b.undo.root], "no state is kept and the root is the current text")

# Saved-state tracking: the write marks the current state, and undo or
# redo back to it clears the modified flag.
b = buffer_of(["abc"])
cut(b)
b.mark_saved
cut(b)
t.assert_true(b.modified?, "an edit after the write modifies the buffer")
undo(b)
t.assert_equal([false, 1, 1], [b.modified?, b.undo.saved, b.undo.save_of(1)], "undo back to the written state clears the flag and the state keeps its write number")
undo(b)
t.assert_true(b.modified?, "undo past it modifies the buffer again")
go(b, 1)
t.assert_true(!b.modified?, "coming back clears it again")

# A write while the transaction is open marks the state it becomes.
b = buffer_of(["abc"])
b.begin_transaction(D::Position.new(0, 0))
b.reload(["xyz"])
b.commit_transaction(D::Position.new(0, 0))
t.assert_equal([1, 1, false], [b.undo.current, b.undo.saved, b.modified?], "a reload inside a command is the saved state")

# A fresh buffer is at its saved state; undoing to it clears the flag.
b = buffer_of(["abc"])
cut(b)
undo(b)
t.assert_true(!b.modified?, "undo to the loaded text clears the flag")

# Memory: a state shares its line strings with the buffer.
lines = []
i = 0
while i < 1000
  lines << "line #{i}"
  i += 1
end
b = buffer_of(lines)
b.set_lines(500, 501, ["changed"])
state = b.undo.transaction_at(b.undo.slot(1))
change = state.record_at(0)
t.assert_equal([1, 1, 1], [state.size, change.removed.length, change.inserted.length], "a one-line change keeps one removed and one inserted line")
t.assert_true(change.inserted[0].equal?(b.lines[500]), "the inserted line is the buffer's own string")
undo(b)
t.assert_true(b.lines[500].equal?(change.removed[0]), "undo puts the very removed string back")

# Typing on one line keeps one record per state.
b = buffer_of(["ab"])
b.begin_transaction(D::Position.new(0, 0))
b.insert(D::Position.new(0, 1), "x")
b.insert(D::Position.new(0, 2), "y")
b.insert(D::Position.new(0, 3), "\n")
b.insert(D::Position.new(1, 0), "z")
b.commit_transaction(D::Position.new(1, 1))
state = b.undo.transaction_at(b.undo.slot(1))
t.assert_equal([1, ["ab"], ["axy", "zb"]], [state.size, state.record_at(0).removed, state.record_at(0).inserted], "records inside the lines the one before inserted merge into it")
undo(b)
t.assert_equal(["ab"], b.lines, "and the merged record undoes the whole session")

# The U line: a run of changes on one row saves the row's text before it.
b = buffer_of(["abc", "def"])
cut(b)
cut(b)
t.assert_equal([0, "abc"], [b.undo.line_row, b.undo.line_text], "the line before the first change of the run is saved")
b.set_lines(1, 2, ["DEF"])
t.assert_equal([1, "def"], [b.undo.line_row, b.undo.line_text], "a change on another row saves that row")
b.set_lines(0, 1, [])
t.assert_equal(-1, b.undo.line_row, "a change that removes a line forgets it")

# Scratch buffers keep no history.
b = buffer_of(["a"])
b.owner = "tree"
cut(b)
t.assert_equal([0, -1], [b.undo.live, b.undo.undo_seq], "a scratch buffer keeps no state")

# Times come from the feed.
b = buffer_of(["abc"])
f = D::BufferFeed.new
f.now = 12.5
b.feed = f
cut(b)
t.assert_equal(12.5, b.undo.time_of(1), "a state keeps the time of the command")

t.finish
