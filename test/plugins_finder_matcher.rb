require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module PluginsFinderMatcherTest
  M = Carat::Plugins::Finder::Matcher

  # The score of a row's query against its path, typed before the call.
  def self.score_of(query, path)
    M.score(query.to_s, path.to_s)
  end

  # Whether the first path outranks the second for the query: its key
  # sorts higher, the first path listed second.
  def self.above?(query, first, second)
    a = first.to_s
    b = second.to_s
    q = query.to_s
    M.key(M.score(q, a), a.bytesize, 1) > M.key(M.score(q, b), b.bytesize, 0)
  end

  def self.main
    t = Carat::Testing.new("plugins_finder_matcher")

    # Rows are [label, [query, path], whether it matches].
    t.cases([
      ["an empty query matches with 0", ["", "a.rb"], true],
      ["the bytes in order match", ["bet", "lib/beta.rb"], true],
      ["case is ignored", ["BETA", "lib/beta.rb"], true],
      ["bytes across directories match", ["lbr", "lib/beta.rb"], true],
      ["bytes out of order do not match", ["teb", "lib/beta.rb"], false],
      ["a byte the path lacks does not match", ["z", "lib/beta.rb"], false],
      ["a query longer than the path does not match", ["abcdef", "abc"], false],
      ["a long gap still matches", ["ab", "xaccccccccccccccccccccccccccccccb"], true],
      ["a long gap across directories still matches", ["ab", "xaccccccccccccccccccccccccccccccc/b.rb"], true]
    ]) do |row|
      score_of(row[0], row[1]) >= 0
    end

    # Rows are [label, [query, better, worse], true].
    t.cases([
      ["the file name match ranks first", ["plugin", "lib/plugin.rb", "plugins/finder/x.rb"], true],
      ["a run ranks above scattered bytes", ["map", "lib/map.rb", "lib/mxaxp.rb"], true],
      ["a word start ranks above a middle byte", ["fs", "lib/file_set.rb", "lib/fuss.rb"], true],
      ["a camel case start counts as a word start", ["fb", "lib/FooBar.rb", "lib/fobar.rb"], true],
      ["a tighter span ranks above a looser one", ["ab", "x/ab.rb", "x/a_long_b.rb"], true],
      ["a shorter path breaks a tie", ["a", "a.rb", "a.txt"], true],
      ["the listing order breaks a tie of equal paths", ["a", "a.rb", "a.rb"], false]
    ]) do |row|
      above?(row[0], row[1], row[2])
    end

    # Rows are [label, [term, text, from], the byte index or -1].
    t.cases([
      ["a term at the start is found at 0", ["abc", "abcd", "0"], 0],
      ["a term in the middle is found there", ["bc", "abcd", "0"], 1],
      ["case is ignored on both sides", ["ABc", "xaBC", "0"], 1],
      ["a term at the very end is found", ["cd", "abcd", "0"], 2],
      ["a later hit is found from past the first", ["ab", "abxab", "1"], 3],
      ["scattered bytes are not a hit", ["abc", "axbxc", "0"], -1],
      ["a term longer than the text is not a hit", ["abcd", "abc", "0"], -1],
      ["an empty term is not a hit", ["", "abc", "0"], -1],
      ["a multi-byte term is found by its bytes", ["é", "caf\u00e9", "0"], 3]
    ]) do |row|
      M.find(row[0].to_s, row[1].to_s, row[2].to_i)
    end

    # Rows are [label, [text, start], whether a word starts there].
    t.cases([
      ["the first byte starts a word", ["abc", "0"], true],
      ["a letter before does not start a word", ["abc", "1"], false],
      ["a digit before does not start a word", ["1bc", "1"], false],
      ["a space before starts a word", ["a bc", "2"], true],
      ["an underscore before starts a word", ["a_bc", "2"], true],
      ["a quote before starts a word", ["'bc'", "1"], true],
      ["an uppercase letter after a lowercase one starts a word", ["aBc", "1"], true],
      ["an uppercase letter after an uppercase one does not", ["ABc", "1"], false],
      ["a multi-byte character before does not start a word", ["ébc", "2"], false]
    ]) do |row|
      M.word_start?(row[0].to_s, row[1].to_i)
    end

    # Rows are [label, [text, end], whether a word ends there].
    t.cases([
      ["the end of the text ends a word", ["abc", "3"], true],
      ["a letter after does not end a word", ["abcd", "3"], false],
      ["a digit after does not end a word", ["abc1", "3"], false],
      ["a space after ends a word", ["abc d", "3"], true],
      ["an underscore after ends a word", ["abc_d", "3"], true],
      ["a dot after ends a word", ["abc.d", "3"], true],
      ["an uppercase letter after a lowercase one ends a word", ["abcD", "3"], true],
      ["an uppercase letter after an uppercase one does not", ["ABCD", "3"], false],
      ["a multi-byte character after does not end a word", ["abc\u00e9", "3"], false]
    ]) do |row|
      M.word_end?(row[0].to_s, row[1].to_i)
    end

    t.assert_equal([256, 0], [score_of("ab", "xaccccccccccccccccccccccccccccccb"), score_of("ab", "xaccccccccccccccccccccccccccccccc/b.rb")], "a match whose gaps outweigh its points scores 0, plus the name bonus in the name")
    t.assert_equal([7, 0, 99_999], [M.index_of(M.key(5, 3, 7)), M.index_of(M.key(0, 2000, 0)), M.index_of(M.key(1, 1, 99_999))], "a key keeps its index")
    t.assert_equal([0, 4, 4], [M.name_start("a.rb"), M.name_start("lib/a.rb"), M.name_start("lib/")], "the file name starts after the last slash")

    t.finish
  end
end

PluginsFinderMatcherTest.main if __FILE__ == $0
