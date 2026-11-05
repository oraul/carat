require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainBufferListTest
  D = Carat::Domain

  def self.pos(row, col)
    Carat::Domain::Position.new(row: row, col: col)
  end

  def self.buffer_named(name)
    Carat::Domain::Buffer.new(lines: ["a", "b", "c"], path: name, line_ending: "\n")
  end

  # The buffer list over a tab list whose one window shows the buffer, and
  # the state over them.
  class Lists < Struct.new(:tabs, :buffers, :state, keyword_init: true)
  end

  def self.lists_over(buffer)
    tabs = D::TabList.new(window: D::Window.new(buffer: buffer))
    buffers = D::BufferList.new(tabs: tabs)
    buffers.add(buffer)
    Lists.new(tabs: tabs, buffers: buffers, state: D::EditorState.new(tabs: tabs, options: D::Options.new))
  end

  def self.ints(values)
    out = []
    values.each { |v| out << v.to_i }
    out
  end

  # The buffer steps places from the one at index.
  def self.step(list, index, steps)
    list.step_from(list.buffer_at(index), steps)
  end

  def self.feed_lines(feed)
    lines = []
    i = 0
    while i < feed.count
      n = feed.notice_at(i)
      lines << "#{n.kind} #{n.buffer_id} #{n.path} #{n.row} -#{n.removed} +#{n.inserted}"
      i += 1
    end
    lines
  end

  def self.main
    t = Carat::Testing.new("domain_buffer_list")

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
    t.assert_equal(3, list.count, "a clean unshown file buffer stays listed, hidden")
    two.mark_unsaved
    list.release(two)
    t.assert_equal(3, list.count, "a modified unshown buffer stays hidden")
    t.assert_true(list.hidden_modified.equal?(two), "it is the hidden modified buffer")
    t.assert_true(list.any_modified?, "the list has a modified buffer")
    list.release(a)
    t.assert_equal(3, list.count, "a shown buffer stays")
    b = buffer_named("b.txt")
    list.load(b)
    t.assert_equal([true, 4, 0], [s.buffer.equal?(b), list.count, list.index_of(a)], "loading replaces the window's buffer and keeps the one it showed")
    t.assert_true(list.for_path("b.txt").equal?(b), "a listed buffer is found by path")
    t.assert_true(list.for_path("a.txt").equal?(a), "so is the buffer left")
    s.cursor.move_to(2, 0)
    c = D::Buffer.from_text("x\n", "b.txt")
    b.reload(c.lines)
    t.assert_equal([0, 0], s.cursor.to_a, "the closed reload pulls the cursors on the buffer back inside it")

    # The empty unnamed buffer of one window is replaced under its number;
    # a buffer shown again gets its cursor back.
    empty = D::Buffer.from_text("", nil)
    w = lists_over(empty)
    s = w.state
    list = w.buffers
    a = buffer_named("a.txt")
    list.load(a)
    t.assert_equal([1, 1, -1], [list.count, a.id, list.index_of(empty)], "a file opened over the empty buffer takes its number")
    t.assert_equal(["open 1  0 -0 +0", "close 1  0 -0 +0", "open 1 a.txt 0 -0 +0"], feed_lines(list.feed), "the empty buffer closes before the file opens")
    s.cursor.move_to(2, 0)
    b = buffer_named("b.txt")
    list.load(b)
    t.assert_equal([2, [2, 0], [0, 0]], [b.id, a.last_cursor.to_a, s.cursor.to_a], "the buffer left remembers the cursor and a fresh one starts at the top")
    s.cursor.move_to(1, 2)
    list.load(a)
    t.assert_equal([2, 0], s.cursor.to_a, "a buffer shown again gets its cursor back")
    a.set_lines(1, 3, [])
    list.load(b)
    t.assert_equal([1, 0], s.cursor.to_a, "the remembered cursor of b is kept inside its text")
    list.load(a)
    t.assert_equal([0, 0], s.cursor.to_a, "a remembered row past the end lands on the last line")
    other = D::Buffer.from_text("", nil)
    list.load(other)
    blank = D::Buffer.from_text("", nil)
    list.load(blank)
    t.assert_equal([3, -1], [blank.id, list.index_of(other)], "a second empty buffer is replaced too")

    # Moving through the list skips scratch buffers and wraps.
    a = buffer_named("a.txt")
    w = lists_over(a)
    list = w.buffers
    scratch = D::Buffer.new(lines: ["l"], path: nil, line_ending: "\n")
    scratch.owner = "hello"
    b = buffer_named("b.txt")
    c = buffer_named("c.txt")
    list.add(scratch)
    list.add(b)
    list.add(c)
    t.table([
      ["one forward skips the scratch buffer", [0, 1], 2],
      ["forward from the last wraps", [3, 1], 0],
      ["back from the first wraps", [0, -1], 3],
      ["0 stays on a file buffer", [0, 0], 0],
      ["0 from a scratch buffer goes to the next file buffer", [1, 0], 2],
      ["a count wraps past the end", [0, 4], 2],
      ["back two", [3, -2], 0]
    ]) { |input| list.index_of(step(list, ints(input)[0], ints(input)[1])) }
    t.assert_equal([3, 2, 2], [list.index_of(list.replacement_for(b)), list.index_of(list.replacement_for(c)), list.index_of(list.replacement_for(scratch))], "the replacement is the next file buffer, or the one before it for the last")
    w = lists_over(scratch)
    t.assert_true(w.buffers.step_from(scratch, 1).nil?, "no file buffer to move to")
    t.assert_true(w.buffers.replacement_for(scratch).nil?, "nor to replace it with")

    # The unsaved buffer quitting names, in Neovim's order.
    a = buffer_named("a.txt")
    w = lists_over(a)
    list = w.buffers
    b = buffer_named("b.txt")
    c = buffer_named("c.txt")
    list.add(b)
    list.add(c)
    t.assert_true(list.first_unsaved(false).nil?, "nothing unsaved")
    c.set_lines(0, 1, ["z"])
    b.set_lines(0, 1, ["z"])
    t.assert_true(list.first_unsaved(false).equal?(b), "a hidden buffer in list order")
    a.set_lines(0, 1, ["z"])
    t.assert_equal([true, true], [list.first_unsaved(false).equal?(a), list.first_unsaved(true).equal?(b)], "the current buffer first, and only the hidden ones when asked")
    list.bring(c)
    t.assert_true(w.state.buffer.equal?(c), "bringing a hidden buffer shows it in the current window")

    # Scratch buffers are not unsaved work and leave the list when unshown.
    w = lists_over(D::Buffer.new(lines: ["one"], path: "a.txt", line_ending: "\n"))
    s = w.state
    list = w.buffers
    scratch = D::Buffer.new(lines: ["l"], path: nil, line_ending: "\n")
    scratch.owner = "hello"
    scratch.title = "list"
    list.add(scratch)
    scratch.set_lines(0, 1, ["m"])
    t.assert_equal([true, false, true], [scratch.modified?, list.any_modified?, list.hidden_modified.nil?], "a changed scratch buffer is not unsaved work")
    t.assert_equal(2, list.number_of(scratch), "number_of is the list position from 1")
    t.assert_equal(0, list.number_of(D::Buffer.new(lines: ["q"], path: nil, line_ending: "\n")), "an unlisted buffer has number 0")
    t.assert_equal(true, list.scratch_for("hello", "list").equal?(scratch), "scratch_for finds the plugin's buffer by title")
    t.assert_equal(true, list.scratch_for("hello", "nope").nil?, "scratch_for answers nil for another title")
    list.release(scratch)
    t.assert_equal(1, list.count, "an unshown scratch buffer leaves the list even when modified")
    s.buffer.set_lines(0, 1, ["two"])
    list.release(s.buffer)
    t.assert_equal(1, list.count, "a shown modified file buffer stays")

    # Buffer ids come from the buffer list.
    first = D::Buffer.new(lines: ["a"], path: "a.txt", line_ending: "\n")
    w = lists_over(first)
    list = w.buffers
    second = D::Buffer.new(lines: ["b"], path: "b.txt", line_ending: "\n")
    loose = D::Buffer.new(lines: ["c"], path: nil, line_ending: "\n")
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
    first = D::Buffer.new(lines: ["a", "b", "c"], path: "a.txt", line_ending: "\n")
    w = lists_over(first)
    list = w.buffers
    feed = list.feed
    other = D::Buffer.new(lines: ["o"], path: "o.txt", line_ending: "\n")
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
  end
end

DomainBufferListTest.main if __FILE__ == $0
