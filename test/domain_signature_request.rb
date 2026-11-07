require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# SignatureRequest: the scan for the call's "(", the serials of ask and
# stop, and the cleaning of an answer.
module DomainSignatureRequestTest
  D = Carat::Domain

  # A typed helper: a table value is untyped, and an untyped argument
  # widens the library method it reaches for every test (docs/spinel-notes.md).
  def self.open_paren(line, col)
    D::SignatureRequest.open_paren(line.to_s, col.to_i)
  end

  # The label and marked range kept for the three pieces.
  def self.kept(prefix, parameter, suffix)
    request = D::SignatureRequest.new
    request.keep(prefix.to_s, parameter.to_s, suffix.to_s)
    [request.label, request.mark_from, request.mark_to, request.arrived]
  end

  def self.main
    t = Carat::Testing.new("domain_signature_request")

    # Rows are [label, [line, cursor column], the "(" column or -1].
    t.table([
      ["no parenthesis", ["foo bar", 7], -1],
      ["just after the open parenthesis", ["foo(", 4], 3],
      ["after an argument", ["foo(a, b", 8], 3],
      ["a closed call before the cursor", ["foo(a) ", 7], -1],
      ["a closed inner call is skipped", ["foo(bar(x), ", 12], 3],
      ["inside the inner call", ["foo(bar(x", 9], 7],
      ["before the parenthesis", ["foo(a)", 3], -1],
      ["the cursor past the line reads to its end", ["f(", 9], 1],
      ["a column of 0", ["(a", 0], -1],
      ["at most 1,024 bytes are scanned", ["f(" + ("x" * 1100), 1102], -1],
      ["a multibyte argument", ["f(é, ", 6], 1]
    ]) do |input|
      open_paren(input[0], input[1])
    end

    # Rows are [label, [prefix, parameter, suffix], [label, from, to, arrived]].
    t.table([
      ["a parameter in the middle", ["foo(", "a", ", b)"], ["foo(a, b)", 4, 5, true]],
      ["no parameter marks nothing", ["foo(a, b)", "", ""], ["foo(a, b)", -1, -1, true]],
      ["an empty answer", ["", "", ""], ["", -1, -1, true]],
      ["escape sequences and controls are dropped", ["f\e[31m(", "a\u0007", "\e]0;x\u0007)"], ["f(a)", 2, 3, true]],
      ["a line feed reads as a space", ["f(a,\n", "b", ")"], ["f(a, b)", 5, 6, true]],
      ["a parameter past the cap is not marked", ["x" * 1030, "a", ")"], ["x" * 1024, -1, -1, true]]
    ]) do |input|
      kept(input[0], input[1], input[2])
    end

    request = D::SignatureRequest.new
    t.assert_equal([false, false], [request.active?, request.waiting?], "a new request follows no call and owes nothing")
    request.ask(2, 1, 0, 3, 4)
    t.assert_equal([true, true, true, false], [request.active?, request.waiting?, request.at?(2, 1, 0, 4), request.at?(2, 1, 0, 5)], "an ask follows the call at the cursor and is owed")
    request.keep("f(", "a", ")")
    request.ask(2, 1, 0, 3, 5)
    t.assert_equal([2, false, ""], [request.want, request.arrived, request.label], "a new ask drops the answer not yet shown")
    request.stop
    t.assert_equal([false, 3, false], [request.active?, request.want, request.on?(2, 1, 0)], "stop follows no call under a new serial")

    t.finish
  end
end

DomainSignatureRequestTest.main if __FILE__ == $0
