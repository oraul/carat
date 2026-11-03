require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module PluginsRubyTest
  R = Carat::Plugins::Ruby
  G = R::Groups

  # A tokenizer whose ids are the group indexes, so a token names its group.
  TK = R::Tokenizer.new(keywords: R::Keywords.new)

  # The tokens of each line, tokenized in order from state 0, as
  # "Group:text" words, a line with no token as "". A table row's lines
  # are untyped, so each is converted before it reaches the tokenizer.
  def self.show(lines)
    out = []
    state = 0
    lines.each do |line|
      tokens = Array.new(0, 0)
      state = TK.call(line.to_s, state, tokens)
      words = []
      i = 0
      while i + 2 < tokens.length
        words << "#{G::NAMES[tokens[i + 2]]}:#{line[tokens[i], tokens[i + 1]]}"
        i += 3
      end
      out << words.join(" ")
    end
    out
  end

  # The state after the lines, described.
  def self.state_after(lines)
    state = 0
    lines.each { |line| state = TK.call(line.to_s, state, Array.new(0, 0)) }
    "mode=#{R::LineState.mode(state)} heredocs=#{R::LineState.heredoc_count(state)} frames=#{R::LineState.frame_count(state)}"
  end

  def self.main
    t = Carat::Testing.new("plugins_ruby")

    identity = []
    k = 0
    while k < G::NAMES.length
      identity << k
      k += 1
    end
    TK.ids = identity

    t.table([
      ["a comment with Todo", ["x = 1 # TODO: later"], ["Number:1 Comment:#  Todo:TODO Comment:: later"]],
      ["Todo words only as words", ["# NOTED XXX FIXME."], ["Comment:# NOTED  Todo:XXX Comment:  Todo:FIXME Comment:."]],
      ["=begin and =end", ["=begin", "def x", "=end", "y"], ["Comment:=begin", "Comment:def x", "Comment:=end", ""]],
      ["=begin needs column 0", ["  =begin"], ["Exception:begin"]],
      ["__END__", ["__END__", "def x"], ["Comment:__END__", "Comment:def x"]],
      ["an endless def", ["def go = \"hi\" # note"], ["Define:def Function:go String:\"hi\" Comment:# note"]],
      ["a method definition", ["def self.call(x) = @x"], ["Define:def Constant:self Function:call Identifier:@x"]],
      ["operator and setter names", ["def ==(o)", "def x=(v)", "def empty?", "def <=>(o)"], ["Define:def Function:==", "Define:def Function:x=", "Define:def Function:empty?", "Define:def Function:<=>"]],
      ["a class", ["class Foo::Bar < Base"], ["Structure:class Type:Foo::Bar Type:Base"]],
      ["a module", ["module A"], ["Structure:module Type:A"]],
      ["a singleton class", ["class << self"], ["Structure:class Constant:self"]],
      ["keywords as method names", ["x.class.end"], [""]],
      ["control flow", ["return nil unless ok and true"], ["Statement:return Constant:nil Conditional:unless Operator:and Boolean:true"]],
      ["loops and blocks", ["while x do end; for a in b; until c"], ["Repeat:while Keyword:do Keyword:end Repeat:for Keyword:in Repeat:until"]],
      ["exceptions", ["begin; raise E; rescue => e; ensure; end"], ["Exception:begin Exception:raise Type:E Exception:rescue Exception:ensure Keyword:end"]],
      ["includes and macros", ["require_relative \"a\"; attr_reader :b; private"], ["Include:require_relative String:\"a\" Macro:attr_reader Constant::b Macro:private"]],
      ["defined? and super", ["defined?(x) && super"], ["Keyword:defined? Keyword:super"]],
      ["variables", ["@a + @@b + $c + $0 + $!"], ["Identifier:@a Identifier:@@b Identifier:$c Identifier:$0 Identifier:$!"]],
      ["constants", ["X = Foo::BAR"], ["Type:X Type:Foo Type:BAR"]],
      ["numbers", ["[0x1F, 0b10, 0o17, 1_000, 2r, 3i, 1.5, 1e3, 1.5r]"], ["Number:0x1F Number:0b10 Number:0o17 Number:1_000 Number:2r Number:3i Float:1.5 Float:1e3 Float:1.5r"]],
      ["a range is not a float", ["1..5"], ["Number:1 Number:5"]],
      ["a method on a number", ["1.to_s"], ["Number:1"]],
      ["symbols and labels", ["f(:a, :\"b c\", d: 1)"], ["Constant::a Constant::\"b c\" Constant:d: Number:1"]],
      ["operator symbols", ["[:+, :[]=, :<=>]"], ["Constant::+ Constant::[]= Constant::<=>"]],
      ["a ternary is not a symbol", ["a ? b : c"], [""]],
      ["character literals", ["x = ?a + ?\\n"], ["Character:?a Character:?\\n"]],
      ["predicate then ternary", ["x.nil? ? 1 : 2"], ["Number:1 Number:2"]],
      ["escapes", ["\"a\\tb\""], ["String:\"a SpecialChar:\\t String:b\""]],
      ["unicode escapes", ["\"\\u{1F600}\\u00e9\\x41\""], ["String:\" SpecialChar:\\u{1F600}\\u00e9\\x41 String:\""]],
      ["single quotes keep other escapes", ["'a\\tb\\'c'"], ["String:'a\\tb SpecialChar:\\' String:c'"]],
      ["nested interpolation", ["\"a \#{b(\"c \#{d}\")} e\""], ["String:\"a  Delimiter:\#{ String:\"c  Delimiter:\#{ Delimiter:} String:\" Delimiter:} String: e\""]],
      ["braces inside interpolation", ["\"\#{h.map { |x| x }}!\""], ["String:\" Delimiter:\#{ Delimiter:} String:!\""]],
      ["short interpolation", ["\"\#@a and \#$b\""], ["String:\" Identifier:\#@a String: and  Identifier:\#$b String:\""]],
      ["interpolation across lines", ["\"a \#{", "  x }", "b\""], ["String:\"a  Delimiter:\#{", "Delimiter:}", "String:b\""]],
      ["a string across lines", ["s = \"one", "two\" + x"], ["String:\"one", "String:two\""]],
      ["words with brackets", ["%w[a [b] c].size"], ["String:%w[a [b] c]"]],
      ["another delimiter", ["%q|a b| + x"], ["String:%q|a b|"]],
      ["percent symbols", ["%i(a b)"], ["Constant:%i(a b)"]],
      ["percent string with interpolation", ["%Q{a \#{b}}"], ["String:%Q{a  Delimiter:\#{ Delimiter:} String:}"]],
      ["a percent regex", ["%r{a/b}i"], ["Delimiter:%r{ String:a/b Delimiter:}i"]],
      ["modulo is not a literal", ["x % 2"], ["Number:2"]],
      ["a format string", ["\"%d\" % [x]"], ["String:\"%d\""]],
      ["a regular expression", ["x =~ /a+b/i"], ["Delimiter:/ String:a+b Delimiter:/i"]],
      ["division", ["a = b / c / 2"], ["Number:2"]],
      ["a regex after a method name", ["puts /x/"], ["Delimiter:/ String:x Delimiter:/"]],
      ["a regex after a keyword", ["if /x/ =~ s"], ["Conditional:if Delimiter:/ String:x Delimiter:/"]],
      ["a regex escape", ["/a\\/b/"], ["Delimiter:/ String:a SpecialChar:\\/ String:b Delimiter:/"]],
      ["a heredoc", ["x = <<~SQL", "  select \#{a}", "  SQL", "y"], ["Delimiter:<<~SQL", "String:  select  Delimiter:\#{ Delimiter:}", "Delimiter:SQL", ""]],
      ["two heredocs on one line", ["f(<<~A, <<~'B')", "a \#{x}", "A", "b \#{x}", "B"], ["Delimiter:<<~A Delimiter:<<~'B'", "String:a  Delimiter:\#{ Delimiter:}", "Delimiter:A", "String:b \#{x}", "Delimiter:B"]],
      ["a plain heredoc needs column 0", ["x = <<EOS", "  EOS", "EOS"], ["Delimiter:<<EOS", "String:  EOS", "Delimiter:EOS"]],
      ["a dash heredoc", ["x = <<-EOS", "a", "  EOS", "z"], ["Delimiter:<<-EOS", "String:a", "Delimiter:EOS", ""]],
      ["shift is not a heredoc", ["a << b", "class << self"], ["", "Structure:class Constant:self"]],
      ["code after a heredoc opener", ["f(<<~A).strip # c", "x", "A"], ["Delimiter:<<~A Comment:# c", "String:x", "Delimiter:A"]],
      ["utf-8 columns", ["s = \"日本\" # é"], ["String:\"日本\" Comment:# é"]],
      ["a keyword label", ["{if: 1, class: 2}"], ["Constant:if: Number:1 Constant:class: Number:2"]]
    ]) { |lines| show(lines) }

    t.table([
      ["plain code ends in state 0", ["x = 1"], "mode=0 heredocs=0 frames=0"],
      ["=begin", ["=begin"], "mode=1 heredocs=0 frames=0"],
      ["=end", ["=begin", "=end"], "mode=0 heredocs=0 frames=0"],
      ["__END__", ["__END__"], "mode=2 heredocs=0 frames=0"],
      ["an open string", ["\"a"], "mode=0 heredocs=0 frames=1"],
      ["an open interpolation", ["\"a \#{"], "mode=0 heredocs=0 frames=1"],
      ["two nested open strings", ["\"a \#{ \"b"], "mode=0 heredocs=0 frames=2"],
      ["three nested open strings keep two", ["\"a \#{ \"b \#{ \"c"], "mode=0 heredocs=0 frames=2"],
      ["a pending heredoc", ["x = <<~A"], "mode=0 heredocs=1 frames=0"],
      ["three pending heredocs keep two", ["f(<<A, <<B, <<C)"], "mode=0 heredocs=2 frames=0"],
      ["a closed heredoc", ["x = <<~A", "a", "A"], "mode=0 heredocs=0 frames=0"],
      ["an open %w", ["%w[a"], "mode=0 heredocs=0 frames=1"]
    ]) { |lines| state_after(lines) }

    # Equal text gives equal states, so the editor can tell a state settled.
    a = TK.call("x = <<~SQL", 0, Array.new(0, 0))
    b = TK.call("y = <<~SQL", 0, Array.new(0, 0))
    t.assert_equal(a, b, "equal heredoc terminators give equal states")
    t.assert_true(TK.call("x = <<~OTHER", 0, Array.new(0, 0)) != a, "another terminator gives another state")
    deep = TK.call("\"a \#{ \"b \#{ \"c \#{ \"d", 0, Array.new(0, 0))
    t.assert_true(deep >= 0, "a state too deep to encode is still a state")
    t.assert_true(TK.call("e\" } f", deep, Array.new(0, 0)) >= 0, "the next line after it is tokenized")
    t.assert_true(deep < (1 << 58), "states stay within 58 bits")

    # The plugin: its manifest declares ruby and resolves its groups.
    plugin = R::Plugin.new
    m = plugin.manifest
    t.assert_equal(["ruby", ["ruby"], Carat::PluginApi::VERSION], [m.name, m.filetypes, m.api_version], "the manifest declares the ruby filetype")
    t.assert_equal([], Carat::Domain::ManifestCheck.check(m), "and breaks no rule")
    t.assert_equal(TK.ids.length, G::NAMES.length, "one id per group")

    t.finish
  end
end

PluginsRubyTest.main if __FILE__ == $0
