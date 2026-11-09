require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorSlotsTest
  # A typed helper: a table value is untyped, and an untyped argument
  # widens the library method it reaches for every test (docs/spinel-notes.md).
  def self.length_of(text)
    text.to_s.length
  end

  def self.main
    t = Carat::Testing.new("editor_slots")

    # Rows are [label, input, expected]. TODO: the rows of the behavior
    # under test; then make snapshots and review the diff.
    t.table([
      ["an empty line has no characters", "", 0],
      ["a word counts its characters", "abc", 3]
    ]) do |text|
      length_of(text)
    end

    t.finish
  end
end

EditorSlotsTest.main if __FILE__ == $0
