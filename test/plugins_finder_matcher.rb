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

    # Rows are [label, [query, path], whether it matches]: a contiguous
    # substring (tier 1) or a few runs, each after the first at a segment
    # or word start (tier 2), and nothing else.
    t.cases([
      ["an empty query matches with 0", ["", "a.rb"], true],
      ["a substring matches", ["bet", "lib/beta.rb"], true],
      ["a substring across a directory boundary matches", ["lib/b", "lib/beta.rb"], true],
      ["case is ignored", ["BETA", "lib/beta.rb"], true],
      ["case is ignored in the path", ["beta", "lib/BETA.rb"], true],
      ["initials match as runs at word starts", ["lbr", "lib/beta.rb"], true],
      ["ep matches explorer_plugin", ["ep", "lib/explorer_plugin.rb"], true],
      ["ep matches a file below a directory", ["ep", "carat/plugins/explorer/plugin.rb"], true],
      ["fgr matches finder/grep.rb", ["fgr", "carat/plugins/finder/grep.rb"], true],
      ["camel humps match as runs", ["fb", "lib/FooBar.rb"], true],
      ["case is ignored in initials", ["EP", "lib/explorer_plugin.rb"], true],
      ["four runs match", ["abcd", "a/b/c/d.rb"], true],
      ["five runs do not match", ["abcde", "a/b/c/d/e.rb"], false],
      ["bytes out of order do not match", ["teb", "lib/beta.rb"], false],
      ["a byte the path lacks does not match", ["z", "lib/beta.rb"], false],
      ["a query longer than the path does not match", ["abcdef", "abc"], false],
      ["a run that starts mid-word does not match", ["fgr", "lib/fingr.rb"], false],
      ["a scattered match does not match", ["fb", "lib/fobar.rb"], false],
      ["a long gap inside a word does not match", ["ab", "xaccccccccccccccccccccccccccccccb"], false],
      ["a long gap across directories matches by its word start", ["ab", "xaccccccccccccccccccccccccccccccc/b.rb"], true],
      ["a scattered path does not match explorer", ["explorer", "ezzzxpzzzlzzzozzzrzzezrrr"], false],
      ["a scattered file name does not match explorer", ["explorer", "lib/ezzzxpzzzlzzzozzzrzzezrrr.rb"], false],
      ["a scattered directory does not match explorer", ["explorer", "ezzzxpzzzlzzzozzzrzzezrrr/a.rb"], false],
      ["two terms match in the order typed", ["lib beta", "lib/beta.rb"], true],
      ["two terms match in the other order", ["beta lib", "lib/beta.rb"], true],
      ["two terms need both", ["beta zzz", "lib/beta.rb"], false],
      ["two terms match by initials and by substring", ["ep lib", "lib/explorer_plugin.rb"], true],
      ["extra spaces make no term", ["  beta  lib ", "lib/beta.rb"], true],
      ["a query of spaces matches like an empty one", ["   ", "lib/beta.rb"], true],
      ["a multi-byte substring matches", ["caf\u00e9", "src/caf\u00e9.rb"], true],
      ["a multi-byte run at a word start matches", ["\u00e9a", "src/\u00e9/a.rb"], true],
      ["a multi-byte character of another case is not folded", ["CAF\u00c9", "src/caf\u00e9.rb"], false],
      ["a multi-byte path does not match scattered bytes", ["cf", "src/caf\u00e9.rb"], false]
    ]) do |row|
      score_of(row[0], row[1]) >= 0
    end

    # Rows are [label, [query, better, worse], true]; both paths match.
    t.cases([
      ["the file name match ranks first", ["plugin", "lib/plugin.rb", "plugins/finder/x.rb"], true],
      ["a word start in the file name ranks above a middle byte of it", ["pl", "x/a_pl.rb", "x/apple.rb"], true],
      ["a word start in the file name ranks above a later hit in the name", ["a", "lib/alpha.rb", "lib/beta.rb"], true],
      ["a segment start ranks above a middle in a directory", ["pl", "a/plug/x.rb", "a/apple/x.rb"], true],
      ["a substring ranks above initials", ["ab", "x/zzabz/y.rb", "a/b.rb"], true],
      ["a substring in a directory ranks above initials in the name", ["ab", "zzabz/y.rb", "a/b_c_d.rb"], true],
      ["fewer runs rank above more", ["abc", "a/bc/x.rb", "a/b/c/x.rb"], true],
      ["a tighter match ranks above a looser one", ["ab", "x/ab.rb", "x/a_long_b.rb"], true],
      ["explorer in a file name ranks above the directory", ["explorer", "test/editor_explorer.rb", "carat/plugins/explorer/plugin.rb"], true],
      ["explorer in a directory ranks above initials", ["explorer", "carat/plugins/explorer/plugin.rb", "tools/explain_pl_or_err.sh"], true],
      ["explorer in a file name ranks above initials", ["explorer", "test/editor_explorer.rb", "tools/explain_pl_or_err.sh"], true],
      ["every term counts toward the rank", ["beta lib", "lib/beta.rb", "lib/b_e_t_a.rb"], true],
      ["a shorter path breaks a tie", ["a", "a.rb", "a.txt"], true],
      ["the listing order breaks a tie of equal paths", ["a", "a.rb", "a.rb"], false]
    ]) do |row|
      above?(row[0], row[1], row[2])
    end

    # Rows are [label, [text], whether it is blank].
    t.cases([
      ["an empty text is blank", [""], true],
      ["spaces are blank", ["  "], true],
      ["a letter is not blank", [" a "], false]
    ]) do |row|
      M.blank?(row[0].to_s)
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

    t.assert_equal(true, score_of("abcd", "a/b/c/d.rb") < score_of("ab", "x/zzabz/y.rb"), "every substring match scores above every initials match")
    t.assert_equal(0, score_of("", "lib/beta.rb"), "an empty query scores 0")
    t.assert_equal([7, 0, 99_999], [M.index_of(M.key(5, 3, 7)), M.index_of(M.key(0, 2000, 0)), M.index_of(M.key(1, 1, 99_999))], "a key keeps its index")
    t.assert_equal([0, 4, 4], [M.name_start("a.rb"), M.name_start("lib/a.rb"), M.name_start("lib/")], "the file name starts after the last slash")

    t.finish
  end
end

PluginsFinderMatcherTest.main if __FILE__ == $0
