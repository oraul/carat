require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainSearchTest
  D = Carat::Domain

  # A search over the lines of text from (row, col) as "row,col" with
  # " wrapped" when it passed an end of the buffer, or the status when
  # it found nothing. Typed: a table value is untyped (docs/spinel-notes.md).
  def self.search(text, pattern, row, col, forward, count)
    buffer = D::Buffer.from_text(text.to_s, nil)
    compiled = D::VimPattern.compile(pattern.to_s, false, false)
    budget = D::SearchBudget.new(left: D::SearchBudget::SEARCH)
    hit = D::Search.find(buffer, compiled, row.to_i, col.to_i, forward == true, count.to_i, budget)
    return hit.status.to_s unless hit.found?
    "#{hit.row},#{hit.col}-#{hit.end_col}#{hit.wrapped ? " wrapped" : ""}"
  end

  def self.main
    t = Carat::Testing.new("domain_search")

    # Rows are [label, [text, pattern, row, col, forward, count], hit].
    t.table([
      ["forward on the line", ["foo bar\n", "bar", 0, 0, true, 1], "0,4-7"],
      ["forward skips the match under the cursor", ["a a a\n", "a", 0, 0, true, 1], "0,2-3"],
      ["forward to a later line", ["ab\ncd\nab\n", "ab", 0, 0, true, 1], "2,0-2"],
      ["forward wraps to the top", ["a\nb\nx\n", "a", 2, 0, true, 1], "0,0-1 wrapped"],
      ["forward finds the only match under the cursor", ["xa\n", "a", 0, 1, true, 1], "0,1-2 wrapped"],
      ["forward with a count", ["a a a a\n", "a", 0, 0, true, 3], "0,6-7"],
      ["a count past the last match wraps", ["a a\n", "a", 0, 0, true, 2], "0,0-1 wrapped"],
      ["backward on the line", ["foo x foo\n", "foo", 0, 6, false, 1], "0,0-3"],
      ["backward to an earlier line", ["foo\nx\n", "foo", 1, 0, false, 1], "0,0-3"],
      ["backward wraps to the bottom", ["a\nb\nx\n", "x", 0, 0, false, 1], "2,0-1 wrapped"],
      ["backward takes the last match of a line", ["ab ab ab\nx\n", "ab", 1, 0, false, 1], "0,6-8"],
      ["backward with a count", ["a a a a\n", "a", 0, 6, false, 2], "0,2-3"],
      ["not found", ["abc\n", "z", 0, 0, true, 1], "missing"],
      ["not found backward", ["abc\n", "z", 0, 2, false, 1], "missing"],
      ["an empty line", ["\n\n", "x", 0, 0, true, 1], "missing"],
      ["the line start moves to the next line", ["ab\ncd\n", "^", 0, 0, true, 1], "1,0-0"],
      ["the line end on the last character moves on", ["ab\ncd\n", "$", 0, 1, true, 1], "1,2-2"],
      ["after an illegal byte", ["a\xFFb\n".dup.force_encoding("UTF-8"), "b", 0, 0, true, 1], "0,2-3"],
      ["U+FFFD matches an illegal byte", ["a\xFFb\n".dup.force_encoding("UTF-8"), "\u{FFFD}", 0, 0, true, 1], "0,1-2"],
      ["a pathological pattern on a long line", [("a" * 3000) + "\n", "\\(a*\\)*b", 0, 0, true, 1], "missing"]
    ]) do |input|
      search(input[0], input[1], input[2], input[3], input[4], input[5])
    end

    # The budget stops a search before the engine runs past it.
    buffer = D::Buffer.from_text(("a" * 100 + "\n") * 100, nil)
    compiled = D::VimPattern.compile("a\\{50}b", false, false)
    budget = D::SearchBudget.new(left: 10_000)
    hit = D::Search.find(buffer, compiled, 0, 0, true, 1, budget)
    t.assert_equal("stopped", hit.status.to_s, "a search stops when its budget cannot pay for a line")
    budget = D::SearchBudget.new(left: 100)
    budget.charge(60)
    t.assert_equal([40, false], [budget.left, budget.stopped], "a charge within the budget is paid")
    budget.charge(60)
    t.assert_equal([40, true], [budget.left, budget.stopped], "a charge past it is refused and stops the budget")

    # The searchable copy of a line keeps its characters.
    bad = "é\xFFx".dup.force_encoding("UTF-8")
    t.assert_equal("é\u{FFFD}x", D::Search.searchable(bad), "an illegal byte becomes U+FFFD")
    good = "abc"
    t.assert_true(D::Search.searchable(good).equal?(good), "a valid line is matched as it is")

    # The history.
    h = D::History.new
    h.add("a")
    h.add("ab")
    h.add("b")
    h.add("a")
    t.assert_equal(["ab", "b", "a"], h.entries, "a repeated entry moves to the newest")
    h.restart
    h.older("")
    t.assert_true(h.moved, "up recalls")
    t.assert_equal("a", h.recalled, "the newest first")
    h.older("a")
    t.assert_equal("b", h.recalled, "then the older")
    h.newer("b")
    t.assert_equal("a", h.recalled, "down comes back")
    h.newer("a")
    t.assert_equal("", h.recalled, "past the newest the typed text returns")
    h.restart
    h.older("a")
    h.older("a")
    t.assert_equal("ab", h.recalled, "a prefix skips the entries that do not start with it")
    h.older("ab")
    t.assert_true(!h.moved, "past the oldest match nothing moves")
    h.older("x")
    t.assert_equal([false, "ab"], [h.moved, h.recalled], "edited text starts a new recall with its prefix")
    i = 0
    while i < 60
      h.add("e#{i}")
      i += 1
    end
    t.assert_equal(50, h.entries.length, "at most fifty entries")
    t.assert_equal("e10", h.entries[0], "the oldest are dropped")

    # What the screen highlights.
    options = D::Options.new
    last = D::LastSearch.new
    t.assert_equal(0, last.drawn(options), "nothing drawn before a search")
    last.remember(D::VimPattern.compile("a", false, false), true)
    t.assert_true(last.drawn(options) > 0, "a search is drawn")
    last.hide
    t.assert_equal(0, last.drawn(options), "noh hides it")
    last.show
    options.hlsearch = false
    t.assert_equal(0, last.drawn(options), "nohlsearch draws nothing")

    t.finish
  end
end

DomainSearchTest.main if __FILE__ == $0
