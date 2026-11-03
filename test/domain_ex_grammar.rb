require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainExGrammarTest
  G = Carat::Domain::ExGrammar

  def self.main
    t = Carat::Testing.new("domain_ex_grammar")

    # Rows are [label, command line, [name, bang, args]].
    t.table([
      ["bang and argument", "w! out.txt", ["w", true, "out.txt"]],
      ["leading colon and spaces", " :q ", ["q", false, ""]],
      ["long form", "write", ["write", false, ""]],
      ["wq with bang", "wq!", ["wq", true, ""]],
      ["edit with path", "e b.txt", ["e", false, "b.txt"]],
      ["argument with spaces trimmed", "e   dir/file name.txt  ", ["e", false, "dir/file name.txt"]],
      ["unknown word", "foo bar", ["foo", false, "bar"]],
      ["number only", "12", ["", false, "12"]],
      ["empty", "", ["", false, ""]],
      ["double colon", "::w", ["w", false, ""]]
    ]) do |text|
      c = G.parse(text)
      [c.name, c.bang, c.args]
    end

    t.finish
  end
end

DomainExGrammarTest.main if __FILE__ == $0
