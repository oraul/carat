require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainPluginManifestTest
  A = Carat::PluginApi
  M = Carat::Domain::ManifestCheck

  # A manifest like the hello plugin's, with one field replaced per row.
  def self.manifest(name, api, actions, commands, bindings, events, options, types)
    Carat::PluginApi::Manifest.new(name: name, version: "0.1.0", api_version: api, actions: actions, commands: commands, bindings: bindings, events: events, options: options, option_types: types, filetypes: [])
  end

  GOOD_ACTIONS = { "plugin.hello.greet" => "Show a greeting" }
  GOOD_BINDINGS = ["keymap.normal <leader>hh plugin.hello.greet"]

  # A manifest that tokenizes the given filetypes.
  def self.tokenizer(filetypes)
    Carat::PluginApi::Manifest.new(name: "lang", version: "0.1.0", api_version: "2.0", actions: {}, commands: {}, bindings: [], events: [], options: [], option_types: {}, filetypes: filetypes)
  end

  def self.good
    manifest("hello", "2.0", GOOD_ACTIONS, { "Hello" => "Hel" }, GOOD_BINDINGS, ["buffer_open"], ["plugin.hello.greeting Hello"], { "greeting" => "string" })
  end

  def self.main
    t = Carat::Testing.new("domain_plugin_manifest")

    t.assert_equal([], M.check(good), "the hello manifest breaks no rule")
    t.assert_equal([], M.check(manifest("hello", "2.0", GOOD_ACTIONS, {}, [], [:buffer_open, :buffer_close], ["plugin.hello.n 1"], { "n" => :integer })), "symbols for events and types are read as names")
    t.assert_equal(["", ""], [M.refusal("2.4"), M.refusal("2.1")], "the host's own version and 2.1 are accepted")
    t.assert_equal("", M.refusal("2.0"), "an older minor is accepted")
    t.assert_equal("needs API 2.5, the host has 2.4", M.refusal("2.5"), "a newer minor is refused")
    t.assert_equal("needs API 3.0, the host has 2.3", M.refusal("3.0"), "a newer major is refused with both versions")
    t.assert_equal("needs API 1.3, the host has 2.3", M.refusal("1.3"), "an older major is refused")
    t.assert_equal("", M.refusal("x"), "a malformed version is not a refusal")

    # Rows are [label, manifest, the first problem reported].
    t.table([
      ["uppercase name", manifest("Hello", "2.0", GOOD_ACTIONS, {}, [], [], [], {}), "name \"Hello\" is not lowercase letters, digits, and underscores starting with a letter"],
      ["name starting with a digit", manifest("1x", "2.0", {}, {}, [], [], [], {}), "name \"1x\" is not lowercase letters, digits, and underscores starting with a letter"],
      ["newer major", manifest("hello", "3.0", GOOD_ACTIONS, {}, [], [], [], {}), "needs API 3.0, the host has 2.3"],
      ["a 1.x manifest", manifest("hello", "1.3", GOOD_ACTIONS, {}, [], [], [], {}), "needs API 1.3, the host has 2.3"],
      ["malformed version", manifest("hello", "one", GOOD_ACTIONS, {}, [], [], [], {}), "api_version \"one\" is not major.minor"],
      ["action for another plugin", manifest("a", "2.0", { "plugin.b.go" => "Go" }, {}, [], [], [], {}), "action \"plugin.b.go\" is not plugin.a.<action>"],
      ["action without the prefix", manifest("hello", "2.0", { "greet" => "Greet" }, {}, [], [], [], {}), "action \"greet\" is not plugin.hello.<action>"],
      ["action with a bad tail", manifest("hello", "2.0", { "plugin.hello.Go" => "Go" }, {}, [], [], [], {}), "action \"plugin.hello.Go\" is not plugin.hello.<action>"],
      ["action without a description", manifest("hello", "2.0", { "plugin.hello.greet" => "" }, {}, [], [], [], {}), "action \"plugin.hello.greet\" has no description"],
      ["lowercase command", manifest("hello", "2.0", GOOD_ACTIONS, { "hello" => "" }, [], [], [], {}), "command \"hello\" does not start with an uppercase letter"],
      ["abbreviation that is not a prefix", manifest("hello", "2.0", GOOD_ACTIONS, { "Hello" => "Hal" }, [], [], [], {}), "abbreviation \"Hal\" is not a proper prefix of \"Hello\""],
      ["abbreviation equal to the name", manifest("hello", "2.0", GOOD_ACTIONS, { "Hello" => "Hello" }, [], [], [], {}), "abbreviation \"Hello\" is not a proper prefix of \"Hello\""],
      ["unknown event", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], ["idle"], [], {}), "event idle is unknown"],
      ["bad key notation", manifest("hello", "2.0", GOOD_ACTIONS, {}, ["keymap.normal <Nope> plugin.hello.greet"], [], [], {}), "binding keymap.normal <Nope> plugin.hello.greet: unknown key <Nope>"],
      ["unknown mode", manifest("hello", "2.0", GOOD_ACTIONS, {}, ["keymap.nope x plugin.hello.greet"], [], [], {}), "binding keymap.nope x plugin.hello.greet: unknown mode nope"],
      ["a binding line that does not read", manifest("hello", "2.0", GOOD_ACTIONS, {}, ["keymap.normal \"x plugin.hello.greet"], [], [], {}), "binding keymap.normal \"x plugin.hello.greet: unterminated quote"],
      ["a binding that is not a keymap line", manifest("hello", "2.0", GOOD_ACTIONS, {}, ["option.number true"], [], [], {}), "binding option.number true: not a keymap line"],
      ["binding to a foreign action", manifest("hello", "2.0", GOOD_ACTIONS, {}, ["keymap.normal x cursor.down"], [], [], {}), "binding \"keymap.normal x cursor.down\" names \"cursor.down\", not one of the plugin's actions"],
      ["bindings that are not a list of lines", manifest("hello", "2.0", GOOD_ACTIONS, {}, { "normal" => { "x" => "plugin.hello.greet" } }, [], [], {}), "bindings is not a list of keymap lines"],
      ["a binding that is not a string", manifest("hello", "2.0", GOOD_ACTIONS, {}, [1], [], [], {}), "bindings is not a list of keymap lines"],
      ["a binding with an illegal byte", manifest("hello", "2.0", GOOD_ACTIONS, {}, ["keymap.normal x plugin.hello.\xFF"], [], [], {}), "binding keymap.normal x plugin.hello.\xFF: illegal byte"],
      ["an option line with an illegal byte", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], [], ["plugin.hello.depth \xC0\xAF"], { "depth" => "integer" }), "option line \"plugin.hello.depth \xC0\xAF\" does not read: illegal byte"],
      ["option without a type", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], [], ["plugin.hello.depth 3"], {}), "option \"depth\" has no type"],
      ["option with an unknown type", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], [], ["plugin.hello.depth 3"], { "depth" => "float" }), "option \"depth\" has the unknown type float"],
      ["integer option with a bad default", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], [], ["plugin.hello.depth many"], { "depth" => "integer" }), "option \"depth\" default \"many\" is not a integer"],
      ["bool option with a bad default", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], [], ["plugin.hello.deep yes"], { "deep" => "bool" }), "option \"deep\" default \"yes\" is not a bool"],
      ["string option with two words", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], [], ["plugin.hello.word a b"], { "word" => "string" }), "option \"word\" default \"a b\" is not a string"],
      ["option line for another plugin", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], [], ["plugin.other.depth 3"], { "depth" => "integer" }), "option line \"plugin.other.depth 3\" is not plugin.hello.<option>"],
      ["option line that does not read", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], [], ["plugin.hello.depth \"3"], { "depth" => "integer" }), "option line \"plugin.hello.depth \\\"3\" does not read: unterminated quote"],
      ["options that are not a list of lines", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], [], { "depth" => "3" }, { "depth" => "integer" }), "options is not a list of option lines"],
      ["actions of the wrong type", manifest("hello", "2.0", "nope", {}, [], [], [], {}), "actions is not an object of action names"],
      ["events of the wrong type", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], 7, [], {}), "events is not a list of event names"],
      ["an event that is not a name", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], [3], [], {}), "event 3 is unknown"],
      ["type without a default", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], [], [], { "depth" => "integer" }), "option \"depth\" has a type but no default"]
    ]) do |m|
      problems = M.check(m)
      problems.empty? ? "" : problems[0]
    end

    # Accepted shapes: rows are [label, manifest, problem count].
    t.table([
      ["a key sequence binding", manifest("hello", "2.0", GOOD_ACTIONS, {}, ["keymap.normal <leader>w :w<CR>"], [], [], {}), 0],
      ["a none binding", manifest("hello", "2.0", GOOD_ACTIONS, {}, ["keymap.normal x none"], [], [], {}), 0],
      ["no bindings", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], [], [], {}), 0],
      ["a command with no abbreviation", manifest("hello", "2.0", GOOD_ACTIONS, { "Hello" => "" }, [], [], [], {}), 0],
      ["every event", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], Carat::PluginApi::EVENTS, [], {}), 0],
      ["every option type", manifest("hello", "2.0", GOOD_ACTIONS, {}, [], [], ["plugin.hello.a true", "plugin.hello.b 2", "plugin.hello.c x", "plugin.hello.d p \"q r\"", "plugin.hello.e"], { "a" => "bool", "b" => "integer", "c" => "string", "d" => "list", "e" => "list" }), 0],
      ["two problems are both reported", manifest("hello", "3.0", GOOD_ACTIONS, { "hello" => "" }, [], [], [], {}), 2]
    ]) do |m|
      M.check(m).length
    end

    # Filetypes: a list of names like plugin names.
    t.table([
      ["no filetypes", [], []],
      ["one filetype", ["ruby"], []],
      ["several", ["ruby", "erb_ruby2"], []],
      ["a malformed filetype", ["Ruby Script"], ["filetype \"Ruby Script\" is not lowercase letters, digits, and underscores starting with a letter"]],
      ["a filetype that is not a string", [3], ["filetype 3 is not lowercase letters, digits, and underscores starting with a letter"]]
    ]) { |types| M.check(tokenizer(types)) }
    t.assert_equal(["filetypes is not a list of filetype names"], M.check(tokenizer("ruby")), "filetypes of the wrong type")

    t.assert_equal("Show a greeting", good.describe("plugin.hello.greet"), "describe returns the description")
    t.assert_equal("", good.describe("plugin.hello.nope"), "describe returns empty for an unknown action")

    t.finish
  end
end

DomainPluginManifestTest.main if __FILE__ == $0
