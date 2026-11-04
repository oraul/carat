require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainExRangeTest
  D = Carat::Domain

  # The range text resolves on a buffer of lines lines with the cursor on
  # row, after a linewise selection of rows top to bottom (none when top is
  # -1): [first, last, given, error]. Typed: a table value is untyped
  # (docs/spinel-notes.md).
  def self.resolve(text, row, lines, top, bottom)
    selection = D::Selection.none
    if top.to_i >= 0
      selection = D::Selection.new(anchor: D::Position.new(row: top.to_i, col: 0), head: D::Position.new(row: bottom.to_i, col: 0), kind: :linewise, to_end: false)
    end
    r = D::ExRange.resolve(text.to_s, row.to_i, lines.to_i, selection)
    [r.first, r.last, r.given, r.error]
  end

  def self.main
    t = Carat::Testing.new("domain_ex_range")

    # Rows are [label, [range, cursor row, lines, selection top, bottom],
    # [first, last, given, error]] on a buffer of five lines.
    t.table([
      ["no range is the cursor line", ["", 2, 5, -1, -1], [2, 2, false, ""]],
      ["percent is every line", ["%", 2, 5, -1, -1], [0, 4, true, ""]],
      ["dot is the cursor line", [".", 2, 5, -1, -1], [2, 2, true, ""]],
      ["dollar is the last line", ["$", 0, 5, -1, -1], [4, 4, true, ""]],
      ["a number", ["3", 0, 5, -1, -1], [2, 2, true, ""]],
      ["two numbers", ["2,4", 0, 5, -1, -1], [1, 3, true, ""]],
      ["dot to dollar", [".,$", 1, 5, -1, -1], [1, 4, true, ""]],
      ["blanks around the addresses", [" 1 , 2 ", 0, 5, -1, -1], [0, 1, true, ""]],
      ["an empty first address is the cursor line", [",4", 1, 5, -1, -1], [1, 3, true, ""]],
      ["an empty second address is the cursor line", ["1,", 2, 5, -1, -1], [0, 2, true, ""]],
      ["line 0 is line 1", ["0", 3, 5, -1, -1], [0, 0, true, ""]],
      ["of three addresses the last two count", ["1,2,3", 0, 5, -1, -1], [1, 2, true, ""]],
      ["the visual marks", ["'<,'>", 0, 5, 3, 1], [1, 3, true, ""]],
      ["a mark past the end is the last line", ["'<,'>", 0, 2, 0, 4], [0, 1, true, ""]],
      ["past the last line", ["6", 0, 5, -1, -1], [0, 0, true, "E16: Invalid range"]],
      ["a huge number", ["99999999999999999999", 0, 5, -1, -1], [0, 0, true, "E16: Invalid range"]],
      ["backwards", ["3,1", 0, 5, -1, -1], [0, 0, true, "E493: Backwards range given"]],
      ["no selection for the marks", ["'<,'>", 0, 5, -1, -1], [0, 0, true, "E20: Mark not set"]],
      ["another mark", ["'a", 0, 5, -1, -1], [0, 0, true, "Not implemented: range 'a"]],
      ["arithmetic", [".+1", 0, 5, -1, -1], [0, 0, true, "Not implemented: range .+1"]],
      ["a semicolon", ["1;2", 0, 5, -1, -1], [0, 0, true, "Not implemented: range 1;2"]],
      ["percent with another address", ["%,2", 0, 5, -1, -1], [0, 0, true, "Not implemented: range %,2"]]
    ]) do |input|
      resolve(input[0], input[1], input[2], input[3], input[4])
    end

    t.finish
  end
end

DomainExRangeTest.main if __FILE__ == $0
