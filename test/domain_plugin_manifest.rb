require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("domain_plugin_manifest")
A = Carat::PluginApi
M = Carat::Domain::ManifestCheck

# A manifest like the hello plugin's, with one field replaced per row.
def manifest(name, api, actions, commands, bindings, events, options, types)
  Carat::PluginApi::Manifest.new(name, "0.1.0", api, actions, commands, bindings, events, options, types)
end

GOOD_ACTIONS = { "plugin.hello.greet" => "Show a greeting" }
GOOD_BINDINGS = { "normal" => { "<leader>hh" => "plugin.hello.greet" } }

def good
  manifest("hello", "1.0", GOOD_ACTIONS, { "Hello" => "Hel" }, GOOD_BINDINGS, [:buffer_open], { "greeting" => "Hello" }, { "greeting" => :string })
end

t.assert_equal([], M.check(good), "the hello manifest breaks no rule")
t.assert_equal("", M.refusal("1.0"), "the host's own version is accepted")
t.assert_equal("", M.refusal("1.3"), "a newer minor is accepted")
t.assert_equal("needs API 2.0, the host has 1.0", M.refusal("2.0"), "a newer major is refused with both versions")
t.assert_equal("", M.refusal("x"), "a malformed version is not a refusal")

# Rows are [label, manifest, the first problem reported].
t.table([
  ["uppercase name", manifest("Hello", "1.0", GOOD_ACTIONS, {}, nil, [], {}, {}), "name \"Hello\" is not lowercase letters, digits, and underscores starting with a letter"],
  ["name starting with a digit", manifest("1x", "1.0", {}, {}, nil, [], {}, {}), "name \"1x\" is not lowercase letters, digits, and underscores starting with a letter"],
  ["newer major", manifest("hello", "2.0", GOOD_ACTIONS, {}, nil, [], {}, {}), "needs API 2.0, the host has 1.0"],
  ["malformed version", manifest("hello", "one", GOOD_ACTIONS, {}, nil, [], {}, {}), "api_version \"one\" is not major.minor"],
  ["action for another plugin", manifest("a", "1.0", { "plugin.b.go" => "Go" }, {}, nil, [], {}, {}), "action \"plugin.b.go\" is not plugin.a.<action>"],
  ["action without the prefix", manifest("hello", "1.0", { "greet" => "Greet" }, {}, nil, [], {}, {}), "action \"greet\" is not plugin.hello.<action>"],
  ["action with a bad tail", manifest("hello", "1.0", { "plugin.hello.Go" => "Go" }, {}, nil, [], {}, {}), "action \"plugin.hello.Go\" is not plugin.hello.<action>"],
  ["action without a description", manifest("hello", "1.0", { "plugin.hello.greet" => "" }, {}, nil, [], {}, {}), "action \"plugin.hello.greet\" has no description"],
  ["lowercase command", manifest("hello", "1.0", GOOD_ACTIONS, { "hello" => "" }, nil, [], {}, {}), "command \"hello\" does not start with an uppercase letter"],
  ["abbreviation that is not a prefix", manifest("hello", "1.0", GOOD_ACTIONS, { "Hello" => "Hal" }, nil, [], {}, {}), "abbreviation \"Hal\" is not a proper prefix of \"Hello\""],
  ["abbreviation equal to the name", manifest("hello", "1.0", GOOD_ACTIONS, { "Hello" => "Hello" }, nil, [], {}, {}), "abbreviation \"Hello\" is not a proper prefix of \"Hello\""],
  ["unknown event", manifest("hello", "1.0", GOOD_ACTIONS, {}, nil, [:idle], {}, {}), "event idle is unknown"],
  ["bad key notation", manifest("hello", "1.0", GOOD_ACTIONS, {}, { "normal" => { "<Nope>" => "plugin.hello.greet" } }, [], {}, {}), "binding normal.<Nope>: unknown key <Nope>"],
  ["unknown mode", manifest("hello", "1.0", GOOD_ACTIONS, {}, { "nope" => { "x" => "plugin.hello.greet" } }, [], {}, {}), "binding nope: unknown mode"],
  ["binding to a foreign action", manifest("hello", "1.0", GOOD_ACTIONS, {}, { "normal" => { "x" => "cursor.down" } }, [], {}, {}), "binding normal.x names \"cursor.down\", not one of the plugin's actions"],
  ["bindings that are not an object", manifest("hello", "1.0", GOOD_ACTIONS, {}, [1], [], {}, {}), "bindings is not an object of modes"],
  ["option without a type", manifest("hello", "1.0", GOOD_ACTIONS, {}, nil, [], { "depth" => "3" }, {}), "option \"depth\" has no type"],
  ["option with an unknown type", manifest("hello", "1.0", GOOD_ACTIONS, {}, nil, [], { "depth" => "3" }, { "depth" => :float }), "option \"depth\" has the unknown type float"],
  ["integer option with a bad default", manifest("hello", "1.0", GOOD_ACTIONS, {}, nil, [], { "depth" => "many" }, { "depth" => :integer }), "option \"depth\" default \"many\" is not a integer"],
  ["bool option with a bad default", manifest("hello", "1.0", GOOD_ACTIONS, {}, nil, [], { "deep" => "yes" }, { "deep" => :bool }), "option \"deep\" default \"yes\" is not a bool"],
  ["type without a default", manifest("hello", "1.0", GOOD_ACTIONS, {}, nil, [], {}, { "depth" => :integer }), "option \"depth\" has a type but no default"]
]) do |m|
  problems = M.check(m)
  problems.empty? ? "" : problems[0]
end

# Accepted shapes: rows are [label, manifest, problem count].
t.table([
  ["a key sequence binding", manifest("hello", "1.0", GOOD_ACTIONS, {}, { "normal" => { "<leader>w" => ":w<CR>" } }, [], {}, {}), 0],
  ["a null binding", manifest("hello", "1.0", GOOD_ACTIONS, {}, { "normal" => { "x" => nil } }, [], {}, {}), 0],
  ["no bindings", manifest("hello", "1.0", GOOD_ACTIONS, {}, nil, [], {}, {}), 0],
  ["a command with no abbreviation", manifest("hello", "1.0", GOOD_ACTIONS, { "Hello" => "" }, nil, [], {}, {}), 0],
  ["every event", manifest("hello", "1.0", GOOD_ACTIONS, {}, nil, Carat::PluginApi::EVENTS, {}, {}), 0],
  ["every option type", manifest("hello", "1.0", GOOD_ACTIONS, {}, nil, [], { "a" => "true", "b" => "-2", "c" => "x", "d" => "p\nq" }, { "a" => :bool, "b" => :integer, "c" => :string, "d" => :list }), 0],
  ["two problems are both reported", manifest("hello", "2.0", GOOD_ACTIONS, { "hello" => "" }, nil, [], {}, {}), 2]
]) do |m|
  M.check(m).length
end

t.assert_equal("Show a greeting", good.describe("plugin.hello.greet"), "describe returns the description")
t.assert_equal("", good.describe("plugin.hello.nope"), "describe returns empty for an unknown action")

t.finish
