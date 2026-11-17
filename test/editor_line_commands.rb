require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorLineCommandsTest
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
    h = editor(text, Carat::Json.element(at, 0), Carat::Json.element(at, 1))
    h.type(keys.to_s)
    [h.cursor, h.message, h.lines.join("|")]
  end

  def self.main
    t = Carat::Testing.new("editor_line_commands")

    # Rows are [label, [text, start, keys], [cursor, message, lines]]; the
    # labels name the line-commands scenarios they prove, the cursor is
    # 0-based where the scenarios count from 1.
    t.cases([
      # :m (scenarios: Move a line to the top, Move a range to the end,
      # Move is one undo step, Move each marked line to the top).
      ["Move a line to the top", ["a\nb\nc\n", [0, 0], ":2m0<CR>"], [[0, 0], "", "b|a|c"]],
      ["Move a range to the end", ["a\nb\nc\nd\n", [0, 0], ":1,3m$<CR>"], [[3, 0], "3 lines moved", "d|a|b|c"]],
      ["Move is one undo step", ["a\nb\nc\n", [0, 0], ":2m0<CR>u"], [[0, 0], "1 change; before #1  0 seconds ago", "a|b|c"]],
      ["Move each marked line to the top", ["x1\na\nx2\nb\nx3\n", [0, 0], ":g/x/m0<CR>"], [[0, 0], "", "x3|x2|x1|a|b"]],
      ["the long name moves the cursor line down", ["a\nb\nc\n", [0, 0], ":move 2<CR>"], [[1, 0], "", "b|a|c"]],
      ["a move up keeps the order of the range", ["a\nb\nc\nd\n", [3, 0], ":3,4m1<CR>"], [[2, 0], "", "a|c|d|b"]],
      ["a move keeps the wanted column", ["abc\nd\nefgh\n", [0, 2], ":m$<CR>"], [[2, 2], "", "d|efgh|abc"]],
      ["a move clamps the column to the line and keeps the wanted one", ["abc\nd\ne\n", [0, 2], ":2m0<CR>j"], [[1, 2], "", "d|abc|e"]],
      ["a move of the visual lines", ["a\nb\nc\n", [0, 0], "Vj<Esc>:'<lt>,'>m$<CR>"], [[2, 0], "", "c|a|b"]],
      ["a move just below its range changes nothing", ["a\nb\nc\n", [0, 0], ":1,2m2<CR>"], [[1, 0], "", "a|b|c"]],
      ["a move just above its range changes nothing", ["a\nb\nc\n", [0, 0], ":2,3m1<CR>"], [[2, 0], "", "a|b|c"]],
      # :co and :t (scenarios: Copy the cursor line below itself, Copy the
      # cursor line to the top).
      ["Copy the cursor line below itself", ["a\nb\n", [0, 0], ":t.<CR>"], [[1, 0], "", "a|a|b"]],
      ["Copy the cursor line to the top", ["a\nb\n", [1, 0], ":co0<CR>"], [[0, 0], "", "b|a|b"]],
      ["a copy of a range to the end", ["a\nb\nc\n", [0, 0], ":1,3t$<CR>"], [[5, 0], "3 more lines", "a|b|c|a|b|c"]],
      ["a copy into its own range", ["a\nb\nc\n", [0, 0], ":1,3copy 1<CR>"], [[3, 0], "3 more lines", "a|a|b|c|b|c"]],
      ["a copy is one undo step", ["a\nb\n", [0, 0], ":t$<CR>u"], [[1, 0], "1 line less; before #1  0 seconds ago", "a|b"]],
      ["each marked line copied to the end", ["x1\na\nx2\n", [0, 0], ":g/x/t$<CR>"], [[4, 0], "", "x1|a|x2|x1|x2"]],
      # Refusals (scenarios: A move into its own range, A bad address).
      ["A move into its own range", ["a\nb\nc\n", [0, 0], ":1,3m2<CR>"], [[0, 0], "E134: Cannot move a range of lines into itself", "a|b|c"]],
      ["A bad address past the last line", ["a\nb\n", [0, 0], ":m 9<CR>"], [[0, 0], "E16: Invalid range", "a|b"]],
      ["A bad address that is not one", ["a\nb\n", [0, 0], ":t x<CR>"], [[0, 0], "E16: Invalid range", "a|b"]],
      ["no address", ["a\nb\n", [0, 0], ":m<CR>"], [[0, 0], "E16: Invalid range", "a|b"]],
      ["an offset is not read", ["a\nb\n", [0, 0], ":m+1<CR>"], [[0, 0], "Not implemented: address +1", "a|b"]],
      ["a bad range", ["a\nb\n", [0, 0], ":5m0<CR>"], [[0, 0], "E16: Invalid range", "a|b"]],
      ["move takes no bang", ["a\nb\n", [0, 0], ":m! 2<CR>"], [[0, 0], "E477: No ! allowed", "a|b"]],
      ["copy takes no bang", ["a\nb\n", [0, 0], ":t! 2<CR>"], [[0, 0], "E477: No ! allowed", "a|b"]],
      ["a move into its own range inside a global", ["x\nx\n", [0, 0], ":g/x/.,$m1<CR>"], [[0, 0], "E134: Cannot move a range of lines into itself", "x|x"]],
      # :j (scenarios: Join the cursor line with the next, Join a range,
      # Join with a bang, Join a count, Join on the last line, Join is one
      # undo step).
      ["Join the cursor line with the next", ["a\n  b\nc\n", [0, 0], ":j<CR>"], [[0, 0], "", "a b|c"]],
      ["Join a range", ["a\nb\nc\nd\n", [3, 0], ":1,3j<CR>"], [[0, 0], "", "a b c|d"]],
      ["Join with a bang", ["a\n  b\n", [0, 0], ":j!<CR>"], [[0, 0], "", "a  b"]],
      ["Join a count", ["a\nb\nc\nd\ne\n", [0, 0], ":2j 3<CR>"], [[1, 0], "", "a|b c d|e"]],
      ["Join on the last line", ["a\nb\n", [1, 0], ":j<CR>"], [[1, 0], "", "a|b"]],
      ["Join is one undo step", ["a\nb\nc\n", [0, 0], ":1,3j<CR>u"], [[0, 0], "2 more lines; before #1  0 seconds ago", "a|b|c"]],
      ["the long name joins", ["a\nb\n", [0, 0], ":join<CR>"], [[0, 0], "", "a b"]],
      ["a join to the first non-blank", ["  a\nb\n", [1, 0], ":1j<CR>"], [[0, 2], "", "  a b"]],
      ["a join with a count of one joins two lines", ["a\nb\nc\n", [0, 0], ":j 1<CR>"], [[0, 0], "", "a b|c"]],
      ["one line with two addresses joins nothing", ["a\nb\nc\n", [0, 0], ":2,2j<CR>"], [[1, 0], "", "a|b|c"]],
      ["one address and a count of one joins nothing", ["a\nb\nc\n", [0, 0], ":2j 1<CR>"], [[1, 0], "", "a|b|c"]],
      ["a count past the end stops at the last line", ["a\nb\nc\n", [0, 0], ":2j 9<CR>"], [[1, 0], "", "a|b c"]],
      ["no space before a closing paren or after a blank", ["f(\n)\nx \ny\n", [0, 0], ":1,2j<CR>:2,3j<CR>"], [[1, 0], "", "f()|x y"]],
      ["a join of the visual lines", ["a\nb\nc\n", [0, 0], "Vj<Esc>:'<lt>,'>j<CR>"], [[0, 0], "", "a b|c"]],
      ["a join of every line", ["a\nb\nc\n", [0, 0], ":%j<CR>"], [[0, 0], "", "a b c"]],
      ["each marked line joined with the next", ["x\n1\nx\n2\n", [0, 0], ":g/x/j<CR>"], [[1, 0], "", "x 1|x 2"]],
      # :> and :< (scenarios: Shift the cursor line right, Shift a range
      # twice, Shift left with a count, Shift is one undo step).
      ["Shift the cursor line right", ["a\nb\n", [0, 0], ":><CR>"], [[0, 2], "", "  a|b"]],
      ["Shift a range twice", ["a\nb\nc\n", [0, 0], ":1,3>><CR>"], [[2, 4], "3 lines >ed 2 times", "    a|    b|    c"]],
      ["Shift left with a count", ["    a\n  b\nc\n", [0, 0], ":<lt> 2<CR>"], [[1, 0], "", "  a|b|c"]],
      ["Shift is one undo step", ["a\nb\n", [0, 0], ":1,2><CR>u"], [[0, 0], "2 changes; before #1  0 seconds ago", "a|b"]],
      ["a shift left of three lines once", ["  a\n  b\n  c\n", [0, 0], ":%<lt><CR>"], [[2, 0], "3 lines <ed 1 time", "a|b|c"]],
      ["a shift keeps an empty line empty", ["a\n\nb\n", [0, 0], ":1,3><CR>"], [[2, 2], "3 lines >ed 1 time", "  a||  b"]],
      ["a shift left stops at column 0", [" a\n", [0, 0], ":<lt><lt><CR>"], [[0, 0], "", "a"]],
      ["a shift with blanks between the characters", ["a\n", [0, 0], ":> ><CR>"], [[0, 4], "", "    a"]],
      ["a shift count from the range's last line", ["a\nb\nc\nd\n", [0, 0], ":2> 2<CR>"], [[2, 2], "", "a|  b|  c|d"]],
      ["a shift of the visual lines", ["a\nb\nc\n", [0, 0], "Vj<Esc>:'<lt>,'>><CR>"], [[1, 2], "", "  a|  b|c"]],
      # Refusals (scenarios: A zero count for join, Text after the shift,
      # A bang on a shift).
      ["A zero count for join", ["a\nb\n", [0, 0], ":j 0<CR>"], [[0, 0], "E939: Positive count required", "a|b"]],
      ["Text after the shift", ["a\nb\n", [0, 0], ":> x<CR>"], [[0, 0], "E488: Trailing characters: x", "a|b"]],
      ["A bang on a shift", ["a\nb\n", [0, 0], ":>!<CR>"], [[0, 0], "E477: No ! allowed", "a|b"]],
      ["a register is no count for join", ["a\nb\n", [0, 0], ":j a<CR>"], [[0, 0], "E488: Trailing characters: a", "a|b"]],
      ["the other shift character is trailing text", ["a\nb\n", [0, 0], ":<lt>><CR>"], [[0, 0], "E488: Trailing characters: >", "a|b"]],
      ["a bad range for join", ["a\nb\n", [0, 0], ":5j<CR>"], [[0, 0], "E16: Invalid range", "a|b"]]
    ]) do |input|
      run(input[0], input[1], input[2])
    end

    t.finish
  end
end

EditorLineCommandsTest.main if __FILE__ == $0
