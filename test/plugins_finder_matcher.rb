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
    t.table([
      ["an empty query matches with 0", ["", "a.rb"], true],
      ["the bytes in order match", ["bet", "lib/beta.rb"], true],
      ["case is ignored", ["BETA", "lib/beta.rb"], true],
      ["bytes across directories match", ["lbr", "lib/beta.rb"], true],
      ["bytes out of order do not match", ["teb", "lib/beta.rb"], false],
      ["a byte the path lacks does not match", ["z", "lib/beta.rb"], false],
      ["a query longer than the path does not match", ["abcdef", "abc"], false]
    ]) do |row|
      score_of(row[0], row[1]) >= 0
    end

    # Rows are [label, [query, better, worse], true].
    t.table([
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

    t.assert_equal([7, 0, 99_999], [M.index_of(M.key(5, 3, 7)), M.index_of(M.key(0, 2000, 0)), M.index_of(M.key(1, 1, 99_999))], "a key keeps its index")
    t.assert_equal([0, 4, 4], [M.name_start("a.rb"), M.name_start("lib/a.rb"), M.name_start("lib/")], "the file name starts after the last slash")

    t.finish
  end
end

PluginsFinderMatcherTest.main if __FILE__ == $0
