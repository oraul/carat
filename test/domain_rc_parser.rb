require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainRcParserTest
  D = Carat::Domain

  # What a line parses to: the key and words, or the error.
  def self.read(text)
    parsed = D::RcParser.parse(text)
    parsed.ok? ? [parsed.key, parsed.words] : parsed.error
  end

  # The kept lines of text read as the project file, each as its key and
  # words, and the problems.
  def self.config_of(text, trusted)
    config = D::Config.new
    config.read(".caratrc", text, trusted)
    kept = []
    i = 0
    while i < config.count
      line = config.line_at(i)
      kept << "#{line.number} #{line.scope}|#{line.name} #{line.words.inspect}"
      i += 1
    end
    [kept, config.report]
  end

  def self.main
    t = Carat::Testing.new("domain_rc_parser")

    # One line: rows are [label, text, [key, words] or the error].
    t.table([
      ["a word", "option.theme carat-dark", ["option.theme", ["carat-dark"]]],
      ["a number", "option.tabstop 2", ["option.tabstop", ["2"]]],
      ["a flag", "option.number true", ["option.number", ["true"]]],
      ["a list", "plugin.explorer.ignore .git build tmp", ["plugin.explorer.ignore", [".git", "build", "tmp"]]],
      ["no value", "plugin.explorer.ignore", ["plugin.explorer.ignore", []]],
      ["tabs and runs of spaces", "\tkeymap.normal \t  j   cursor.down  ", ["keymap.normal", ["j", "cursor.down"]]],
      ["a quoted word", "language.ruby.formatter rubocop \"--config my file.yml\"", ["language.ruby.formatter", ["rubocop", "--config my file.yml"]]],
      ["an empty quoted word", "option.clipboard \"\"", ["option.clipboard", [""]]],
      ["an escaped quote", "keymap.normal \"\\\"\" register.select", ["keymap.normal", ["\"", "register.select"]]],
      ["an escaped backslash", "keymap.normal \"a\\\\b\" x.y", ["keymap.normal", ["a\\b", "x.y"]]],
      ["another backslash stays", "keymap.normal \"a\\nb\" x.y", ["keymap.normal", ["a\\nb", "x.y"]]],
      ["a backslash outside quotes", "keymap.normal <C-\\> x.y", ["keymap.normal", ["<C-\\>", "x.y"]]],
      ["a quote inside a word", "keymap.operator_pending i\" textobject.inner_double_quote", ["keymap.operator_pending", ["i\"", "textobject.inner_double_quote"]]],
      ["a quoted hash", "keymap.normal \"#\" x.y", ["keymap.normal", ["#", "x.y"]]],
      ["a hash inside a word", "keymap.normal a#b x.y", ["keymap.normal", ["a#b", "x.y"]]],
      ["a comment after the value", "option.tabstop 4 # four columns", ["option.tabstop", ["4"]]],
      ["a comment right after a word", "option.tabstop 4 #x", ["option.tabstop", ["4"]]],
      ["UTF-8 in a word", "plugin.hello.greeting ¡Hola!", ["plugin.hello.greeting", ["¡Hola!"]]],
      ["UTF-8 in quotes", "plugin.hello.greeting \"día bueno\"", ["plugin.hello.greeting", ["día bueno"]]],
      ["a carriage return", "option.tabstop 4\r", ["option.tabstop", ["4"]]],
      ["a blank line", "   ", ["", []]],
      ["an empty line", "", ["", []]],
      ["a comment line", "# Options", ["", []]],
      ["an indented comment", "  # Options", ["", []]],
      ["a key with digits and underscores", "plugin.git_signs2.on true", ["plugin.git_signs2.on", ["true"]]],
      ["an unterminated quote", "option.clipboard \"unnamed", "unterminated quote"],
      ["an escaped closing quote", "option.clipboard \"a\\\"", "unterminated quote"],
      ["text after a closing quote", "option.clipboard \"a\"b", "text after a closing quote"],
      ["a control character", "option.tabstop 4\e[31m", "control character"],
      ["a control character in a comment", "# \a", "control character"],
      ["a delete character", "option.tabstop \x7f", "control character"],
      ["an undotted key", "tabstop 4", "invalid key"],
      ["an uppercase key", "Option.Tabstop 4", "invalid key"],
      ["a key with an empty segment", "option..tabstop 4", "invalid key"],
      ["a key ending in a dot", "option. 4", "invalid key"],
      ["a key with a dash", "option.tab-stop 4", "invalid key"],
      ["a quoted key", "\"option.tabstop\" 4", "invalid key"],
      ["a control character in quotes", "option.clipboard \"a\tb\ec\"", "control character"],
      ["a tab in quotes stays", "option.clipboard \"a\tb\"", ["option.clipboard", ["a\tb"]]],
      ["a lone Latin-1 byte in a word", "option.theme caf\xE9", "illegal byte"],
      ["an illegal byte in the key", "option.tab\xFFstop 4", "illegal byte"],
      ["an illegal byte in quotes", "option.clipboard \"a\xFFb\"", "illegal byte"],
      ["an illegal byte in a comment", "option.tabstop 4 # caf\xE9", "illegal byte"],
      ["a truncated sequence", "option.theme \xE2\x82", "illegal byte"],
      ["an overlong slash", "option.theme \xC0\xAF", "illegal byte"],
      ["a surrogate", "option.theme \xED\xA0\x80", "illegal byte"],
      ["above U+10FFFF", "option.theme \xF4\x90\x80\x80", "illegal byte"],
      ["a lone continuation byte", "keymap.normal \x80 cursor.down", "illegal byte"],
      ["four-byte UTF-8 stays", "plugin.hello.greeting \u{1F600}", ["plugin.hello.greeting", ["\u{1F600}"]]],
      ["UTF-8 in a comment stays", "option.tabstop 4 # quatre espaces, \u00E9", ["option.tabstop", ["4"]]]
    ]) do |text|
      read(text.to_s)
    end

    # A file: rows are [label, text, [kept lines, problems]].
    t.table([
      ["comments, blanks, and settings", "# a comment\n\noption.tabstop 4 # four\nkeymap.normal j cursor.down\n", [["3 option|tabstop [\"4\"]", "4 keymap|normal [\"j\", \"cursor.down\"]"], []]],
      ["no final newline", "option.tabstop 4", [["1 option|tabstop [\"4\"]"], []]],
      ["carriage returns", "option.tabstop 4\r\noption.number true\r\n", [["1 option|tabstop [\"4\"]", "2 option|number [\"true\"]"], []]],
      ["a malformed line among good ones", "option.tabstop 4\noption.clipboard \"x\noption.number true\n", [["1 option|tabstop [\"4\"]", "3 option|number [\"true\"]"], [".caratrc:2: unterminated quote"]]],
      ["an unknown scope", "editor.font mono\n", [[], [".caratrc:1: unknown setting editor.font"]]],
      ["a language command", "language.ruby.lsp ruby-lsp --debug\n", [["1 language|ruby.lsp [\"ruby-lsp\", \"--debug\"]"], []]],
      ["an unknown language setting", "language.ruby.linter rubocop\nlanguage.ruby x\n", [[], [".caratrc:1: unknown language setting linter", ".caratrc:2: unknown setting language.ruby"]]],
      ["an illegal byte in each scope", "option.theme caf\xE9\nkeymap.normal x a\xFF.b\nplugin.hello.greeting \xC0\xAF\nlanguage.ruby.lsp ruby-lsp\xFE\noption.tabstop 4\n", [["5 option|tabstop [\"4\"]"], [".caratrc:1: illegal byte", ".caratrc:2: illegal byte", ".caratrc:3: illegal byte", ".caratrc:4: illegal byte"]]]
    ]) do |text|
      config_of(text.to_s, true)
    end
    t.assert_equal([[], [".caratrc:1: language commands are not read from a project file"]], config_of("language.ruby.lsp ./evil\n", false), "an untrusted file cannot set language commands")
    t.assert_equal([["1 keymap|normal [\"x\", \"cursor.down\"]", "2 keymap|normal [\"y\", \"none\"]", "4 keymap|leader [\",\"]", "5 keymap|normal [\"z\"]"], [".caratrc:3: key sequences are not read from a project file"]], config_of("keymap.normal x cursor.down\nkeymap.normal y none\nkeymap.normal q :e<Space>.git/config<CR>\nkeymap.leader ,\nkeymap.normal z\n", false), "an untrusted file binds actions and none but no key sequence")
    t.assert_equal([["1 keymap|normal [\"q\", \":w<CR>\"]"], []], config_of("keymap.normal q :w<CR>\n", true), "a trusted file binds a key sequence")
    t.assert_equal([["1 option|tabstop [\"3\"]"], []], config_of("option.tabstop 3\n", false), "an untrusted file sets anything else")

    # Several files: load order, the last line, notes, and the order of
    # problems.
    config = D::Config.new
    config.read_defaults("config/default.caratrc", "option.tabstop 2\nlanguage.ruby.lsp ruby-lsp\n")
    config.read("~/.config/carat/caratrc", "option.tabstop 4\nbad line\n", true)
    config.refuse("extra", "cannot be read")
    config.read(".caratrc", "option.number false\nlanguage.ruby.lsp ./evil\noption.tabstop 3\n", false)
    t.assert_equal(["3", "ruby-lsp", true, false], [config.last("option.tabstop").words[0], config.last("language.ruby.lsp").words[0], config.shipped?(config.line_at(0)), config.shipped?(config.line_at(2))], "the last line of a key wins and the defaults are the shipped lines")
    t.assert_equal(true, config.last("option.wrap").nil?, "a key no line sets has no last line")
    config.note(config.last("option.number"), "a later note")
    config.note(config.line_at(0), "an early note")
    t.assert_equal([
      "config/default.caratrc:1: an early note",
      "~/.config/carat/caratrc:2: invalid key",
      "extra: cannot be read",
      ".caratrc:1: a later note",
      ".caratrc:2: language commands are not read from a project file"
    ], config.report, "problems are reported in file and line order, whoever noted them")

    # Values: rows are [label, [words, kind], [valid, text]].
    t.table([
      ["true", [["true"], "bool"], [true, "true"]],
      ["false", [["false"], "bool"], [true, "false"]],
      ["yes is not a flag", [["yes"], "bool"], [false, "yes"]],
      ["a number", [["42"], "integer"], [true, "42"]],
      ["nine digits", [["999999999"], "integer"], [true, "999999999"]],
      ["ten digits", [["9999999999"], "integer"], [false, "9999999999"]],
      ["a negative number", [["-2"], "integer"], [false, "-2"]],
      ["a word is not a number", [["wide"], "integer"], [false, "wide"]],
      ["a word", [["x"], "string"], [true, "x"]],
      ["an empty word", [[""], "string"], [true, ""]],
      ["two words are not one", [["a", "b"], "string"], [false, "a"]],
      ["no word is not one", [[], "string"], [false, ""]],
      ["a list", [["a", "b c"], "list"], [true, "a\nb c"]],
      ["an empty list", [[], "list"], [true, ""]],
      ["an unknown kind", [["x"], "float"], [false, "x"]]
    ]) do |input|
      words = []
      input[0].each { |word| words << word.to_s }
      kind = input[1].to_s
      [D::RcValue.valid?(words, kind), D::RcValue.text(words, kind)]
    end
    t.assert_equal(["takes true or false", "takes a number", "takes one word", "takes a list of words"], [D::RcValue.expectation("bool"), D::RcValue.expectation("integer"), D::RcValue.expectation("string"), D::RcValue.expectation("list")], "each kind says what it takes")

    t.finish
  end
end

DomainRcParserTest.main if __FILE__ == $0
