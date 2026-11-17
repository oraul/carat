require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainGlobalTest
  D = Carat::Domain

  # A typed helper: a table value is untyped, and an untyped argument
  # widens the library method it reaches for every test (docs/spinel-notes.md).
  def self.strings(values)
    out = Array.new(0, "")
    values.each { |v| out << v.to_s }
    out
  end

  def self.ints(values)
    out = Array.new(0, 0)
    values.each { |v| out << v.to_i }
    out
  end

  # Marks rows of lines, then takes one row and applies one edit (from,
  # to, new lines) before each further take, as a global's command does;
  # answers every row taken, -1 at the end.
  def self.walk(lines, rows, edits)
    buffer = D::Buffer.new(lines: strings(lines), path: nil, line_ending: "\n")
    buffer.global_marks.mark(ints(rows), buffer.line_count)
    taken = Array.new(0, 0)
    k = 0
    loop do
      row = buffer.global_marks.take
      taken << row
      break if row < 0
      edit = Carat::Json.element(edits, k)
      unless edit.nil?
        buffer.set_lines(Carat::Json.element(edit, 0).to_i, Carat::Json.element(edit, 1).to_i, strings(Carat::Json.element(edit, 2)))
      end
      k += 1
    end
    taken
  end

  def self.global(text)
    a = D::GlobalArgs.parse(text.to_s)
    [a.pattern, a.command, a.error]
  end

  def self.delimited(text)
    a = D::DelimitedPattern.parse(text.to_s, ":s")
    [a.pattern, a.rest, a.error]
  end

  def self.register_count(text)
    a = D::RegisterCount.parse(text.to_s)
    [a.register, a.count, a.error]
  end

  def self.count_only(text)
    a = D::RegisterCount.parse_count(text.to_s)
    [a.register, a.count, a.error]
  end

  def self.main
    t = Carat::Testing.new("domain_global")

    # Rows are [label, [lines, marked rows, edits after each take], rows taken].
    t.cases([
      ["the marked rows in order", [["a", "b", "a", "a"], [0, 2, 3], []], [0, 2, 3, -1]],
      ["no marks", [["a"], [], []], [-1]],
      ["deleting each taken row", [["a", "a", "b", "a"], [0, 1, 3], [[0, 1, []], [0, 1, []], [1, 2, []]]], [0, 0, 1, -1]],
      ["deleting a marked row below loses its mark", [["a", "a", "b"], [0, 1], [[1, 2, []]]], [0, -1]],
      ["inserted rows are not marked", [["a", "b", "a"], [0, 2], [[1, 1, ["x", "y"]]]], [0, 4, -1]],
      ["many inserted rows move the marks", [["a", "a"], [0, 1], [[1, 1, ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]]]], [0, 11, -1]],
      ["an edit above the scan start lowers it", [["a", "b", "a", "a"], [0, 2, 3], [[0, 3, ["c"]]]], [0, 1, -1]],
      ["clearing the whole buffer drops every mark", [["a", "a", "a"], [0, 1, 2], [[0, 3, []]]], [0, -1]]
    ]) do |input|
      walk(input[0], input[1], input[2])
    end

    buffer = D::Buffer.new(lines: ["a", "b"], path: nil, line_ending: "\n")
    t.assert_equal(false, buffer.global_marks.active?, "a buffer starts with no marks")
    buffer.set_lines(0, 0, ["x"])
    t.assert_equal([false, 0], [buffer.global_marks.active?, buffer.global_marks.flags.length], "an edit with no global running marks nothing")
    buffer.global_marks.mark([1], buffer.line_count)
    t.assert_equal(true, buffer.global_marks.active?, "marking makes the marks active")
    buffer.global_marks.clear
    t.assert_equal([false, -1], [buffer.global_marks.active?, buffer.global_marks.take], "clear drops the marks")

    # A plugin edit that fails part way inside :g: GlobalCommand#visit has
    # marked the rows and opened the transaction, BufferRequests#edit_buffer
    # applied some edits and reverts them with revert_to.
    reverted = D::Buffer.new(lines: ["a", "b", "a", "a"], path: nil, line_ending: "\n")
    reverted.global_marks.mark([0, 2, 3], reverted.line_count)
    reverted.begin_transaction(D::Position.new(row: 0, col: 0))
    first = reverted.global_marks.take
    mark = reverted.transaction_size
    reverted.set_lines(1, 1, ["x", "y"])
    reverted.revert_to(mark)
    taken = [first, reverted.global_marks.take, reverted.global_marks.take, reverted.global_marks.take]
    t.assert_equal([[0, 2, 3, -1], ["a", "b", "a", "a"]], [taken, reverted.lines], "A reverted plugin edit inside a global: the marks stay on their lines")

    # Rows are [label, argument, [pattern, command, error]].
    t.table([
      ["pattern and command", "/a/d", ["a", "d", ""]],
      ["a command with its own delimiters", "/a/s/x/y/g", ["a", "s/x/y/g", ""]],
      ["no closing delimiter lists", "/a", ["a", "", ""]],
      ["an empty command lists", "/a/", ["a", "", ""]],
      ["an empty pattern", "//d", ["", "d", ""]],
      ["another delimiter", "#/#d", ["/", "d", ""]],
      ["an escaped delimiter", "/a\\/b/d", ["a\\/b", "d", ""]],
      ["a delimiter in a collection", "/[/]/d", ["[/]", "d", ""]],
      ["a digit delimiter", "1a1d", ["a", "d", ""]],
      ["no argument", "", ["", "", "E148: Regular expression missing from :global"]],
      ["a letter", "xaxd", ["", "", "E146: Regular expressions can't be delimited by letters"]],
      ["a backslash", "\\/d", ["", "", "Not implemented: \\ as the delimiter of :g"]],
      ["not ASCII", "éaéd", ["", "", "Not implemented: a delimiter that is not ASCII"]]
    ]) do |text|
      global(text)
    end

    # Rows are [label, text, [pattern, rest, error]], read for :s.
    t.table([
      ["a pattern and the rest", "/a/b/g", ["a", "b/g", ""]],
      ["no closing delimiter", "#a", ["a", "", ""]],
      ["a closing delimiter and nothing after", "/a/", ["a", "", ""]],
      ["an escaped delimiter", "/a\\/b/c", ["a\\/b", "c", ""]],
      ["a delimiter in a collection", "/[/]/c", ["[/]", "c", ""]],
      ["nothing", "", ["", "", ""]],
      ["a letter", "aba", ["", "", "E146: Regular expressions can't be delimited by letters"]],
      ["a backslash names the command", "\\/a", ["", "", "Not implemented: \\ as the delimiter of :s"]],
      ["not ASCII", "éaé", ["", "", "Not implemented: a delimiter that is not ASCII"]]
    ]) do |text|
      delimited(text)
    end

    # Rows are [label, argument, [register, count, error]].
    t.table([
      ["nothing", "", ["", -1, ""]],
      ["a register", "x", ["x", -1, ""]],
      ["a count", "3", ["", 3, ""]],
      ["a register and a count", "a 2", ["a", 2, ""]],
      ["a register right before a count", "a2", ["a", 2, ""]],
      ["the unnamed register", "\"", ["\"", -1, ""]],
      ["the black hole", "_", ["_", -1, ""]],
      ["an uppercase register appends", "A", ["A", -1, ""]],
      ["a read-only register", "/", ["", -1, "E488: Trailing characters: /"]],
      ["a zero count", "0", ["", -1, "E939: Positive count required"]],
      ["something after the count", "2 x", ["", -1, "E488: Trailing characters: x"]],
      ["two registers", "ab", ["", -1, "E488: Trailing characters: b"]],
      ["blanks after the count", "4  ", ["", 4, ""]]
    ]) do |text|
      register_count(text)
    end

    # The count of :j, :>, and :<, which take no register. Rows are
    # [label, [text], [register, count, error]].
    t.cases([
      ["a count alone", ["3"], ["", 3, ""]],
      ["no count", [""], ["", -1, ""]],
      ["a letter is trailing text", ["a"], ["", -1, "E488: Trailing characters: a"]],
      ["a zero count alone", ["0"], ["", -1, "E939: Positive count required"]]
    ]) do |input|
      count_only(Carat::Json.element(input, 0))
    end

    t.finish
  end
end

DomainGlobalTest.main if __FILE__ == $0
