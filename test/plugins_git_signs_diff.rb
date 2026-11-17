require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# GitSigns::LineDiff over texts of one word a line: the text at HEAD, then
# the buffer's, and one character per buffer line for its mark: "." none,
# "a" added, "c" changed, "d" deleted.
module PluginsGitSignsDiffTest
  D = Carat::Plugins::GitSigns::LineDiff
  LETTERS = [".", "a", "c", "d"]

  # The words of a text, one line each; the buffer of "" is one empty line.
  #: (String, bool) -> Array[String]
  def self.lines_of(text, buffer)
    return [""] if buffer && text.empty?
    text.split(" ")
  end

  # The marks of the buffer text against the text at HEAD, as letters.
  def self.marks_of(old_text, new_text)
    out = +""
    D.marks(lines_of(old_text.to_s, false), lines_of(new_text.to_s, true)).each { |mark| out << LETTERS[mark] }
    out
  end

  # n words, the prefix then the number.
  #: (String, Integer) -> String
  def self.words(prefix, n)
    list = [""]
    list.clear
    n.times { |i| list << "#{prefix}#{i}" }
    list.join(" ")
  end

  def self.main
    t = Carat::Testing.new("plugins_git_signs_diff")

    # Rows are [label, [text at HEAD, buffer text], marks].
    t.table([
      # Scenario "Each sign kind shows on its lines"
      ["each sign kind on its lines: changed, added, and deleted on the line above", ["one two three four five", "one TWO three new four"], ".c.ad"],
      # Scenario "Lines removed at the top mark the first line"
      ["lines removed at the top mark the first line", ["zero one two", "one two"], "d."],
      ["equal texts mark nothing", ["a b c", "a b c"], "..."],
      ["lines added at the top", ["b c", "a b c"], "a.."],
      ["lines added at the end", ["a b", "a b c d"], "..aa"],
      ["lines removed at the end mark the last kept line", ["a b c", "a b"], ".d"],
      ["lines removed in the middle mark the line above", ["a b c d", "a d"], "d."],
      ["a replaced run is changed on its inserted lines", ["a b c d", "a x y z w d"], ".cccc."],
      ["a change and a removal apart", ["a b c d e", "a x c e"], ".cd."],
      ["every line replaced", ["a b", "x y"], "cc"],
      ["an empty buffer against text at HEAD marks its one line deleted", ["a b", ""], "d"],
      ["a file empty at HEAD marks every line added", ["", "a b"], "aa"],
      ["both empty mark nothing", ["", ""], "."],
      ["a line moved reads as a removal at the top and an addition", ["a b c", "b c a"], "d.a"]
    ]) do |pair|
      marks_of(pair[0], pair[1])
    end

    # Past MAX_EDITS steps the middle is one changed run.
    capped = marks_of(words("o", 400), words("n", 400))
    t.assert_equal([400, 400], [capped.length, capped.count("c")], "past the edit cap the whole middle reads as one changed run")
    near = marks_of("head #{words("o", 100)} tail", "head #{words("n", 100)} tail")
    t.assert_equal(".#{"c" * 100}.", near, "within the cap the trimmed head and tail stay unmarked")
    long_old = words("x", 3000)
    long_new = long_old.sub("x1500 ", "")
    t.assert_equal(1, marks_of(long_old, long_new).count("d"), "one removal in a long file marks one line")

    t.finish
  end
end

PluginsGitSignsDiffTest.main if __FILE__ == $0
