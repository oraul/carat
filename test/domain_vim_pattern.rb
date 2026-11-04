require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainVimPatternTest
  P = Carat::Domain::VimPattern

  # Where the pattern first matches text, as "from-to", "none", or the
  # error that refused the pattern. Typed: a table value is untyped, and
  # an untyped argument widens the library method it reaches for every
  # test (docs/spinel-notes.md).
  def self.probe(pattern, text, ignorecase, smartcase)
    compiled = P.compile(pattern.to_s, ignorecase == true, smartcase == true)
    return compiled.error unless compiled.ok?
    found = compiled.regexp.match(text.to_s, 0)
    found.nil? ? "none" : "#{found.begin(0)}-#{found.end(0)}"
  end

  def self.main
    t = Carat::Testing.new("domain_vim_pattern")

    # Rows are [label, [pattern, text], first match or error], case
    # matched.
    t.table([
      # Literal text and the characters the engine would read specially.
      ["a word", ["bar", "foo bar"], "4-7"],
      ["parentheses are literal", ["f(x)", "a f(x)"], "2-6"],
      ["plus, question mark, and braces are literal", ["a+b?{1}", "a+b?{1}"], "0-7"],
      ["a bar is literal", ["a|b", "b a|b"], "2-5"],
      ["an escaped slash", ["a\\/b", "a/b"], "0-3"],
      ["an escaped backslash", ["a\\\\b", "a\\b"], "0-3"],
      ["non-ASCII text", ["é+", "aé+"], "1-3"],
      # Wildcards and multis.
      ["dot", ["b.d", "abcd"], "1-4"],
      ["star", ["ab*c", "xac abbc"], "1-3"],
      ["star at the start is literal", ["*a", "b*a"], "1-3"],
      ["star after a caret is literal", ["^*a", "*a"], "0-2"],
      ["backslash plus", ["ab\\+", "a abb"], "2-5"],
      ["backslash equals", ["ab\\=c", "ac"], "0-2"],
      ["backslash question mark", ["ab\\?c", "abc"], "0-3"],
      ["count", ["a\\{2}", "a aa"], "2-4"],
      ["count range", ["a\\{2,3}", "aaaa"], "0-3"],
      ["count with a closing backslash", ["a\\{2,3\\}", "aaaa"], "0-3"],
      ["open count", ["a\\{2,}", "aaaa"], "0-4"],
      ["count up to", ["a\\{,2}b", "aaab"], "1-4"],
      ["reversed count", ["a\\{3,2}", "aaaa"], "0-3"],
      ["empty count is a star", ["ba\\{}", "baaa"], "0-4"],
      ["lazy count", ["a\\{-1,}", "aaa"], "0-1"],
      # Anchors.
      ["caret anchors at the start", ["^a", "ba a"], "none"],
      ["caret inside is literal", ["a^b", "a^b"], "0-3"],
      ["dollar anchors at the end", ["a$", "a ba"], "3-4"],
      ["dollar inside is literal", ["a$b", "a$b"], "0-3"],
      ["dollar before a bar anchors", ["x$\\|a", "ab"], "0-1"],
      # Collections.
      ["collection", ["[bc]", "abc"], "1-2"],
      ["range", ["[0-9]\\+", "ab123"], "2-5"],
      ["negated", ["[^a]", "aab"], "2-3"],
      ["bracket first is a member", ["[]a]", "x]"], "1-2"],
      ["escaped bracket", ["[\\]]", "x]"], "1-2"],
      ["dash last is a member", ["[a-]", "x-"], "1-2"],
      ["ampersands are members", ["[&]", "a&"], "1-2"],
      ["POSIX class", ["[[:digit:]]", "ab3"], "2-3"],
      ["an unclosed bracket is literal", ["a[b", "a[b"], "0-3"],
      ["reverse range", ["[z-a]", "a"], "E944: Reverse range in character class"],
      # Groups, alternation, and word boundaries.
      ["group with a multi", ["\\(ab\\)\\+", "xabab"], "1-5"],
      ["alternation", ["foo\\|bar", "a bar"], "2-5"],
      ["percent group", ["\\%(a\\|b\\)c", "bc"], "0-2"],
      ["word start", ["\\<oo", "foo oo"], "4-6"],
      ["whole word", ["\\<foo\\>", "food foo"], "5-8"],
      # Class escapes.
      ["digits", ["\\d\\+", "ab42"], "2-4"],
      ["white space", ["a\\sb", "a\tb"], "0-3"],
      ["word characters", ["\\w\\+", "--a_1--"], "2-5"],
      ["keyword characters", ["\\k\\+", "--é1--"], "2-4"],
      ["uppercase", ["\\u\\l", "aBc"], "1-3"],
      ["tab", ["a\\tb", "a\tb"], "0-3"],
      # Magic modes.
      ["very magic", ["\\v(ab)+", "abab"], "0-4"],
      ["very magic word boundaries", ["\\v<a>", "ba a"], "3-4"],
      ["nomagic dot is literal", ["\\Ma.c", "abc a.c"], "4-7"],
      ["nomagic escaped dot", ["\\Ma\\.c", "abc"], "0-3"],
      ["very nomagic", ["\\Va*b", "aab a*b"], "4-7"],
      # Errors.
      ["unmatched open", ["\\(a", "a"], "E54: Unmatched \\("],
      ["unmatched close", ["a\\)", "a"], "E55: Unmatched \\)"],
      ["nested star", ["a**", "a"], "E61: Nested *"],
      ["nested plus", ["a*\\+", "a"], "E62: Nested \\+"],
      ["plus follows nothing", ["\\+a", "a"], "E64: \\+ follows nothing"],
      ["bad count", ["a\\{x}", "a"], "E554: Syntax error in \\{...}"],
      ["tilde", ["a~", "a"], "E33: No previous substitute regular expression"],
      ["back reference", ["\\(a\\)\\1", "aa"], "Not implemented: \\1 in a pattern"],
      ["look-around", ["a\\@=", "a"], "Not implemented: \\@ in a pattern"],
      ["end of line item", ["a\\nb", "a"], "Not implemented: \\n in a pattern"],
      ["underscore classes", ["\\_s", "a"], "Not implemented: \\_ in a pattern"],
      ["percent items", ["\\%V", "a"], "Not implemented: \\% in a pattern"],
      ["very magic look-around", ["\\va@=", "a"], "Not implemented: @ in a pattern"],
      ["too large", ["\\(a\\{999}\\)\\{999}", "a"], "E363: pattern uses more memory than 'maxmempattern'"],
      ["a count past the limit", ["a\\{99999999999999999999}", "a"], "E363: pattern uses more memory than 'maxmempattern'"],
      ["too long", ["a" * 5000, "a"], "E363: pattern uses more memory than 'maxmempattern'"],
      ["an illegal byte is U+FFFD", ["a\xFFb".dup.force_encoding("UTF-8"), "a\u{FFFD}b"], "0-3"]
    ]) do |input|
      probe(input[0], input[1], false, false)
    end

    # Case: rows are [label, [pattern, text, ignorecase, smartcase], match].
    t.table([
      ["case matched by default", ["foo", "FOO", false, false], "none"],
      ["ignorecase", ["foo", "FOO", true, false], "0-3"],
      ["smartcase with an uppercase letter", ["Foo", "FOO", true, true], "none"],
      ["smartcase without one", ["foo", "FOO", true, true], "0-3"],
      ["an escaped letter is not uppercase", ["\\Sfoo", "XFOO", true, true], "0-4"],
      ["backslash c ignores case", ["\\cFoo", "FOO", false, false], "0-3"],
      ["backslash C matches case", ["\\Cfoo", "FOO", true, false], "none"],
      ["an uppercase letter in a collection counts", ["[F]oo", "foo", true, true], "none"]
    ]) do |input|
      probe(input[0], input[1], input[2], input[3])
    end

    t.assert_equal("a\\.b\\*c\\/\\\\", P.escape("a.b*c/\\"), "escape for a literal search")
    t.assert_equal("1-5", probe(P.escape("a.*b"), "xa.*b", false, false), "an escaped text matches itself")

    t.finish
  end
end

DomainVimPatternTest.main if __FILE__ == $0
