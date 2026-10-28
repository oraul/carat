require_relative "../carat/domain/json"
require_relative "../carat/testing"

t = Carat::Testing.new("json")
J = Carat::Json

t.table([
  ["null", "null", nil],
  ["true", "true", true],
  ["false", "false", false],
  ["integer", "42", 42],
  ["negative integer", "-7", -7],
  ["float", "3.25", 3.25],
  ["exponent", "1e3", 1000.0],
  ["string", "\"hi\"", "hi"],
  ["escapes", "\"a\\nb\\t\\\"c\\\"\"", "a\nb\t\"c\""],
  ["unicode escape", "\"\\u00e9\"", "\u00e9"],
  ["surrogate pair", "\"\\ud83d\\ude00\"", "\u{1F600}"],
  ["empty array", "[]", []],
  ["array", "[1, \"two\", [3]]", [1, "two", [3]]],
  ["empty object", "{}", {}],
  ["object", "{\"a\": 1, \"b\": {\"c\": [true]}}", { "a" => 1, "b" => { "c" => [true] } }],
  ["whitespace", " \n{ \"k\" :\t[ 1 , 2 ] }\r\n", { "k" => [1, 2] }]
]) { |text| J.parse(text) }

t.assert_raises(J::Error, "trailing garbage") { J.parse("1 2") }
t.assert_raises(J::Error, "unterminated string") { J.parse("\"abc") }
t.assert_raises(J::Error, "bad literal") { J.parse("tru") }
t.assert_raises(J::Error, "leading zero") { J.parse("[01]") }
t.assert_raises(J::Error, "missing colon") { J.parse("{\"a\" 1}") }

t.table([
  ["write null", nil, "null"],
  ["write number", 12, "12"],
  ["write string", "x\"y\n", "\"x\\\"y\\n\""],
  ["write array", [1, [2]], "[1,[2]]"],
  ["write object", { "a" => 1, "b" => [] }, "{\"a\":1,\"b\":[]}"]
]) { |value| J.generate(value) }

t.assert_equal("{\n  \"a\": [\n    1\n  ]\n}", J.pretty_generate({ "a" => [1] }), "pretty print")

round = { "k" => [1, 2.5, "s", nil, true, { "n" => {} }] }
t.assert_equal(round, J.parse(J.generate(round)), "round trip")

t.finish
