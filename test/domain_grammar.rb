require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("domain_grammar")
D = Carat::Domain

def codes(text)
  Carat::Domain::KeyNotation.parse(text, " ").codes
end

# Feeds a script to a fresh grammar: each step is [:digit, code],
# [:char, code], or [:accept, action, keys]; returns the results and the
# command taken when the last result was :complete.
def run(script)
  grammar = Carat::Domain::CommandGrammar.new
  results = []
  script.each do |step|
    case step[0]
    when :digit then grammar.digit(step[1]); results << :digit
    when :char then results << grammar.char(step[1])
    else results << grammar.accept(step[1], step[2])
    end
  end
  command = results.last == :complete ? grammar.take : nil
  [results, command]
end

# Rows are [label, script, [results, [register, count, operator, action, char, linewise]]].
t.table([
  ["a motion completes at once", [[:accept, "cursor.down", codes("j")]], [[:complete], ["", 0, "", "cursor.down", "", false]]],
  ["a count then a motion", [[:digit, 51], [:accept, "cursor.down", codes("j")]], [[:digit, :complete], ["", 3, "", "cursor.down", "", false]]],
  ["two digits", [[:digit, 49], [:digit, 48], [:accept, "cursor.down", codes("j")]], [[:digit, :digit, :complete], ["", 10, "", "cursor.down", "", false]]],
  ["an operator waits", [[:accept, "operator.delete", codes("d")]], [[:operator], nil]],
  ["an operator then a motion", [[:accept, "operator.delete", codes("d")], [:accept, "motion.word_forward", codes("w")]], [[:operator, :complete], ["", 0, "operator.delete", "motion.word_forward", "", false]]],
  ["counts multiply", [[:digit, 50], [:accept, "operator.delete", codes("d")], [:digit, 51], [:accept, "motion.word_forward", codes("w")]], [[:digit, :operator, :digit, :complete], ["", 6, "operator.delete", "motion.word_forward", "", false]]],
  ["a count after the operator only", [[:accept, "operator.delete", codes("d")], [:digit, 51], [:accept, "motion.word_forward", codes("w")]], [[:operator, :digit, :complete], ["", 3, "operator.delete", "motion.word_forward", "", false]]],
  ["a doubled operator is linewise", [[:accept, "operator.yank", codes("y")], [:accept, "operator.yank", codes("y")]], [[:operator, :complete], ["", 0, "operator.yank", "", "", true]]],
  ["a different operator cancels", [[:accept, "operator.yank", codes("y")], [:accept, "operator.delete", codes("d")]], [[:operator, :cancel], nil]],
  ["a standalone action in operator-pending cancels", [[:accept, "operator.delete", codes("d")], [:accept, "mode.normal", codes("<Esc>")]], [[:operator, :cancel], nil]],
  ["a text object completes an operator", [[:accept, "operator.change", codes("c")], [:accept, "textobject.inner_word", codes("iw")]], [[:operator, :complete], ["", 0, "operator.change", "textobject.inner_word", "", false]]],
  ["a text object without an operator cancels", [[:accept, "textobject.inner_word", codes("iw")]], [[:cancel], nil]],
  ["a register prefix", [[:accept, "register.select", codes("\"")], [:char, 97], [:accept, "operator.delete", codes("d")], [:accept, "operator.delete", codes("d")]], [[:pending, :pending, :operator, :complete], ["a", 0, "operator.delete", "", "", true]]],
  ["an uppercase register", [[:accept, "register.select", codes("\"")], [:char, 65], [:accept, "operator.put_after", codes("p")]], [[:pending, :pending, :complete], ["A", 0, "", "operator.put_after", "", false]]],
  ["the quote register", [[:accept, "register.select", codes("\"")], [:char, 34], [:accept, "operator.put_after", codes("p")]], [[:pending, :pending, :complete], ["\"", 0, "", "operator.put_after", "", false]]],
  ["an invalid register cancels", [[:accept, "register.select", codes("\"")], [:char, 49]], [[:pending, :cancel], nil]],
  ["a special key as a register cancels", [[:accept, "register.select", codes("\"")], [:char, 27]], [[:pending, :cancel], nil]],
  ["a find motion wants a character", [[:accept, "motion.find_forward", codes("f")], [:char, 120]], [[:pending, :complete], ["", 0, "", "motion.find_forward", "x", false]]],
  ["a find motion under an operator", [[:accept, "operator.delete", codes("d")], [:accept, "motion.till_forward", codes("t")], [:char, 46]], [[:operator, :pending, :complete], ["", 0, "operator.delete", "motion.till_forward", ".", false]]],
  ["escape cancels a find motion", [[:accept, "motion.find_forward", codes("f")], [:char, 27]], [[:pending, :cancel], nil]],
  ["a standalone action with a count", [[:digit, 51], [:accept, "operator.delete_char", codes("x")]], [[:digit, :complete], ["", 3, "", "operator.delete_char", "", false]]],
  ["a remap-style action name", [[:accept, "mode.cmdline", codes(":")]], [[:complete], ["", 0, "", "mode.cmdline", "", false]]]
]) do |script|
  results, command = run(script)
  fields = command.nil? ? nil : [command.register, command.count, command.operator, command.action, command.char, command.linewise]
  [results, fields]
