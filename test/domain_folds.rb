require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainFoldsTest
  # Folds made from [first, last] pairs, each created closed in order.
  def self.made(pairs)
    folds = Carat::Domain::Folds.new
    i = 0
    while i < pairs.length
      pair = pairs[i]
      folds.create(pair[0].to_i, pair[1].to_i)
      i += 1
    end
    folds
  end

  # The folds as [first, last, closed] triples.
  def self.triples(folds)
    list = []
    i = 0
    while i < folds.count
      list << [folds.first_of(i), folds.last_of(i), folds.closed?(i)]
      i += 1
    end
    list
  end

  def self.main
    t = Carat::Testing.new("domain_folds")

    # Creating: rows are [label, pairs, triples].
    t.table([
      ["one fold is closed", [[2, 4]], [[2, 4, true]]],
      ["a reversed range is put in order", [[4, 2]], [[2, 4, true]]],
      ["an inner fold sorts after its outer one", [[1, 6], [2, 3]], [[1, 6, true], [2, 3, true]]],
      ["an outer fold sorts before its inner one", [[2, 3], [1, 6]], [[1, 6, true], [2, 3, true]]],
      ["an outer fold at the same first row sorts first", [[2, 3], [2, 6]], [[2, 6, true], [2, 3, true]]],
      ["a fold crossing another from above grows to hold it", [[3, 6], [1, 4]], [[1, 6, true], [3, 6, true]]],
      ["a fold crossing another from below grows to hold it", [[1, 4], [3, 6]], [[1, 6, true], [1, 4, true]]]
    ]) do |pairs|
      triples(made(pairs))
    end

    # Shifting by an edit: rows are [label, [row, removed, inserted],
    # triples] for one closed fold over rows 2 to 4.
    t.table([
      ["an edit below leaves the fold", [6, 1, 3], [[2, 4, true]]],
      ["a line inserted above shifts it down", [0, 0, 1], [[3, 5, true]]],
      ["a line inserted at its first row shifts it down", [2, 0, 1], [[3, 5, true]]],
      ["a line inserted inside extends it", [3, 0, 2], [[2, 6, true]]],
      ["a line inserted after its last row leaves it", [5, 0, 1], [[2, 4, true]]],
      ["a line changed in place leaves it", [2, 1, 1], [[2, 4, true]]],
      ["a line split in its first row extends it", [2, 1, 2], [[2, 5, true]]],
      ["a line deleted above shifts it up", [0, 1, 0], [[1, 3, true]]],
      ["a line deleted inside shrinks it", [3, 1, 0], [[2, 3, true]]],
      ["lines deleted over its start keep the rest", [1, 2, 0], [[1, 2, true]]],
      ["lines deleted over its end keep the rest", [4, 2, 0], [[2, 3, true]]],
      ["all its lines deleted drop it", [2, 3, 0], []],
      ["lines around it deleted drop it", [1, 5, 0], []]
    ]) do |edit|
      folds = made([[2, 4]])
      folds.shift(edit[0].to_i, edit[1].to_i, edit[2].to_i)
      triples(folds)
    end

    # Rows: a closed fold over 2 to 4 inside an open one over 1 to 6.
    folds = made([[1, 6], [2, 4]])
    folds.open_at(1)
    t.assert_equal([[1, 6, false], [2, 4, true]], triples(folds), "zo opens the outermost closed fold")
    t.assert_equal([-1, 1, 1, 1, -1], [folds.closed_at(1), folds.closed_at(2), folds.closed_at(4), folds.closed_at(3), folds.closed_at(5)], "the closed region is the closed fold holding the row")
    t.assert_equal([2, 4, 5, 5], [folds.first_row(3), folds.last_row(3), folds.first_row(5), folds.last_row(5)], "first_row and last_row span the closed region")
    t.assert_equal([5, 2, 9, 1, 0], [folds.down(1, 2, 9), folds.down(1, 1, 9), folds.down(1, 20, 9), folds.up(5, 2), folds.up(5, 9)], "down and up count the closed fold once and stop at the ends")
    t.assert_equal([0, 1, 2, 3], [folds.rows_between(2, 2), folds.rows_between(2, 5), folds.rows_between(1, 5), folds.rows_between(1, 6)], "rows_between counts the closed fold as one row")
    t.assert_equal(true, folds.folded?, "a closed fold makes the record folded")
    t.assert_equal("+---  3 lines: c····", folds.label(1, "\t c", 20), "the fold text has a dash per level, no leading blanks, and the fill")
    t.assert_equal("+---  3 lines: c····", folds.label(1, "other", 20), "the fold text is kept for one width")
    t.assert_equal("+---  3 lines: c", folds.label(1, "c", 10), "a narrow width keeps the whole text with no fill")
    folds.shift(9, 1, 1)
    t.assert_equal("+---  3 lines: x····", folds.label(1, "x", 20), "an edit drops the kept text")
    t.assert_equal("+--  6 lines: a b", made([[1, 6]]).label(0, "a\tb", 0), "a tab after the first non-blank becomes a space")

    # Closing, toggling, and deleting.
    folds = made([[1, 6], [2, 4]])
    folds.open_at(2)
    folds.open_at(2)
    t.assert_equal([[1, 6, false], [2, 4, false]], triples(folds), "zo twice opens both folds")
    t.assert_equal(true, folds.close_at(3), "zc on a row in a fold succeeds")
    t.assert_equal([[1, 6, false], [2, 4, true]], triples(folds), "zc closes the innermost open fold")
    folds.close_at(3)
    t.assert_equal([[1, 6, true], [2, 4, true]], triples(folds), "zc again closes the outer fold")
    folds.toggle_at(3)
    t.assert_equal([[1, 6, false], [2, 4, true]], triples(folds), "za on a closed fold opens it")
    t.assert_equal([false, false, false], [folds.open_at(8), folds.close_at(8), folds.delete_at(8)], "no fold at the row is false")
    t.assert_equal(true, folds.delete_at(3), "zd on a closed fold succeeds")
    t.assert_equal([[1, 6, false]], triples(folds), "zd deletes the closed fold first")
    folds.delete_at(3)
    t.assert_equal([true, false], [folds.empty?, folds.folded?], "zd again deletes the outer fold")
    folds = made([[1, 2], [4, 5]])
    copy = Carat::Domain::Folds.new
    copy.copy_from(folds)
    folds.clear
    t.assert_equal([[], [[1, 2, true], [4, 5, true]]], [triples(folds), triples(copy)], "clear empties the record and a copy keeps its own folds")

    t.finish
  end
end

DomainFoldsTest.main if __FILE__ == $0
