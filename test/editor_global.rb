require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorGlobalTest
  # The editor over text with the default configuration, the cursor at
  # (row, col).
  def self.editor(text, row, col)
    config = Carat::Doubles::FixedConfig.with("option.number false\noption.relativenumber false\n")
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", text.to_s)
    h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 10, cols: 60, plugins: [])
    h.open("a.txt")
    h.state.cursor.move_to(row.to_i, col.to_i)
    h
  end

  # Keys typed on text from a position: the cursor, the message, and the
  # lines after them. Typed: a table value is untyped (docs/spinel-notes.md).
  def self.run(text, at, keys)
    h = editor(text, at[0], at[1])
    h.type(keys.to_s)
    [h.cursor, h.message, h.lines.join("|")]
  end

  def self.main
    t = Carat::Testing.new("editor_global")

    # Rows are [label, [text, start, keys], [cursor, message, lines]].
    t.table([
      # Marking and running.
      ["a substitute on the matching lines", ["ax\nbx\nax\n", [0, 0], ":g/a/s/x/y/<CR>"], [[2, 0], "", "ay|bx|ay"]],
      ["the long name", ["ax\nbx\n", [1, 0], ":global/a/s/x/y/<CR>"], [[0, 0], "", "ay|bx"]],
      ["a range limits the marked lines", ["ax\nax\nax\n", [0, 0], ":2,3g/a/s/x/y/<CR>"], [[2, 0], "", "ax|ay|ay"]],
      ["a range past the last line", ["a\n", [0, 0], ":5g/a/d<CR>"], [[0, 0], "E16: Invalid range", "a"]],
      ["v runs on the lines that do not match", ["a\nb\na\n", [0, 0], ":v/a/d<CR>"], [[1, 0], "", "a|a"]],
      ["vglobal is v", ["a\nb\n", [0, 0], ":vglobal/a/d<CR>"], [[0, 0], "", "a"]],
      ["g! is v", ["a\nb\na\n", [0, 0], ":g!/a/d<CR>"], [[1, 0], "", "a|a"]],
      ["v takes no bang", ["a\n", [0, 0], ":v!/a/d<CR>"], [[0, 0], "E477: No ! allowed", "a"]],
      # Lines that move.
      ["deleting every matching line", ["a1\na2\nb\na3\n", [0, 0], ":g/a/d<CR>"], [[0, 0], "", "b"]],
      ["a marked line deleted before its turn is not visited", ["a\na\nb\n", [0, 0], ":g/a/2d<CR>"], [[1, 0], "", "a|b"]],
      ["inserted lines are not visited", ["a\nb\n", [0, 0], ":g/a/s/$/\\ra/<CR>"], [[1, 0], "", "a|a|b"]],
      ["inserted lines above move the marks", ["xa\nxa\n", [1, 0], ":g/a/s/x/z\\r/<CR>"], [[3, 0], "", "z|a|z|a"]],
      # The argument.
      ["another delimiter", ["a/b\nc\n", [0, 0], ":g#/#d<CR>"], [[0, 0], "", "c"]],
      ["a blank before the delimiter", ["a\nb\n", [0, 0], ":g /a/d<CR>"], [[0, 0], "", "b"]],
      ["an empty pattern is the last search", ["a\nb\n", [0, 0], "/b<CR>:g//d<CR>"], [[0, 0], "", "a"]],
      ["no previous pattern", ["a\n", [0, 0], ":g//d<CR>"], [[0, 0], "E35: No previous regular expression", "a"]],
      ["no argument", ["a\n", [0, 0], ":g<CR>"], [[0, 0], "E148: Regular expression missing from :global", "a"]],
      ["a letter as delimiter", ["a\n", [0, 0], ":g aad<CR>"], [[0, 0], "E146: Regular expressions can't be delimited by letters", "a"]],
      ["a bad pattern", ["a\n", [0, 0], ":g/\\(a/d<CR>"], [[0, 0], "E54: Unmatched \\(", "a"]],
      ["smartcase keeps an uppercase pattern exact", ["a\nb\n", [0, 0], ":set ic<CR>:g/A/d<CR>"], [[0, 0], "Pattern not found: A", "a|b"]],
      ["ignorecase without smartcase", ["a\nb\n", [0, 0], ":set ic noscs<CR>:g/A/d<CR>"], [[0, 0], "", "b"]],
      # Listing and messages.
      ["without a command the lines are listed", ["a1\nb\n a2\n", [0, 0], ":g/a<CR>"], [[2, 1], "a1\n a2", "a1|b| a2"]],
      ["nothing matches", ["a\n", [0, 0], ":g/z/d<CR>"], [[0, 0], "Pattern not found: z", "a"]],
      ["every line matches", ["a\nab\n", [0, 0], ":v/a/d<CR>"], [[0, 0], "Pattern found in every line: a", "a|ab"]],
      ["a failing command stops it", ["a\na\n", [1, 0], ":g/a/foo<CR>"], [[0, 0], "E492: Not an editor command: foo", "a|a"]],
      ["a failing command stops after the lines before it", ["ax\na\nax\n", [0, 0], ":g/a/s/x/y/<CR>"], [[1, 0], "E486: Pattern not found: x", "ay|a|ax"]],
      ["the last message a command gave", ["aaa\nb\n", [0, 0], ":g/a/s/a/b/g<CR>"], [[0, 0], "3 substitutions on 1 line", "bbb|b"]],
      # Memory, undo, and repeat.
      ["n searches the pattern", ["ab b\n", [0, 0], ":g/b<CR>n"], [[0, 1], "/b", "ab b"]],
      [":s reuses the pattern", ["ab\n", [0, 0], ":g/b<CR>:s//c/<CR>"], [[0, 0], "", "ac"]],
      ["the search history holds it", ["ab b\n", [0, 0], ":g/b<CR>/<Up><CR>"], [[0, 1], "/b", "ab b"]],
      [":& uses it as the last substitute pattern", ["ab\n", [0, 0], ":s/a/x/<CR>:g/b<CR>:&<CR>"], [[0, 0], "", "xx"]],
      ["the search register holds it", ["ab\n", [0, 0], ":g/b<CR>\"/P"], [[0, 0], "", "bab"]],
      ["one undo step", ["a\nb\na\n", [0, 0], ":g/a/d<CR>u"], [[0, 0], "2 more lines; before #1  0 seconds ago", "a|b|a"]],
      ["dot does not repeat it", ["abc\nabc\nabc\n", [0, 0], "x:2g/b/s/b/X/<CR>j."], [[2, 0], "", "bc|aXc|bc"]],
      # A global inside a global.
      ["a nested global acts on the cursor line", ["ab\na\nb\n", [0, 0], ":g/a/g/b/d<CR>"], [[0, 0], "", "a|b"]],
      ["a nested global with a range", ["ab\nc\n", [0, 0], ":g/a/1g/b/d<CR>"], [[0, 0], "E147: Cannot do :global recursive with a range", "ab|c"]],
      # :d.
      [":d deletes the cursor line", ["a\n b\nc\n", [1, 0], ":d<CR>"], [[1, 0], "", "a|c"]],
      [":d leaves the cursor on the first non-blank", ["a\nb\n  c\n", [1, 0], ":d<CR>"], [[1, 2], "", "a|  c"]],
      [":d of the last lines", ["a\nb\nc\n", [1, 0], ":2,3d<CR>"], [[0, 0], "", "a"]],
      [":d with a count", ["a\nb\nc\nd\n", [0, 0], ":2d 2<CR>"], [[1, 0], "", "a|d"]],
      [":d with a count past the end", ["a\nb\nc\n", [0, 0], ":2d 9<CR>"], [[0, 0], "", "a"]],
      [":d into a register", ["a\nb\nc\n", [0, 0], ":1,2delete x<CR>\"xp"], [[1, 0], "", "c|a|b"]],
      [":d into the unnamed register", ["a\nb\n", [0, 0], ":d<CR>p"], [[1, 0], "", "b|a"]],
      [":d shifts the numbered registers", ["a\nb\nc\n", [0, 0], ":d<CR>:d<CR>\"2p"], [[1, 0], "", "c|a"]],
      [":d into the black hole", ["a\nb\n", [0, 0], "yy:2d _<CR>p"], [[1, 0], "", "a|a"]],
      [":d of a read-only register", ["a\n", [0, 0], ":d /<CR>"], [[0, 0], "E488: Trailing characters: /", "a"]],
      [":d with a zero count", ["a\n", [0, 0], ":d 0<CR>"], [[0, 0], "E939: Positive count required", "a"]],
      [":d takes no bang", ["a\n", [0, 0], ":d!<CR>"], [[0, 0], "E477: No ! allowed", "a"]],
      [":d of the only line", ["a\n", [0, 0], ":d<CR>"], [[0, 0], "", ""]],
      [":d is one undo step", ["a\nb\nc\n", [0, 0], ":%d<CR>u"], [[0, 0], "3 more lines; before #1  0 seconds ago", "a|b|c"]]
    ]) do |input|
      run(input[0], input[1], input[2])
    end

    # A pattern the budget cannot pay for on a long line marks nothing and
    # runs nothing.
    h = editor("#{"a" * 250_000}\nb\n", 0, 0)
    h.type(":g/a\\{1900}b/d<CR>")
    t.assert_equal(["E363: search stopped, pattern too costly here", 2], [h.message, h.lines.length], "a global whose scan runs out of budget changes nothing")

    # A command that leaves the buffer stops the global: one tab page
    # opened, not one per marked line.
    h = editor("a\na\na\n", 0, 0)
    h.type(":g/a/tabnew<CR>")
    t.assert_equal(2, h.state.tabs.tab_count, "a command that leaves the buffer stops the global")

    t.finish
  end
end

EditorGlobalTest.main if __FILE__ == $0
