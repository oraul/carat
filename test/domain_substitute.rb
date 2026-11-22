require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainSubstituteTest
  D = Carat::Domain

  # The argument parsed: [fresh, pattern, replacement, flags, count, error].
  def self.args(text, allow)
    a = D::SubstituteArgs.parse(text.to_s, allow == true)
    [a.fresh, a.pattern, a.replacement, a.flags, a.count, a.error]
  end

  # One line substituted with a pattern compiled for a substitute, the
  # previous string "PREV": [text, count], or the pattern's error.
  def self.line(source, line, replacement, all, count_only)
    compiled = D::VimPattern.compile_substitute(source.to_s, false, false, "PREV", true)
    return compiled.error unless compiled.ok?
    budget = D::SearchBudget.new(left: D::SearchBudget::SEARCH)
    r = D::Substitution.line(compiled, line.to_s, replacement.to_s, all == true, count_only == true, budget)
    [r.text, r.count]
  end

  # The flags applied to a fresh memory after the flags "g":
  # [all, report, count_only, case_mode, print], the last two as text.
  def self.flags(text)
    memory = D::LastSubstitute.new
    memory.apply_flags("g")
    memory.apply_flags(text.to_s)
    [memory.all, memory.report, memory.count_only, memory.case_mode.to_s, memory.print.to_s]
  end

  def self.main
    t = Carat::Testing.new("domain_substitute")

    # Rows are [label, [argument, pattern allowed], parsed].
    t.cases([
      ["pattern, string, and flags", ["/a/b/g", true], [true, "a", "b", "g", -1, ""]],
      ["no closing delimiter", ["/a/b", true], [true, "a", "b", "", -1, ""]],
      ["pattern only", ["/a", true], [true, "a", "", "", -1, ""]],
      ["empty pattern", ["//x/", true], [true, "", "x", "", -1, ""]],
      ["another delimiter", ["#a/b#c#", true], [true, "a/b", "c", "", -1, ""]],
      ["an escaped delimiter stays escaped", ["/a\\/b/c\\/d/", true], [true, "a\\/b", "c\\/d", "", -1, ""]],
      ["a delimiter in a collection", ["/[/]/x/", true], [true, "[/]", "x", "", -1, ""]],
      ["flags and a count", ["/a/b/gi 3", true], [true, "a", "b", "gi", 3, ""]],
      ["keep flags first", ["/a/b/&g", true], [true, "a", "b", "&g", -1, ""]],
      ["a comment after", ["/a/b/ \"note", true], [true, "a", "b", "", -1, ""]],
      ["trailing characters", ["/a/b/gx", true], [false, "", "", "", -1, "E488: Trailing characters: x"]],
      ["a letter delimiter", ["xaxbx", true], [false, "", "", "", -1, "E146: Regular expressions can't be delimited by letters"]],
      ["a backslash delimiter", ["\\/a/", true], [false, "", "", "", -1, "Not implemented: \\ as the delimiter of :s"]],
      ["a delimiter that is not ASCII", ["\u00e9a\u00e9b\u00e9", true], [false, "", "", "", -1, "Not implemented: a delimiter that is not ASCII"]],
      ["flags only", ["g 2", true], [false, "", "", "g", 2, ""]],
      ["a count only", ["4", true], [false, "", "", "", 4, ""]],
      ["a zero count", ["0", true], [false, "", "", "", 0, ""]],
      ["nothing", ["", true], [false, "", "", "", -1, ""]],
      ["the & command reads flags only", ["&g", false], [false, "", "", "&g", -1, ""]],
      ["the & command refuses a pattern", ["/a/", false], [false, "", "", "", -1, "E488: Trailing characters: /a/"]],
      ["a huge count", ["99999999999999999999", true], [false, "", "", "", 9999999999, ""]]
    ]) do |input|
      args(input[0], input[1])
    end

    # Rows are [label, flags, [all, report, count_only, case_mode, print]].
    t.table([
      ["no flags start again", "", [false, true, false, "options", "none"]],
      ["g switches every match on", "g", [true, true, false, "options", "none"]],
      ["& keeps the flags and g switches", "&g", [false, true, false, "options", "none"]],
      ["& alone keeps them", "&", [true, true, false, "options", "none"]],
      ["e switches the report off", "e", [false, false, false, "options", "none"]],
      ["n counts", "n", [false, true, true, "options", "none"]],
      ["i ignores case and I matches it", "iI", [false, true, false, "match", "none"]],
      ["p prints and # numbers", "p#", [false, true, false, "options", "number"]],
      ["i ignores case", "i", [false, true, false, "ignore", "none"]],
      ["p prints the line", "p", [false, true, false, "options", "line"]]
    ]) do |text|
      flags(text)
    end

    # Rows are [label, [pattern, line, string, all, count only], result].
    t.cases([
      ["the first match", ["o", "foo", "0", false, false], ["f0o", 1]],
      ["every match", ["o", "foo", "0", true, false], ["f00", 2]],
      ["no match", ["z", "foo", "0", true, false], ["foo", 0]],
      ["counting changes nothing", ["o", "foo", "0", true, true], ["foo", 2]],
      ["the whole match", ["b", "abc", "[&]", false, false], ["a[b]c", 1]],
      ["backslash zero", ["b", "abc", "<\\0>", false, false], ["a<b>c", 1]],
      ["groups", ["\\(a\\)\\(b\\)", "abc", "\\2\\1", false, false], ["bac", 1]],
      ["a group that did not match", ["\\(x\\)\\=a", "a", "[\\1]", false, false], ["[]", 1]],
      ["a group past the pattern's", ["a", "a", "[\\5]", false, false], ["[]", 1]],
      ["a non-capturing group is not counted", ["\\%(a\\)\\(b\\)", "ab", "\\1", false, false], ["b", 1]],
      ["upper the next character", ["\\w\\+", "one two", "\\u&", true, false], ["One Two", 2]],
      ["lower the next character", ["ONE", "ONE", "\\l&", false, false], ["oNE", 1]],
      ["upper until \\E", ["one", "one", "\\U&\\Ex", false, false], ["ONEx", 1]],
      ["lower until \\e", ["ONE", "ONE", "\\L&\\eX", false, false], ["oneX", 1]],
      ["one before all", ["ONE", "ONE", "\\u\\L&", false, false], ["One", 1]],
      ["case of a literal", ["a", "a", "\\uxy", false, false], ["Xy", 1]],
      ["case of a non-ASCII letter", ["a", "a", "\\U\u00e9", false, false], ["\u00c9", 1]],
      ["a line break", [",", "a,b", "\\r", true, false], ["a\nb", 1]],
      ["a tab", ["a", "a", "\\t", false, false], ["\t", 1]],
      ["a literal ampersand", ["a", "a", "\\&", false, false], ["&", 1]],
      ["a literal backslash", ["a", "a", "\\\\", false, false], ["\\", 1]],
      ["another escaped character is itself", ["a", "a", "\\q\\/", false, false], ["q/", 1]],
      ["a trailing backslash is kept", ["a", "a", "x\\", false, false], ["x\\", 1]],
      ["empty matches between characters", ["x*", "abc", "-", true, false], ["-a-b-c-", 4]],
      ["an empty match after a match does not count", ["x*", "xab", "-", true, false], ["-a-b-", 3]],
      ["the start anchor matches once", ["^", "aa", "-", true, false], ["-aa", 1]],
      ["the end anchor", ["$", "aa", "!", true, false], ["aa!", 1]],
      ["non-ASCII text", ["\u00e9", "\u00e0\u00e9\u00e8\u00e9", "e", true, false], ["\u00e0e\u00e8e", 2]],
      ["tilde matches the previous string", ["~", "aPREVb", "x", false, false], ["axb", 1]],
      ["ten groups are too many", ["\\(a\\)\\(a\\)\\(a\\)\\(a\\)\\(a\\)\\(a\\)\\(a\\)\\(a\\)\\(a\\)\\(a\\)", "a", "", false, false], "E51: Too many \\("]
    ]) do |input|
      line(input[0], input[1], input[2], input[3], input[4])
    end

    # A line that is not UTF-8 keeps its illegal byte.
    bad = "a\xFFb".dup.force_encoding(Encoding::UTF_8)
    t.assert_equal(["x\xFFb".dup.force_encoding(Encoding::UTF_8), 1], line("a", bad, "x", false, false), "an illegal byte is kept")

    # Rows are [label, [raw, previous, has previous], expanded].
    t.cases([
      ["no tilde", ["abc", "P", true], "abc"],
      ["a tilde is the previous string", ["a~b", "P", true], "aPb"],
      ["no previous string", ["a~b", "", false], "ab"],
      ["an escaped tilde stays", ["a\\~", "P", true], "a\\~"]
    ]) do |input|
      D::Replacement.tilde(input[0].to_s, input[1].to_s, input[2] == true)
    end

    # Rows are [label, string, message].
    t.table([
      ["a plain string", "a\\1&", ""],
      ["an expression", "\\=1", "Not implemented: \\= in a substitute string"],
      ["a NUL", "a\\nb", "Not implemented: \\n in a substitute string"],
      ["an escaped backslash before n", "\\\\n", ""]
    ]) do |text|
      D::Replacement.check(text.to_s)
    end

    # The group an item names, read by the one block of expand that
    # inserts a group. Rows are [label, [text, byte], group].
    t.cases([
      ["an ampersand is the match", ["a&", 1], 0],
      ["a backslash and zero is the match", ["\\0", 0], 0],
      ["a backslash and a digit is its group", ["x\\9", 1], 9],
      ["an escaped ampersand is no group", ["\\&", 0], -1],
      ["a case escape is no group", ["\\u", 0], -1],
      ["a backslash last is no group", ["a\\", 1], -1],
      ["a digit alone is no group", ["1", 0], -1]
    ]) do |input|
      text = input[0].to_s
      D::Replacement.group_at(text, input[1].to_i, text.bytesize)
    end
    plain = "ab"
    t.assert_true(D::Replacement.recase(plain, 0, 0).equal?(plain), "recase answers the text itself when nothing is recased")

    big = "x" * 600_000
    t.assert_equal([false, true], [D::Replacement.too_long?("~", big), D::Replacement.too_long?("~~", big)], "a string whose tildes could pass a mebibyte is too long")

    # The budget: replacement text is charged, so a long string stops it.
    budget = D::SearchBudget.new(left: 1000)
    compiled = D::VimPattern.compile_substitute("a", false, false, "", false)
    r = D::Substitution.line(compiled, "aaaa", "x" * 100, true, false, budget)
    t.assert_equal([true, "aaaa", 0], [budget.stopped, r.text, r.count], "replacement text past the budget stops it and changes nothing")

    # The size of a replacement is counted without building it, item by
    # item as expand reads them: [replacement, line, pattern].
    t.cases([
      ["plain characters", ["xyz", "abc", "b"], true],
      ["the match and a group", ["<&\\1&>", "abcabc", "\\(a\\)bc"], true],
      ["a group that did not take part", ["[\\2]", "ab", "\\(a\\)\\|\\(z\\)"], true],
      ["the escapes and a carriage return", ["\\r\\t\\b\\x\r\\u\\e", "a", "a"], true],
      ["multi-byte characters", ["é\\ü", "caf\u00e9", "f."], true],
      ["a match holding a multi-byte character", ["&&", "xéy", "é"], true]
    ]) do |input|
      replacement = input[0].to_s
      text = input[1].to_s
      compiled = D::VimPattern.compile_substitute(input[2].to_s, false, false, "", false)
      searched = D::Search.searchable(text)
      found = D::Search.match_at(compiled, searched, searched.length, 0, D::SearchBudget.new(left: D::SearchBudget::SEARCH))
      D::Replacement.size(replacement, text, found) == D::Replacement.expand(replacement, text, found).bytesize
    end

    # Scenario "A replacement past the budget is never built" (substitute):
    # 131072 copies of a 128 KiB match would be 16 GiB; the size is
    # charged first, so the command stops without building it, where the
    # build before the charge ran out of memory.
    long = "x" * 131_072
    budget = D::SearchBudget.new(left: D::SearchBudget::SEARCH)
    compiled = D::VimPattern.compile_substitute(".*", false, false, "", false)
    r = D::Substitution.line(compiled, long, "&" * 131_072, false, false, budget)
    t.assert_equal([true, 0, true], [budget.stopped, r.count, r.text.equal?(long)], "a replacement past the budget is never built")

    t.finish
  end
end

DomainSubstituteTest.main if __FILE__ == $0
