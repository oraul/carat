require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorRubyStructureTest
  # The signs of the buffer's rows, "." for a row without one.
  def self.signs(h)
    out = []
    i = 0
    while i < h.buffer.line_count
      sign = h.buffer.sign_at(i)
      out << (sign.empty? ? "." : sign)
      i += 1
    end
    out.join(" ")
  end

  def self.main
    t = Carat::Testing.new("editor_ruby_structure")

    files = Carat::Doubles::MemoryFiles.new
    files.put("a.rb", "def go\n")
    files.put("b.rb", "class A\n  def go\n  end\nend\n")
    files.put("c.txt", "def go\n")
    h = Carat::Doubles::EditorHarness.with_plugins(files, 24, 80, [Carat::Plugins::Ruby::Plugin.new])

    # Scenario "The mark appears on open and follows edits" (ruby-syntax).
    h.open("a.rb")
    t.assert_equal("✖", signs(h), "an unclosed def is marked when the file opens")
    h.type("oend")
    t.assert_equal(["insert", "✖ ."], [h.mode.to_s, signs(h)], "typing in insert mode leaves the sign until the mode ends")
    h.type("<Esc>")
    t.assert_equal(". .", signs(h), "leaving insert mode with the def closed clears the sign")
    h.type("dd")
    t.assert_equal("✖", signs(h), "a change in normal mode marks the def again")
    h.type("u")
    t.assert_equal(". .", signs(h), "and undoing it clears the sign")

    h.open("b.rb")
    t.assert_equal(". . . .", signs(h), "a closed file shows no mark")
    h.type("3Gdd")
    t.assert_equal("✖ . .", signs(h), "deleting an inner end marks the outer opener left open")

    h.open("c.txt")
    t.assert_equal(".", signs(h), "a file that is not Ruby is not checked")

    t.finish
  end
end

EditorRubyStructureTest.main if __FILE__ == $0