end

# Digits and the typed text.
g = D::CommandGrammar.new
t.assert_true(!g.digit?(48), "0 does not start a count")
t.assert_true(g.digit?(49), "1 starts a count")
g.digit(49)
t.assert_true(g.digit?(48), "0 continues a count")
g.digit(48)
t.assert_equal(10, g.count, "digits accumulate")
t.assert_equal("10", g.typed, "typed shows the digits")
g.accept("operator.delete", codes("d"))
t.assert_equal("10d", g.typed, "typed shows the operator")
t.assert_equal([10, 0], [g.operator_count, g.count], "the count moves to the operator on an operator")
g = D::CommandGrammar.new
g.accept("register.select", codes("\""))
t.assert_equal(:cancel, g.accept("cursor.down", codes("j")), "an action while a register is wanted cancels")
g = D::CommandGrammar.new
g.accept("motion.find_forward", codes("f"))
t.assert_equal("f", g.typed, "typed shows the waiting motion")
g.char(97)
t.assert_equal("fa", g.typed, "typed shows the character")
t.assert_equal("", g.take.register, "take resets the register")
t.assert_equal(["", 0, "", :none, false, [], ""], [g.operator, g.count, g.register, g.want, g.linewise, g.keys, g.typed], "take resets everything")
t.assert_true(!g.pending?, "nothing pending after take")
t.assert_equal("<Esc>", D::CommandGrammar.display(27), "a special key displays in notation")
t.assert_equal("é", D::CommandGrammar.display(233), "a printable key displays itself")

# Classification by name.
t.assert_true(D::CommandGrammar.motion?("cursor.left"), "cursor actions are motions")
t.assert_true(D::CommandGrammar.motion?("motion.word_forward"), "motion actions are motions")
t.assert_true(!D::CommandGrammar.motion?("operator.delete"), "operators are not motions")
t.assert_true(D::CommandGrammar.operator?("operator.indent"), "indent is an operator")
t.assert_true(!D::CommandGrammar.operator?("operator.delete_char"), "x is not a pending operator")
t.assert_true(D::CommandGrammar.text_object?("textobject.a_paren"), "text objects are recognized")

# Command values.
c = D::Command.plain("mode.insert")
t.assert_equal(["", 0, "", "mode.insert", "", false, []], [c.register, c.count, c.operator, c.action, c.char, c.linewise, c.keys], "a plain command")
t.assert_equal(1, c.count_or(1), "count_or with no count")
t.assert_equal(4, D::Command.new("", 4, "", "x", "", false, []).count_or(1), "count_or with a count")
t.assert_true(!c.operator?, "a plain command has no operator")
f = D::Find.new(".", true, true)
t.assert_equal([".", false, true], [f.reversed.char, f.reversed.forward, f.reversed.till], "reversed flips the direction")

t.finish
