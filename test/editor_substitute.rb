require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorSubstituteTest
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
    t = Carat::Testing.new("editor_substitute")

    # Rows are [label, [text, start, keys], [cursor, message, lines]].
    t.table([
      # Ranges.
      ["no range is the cursor line", ["a\na\na\n", [1, 0], ":s/a/b/<CR>"], [[1, 0], "", "a|b|a"]],
      ["percent is every line", ["a\na\na\n", [0, 0], ":%s/a/b/<CR>"], [[2, 0], "3 substitutions on 3 lines", "b|b|b"]],
      ["two numbers", ["a\na\na\na\n", [0, 0], ":2,3s/a/b/<CR>"], [[2, 0], "", "a|b|b|a"]],
      ["dot to dollar", ["a\na\na\n", [1, 0], ":.,$s/a/b/<CR>"], [[2, 0], "", "a|b|b"]],
      ["the visual marks", ["a\na\na\na\n", [1, 0], "Vj<Esc>gg:'<lt>,'>s/a/b/<CR>"], [[2, 0], "", "a|b|b|a"]],
      ["colon in visual mode starts the range", ["a\na\na\na\n", [1, 0], "Vj:s/a/b/<CR>"], [[2, 0], "", "a|b|b|a"]],
      ["colon in charwise visual mode", ["ab\nab\n", [0, 1], "vj:s/a/x/<CR>"], [[1, 0], "", "xb|xb"]],
      ["past the last line", ["a\na\n", [0, 0], ":5s/a/b/<CR>"], [[0, 0], "E16: Invalid range", "a|a"]],
      ["backwards", ["a\na\na\n", [0, 0], ":3,1s/a/b/<CR>"], [[0, 0], "E493: Backwards range given", "a|a|a"]],
      ["no selection for the marks", ["a\n", [0, 0], ":'<lt>,'>s/a/b/<CR>"], [[0, 0], "E20: Mark not set", "a"]],
      ["arithmetic is not implemented", ["a\na\n", [0, 0], ":.+1s/a/b/<CR>"], [[0, 0], "Not implemented: range .+1", "a|a"]],
      ["a range before a command that takes none", ["a\n", [0, 0], ":1w<CR>"], [[0, 0], "E481: No range allowed", "a"]],
      ["a number moves the cursor", ["a\nbc\nd\n", [0, 1], ":2<CR>"], [[1, 1], "", "a|bc|d"]],
      ["dollar moves to the last line", ["ab\nc\nde\n", [0, 0], ":$<CR>"], [[2, 0], "", "ab|c|de"]],
      ["the end mark alone moves there", ["a\nb\nc\n", [0, 0], "Vj<Esc>gg:'><CR>"], [[1, 0], "", "a|b|c"]],
      # :s.
      ["the first match", ["foo\n", [0, 0], ":s/o/0/<CR>"], [[0, 0], "", "f0o"]],
      ["every match", ["foo\n", [0, 0], ":s/o/0/g<CR>"], [[0, 0], "", "f00"]],
      ["the long name", ["foo\n", [0, 0], ":substitute/o/0/<CR>"], [[0, 0], "", "f0o"]],
      ["another delimiter", ["a/b/c\n", [0, 0], ":s#/#-#g<CR>"], [[0, 0], "", "a-b-c"]],
      ["no closing delimiter deletes", ["abc\n", [0, 0], ":s/b<CR>"], [[0, 0], "", "ac"]],
      ["empty matches", ["abc\n", [0, 0], ":s/x*/-/g<CR>"], [[0, 0], "4 substitutions on 1 line", "-a-b-c-"]],
      ["the cursor goes to the first non-blank", ["  ab\n", [0, 3], ":s/b/c/<CR>"], [[0, 2], "", "  ac"]],
      ["a count from the cursor line", ["a\na\na\n", [0, 0], ":s/a/b/ 2<CR>"], [[1, 0], "", "b|b|a"]],
      ["a count from the range's last line", ["a\na\na\na\n", [0, 0], ":1,2s/a/b/ 2<CR>"], [[2, 0], "", "a|b|b|a"]],
      ["a count past the end stops at the last line", ["a\na\n", [0, 0], ":s/a/b/ 9<CR>"], [[1, 0], "", "b|b"]],
      ["a zero count", ["a\n", [0, 0], ":s/a/b/ 0<CR>"], [[0, 0], "E939: Positive count required", "a"]],
      ["a letter is no delimiter", ["a\n", [0, 0], ":sxaxbx<CR>"], [[0, 0], "E492: Not an editor command: sxaxbx", "a"]],
      ["trailing characters", ["a\n", [0, 0], ":s/a/b/gx<CR>"], [[0, 0], "E488: Trailing characters: x", "a"]],
      ["a bang", ["a\n", [0, 0], ":s!/a/b/<CR>"], [[0, 0], "E477: No ! allowed", "a"]],
      ["not found", ["abc\n", [0, 0], ":s/z/y/<CR>"], [[0, 0], "E486: Pattern not found: z", "abc"]],
      ["a bad pattern", ["abc\n", [0, 0], ":s/\\(a/y/<CR>"], [[0, 0], "E54: Unmatched \\(", "abc"]],
      ["an empty pattern is the last search", ["abc\n", [0, 0], "/b<CR>:s//x/<CR>"], [[0, 0], "", "axc"]],
      ["an empty pattern with no search", ["abc\n", [0, 0], ":s//x/<CR>"], [[0, 0], "E35: No previous regular expression", "abc"]],
      # The string.
      ["the whole match", ["abc\n", [0, 0], ":s/b/[&]/<CR>"], [[0, 0], "", "a[b]c"]],
      ["groups", ["abc\n", [0, 0], ":s/\\(a\\)\\(b\\)/\\2\\1/<CR>"], [[0, 0], "", "bac"]],
      ["case", ["one two\n", [0, 0], ":s/\\w\\+/\\u&/g<CR>"], [[0, 0], "", "One Two"]],
      ["line breaks", ["a,b,c\n", [0, 0], ":s/,/\\r/g<CR>"], [[2, 0], "", "a|b|c"]],
      ["line breaks on several lines", ["a,b\nx\nc,d\n", [0, 0], ":%s/,/\\r/<CR>"], [[4, 0], "", "a|b|x|c|d"]],
      ["the previous string", ["a\nb\n", [0, 0], ":s/a/xy/<CR>j:s/b/~~/<CR>"], [[1, 0], "", "xy|xyxy"]],
      ["tilde in the pattern", ["a\naxy\n", [0, 0], ":s/a/xy/<CR>j:s/~/z/<CR>"], [[1, 0], "", "xy|az"]],
      ["a literal ampersand", ["a\n", [0, 0], ":s/a/\\&/<CR>"], [[0, 0], "", "&"]],
      ["an expression", ["a\n", [0, 0], ":s/a/\\=1/<CR>"], [[0, 0], "Not implemented: \\= in a substitute string", "a"]],
      # Flags.
      ["ignore case", ["abc\n", [0, 0], ":s/A/x/i<CR>"], [[0, 0], "", "xbc"]],
      ["match case over ignorecase", ["Abc\nabc\n", [0, 0], ":set ic<CR>:%s/a/x/I<CR>"], [[1, 0], "", "Abc|xbc"]],
      ["count only", ["aa\na\n", [0, 0], ":%s/a//gn<CR>"], [[0, 0], "3 matches on 2 lines", "aa|a"]],
      ["one match", ["a\n", [0, 0], ":s/a//n<CR>"], [[0, 0], "1 match on 1 line", "a"]],
      ["no error", ["abc\n", [0, 0], ":s/z/y/e<CR>"], [[0, 0], "", "abc"]],
      ["confirm", ["a\n", [0, 0], ":s/a/b/c<CR>"], [[0, 0], "Not implemented: :s flag c", "a"]],
      ["print", ["ab\n", [0, 0], ":s/a/x/p<CR>"], [[0, 0], "xb", "xb"]],
      ["print with the number", ["q\nab\n", [1, 0], ":s/a/x/#<CR>"], [[1, 0], "  2 xb", "q|xb"]],
      ["many substitutions", ["aa\na\n", [0, 0], ":%s/a/b/g<CR>"], [[1, 0], "3 substitutions on 2 lines", "bb|b"]],
      # Repeats.
      ["& repeats on the cursor line", ["a\na\n", [0, 0], ":s/a/b/<CR>j&"], [[1, 0], "", "b|b"]],
      ["& drops the flags", ["aa\naa\n", [0, 0], ":s/a/b/g<CR>j&"], [[1, 0], "", "bb|ba"]],
      ["a count with &", ["a\na\na\na\n", [0, 0], ":s/a/b/<CR>j2&"], [[2, 0], "", "b|b|b|a"]],
      ["a count with & past the end", ["a\na\n", [0, 0], ":s/a/b/<CR>j3&"], [[1, 0], "E16: Invalid range", "b|a"]],
      [":&& keeps the flags", ["aa\naa\n", [0, 0], ":s/a/b/g<CR>j:&&<CR>"], [[1, 0], "", "bb|bb"]],
      [":& with a range", ["a\na\na\n", [0, 0], ":s/a/b/<CR>:%&<CR>"], [[2, 0], "", "b|b|b"]],
      [":s alone repeats", ["a\na\n", [0, 0], ":s/a/b/<CR>j:s<CR>"], [[1, 0], "", "b|b"]],
      [":s with flags repeats", ["aa\naa\n", [0, 0], ":s/a/b/<CR>j:s g<CR>"], [[1, 0], "", "ba|bb"]],
      ["the r flag uses the last search", ["ab\nab\n", [0, 0], ":s/a/x/<CR>/b<CR>j:&r<CR>"], [[1, 0], "", "xb|ax"]],
      ["g& repeats everywhere with the flags", ["aa\naa\naa\n", [0, 0], ":s/a/b/g<CR>g&"], [[2, 0], "4 substitutions on 2 lines", "bb|bb|bb"]],
      ["g& uses the last search", ["ab\nab\n", [0, 0], ":s/a/x/<CR>/b<CR>g&"], [[1, 0], "", "xx|ax"]],
      ["& before any substitute", ["a\n", [0, 0], "&"], [[0, 0], "E33: No previous substitute regular expression", "a"]],
      [":& before any substitute", ["a\n", [0, 0], ":&<CR>"], [[0, 0], "E33: No previous substitute regular expression", "a"]],
      ["g& before any search", ["a\n", [0, 0], "g&"], [[0, 0], "E35: No previous regular expression", "a"]],
      # Undo, repeat, and search.
      ["one undo step", ["a\na\na\n", [0, 0], ":%s/a/b/<CR>u"], [[0, 0], "3 changes; before #1  0 seconds ago", "a|a|a"]],
      ["undo a line break", ["a,b\n", [0, 0], ":s/,/\\r/<CR>u"], [[0, 0], "1 line less; before #1  0 seconds ago", "a,b"]],
      ["dot does not repeat it", ["ab\nab\n", [0, 0], "x:s/b/c/<CR>j."], [[1, 0], "", "c|b"]],
      ["n searches the pattern", ["abc b\n", [0, 0], ":s/b/x/<CR>n"], [[0, 4], "/b", "axc b"]],
      ["the search register holds it", ["ab\n", [0, 0], ":s/b/x/<CR>\"/P"], [[0, 0], "", "bax"]]
    ]) do |input|
      run(input[0], input[1], input[2])
    end

    t.finish
  end
end

EditorSubstituteTest.main if __FILE__ == $0
