require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainCommandLineTextTest
  C = Carat::Domain::CommandLineText

  # Typed helpers: a table value is untyped, and an untyped argument
  # widens the library method it reaches for every test (docs/spinel-notes.md).
  def self.back(text, at)
    C.word_back(text.to_s, at.to_i)
  end

  def self.forward(text, at)
    C.word_forward(text.to_s, at.to_i)
  end

  def self.removal(text, at)
    C.removal_start(text.to_s, at.to_i)
  end

  def self.main
    t = Carat::Testing.new("domain_command_line_text")

    # Rows are [label, [text, cursor], expected].
    t.cases([
      ["back from the end of a path word", ["e app/models", 12], 2],
      ["back from the start of a word", ["e app", 2], 0],
      ["back skips blanks first", ["e  app  ", 8], 3],
      ["back over a path is one blank-separated word", ["e a/b.rb c", 9], 2],
      ["back at the start stays", ["abc", 0], 0],
      ["back over multi-byte text", ["é 日本", 4], 2],
      ["back over a tab", ["a\tb", 3], 2],
      ["back on an empty text", ["", 0], 0]
    ]) { |input| back(input[0], input[1]) }

    t.cases([
      ["forward from the start of a word", ["e app/models x", 2], 13],
      ["forward skips the rest of the word and the blanks", ["ab   cd", 1], 5],
      ["forward on the last word goes to the end", ["ab cd", 3], 5],
      ["forward at the end stays", ["ab", 2], 2],
      ["forward over wide text", ["日本 語", 0], 3],
      ["forward on an empty text", ["", 0], 0]
    ]) { |input| forward(input[0], input[1]) }

    t.cases([
      ["removal takes a run of word characters", ["e app/models", 12], 6],
      ["removal takes a run of other characters", ["e app/", 6], 5],
      ["removal skips blanks first", ["e app ", 6], 2],
      ["removal stops at a blank", ["e app", 5], 2],
      ["removal on the first word takes it whole", ["app", 3], 0],
      ["removal at the start takes nothing", ["app", 0], 0],
      ["removal over a word with an underscore and digits", ["x foo_1", 7], 2],
      ["removal over multi-byte letters", ["é日本", 3], 0],
      ["removal on blanks only reaches the start", ["   ", 3], 0],
      ["removal on an empty text", ["", 0], 0]
    ]) { |input| removal(input[0], input[1]) }

    t.finish
  end
end

DomainCommandLineTextTest.main if __FILE__ == $0
