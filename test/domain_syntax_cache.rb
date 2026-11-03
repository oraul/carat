require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainSyntaxCacheTest
  D = Carat::Domain
  C = D::SyntaxCache

  # A toy tokenizer state: inside or outside a double-quoted string, which
  # each quote toggles, so a quote changes the state of every row after it.
  #: (String, Integer) -> Integer
  def self.toy_state(text, start)
    state = start
    i = 0
    while i < text.bytesize
      state = 1 - state if text.getbyte(i) == 34
      i += 1
    end
    state
  end

  # Advances the cache over the rows of the buffer up to bottom, as the
  # highlighting use case does, and returns how many rows it computed.
  #: (Carat::Domain::SyntaxCache, Carat::Domain::Buffer, Integer) -> Integer
  def self.catch_up(cache, buffer, bottom)
    done = 0
    while cache.valid < bottom
      k = cache.valid
      cache.advance(k, toy_state(buffer.line(k), cache.start_of(k)))
      done += 1
    end
    done
  end

  def self.main
    t = Carat::Testing.new("domain_syntax_cache")

    # Lines by identity, per start state, in two generations.
    c = C.new
    t.assert_equal([false, 0, []], [c.active?, c.valid, c.ends], "a new cache is empty and inactive")
    line = String.new("def x")
    c.prepare("ruby", "ruby", 1)
    t.assert_true(c.active?, "prepare makes it active")
    c.store(line, 0, [0, 3, D::Highlight::DEFINE], 0)
    t.assert_equal([0, 3, D::Highlight::DEFINE], c.find(line, 0).tokens, "a stored line is found by identity")
    t.assert_true(c.find(String.new("def x"), 0).nil?, "an equal string that is another object is not")
    t.assert_true(c.find(line, 1).nil?, "another start state is not")
    c.prepare("ruby", "ruby", 2)
    t.assert_true(!c.find(line, 0).nil?, "a line survives one turn and moves forward")
    c.prepare("ruby", "ruby", 3)
    t.assert_true(!c.find(line, 0).nil?, "found again, it survives the next")
    c.prepare("ruby", "ruby", 4)
    c.prepare("ruby", "ruby", 4)
    t.assert_true(!c.find(line, 0).nil?, "the same frame serial does not turn")
    c.prepare("ruby", "ruby", 5)
    c.prepare("ruby", "ruby", 6)
    t.assert_true(c.find(line, 0).nil?, "a line not looked at for two turns is dropped")
    c.store(line, 0, [0, 3, D::Highlight::DEFINE], 0)
    c.prepare("other", "ruby", 7)
    t.assert_true(c.find(line, 0).nil?, "another plugin resets the cache")
    c.store(line, 0, [], 0)
    c.prepare("other", "ruby_fork", 8)
    t.assert_true(c.find(line, 0).nil?, "another syntax resets the cache")
    c.drop
    t.assert_equal([false, 0], [c.active?, c.ends.length], "drop forgets everything")

    # Advancing: valid moves one row at a time, the frontier grows.
    b = D::Buffer.from_text(["a", "b \"open", "c", "d \"close", "e", "f", "g", "h", "i", "j"].join("\n") + "\n", "a.rb")
    c = b.syntax_cache
    c.prepare("toy", "ruby", 1)
    t.assert_equal(10, catch_up(c, b, 10), "ten rows computed")
    t.assert_equal([[0, 1, 1, 0, 0, 0, 0, 0, 0, 0], 10], [c.ends, c.valid], "the end states and valid")
    t.assert_equal([0, 0, 1, 1], [c.start_of(0), c.start_of(1), c.start_of(2), c.start_of(3)], "start_of is the state after the row before")

    # An edit that keeps the state settles on the row after it.
    b.insert(D::Position.new(row: 2, col: 0), "x")
    t.assert_equal([2, C::UNKNOWN, 3], [c.valid, c.ends[2], c.dirty_to], "an edit lowers valid and marks its row unknown")
    t.assert_equal(2, catch_up(c, b, 10), "the edited row and the one after are computed, then it settles")
    t.assert_equal(10, c.valid, "valid jumps to the frontier")

    # An edit that changes the state goes on while the states differ: an
    # unclosed quote flips every row after it.
    b.insert(D::Position.new(row: 0, col: 0), "\"")
    t.assert_equal(10, catch_up(c, b, 10), "every row after an unclosed quote changes state")
    t.assert_equal([1, 0, 0, 1, 1], c.ends[0, 5], "the states after the quote are flipped")
    t.assert_equal(10, c.valid, "and valid is at the frontier again")

    # Undo goes through the same splice and re-computes the restored row.
    b.revert(b.last_transaction)
    t.assert_equal([0, "a"], [c.valid, b.line(0)], "undoing the quote lowers valid to its row")
    t.assert_equal(10, catch_up(c, b, 10), "and recomputes every row whose state changes back")
    t.assert_equal([0, 1, 1, 0, 0], c.ends[0, 5], "the states are back")

    # A deletion: the row that moves up keeps its text but gets a new start,
    # and its old end state still matches.
    b.set_lines(1, 4, [])
    t.assert_equal([7, 1, 1], [c.ends.length, c.valid, c.dirty_to], "three rows deleted: the frontier shrinks, valid and dirty_to at the row")
    t.assert_equal(1, catch_up(c, b, 7), "the row that moved up is computed and settles")
    t.assert_equal(7, c.valid, "valid reaches the frontier")

    # Two edits: rows are computed up to the row after the last before it
    # can settle.
    b.set_lines(0, 1, ["\"a"])
    b.set_lines(3, 4, ["g\""])
    t.assert_equal([0, 4], [c.valid, c.dirty_to], "valid at the first edit, dirty_to after the second")
    t.assert_equal(5, catch_up(c, b, 7), "rows 0 to 4 are computed, row 4 settles")

    # Two edits far apart: no settling between them.
    b2 = D::Buffer.from_text((["x"] * 20).join("\n") + "\n", "b.rb")
    c2 = b2.syntax_cache
    c2.prepare("toy", "ruby", 1)
    catch_up(c2, b2, 20)
    b2.insert(D::Position.new(row: 3, col: 0), "y")
    b2.insert(D::Position.new(row: 12, col: 0), "y")
    t.assert_equal([3, 13], [c2.valid, c2.dirty_to], "valid at the first edit, dirty_to after the second")
    t.assert_equal(11, catch_up(c2, b2, 20), "rows 3 to 13 are computed before it settles")
    t.assert_equal(20, c2.valid, "then valid jumps to the frontier")

    # Only rows reached are kept: an edit beyond the frontier changes nothing,
    # one that reaches it cuts it there.
    b3 = D::Buffer.from_text((["x"] * 50).join("\n") + "\n", "c.rb")
    c3 = b3.syntax_cache
    c3.prepare("toy", "ruby", 1)
    catch_up(c3, b3, 10)
    b3.insert(D::Position.new(row: 30, col: 0), "y")
    t.assert_equal([10, 10], [c3.ends.length, c3.valid], "an edit past the frontier changes nothing")
    b3.set_lines(8, 12, ["z"])
    t.assert_equal([8, 8], [c3.ends.length, c3.valid], "an edit reaching the frontier cuts it at the edit")
    b3.reload(["a", "b"])
    t.assert_equal([0, 0], [c3.ends.length, c3.valid], "a reload cuts it at the top")

    # lookup: the entry of a row for its start state, NONE otherwise.
    b4 = D::Buffer.from_text("a\nb\n", "d.rb")
    c4 = b4.syntax_cache
    t.assert_true(c4.lookup(0, b4.line(0)).equal?(D::SyntaxLine::NONE), "an inactive cache gives NONE")
    c4.prepare("toy", "ruby", 1)
    c4.store(b4.line(0), 0, [0, 1, D::Highlight::STRING], 0)
    c4.advance(0, 0)
    t.assert_equal([0, 1, D::Highlight::STRING], c4.lookup(0, b4.line(0)).tokens, "a stored row is looked up")
    t.assert_true(c4.lookup(1, b4.line(1)).equal?(D::SyntaxLine::NONE), "a row not stored gives NONE")
    t.assert_true(c4.lookup(5, b4.line(1)).equal?(D::SyntaxLine::NONE), "a row past valid gives NONE")
    t.assert_equal(0, D::SyntaxLine::NONE.size, "NONE has no tokens")

    t.finish
  end
end

DomainSyntaxCacheTest.main if __FILE__ == $0
