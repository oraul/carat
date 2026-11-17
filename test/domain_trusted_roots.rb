require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# TrustedRoots over a user file's language.trusted_roots line, the home
# being /home/user.
module DomainTrustedRootsTest
  HOME = "/home/user"

  # Whether the roots cover the directory; the input is "ROOTS|CWD", an
  # empty ROOTS meaning no line. A table value is untyped, so it is
  # converted before it reaches the library (docs/spinel-notes.md).
  #: (untyped) -> bool
  def self.covered(value)
    text = value.to_s
    bar = text.index("|").to_i
    roots = text[0, bar].to_s
    cwd = text[bar + 1, text.length - bar - 1].to_s
    config = roots.empty? ? Carat::Doubles::FixedConfig.defaults : Carat::Doubles::FixedConfig.with_user("language.trusted_roots #{roots}\n")
    Carat::Domain::TrustedRoots.cover?(config, cwd, HOME)
  end

  # Whether the directory is under one root word; the input is
  # "WORD|CWD".
  #: (untyped) -> bool
  def self.under(value)
    text = value.to_s
    bar = text.index("|").to_i
    Carat::Domain::TrustedRoots.under?(text[0, bar].to_s, text[bar + 1, text.length - bar - 1].to_s, HOME)
  end

  # Whether a word is a root by RootWord's rule.
  #: (untyped) -> bool
  def self.root(value)
    Carat::Domain::RootWord.root?(value.to_s)
  end

  def self.main
    t = Carat::Testing.new("domain_trusted_roots")

    # Rows are [label, "ROOTS|CWD", trusted].
    t.table([
      ["no line trusts nothing", "|/project", false],
      ["a root trusts itself", "/project|/project", true],
      ["a root trusts a directory below it", "/work|/work/app", true],
      ["a root does not trust a sibling sharing its prefix", "/work|/workshop", false],
      ["a trailing slash is ignored", "/work/|/work/app", true],
      ["a root under the home", "~/src|/home/user/src/app", true],
      ["the home itself", "~|/home/user", true],
      ["a relative root trusts nothing", "src|/src", false],
      ["a root with a .. segment trusts nothing", "/work/../etc|/etc", false],
      ["the root directory trusts every absolute directory", "/|/anything", true],
      ["a relative working directory is never trusted", "/|project", false],
      ["any of several roots", "/elsewhere ~/src /project|/project/lib", true],
      ["none of several roots", "/elsewhere ~/src|/project", false]
    ]) do |input|
      covered(input)
    end

    # One root word, the rule a language.<name>.lsp.root line's root
    # follows. Rows are [label, "WORD|CWD", under].
    t.table([
      ["one word covers itself", "/work|/work", true],
      ["one word covers a directory below it", "/work/|/work/app/lib", true],
      ["one word does not cover a sibling sharing its prefix", "/work|/workshop", false],
      ["one word under the home", "~/src|/home/user/src/app", true],
      ["a relative word covers nothing", "work|/work", false],
      ["a word with a . segment covers nothing", "/work/.|/work", false],
      ["the root directory covers every absolute directory", "/|/anything", true],
      ["a relative directory is under nothing", "/|work", false]
    ]) do |input|
      under(input)
    end

    # What a root word is, one rule for the configuration reader and the
    # roots above. Rows are [label, word, root].
    t.table([
      ["an absolute path is a root", "/a/b", true],
      ["the root directory is a root", "/", true],
      ["a trailing slash is a root", "/a/b/", true],
      ["the home is a root", "~", true],
      ["a path under the home is a root", "~/src", true],
      ["a relative word is no root", "src", false],
      ["a user's home by name is no root", "~src", false],
      ["a . segment is no root", "/a/./b", false],
      ["a .. segment is no root", "/a/../b", false],
      ["a final .. segment is no root", "/a/..", false],
      ["a . segment under the home is no root", "~/./src", false],
      ["dots inside a name are a root", "/a/..b/.c", true],
      ["an empty word is no root", "", false]
    ]) do |input|
      root(input)
    end

    t.finish
  end
end

DomainTrustedRootsTest.main if __FILE__ == $0
