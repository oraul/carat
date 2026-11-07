require_relative "../carat/domain/json"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module JsonTest
  J = Carat::Json

  def self.main
    t = Carat::Testing.new("json")

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

    # Hostile text from a language server: illegal UTF-8 bytes read as
    # U+FFFD, and nesting past the limit is refused, never a crash.
    t.table([
      ["an illegal byte reads as U+FFFD", "\"a\xFFb\"", "a\u{FFFD}b"],
      ["a high surrogate's bytes read as three U+FFFD", "\"\xED\xA0\x80\"", "\u{FFFD}\u{FFFD}\u{FFFD}"],
      ["a well-formed sequence is kept", "\"\u00e9\u{1F600}\"", "\u00e9\u{1F600}"],
      ["a lone low surrogate escape reads as U+FFFD", "\"\\udc00\"", "\u{FFFD}"],
      ["a truncated sequence at the end", "\"\xE2\x82\"", "\u{FFFD}\u{FFFD}"]
    ]) { |text| J.parse(text) }
    t.assert_equal([[[1]]], J.parse("[[[1]]]"), "shallow nesting reads")
    t.assert_equal(64, depth_of(J.parse(("[" * 64) + ("]" * 64))), "nesting at the limit reads")
    t.assert_raises(J::Error, "nesting past the limit") { J.parse(("[" * 65) + ("]" * 65)) }
    t.assert_raises(J::Error, "deep object nesting") { J.parse("{\"a\":" * 100 + "1" + "}" * 100) }
    t.assert_raises(J::Error, "a hundred thousand brackets") { J.parse("[" * 100_000) }

    t.table([
      ["write null", nil, "null"],
      ["write number", 12, "12"],
      ["write string", "x\"y\n", "\"x\\\"y\\n\""],
      ["write array", [1, [2]], "[1,[2]]"],
      ["write object", { "a" => 1, "b" => [] }, "{\"a\":1,\"b\":[]}"],
      ["write an illegal byte as U+FFFD", "a\xFFb", "\"a\u{FFFD}b\""],
      ["write a truncated sequence as U+FFFD", "x\xE2\x82", "\"x\u{FFFD}\u{FFFD}\""],
      ["write UTF-8 and a control byte", "\u00e9\u0001\u{1F600}", "\"\u00e9\\u0001\u{1F600}\""],
      ["write every short escape", "\"\\\n\r\t\b\f", "\"\\\"\\\\\\n\\r\\t\\b\\f\""]
    ]) { |value| J.generate(value) }

    t.assert_equal("{\n  \"a\": [\n    1\n  ]\n}", J.pretty_generate({ "a" => [1] }), "pretty print")

    round = { "k" => [1, 2.5, "s", nil, true, { "n" => {} }] }
    t.assert_equal(round, J.parse(J.generate(round)), "round trip")

    t.finish
  end

  # How deep the first elements of nested arrays go.
  def self.depth_of(value)
    depth = 0
    while value.is_a?(Array)
      depth += 1
      value = value.empty? ? nil : value[0]
    end
    depth
  end
end

JsonTest.main if __FILE__ == $0
