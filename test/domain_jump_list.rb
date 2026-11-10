require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# The jump list: pushing, the cap, the same-line replacement, and
# stepping with the newest-end push.
module DomainJumpListTest
  D = Carat::Domain

  # The entries as "buffer:row:col" strings, oldest first, then the index.
  def self.entries(list)
    out = [""]
    out.clear
    i = 0
    while i < list.count
      out << "#{list.buffer_ids[i]}:#{list.rows[i]}:#{list.cols[i]}"
      i += 1
    end
    out << "at #{list.index}"
    out
  end

  # A list holding the rows given, all in buffer 1 at column 0.
  def self.filled(rows)
    list = D::JumpList.new
    i = 0
    while i < rows.length
      list.push(1, rows[i].to_i, 0)
      i += 1
    end
    list
  end

  #: (untyped) -> Array[Integer]
  def self.ints(values)
    out = [0]
    out.clear
    values.each { |v| out << v.to_i }
    out
  end

  def self.main
    t = Carat::Testing.new("domain_jump_list")

    # Rows are [label, rows pushed, steps as [by, row of the current position], the entries and index after].
    t.table([
      ["a push appends and leaves no entry current", [[3], []], ["1:3:0", "at 1"]],
      ["Ctrl-O from the newest end records the start and goes back", [[3], [-1, 9]], ["1:3:0", "1:9:0", "at 0"]],
      ["Ctrl-I after Ctrl-O comes back to the start", [[3], [-1, 9, 1, 3]], ["1:3:0", "1:9:0", "at 1"]],
      ["Ctrl-O past the oldest entry moves nothing", [[3], [-1, 9, -1, 3]], ["1:3:0", "1:9:0", "at 0"]],
      ["Ctrl-I at the newest end moves nothing", [[3, 5], [1, 7]], ["1:3:0", "1:5:0", "at 2"]],
      ["a count of two goes back two", [[3, 5, 7], [-2, 9]], ["1:3:0", "1:5:0", "1:7:0", "1:9:0", "at 1"]],
      ["A new entry on the same line replaces the old one", [[3, 5, 3], []], ["1:5:0", "1:3:0", "at 2"]]
    ]) do |input|
      list = filled(ints(input[0]))
      steps = ints(input[1])
      i = 0
      while i + 1 < steps.length
        list.step(steps[i], 1, steps[i + 1], 0)
        i += 2
      end
      entries(list)
    end

    list = D::JumpList.new
    i = 0
    while i < 105
      list.push(1, i, 0)
      i += 1
    end
    t.assert_equal([100, 5, 104, 100], [list.count, list.rows[0], list.rows[99], list.index], "The list keeps the last hundred entries")

    list = D::JumpList.new
    t.assert_equal([-1, 1], [list.step(-1, 1, 4, 0), list.count], "Ctrl-O past the oldest entry does nothing")
    list = D::JumpList.new
    list.push(1, 2, 0)
    list.push(2, 2, 0)
    list.remove_at(0)
    t.assert_equal(["2:2:0", "at 1"], entries(list), "dropping an entry keeps the index on the same place")

    t.finish
  end
end

DomainJumpListTest.main if __FILE__ == $0
