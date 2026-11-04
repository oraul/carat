require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainGrammarTest
  D = Carat::Domain

  # A script step's values are untyped; the grammar takes typed key codes,
  # and an untyped argument would widen its parameters for the whole
  # program, so the codes are copied into an integer array.
  #: (untyped) -> Array[Integer]
  def self.ints(value)
    out = []
    i = 0
    while i < value.length
      out << value[i].to_i
      i += 1
    end
    out
  end

  def self.codes(text)
    ints(Carat::Domain::KeyNotation.parse(text, " ").codes)
  end

  # The kind the action table registers for each action these tests use,
  # which HandleKey passes to the grammar with the action.
  def self.kind(action)
    return :register if action == "register.select"
    return :char if action == "visual.replace"
    return :operator if ["operator.delete", "operator.change", "operator.yank", "operator.indent", "operator.dedent"].include?(action)
    return :find if Carat::Domain::Motions::FIND_NAMES.include?(action)
    return :motion if Carat::Domain::Motions::NAMES.include?(action)
    return :text_object if Carat::Domain::TextObjects.object?(action)
    :action
  end

  # What run answers. An object, not an array: destructured from an
  # array inside a method, the two values lost their types on the pinned
  # Spinel.
  class Run
    attr_reader :results #: Array[untyped]
    attr_reader :command #: Carat::Domain::Command?

    #: (Array[untyped], Carat::Domain::Command?) -> void
    def initialize(results, command)
      @results = results
      @command = command
    end
  end

  # Feeds a script to a fresh grammar: each step is [:digit, code],
  # [:char, code], or [:accept, action, keys]; returns the results and the
  # command taken when the last result was :complete.
  def self.run(script)
    grammar = Carat::Domain::CommandGrammar.new
    results = []
    script.each do |step|
      case step[0]
      when :digit then grammar.digit(step[1]); results << :digit
      when :char then results << grammar.char(step[1])
      when :visual then results << grammar.accept_visual(step[1], kind(step[1]), ints(step[2]))
      else results << grammar.accept(step[1], kind(step[1]), ints(step[2]))
      end
    end
    command = results.last == :complete ? grammar.take : nil
    Run.new(results, command)
  end

  def self.main
    t = Carat::Testing.new("domain_grammar")

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
      ["an invalid register cancels", [[:accept, "register.select", codes("\"")], [:char, 35]], [[:pending, :cancel], nil]],
      ["a digit names a register", [[:accept, "register.select", codes("\"")], [:char, 49], [:accept, "operator.put_after", codes("p")]], [[:pending, :pending, :complete], ["1", 0, "", "operator.put_after", "", false]]],
      ["a special key as a register cancels", [[:accept, "register.select", codes("\"")], [:char, 27]], [[:pending, :cancel], nil]],
      ["a find motion wants a character", [[:accept, "motion.find_forward", codes("f")], [:char, 120]], [[:pending, :complete], ["", 0, "", "motion.find_forward", "x", false]]],
      ["a find motion under an operator", [[:accept, "operator.delete", codes("d")], [:accept, "motion.till_forward", codes("t")], [:char, 46]], [[:operator, :pending, :complete], ["", 0, "operator.delete", "motion.till_forward", ".", false]]],
      ["escape cancels a find motion", [[:accept, "motion.find_forward", codes("f")], [:char, 27]], [[:pending, :cancel], nil]],
      ["a standalone action with a count", [[:digit, 51], [:accept, "operator.delete_char", codes("x")]], [[:digit, :complete], ["", 3, "", "operator.delete_char", "", false]]],
      ["a remap-style action name", [[:accept, "mode.cmdline", codes(":")]], [[:complete], ["", 0, "", "mode.cmdline", "", false]]],
      # Visual mode: an operator completes at once on the selection.
      ["a visual operator completes at once", [[:visual, "operator.delete", codes("d")]], [[:complete], ["", 0, "", "operator.delete", "", false]]],
      ["a visual motion with a count", [[:digit, 51], [:visual, "cursor.down", codes("j")]], [[:digit, :complete], ["", 3, "", "cursor.down", "", false]]],
      ["a visual register prefix", [[:visual, "register.select", codes("\"")], [:char, 97], [:visual, "operator.yank", codes("y")]], [[:pending, :pending, :complete], ["a", 0, "", "operator.yank", "", false]]],
      ["a visual text object completes", [[:visual, "textobject.inner_word", codes("iw")]], [[:complete], ["", 0, "", "textobject.inner_word", "", false]]],
      ["visual r wants a character", [[:visual, "visual.replace", codes("r")], [:char, 120]], [[:pending, :complete], ["", 0, "", "visual.replace", "x", false]]],
      ["visual r with a special key cancels", [[:visual, "visual.replace", codes("r")], [:char, 27]], [[:pending, :cancel], nil]],
      ["a visual find wants a character", [[:visual, "motion.find_forward", codes("f")], [:char, 99]], [[:pending, :complete], ["", 0, "", "motion.find_forward", "c", false]]],
      ["a visual action while a register is wanted cancels", [[:visual, "register.select", codes("\"")], [:visual, "cursor.down", codes("j")]], [[:pending, :cancel], nil]]
    ]) do |script|
      outcome = run(script)
      results, command = outcome.results, outcome.command
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
    g.accept("operator.delete", :operator, codes("d"))
    t.assert_equal("10d", g.typed, "typed shows the operator")
    t.assert_equal([10, 0], [g.operator_count, g.count], "the count moves to the operator on an operator")
    g = D::CommandGrammar.new
    g.accept("register.select", :register, codes("\""))
    t.assert_equal(:cancel, g.accept("cursor.down", :motion, codes("j")), "an action while a register is wanted cancels")
    g = D::CommandGrammar.new
    g.accept("motion.find_forward", :find, codes("f"))
    t.assert_equal("f", g.typed, "typed shows the waiting motion")
    g.char(97)
    t.assert_equal("fa", g.typed, "typed shows the character")
    t.assert_equal("", g.take.register, "take resets the register")
    t.assert_equal(["", 0, "", :none, false, [], ""], [g.operator, g.count, g.register, g.want, g.linewise, g.keys, g.typed], "take resets everything")
    t.assert_true(!g.pending?, "nothing pending after take")
    g = D::CommandGrammar.new
    g.digit(50)
    g.accept("operator.delete", :operator, codes("d"))
    t.assert_equal(:prompt, g.accept("search.forward", :search, codes("/")), "a search under an operator wants a pattern")
    t.assert_true(g.wants_pattern? && !g.wants_char?, "the pattern is typed on the command line, not read as a key")
    c = g.pattern("foo")
    t.assert_equal([2, "operator.delete", "search.forward", "foo"], [c.count, c.operator, c.action, c.char], "the pattern completes the command as its argument")
    t.assert_true(!g.wants_pattern?, "the grammar is reset after the pattern")
    g = D::CommandGrammar.new
    t.assert_equal(:prompt, g.accept_visual("search.backward", :search, codes("?")), "a visual search wants a pattern")
    t.assert_equal(:cancel, g.accept_visual("cursor.down", :motion, codes("j")), "a key while a pattern is wanted cancels")
    t.assert_equal("<Esc>", D::CommandGrammar.display(27), "a special key displays in notation")
    t.assert_equal("é", D::CommandGrammar.display(233), "a printable key displays itself")

    # The name lists the action table registers from.
    t.assert_true(D::Motions::NAMES.include?("cursor.left") && D::Motions::NAMES.include?("motion.word_forward"), "cursor and motion actions are listed as motions")
    t.assert_true(!D::Motions::NAMES.include?("motion.find_forward") && D::Motions::FIND_NAMES.include?("motion.till_backward"), "the find motions are listed apart")
    t.assert_true(D::TextObjects.object?("textobject.a_paren") && !D::TextObjects.object?("operator.delete"), "text objects are recognized")
    t.assert_true(kind("operator.delete_char") == :action && kind("operator.indent") == :operator, "x is a plain action and > a pending operator")

    # Command values.
    c = D::Command.plain("mode.insert")
    t.assert_equal(["", 0, "", "mode.insert", "", false, []], [c.register, c.count, c.operator, c.action, c.char, c.linewise, c.keys], "a plain command")
    t.assert_equal(1, c.count_or(1), "count_or with no count")
    t.assert_equal(4, D::Command.new(register: "", count: 4, operator: "", action: "x", char: "", linewise: false, keys: []).count_or(1), "count_or with a count")
    t.assert_true(!c.operator?, "a plain command has no operator")
    f = D::Find.new(char: ".", forward: true, till: true)
    t.assert_equal([".", false, true], [f.reversed.char, f.reversed.forward, f.reversed.till], "reversed flips the direction")

    t.finish
  end
end

DomainGrammarTest.main if __FILE__ == $0
