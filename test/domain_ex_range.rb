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

  # The target address text gives on a buffer of lines lines with the
  # cursor on row, with no selection: [line, error]. Typed: a table value
  # is untyped.
  def self.target(text, row, lines)
    r = D::ExRange.target(text.to_s, row.to_i, lines.to_i, D::Selection.none)
    [r.first, r.error]
  end

  def self.main
    t = Carat::Testing.new("domain_ex_range")

    # Rows are [label, [range, cursor row, lines, selection top, bottom],
    # [first, last, given, error]] on a buffer of five lines.
    t.cases([
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
      ["percent with another address", ["%,2", 0, 5, -1, -1], [0, 0, true, "Not implemented: range %,2"]],
      ["numbers joined by a blank", ["1 2", 0, 5, -1, -1], [0, 0, true, "Not implemented: range 1 2"]],
      ["text that is no address", ["x", 0, 5, -1, -1], [0, 0, true, "E16: Invalid range"]]
    ]) do |input|
      resolve(input[0], input[1], input[2], input[3], input[4])
    end

    # The target of :m, :co, and :t. Rows are [label, [address, cursor
    # row, lines], [row, error]] on a buffer of five lines: the row the
    # lines are put at, which is the 1-based line they go below.
    t.cases([
      ["a target line number", ["3", 0, 5], [3, ""]],
      ["target 0 is above the first line", ["0", 2, 5], [0, ""]],
      ["a target dot is the cursor line", [".", 2, 5], [3, ""]],
      ["a target dollar is the last line", ["$", 0, 5], [5, ""]],
      ["blanks around the target", [" 2 ", 0, 5], [2, ""]],
      ["no target", ["", 0, 5], [0, "E16: Invalid range"]],
      ["a target past the last line", ["6", 0, 5], [0, "E16: Invalid range"]],
      ["a target that is not an address", ["x", 0, 5], [0, "E16: Invalid range"]],
      ["text after the target", ["2 x", 0, 5], [0, "E16: Invalid range"]],
      ["a target with an offset", [".+1", 0, 5], [0, "Not implemented: address .+1"]],
      ["a target pattern", ["/a/", 0, 5], [0, "Not implemented: address /a/"]],
      ["another mark as the target", ["'a", 0, 5], [0, "Not implemented: address 'a"]],
      ["an unset visual mark as the target", ["'<", 0, 5], [0, "E20: Mark not set"]],
      ["numbers joined by a blank as the target", ["1 2", 0, 5], [0, "Not implemented: address 1 2"]],
      ["a percent target is no address", ["%", 0, 5], [0, "E16: Invalid range"]]
    ]) do |input|
      target(input[0], input[1], input[2])
    end

    # A count after a line command. Rows are [label, [first, last, count,
    # lines], [first, last]].
    t.cases([
      ["a count from the last row", [1, 2, 3, 9], [2, 4]],
      ["a count stops at the last row", [0, 0, 9, 3], [0, 2]],
      ["a count of one is the last row", [0, 3, 1, 9], [3, 3]]
    ]) do |input|
      r = D::ExRange.new(first: input[0].to_i, last: input[1].to_i, given: true, error: "", addresses: 1).counted(input[2].to_i, input[3].to_i)
      [r.first, r.last]
    end

    # How many addresses a range typed, as :j reads it. Rows are [label,
    # [text, row, lines], addresses].
    t.cases([
      ["no address", ["", 1, 5], 0],
      ["one address", ["2", 1, 5], 1],
      ["two addresses", ["1,2", 1, 5], 2],
      ["three addresses count as two", ["1,2,3", 1, 5], 2],
      ["percent counts as two", ["%", 1, 5], 2],
      ["a refused range has none", ["9", 1, 5], 0]
    ]) do |input|
      D::ExRange.resolve(input[0].to_s, input[1].to_i, input[2].to_i, D::Selection.none).addresses
    end

    t.finish
  end
end

DomainExRangeTest.main if __FILE__ == $0
