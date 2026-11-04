require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainExGrammarTest
  G = Carat::Domain::ExGrammar

  def self.main
    t = Carat::Testing.new("domain_ex_grammar")

    # Rows are [label, command line, [range, name, bang, args]].
    t.table([
      ["bang and argument", "w! out.txt", ["", "w", true, "out.txt"]],
      ["leading colon and spaces", " :q ", ["", "q", false, ""]],
      ["long form", "write", ["", "write", false, ""]],
      ["wq with bang", "wq!", ["", "wq", true, ""]],
      ["edit with path", "e b.txt", ["", "e", false, "b.txt"]],
      ["argument with spaces trimmed", "e   dir/file name.txt  ", ["", "e", false, "dir/file name.txt"]],
      ["unknown word", "foo bar", ["", "foo", false, "bar"]],
      ["number only", "12", ["12", "", false, ""]],
      ["empty", "", ["", "", false, ""]],
      ["double colon", "::w", ["", "w", false, ""]],
      ["percent range", "%s/a/b/g", ["%", "s", false, "/a/b/g"]],
      ["two numbers", "1,3s/a/b/", ["1,3", "s", false, "/a/b/"]],
      ["visual marks", "'<,'>s/x/y/", ["'<,'>", "s", false, "/x/y/"]],
      ["dot and dollar with blanks", ":. , $ s/x/y/", [". , $", "s", false, "/x/y/"]],
      ["arithmetic is read as range", ".+1;$-2s", [".+1;$-2", "s", false, ""]],
      ["a mark at the end", "'", ["", "", false, "'"]],
      ["ampersand is a name", "&&", ["", "&", false, "&"]],
      ["ampersand with a range", "%&g", ["%", "&", false, "g"]],
      ["s with a delimiter", "s#a#b#", ["", "s", false, "#a#b#"]],
      ["letters after s are the name", "sxaxbx", ["", "sxaxbx", false, ""]]
    ]) do |text|
      c = G.parse(text)
      [c.range, c.name, c.bang, c.args]
    end

    t.finish
  end
end

DomainExGrammarTest.main if __FILE__ == $0
