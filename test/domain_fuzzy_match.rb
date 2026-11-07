require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainFuzzyMatchTest
  D = Carat::Domain

  # Whether the pattern matches the word, from table values.
  def self.matches(pattern, word)
    D::FuzzyMatch.score(pattern.to_s, word.to_s) >= 0
  end

  # The words in the order of their scores for the pattern, best first,
  # equal scores in the given order.
  def self.ranked(pattern, words)
    p = pattern.to_s
    names = []
    scores = []
    words.each do |w|
      s = D::FuzzyMatch.score(p, w.to_s)
      next if s < 0
      i = scores.length
      i -= 1 while i > 0 && scores[i - 1] < s
      scores.insert(i, s)
      names.insert(i, w.to_s)
    end
    names
  end

  def self.plain(text, limit)
    D::ControlText.plain(text.to_s, limit.to_i)
  end

  def self.item(label, kind, detail, text)
    D::CompletionItem.from_source(label.to_s, kind.to_s, detail.to_s, text.to_s)
  end

  def self.main
    t = Carat::Testing.new("domain_fuzzy_match")

    # Rows are [label, [pattern, word], matches].
    t.table([
      ["fn_na finds file_name", ["fn_na", "file_name"], true],
      ["fn_na finds fn_name", ["fn_na", "fn_name"], true],
      ["fn_na does not find final", ["fn_na", "final"], false],
      ["fn_na does not find name", ["fn_na", "name"], false],
      ["a prefix matches", ["fil", "file_name"], true],
      ["a subsequence from the start matches", ["fname", "file_name"], true],
      ["a part starting mid-word does not match", ["ame", "file_name"], false],
      ["a later part matches at its start", ["na", "file_name"], true],
      ["case is ignored", ["FILE", "file_name"], true],
      ["a case change starts a part", ["gn", "getName"], true],
      ["a lowercase run is no part start", ["am", "getName"], false],
      ["a leading underscore word", ["_fo", "_foo"], true],
      ["the parts keep their order", ["na_fi", "file_name"], false],
      ["a trailing underscore is ignored", ["fi_", "filter"], true],
      ["a letter missing", ["fz", "file_name"], false],
      ["an empty pattern matches nothing", ["", "file"], false],
      ["bytes beyond ASCII match exactly", ["é", "été"], true]
    ]) do |pair|
      matches(pair[0], pair[1])
    end

    # Rows are [label, [pattern, words], ranked].
    t.table([
      ["a prefix comes first", ["fil", ["a_file_list", "file"]], ["file", "a_file_list"]],
      ["runs beat gaps", ["fn", ["f_x_n", "fn_x"]], ["fn_x", "f_x_n"]],
      ["shorter first among equals", ["ab", ["abcdef", "abc"]], ["abc", "abcdef"]],
      ["equal words keep their order", ["x", ["x_b", "x_a"]], ["x_b", "x_a"]]
    ]) do |pair|
      ranked(pair[0], pair[1])
    end

    # Rows are [label, [text, limit], cleaned].
    t.table([
      ["CSI sequences are dropped whole", ["\e[31mred\e[0m", 80], "red"],
      ["an OSC title ended by BEL", ["a\e]0;title\ab", 80], "ab"],
      ["an OSC ended by ESC backslash", ["a\e]8;;x\e\\b", 80], "ab"],
      ["a two-character escape", ["a\ecb", 80], "ab"],
      ["C1 CSI is dropped whole", ["a\u009B1mb", 80], "ab"],
      ["C1 OSC ended by C1 ST", ["a\u009D0;t\u009Cb", 80], "ab"],
      ["an unterminated OSC drops the rest", ["ab\e]0;title", 80], "ab"],
      ["a lone ESC at the end", ["ab\e", 80], "ab"],
      ["other controls are dropped, breaks are spaces", ["a\x01b\nc\td", 80], "ab c d"],
      ["an illegal byte is U+FFFD", ["a\xFFb", 80], "a\u{FFFD}b"],
      ["cut at the limit", ["abcdef", 4], "abcd"],
      ["cut at a character boundary", ["aé", 2], "a"]
    ]) do |pair|
      plain(pair[0], pair[1])
    end

    long = "a" * 500
    t.assert_equal(80, item(long, "text", "", "").label.bytesize, "a label of 500 letters is cut to 80 bytes")
    t.assert_equal(200, item(long, "text", "", long).text.bytesize, "an insert text is cut to 200 bytes")
    t.assert_equal(80, item("x", "text", long, "").detail.bytesize, "a detail is cut to 80 bytes")
    t.assert_equal(4096, D::ControlText.plain("a" * 10_000, 100_000).bytesize, "plain reads at most 4096 raw bytes")
    t.assert_equal(["red_x", "text", "kind_text"], [item("\e[31mred\e[0m\e]0;title\a_x", "bogus", "", "").label, item("x", "bogus", "", "").kind, item("x", "bogus", "", "").icon_name], "an escape-laden label is cleaned and an unknown kind reads as text")
    t.assert_equal(["file_name", "variable", "String"], [item("file_name", "variable", "String", "").text, item("file_name", "variable", "String", "").kind, item("file_name", "variable", "String", "").detail], "an empty insert text is the label")

    list = D::CompletionList.new
    added = 0
    300.times { |i| added += 1 if list.add(item("w#{i}", "text", "", "")) }
    t.assert_equal([200, 200], [added, list.count], "a list keeps 200 candidates")

    t.finish
  end
end

DomainFuzzyMatchTest.main if __FILE__ == $0
