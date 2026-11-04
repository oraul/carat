require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorSearchTest
  # The editor over text with the default configuration and an extra
  # configuration line, the cursor at (row, col).
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
    t = Carat::Testing.new("editor_search")

    # Rows are [label, [text, start, keys], [cursor, message, lines]].
    t.table([
      # / and ?.
      ["/ moves to the next match", ["foo bar\nbar\n", [0, 0], "/bar<CR>"], [[0, 4], "/bar", "foo bar|bar"]],
      ["? moves to the previous match", ["foo\nx foo\n", [1, 2], "?foo<CR>"], [[0, 0], "?foo", "foo|x foo"]],
      ["an empty pattern reuses the last one", ["foo\n", [0, 0], "/o<CR>/<CR>"], [[0, 2], "/o", "foo"]],
      ["an empty pattern before any search", ["foo\n", [0, 0], "/<CR>"], [[0, 0], "E35: No previous regular expression", "foo"]],
      ["escape cancels the search", ["ab\n", [0, 0], "/b<Esc>"], [[0, 0], "", "ab"]],
      ["backspace on an empty prompt cancels", ["ab\n", [0, 0], "/b<BS><BS>"], [[0, 0], "", "ab"]],
      ["a search offset is not implemented", ["ab\n", [0, 0], "/b/e<CR>"], [[0, 0], "Not implemented: search offset e", "ab"]],
      ["a slash in a collection is not the delimiter", ["a/b\n", [0, 2], "/[/]<CR>"], [[0, 1], "search hit BOTTOM, continuing at TOP", "a/b"]],
      # n and N.
      ["n repeats forward", ["a a a\n", [0, 0], "/a<CR>n"], [[0, 4], "/a", "a a a"]],
      ["N reverses", ["a a a\n", [0, 0], "/a<CR>nN"], [[0, 2], "?a", "a a a"]],
      ["n after ? goes backward", ["a a a\n", [0, 4], "?a<CR>n"], [[0, 0], "?a", "a a a"]],
      ["n before any search", ["a\n", [0, 0], "n"], [[0, 0], "E35: No previous regular expression", "a"]],
      # Counts.
      ["a count with n", ["a a a a\n", [0, 0], "/a<CR>2n"], [[0, 6], "/a", "a a a a"]],
      ["a count with /", ["a a a a\n", [0, 0], "3/a<CR>"], [[0, 6], "/a", "a a a a"]],
      # Wrapping and failure.
      ["wrap at the bottom", ["a\nb\nx\n", [2, 0], "/a<CR>"], [[0, 0], "search hit BOTTOM, continuing at TOP", "a|b|x"]],
      ["wrap at the top", ["a\nb\nx\n", [0, 0], "?x<CR>"], [[2, 0], "search hit TOP, continuing at BOTTOM", "a|b|x"]],
      ["pattern not found", ["abc\n", [0, 1], "/z<CR>"], [[0, 1], "E486: Pattern not found: z", "abc"]],
      ["a match at the line end rests on the last character", ["ab\ncd\n", [0, 0], "/$<CR>"], [[0, 1], "/$", "ab|cd"]],
      ["n from a line end goes to the next one", ["ab\ncd\n", [0, 0], "/$<CR>n"], [[1, 1], "/$", "ab|cd"]],
      # * # g* g#.
      ["star finds the next whole word", ["foo food foo\n", [0, 1], "*"], [[0, 9], "/\\<foo\\>", "foo food foo"]],
      ["g star finds part of a word", ["foo food foo\n", [0, 1], "g*"], [[0, 4], "/foo", "foo food foo"]],
      ["hash searches backward from the word start", ["foo x foo\n", [0, 7], "#"], [[0, 0], "?\\<foo\\>", "foo x foo"]],
      ["star takes the keyword after the cursor", ["  ab ab\n", [0, 0], "*"], [[0, 5], "/\\<ab\\>", "  ab ab"]],
      ["star on punctuation takes the non-blank text", ["-> ->\n", [0, 0], "*"], [[0, 3], "/->", "-> ->"]],
      ["no string under the cursor", ["   \n", [0, 0], "*"], [[0, 0], "E348: No string under cursor", "   "]],
      ["star then n repeats the word", ["ab x ab x ab\n", [0, 0], "*n"], [[0, 10], "/\\<ab\\>", "ab x ab x ab"]],
      # Search under an operator.
      ["d/ deletes up to the match", ["foo bar\n", [0, 0], "d/bar<CR>"], [[0, 0], "", "bar"]],
      ["dn deletes up to the next match", ["a b a\n", [0, 0], "/a<CR>0dn"], [[0, 0], "", "a"]],
      ["cn changes up to the next match", ["ab x\n", [0, 0], "/x<CR>0cnY<Esc>"], [[0, 0], "", "Yx"]],
      ["d? deletes back to the match", ["foo bar\n", [0, 6], "d?b<CR>"], [[0, 4], "", "foo r"]],
      ["d* deletes to the next word", ["ab x ab\n", [0, 0], "d*"], [[0, 0], "", "ab"]],
      ["the dot repeats with the same pattern", ["x a x a\n", [0, 0], "d/a<CR>w."], [[0, 2], "", "a a"]],
      ["d/ with no match changes nothing", ["abc\n", [0, 0], "d/z<CR>"], [[0, 0], "E486: Pattern not found: z", "abc"]],
      ["d/ escaped changes nothing", ["abc\n", [0, 0], "d/c<Esc>"], [[0, 0], "", "abc"]],
      # Visual mode.
      ["a visual search extends the selection", ["abcd\n", [0, 0], "v/c<CR>d"], [[0, 0], "", "d"]],
      ["visual n extends to the next match", ["a b a b\n", [0, 0], "/b<CR>0vnd"], [[0, 0], "", " a b"]],
      # Patterns.
      ["magic characters", ["a bcccd\n", [0, 0], "/b.\\+d<CR>"], [[0, 2], "/b.\\+d", "a bcccd"]],
      ["an unmatched group", ["a\n", [0, 0], "/\\(a<CR>"], [[0, 0], "E54: Unmatched \\(", "a"]],
      ["a nested multi", ["a\n", [0, 0], "/a**<CR>"], [[0, 0], "E61: Nested *", "a"]],
      ["a back reference", ["aa\n", [0, 0], "/\\(a\\)\\1<CR>"], [[0, 0], "Not implemented: \\1 in a pattern", "aa"]],
      ["an oversized pattern", ["a\n", [0, 0], "/\\(a\\{999}\\)\\{999}<CR>"], [[0, 0], "E363: pattern uses more memory than 'maxmempattern'", "a"]],
      ["a line with an illegal byte", ["a\xFFb\n".dup.force_encoding("UTF-8"), [0, 0], "/b<CR>"], [[0, 2], "/b", "a\xFFb".dup.force_encoding("UTF-8")]],
      # Case.
      ["case matches by default", ["x FOO\n", [0, 0], "/foo<CR>"], [[0, 0], "E486: Pattern not found: foo", "x FOO"]],
      ["ignorecase with smartcase from the configuration", ["x foo\n", [0, 0], ":set ic<CR>/FOO<CR>"], [[0, 0], "E486: Pattern not found: FOO", "x foo"]],
      ["ignorecase without smartcase", ["x foo\n", [0, 0], ":set ic noscs<CR>/FOO<CR>"], [[0, 2], "/FOO", "x foo"]],
      ["backslash c", ["x foo\n", [0, 0], "/\\cFOO<CR>"], [[0, 2], "/\\cFOO", "x foo"]],
      ["star ignores smartcase", ["Ab x ab\n", [0, 0], ":set ic<CR>*"], [[0, 5], "/\\<Ab\\>", "Ab x ab"]]
    ]) do |input|
      run(input[0], input[1], input[2])
    end

    # The "/" register and the history.
    h = editor("ab\n", 0, 0)
    h.type("/b<CR>\"/P")
    t.assert_equal(["abb"], h.lines, "the / register puts the last pattern")
    h.type("\"/dd")
    t.assert_equal("E354: Invalid register name: '/'", h.message, "the / register is read-only")
    h.type(":registers<CR>")
    t.assert_true(h.message.include?("  c  \"/   b"), "registers lists the search register")
    h = editor("a b\n", 0, 0)
    h.type("/a<CR>/b<CR>/<Up>")
    t.assert_equal("b", h.state.cmdline, "up recalls the last pattern")
    h.type("<Up>")
    t.assert_equal("a", h.state.cmdline, "up again recalls the one before")
    h.type("<Down><Down>")
    t.assert_equal("", h.state.cmdline, "down past the newest returns the typed text")
    h.type("<Esc>")
    h = editor("a b\n", 0, 0)
    h.type("/ax<CR>/b<CR>/a<Up>")
    t.assert_equal("ax", h.state.cmdline, "up recalls by prefix")
    h.type("<Esc>*")
    h.type("/<Up>")
    t.assert_equal("\\<b\\>", h.state.cmdline, "star adds its pattern to the history")
    h.type("<Esc>:set ft?<CR>:<Up>")
    t.assert_equal("set ft?", h.state.cmdline, "the command line has its own history")
    h.type("<Esc>")

    # The prompt and incsearch.
    h = editor("a b\nb\n", 0, 0)
    h.type("/")
    t.assert_equal([:cmdline, "/"], [h.mode, h.screen[9].strip], "slash opens the search prompt")
    h.type("b")
    t.assert_equal([0, 2], h.cursor, "incsearch moves the cursor to the first match")
    t.assert_equal(Carat::Domain::Highlight::INC_SEARCH, h.frame.cell(0, 2).hl, "the previewed match is drawn in IncSearch")
    h.type("x")
    t.assert_equal([0, 0], h.cursor, "with no match the cursor goes back")
    h.type("<Esc>")
    t.assert_equal([[0, 0], :normal], [h.cursor, h.mode], "escape puts the cursor back")
    t.assert_equal(Carat::Domain::Highlight::NORMAL, h.frame.cell(0, 2).hl, "and ends the preview")
    h.type(":set nois<CR>/b")
    t.assert_equal([0, 0], h.cursor, "without incsearch the cursor stays while typing")
    h.type("<Esc>")
    h = editor("a x\n", 0, 0)
    h.type("v/x")
    t.assert_equal([0, 2], h.cursor, "a visual search previews too")
    h.type("<Esc>")
    t.assert_equal([:visual, [0, 0]], [h.mode, h.cursor], "escape returns to visual mode")

    # hlsearch and :noh.
    h = editor("a b a\n", 0, 0)
    h.type("/a<CR>")
    sea = Carat::Domain::Highlight::SEARCH
    t.assert_equal([sea, sea], [h.frame.cell(0, 0).hl, h.frame.cell(0, 4).hl], "hlsearch draws every match")
    t.assert_true(h.frame.cell(0, 2).hl != sea, "and nothing else")
    h.type(":noh<CR>")
    t.assert_true(h.frame.cell(0, 4).hl != sea, ":noh hides the highlight")
    h.type("n")
    t.assert_equal(sea, h.frame.cell(0, 4).hl, "n shows it again")
    h.type(":nohlsearch<CR>:set hls<CR>")
    t.assert_equal(sea, h.frame.cell(0, 4).hl, ":set hlsearch shows it again")
    h.type(":set nohls<CR>")
    t.assert_true(h.frame.cell(0, 4).hl != sea, ":set nohlsearch hides it")
    h.type(":set hls?<CR>")
    t.assert_equal("nohlsearch", h.message, ":set hls? shows the option")
    h.type(":set invhls<CR>:set hlsearch?<CR>")
    t.assert_equal("  hlsearch", h.message, "inv switches it")
    h.type(":set hls=1<CR>")
    t.assert_equal("E474: Invalid argument: hls=1", h.message, "a boolean takes no value")

    t.finish
  end
end

EditorSearchTest.main if __FILE__ == $0
