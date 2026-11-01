require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("domain_buffer_list")
D = Carat::Domain

def pos(row, col)
  Carat::Domain::Position.new(row, col)
end

def buffer_named(name)
  Carat::Domain::Buffer.new(["a", "b", "c"], name, "\n")
end

# The buffer list over a tab list whose one window shows the buffer, and
# the state over them.
class Lists < Struct.new(:tabs, :buffers, :state)
end

def lists_over(buffer)
  tabs = D::TabList.new(D::Window.new(buffer))
  buffers = D::BufferList.new(tabs)
  buffers.add(buffer)
  Lists.new(tabs, buffers, D::EditorState.new(tabs, D::Options.new))
end

# The list, the keep or release policy, and loading.
a = buffer_named("a.txt")
w = lists_over(a)
s = w.state
list = w.buffers
t.assert_equal([1, 1, 1], [list.count, w.tabs.tab_count, s.tab.window_count], "one buffer, one tab page, one window")
t.assert_true(s.buffer.equal?(a) && s.window.buffer.equal?(a), "the current window shows the buffer")
one = D::Buffer.from_text("", nil)
two = D::Buffer.from_text("", nil)
list.add(one)
list.add(two)
list.add(one)
t.assert_equal(3, list.count, "a buffer is listed once")
t.assert_equal([1, 2], [list.index_of(one), list.index_of(two)], "two unnamed buffers are told apart by identity")
t.assert_equal([false, false], [w.tabs.shown?(one), w.tabs.shown?(two)], "neither unnamed buffer is shown")
list.release(one)
t.assert_equal(2, list.count, "a clean unshown buffer leaves the list when released")
two.mark_unsaved
list.release(two)
t.assert_equal(2, list.count, "a modified unshown buffer stays hidden")
t.assert_true(list.hidden_modified.equal?(two), "it is the hidden modified buffer")
t.assert_true(list.any_modified?, "the list has a modified buffer")
list.release(a)
t.assert_equal(2, list.count, "a shown buffer stays")
b = buffer_named("b.txt")
list.load(b)
t.assert_equal([true, 2, -1], [s.buffer.equal?(b), list.count, list.index_of(a)], "loading replaces the window's buffer and drops the one no window shows")
t.assert_true(list.for_path("b.txt").equal?(b), "a listed buffer is found by path")
t.assert_equal(nil, list.for_path("a.txt"), "a dropped buffer is not")
s.cursor.move_to(2, 0)
c = D::Buffer.from_text("x\n", "b.txt")
b.reload(c.lines)
t.assert_equal([0, 0], s.cursor.to_a, "the closed reload pulls the cursors on the buffer back inside it")

# Scratch buffers are not unsaved work and leave the list when unshown.
w = lists_over(D::Buffer.new(["one"], "a.txt", "\n"))
s = w.state
list = w.buffers
scratch = D::Buffer.new(["l"], nil, "\n")
scratch.owner = "hello"
scratch.title = "list"
list.add(scratch)
scratch.set_lines(0, 1, ["m"])
t.assert_equal([true, false, true], [scratch.modified?, list.any_modified?, list.hidden_modified.nil?], "a changed scratch buffer is not unsaved work")
t.assert_equal(2, list.number_of(scratch), "number_of is the list position from 1")
t.assert_equal(0, list.number_of(D::Buffer.new(["q"], nil, "\n")), "an unlisted buffer has number 0")
t.assert_equal(true, list.scratch_for("hello", "list").equal?(scratch), "scratch_for finds the plugin's buffer by title")
t.assert_equal(true, list.scratch_for("hello", "nope").nil?, "scratch_for answers nil for another title")
list.release(scratch)
t.assert_equal(1, list.count, "an unshown scratch buffer leaves the list even when modified")
s.buffer.set_lines(0, 1, ["two"])
list.release(s.buffer)
t.assert_equal(1, list.count, "a shown modified file buffer stays")

# Buffer ids come from the buffer list.
first = D::Buffer.new(["a"], "a.txt", "\n")
w = lists_over(first)
list = w.buffers
second = D::Buffer.new(["b"], "b.txt", "\n")
loose = D::Buffer.new(["c"], nil, "\n")
list.add(second)
t.assert_equal([1, 2, 0], [first.id, second.id, loose.id], "a buffer gets the next id when it enters the list, an unlisted one has 0")
list.remove(second)
list.add(second)
list.add(loose)
t.assert_equal([2, 3], [second.id, loose.id], "a buffer keeps its id when it comes back to the list")
second.set_lines(0, 1, ["z"])
t.assert_equal(2, second.last_transaction.record_at(0).buffer_id, "records carry the buffer's id")
t.assert_equal([true, true], [list.with_id(1).equal?(first), list.with_id(7).nil?], "a buffer is found by its id")

# The feed records opens, closes, renames, and closed transactions with
# their cause.
first = D::Buffer.new(["a", "b", "c"], "a.txt", "\n")
w = lists_over(first)
list = w.buffers
feed = list.feed
other = D::Buffer.new(["o"], "o.txt", "\n")
list.add(other)
first.set_lines(1, 2, [])
feed.cause = "probe"
other.rename("p.txt")
other.insert(pos(0, 0), "x")
feed.cause = ""
list.remove(other)
lines = []
i = 0
while i < feed.count
  n = feed.notice_at(i)
  lines << "#{n.kind} #{n.buffer_id} #{n.path} #{n.row} -#{n.removed} +#{n.inserted} #{n.detail} [#{n.cause}]"
  i += 1
end
t.assert_equal(["open 1 a.txt 0 -0 +0  []", "open 2 o.txt 0 -0 +0  []", "change 1 a.txt 1 -1 +0  []", "rename 2 p.txt 0 -0 +0 o.txt [probe]", "change 2 p.txt 0 -1 +1  [probe]", "close 2 p.txt 0 -0 +0  []"], lines, "every listed buffer's events are in the feed in order, with the cause at the time")
t.assert_true(feed.tabs.equal?(w.tabs), "the feed reports to the list's tab list")

t.finish
