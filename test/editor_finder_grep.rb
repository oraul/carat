require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorFinderGrepTest
  ROOT = "/p"

  # /p with the files the grep searches: plain lines, a last line with no
  # newline, CRLF lines, a multi-byte line, an empty file, a line with
  # control bytes and one with invalid UTF-8, a binary file, a file over
  # the read limit, and an ignored directory.
  def self.disk
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("docs/guide.md", "guide\nTodo: write\n")
    files.put("lib/alpha.rb", "def alpha\n  puts 'hello'\nend")
    files.put("lib/beta.rb", "a = 1\r\nhello world\r\n")
    files.put("lib/utf.rb", "café x = 1\n")
    files.put("lib/ctrl.txt", "hello \e[31mred\a\nbad \xFF\xFE\n")
    files.put("empty.rb", "")
    files.put("bin.dat", "he\0llo\n")
    files.put("big.txt", "hello\n" * 50_000)
    files.put(".git/config", "hello\n")
    files
  end

  # Fifty more lines than the row cap, in one file.
  def self.crowded
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    text = +""
    i = 1
    while i <= 250
      text << "needle #{i}\n"
      i += 1
    end
    files.put("many.txt", text)
    files
  end

  # The crowded file and, on a longer path, a file with one hit.
  def self.spread
    files = crowded
    files.put("z/one.txt", "needle here\n")
    files
  end

  # Two files of equal path length, each with three lines of equal rank.
  def self.even
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("docs/guide.md", "guide\n")
    files.put("a.txt", "k 1\nk 2\nk 3\n")
    files.put("b.txt", "k 4\nk 5\nk 6\n")
    files
  end

  # 40 files of 1000 lines holding "ab", then a file with one line
  # holding "abc", past the per-key budget.
  def self.far
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("docs/guide.md", "guide\n")
    i = 0
    while i < 40
      files.put("f#{i}.txt", "ab\n" * 1000)
      i += 1
    end
    files.put("z.txt", "abc\n")
    files
  end

  # One line for each bidirectional embedding, override, isolate, and mark,
  # each zero-width character, and the line and paragraph separators,
  # between its hexadecimal name and a q.
  def self.bidi
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("docs/guide.md", "guide\n")
    files.put("bidi.txt", "p202a\u202Aq\np202b\u202Bq\np202c\u202Cq\np202d\u202Dq\np202e\u202Eq\np2066\u2066q\np2067\u2067q\np2068\u2068q\np2069\u2069q\np061c\u061Cq\np200b\u200Bq\np200c\u200Cq\np200d\u200Dq\np200e\u200Eq\np200f\u200Fq\np2028\u2028q\np2029\u2029q\npfeff\uFEFFq\n")
    files
  end

  # The bounds: a line of continuation bytes, a C1 control, a line with a
  # valid multi-byte character beside an invalid byte, a 500-byte line, a
  # line the 400-byte cut falls inside a character of, and 1200 lines, all
  # read: 1000 that hit and 200 that miss.
  def self.bounded
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("docs/guide.md", "guide\n")
    files.put("u8.txt", "café \xFF\n")
    files.put("bad.txt", "z" + "\x80" * 450 + "\n")
    files.put("c1.txt", "c\u009Bd\n")
    files.put("long.txt", "a" * 500 + "\n")
    files.put("wide.txt", "x" + "é" * 250 + "\n")
    text = +""
    i = 1
    while i <= 1200
      text << (i <= 1000 ? "hit\n" : "miss\n")
      i += 1
    end
    files.put("rows.txt", text)
    files
  end

  # A file of 2000 lines, "line K" for each K but 1500, which reads
  # "needle 1500".
  def self.long_file
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("docs/guide.md", "guide\n")
    text = +""
    i = 1
    while i <= 2000
      text << (i == 1500 ? "needle #{i}\n" : "line #{i}\n")
      i += 1
    end
    files.put("t.txt", text)
    files
  end

  # guide.md and count files of 1000 lines each.
  def self.huge(count)
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("docs/guide.md", "guide\n")
    i = 0
    while i < count
      files.put("f#{i}.txt", "x\n" * 1000)
      i += 1
    end
    files
  end

  # guide.md, seventy files of one 262,144-byte line each, and a last file
  # holding a needle: the bytes read pass READ_BUDGET before the last.
  def self.heavy
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("docs/guide.md", "guide\n")
    i = 0
    while i < 70
      files.put("f#{i < 10 ? "0" : ""}#{i}.txt", "x" * 262_144)
      i += 1
    end
    files.put("z_last.txt", "needle\n")
    files
  end

  # Lines for the term matching: a whole-word hit, a hit after a scattered
  # one, scattered letters only, a prefix that diverges, a hit between
  # underscores, a longer word, two whole-word hits (g.txt), and a part-word
  # line with more hits and a shorter path.
  def self.terms
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("docs/guide.md", "guide\n")
    files.put("a.txt", "explorer open\n")
    files.put("bb.txt", "e x p l o r e r and later Explorer here\n")
    files.put("ccc.txt", "ezzzxpzzzlzzzozzzrzzezrrr\n")
    files.put("dddd.txt", "exploring\n")
    files.put("eeeee.txt", "my_explorer_x\n")
    files.put("ffffff.txt", "unexplorered\n")
    files.put("g.txt", "Explorer Explorer\n")
    files.put("h", "xexplorer explorerx explorerz\n")
    files
  end

  # A line of 300 x's (no whole-word hit, more hits than HIT_ROOM) on a short
  # path, and a single whole-word x on a longer one.
  def self.dense
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("docs/guide.md", "guide\n")
    files.put("a", "x" * 300 + "\n")
    files.put("long/path.txt", "x\n")
    files
  end

  def self.editor_on(files, config, cols = 80)
    fixed = Carat::Doubles::FixedConfig.with(config.to_s)
    h = Carat::Doubles::EditorHarness.new(files: files, config: fixed, rows: 24, cols: cols, plugins: [Carat::Plugins::Finder::Plugin.new])
    h.open("docs/guide.md")
    h
  end

  # Each float of the current tab page as its title, "|", and its lines;
  # the first float, the list, without its query row.
  def self.floats(h)
    layer = h.state.tab.floats
    out = []
    i = 0
    while i < layer.count
      f = layer.at(i)
      lines = f.window.buffer.lines
      lines = lines[1, lines.length - 1].to_a if i == 0
      out << "#{f.spec.title}|#{lines.join("\n")}"
      i += 1
    end
    out
  end

  def self.shown(keys)
    shown_in(disk, keys)
  end

  def self.shown_in(files, keys)
    h = editor_on(files, "")
    h.type(keys.to_s)
    floats(h)
  end

  # The file, the cursor row and column, the window count, the tab count,
  # and the floats left after the keys.
  def self.opened(keys, config)
    opened_in(disk, keys, config)
  end

  def self.opened_in(files, keys, config)
    h = editor_on(files, config)
    h.type(keys.to_s)
    c = h.cursor
    [h.buffer.path.to_s, c[0], c[1], h.windows.length, h.tab_count, h.state.tab.floats.count]
  end

  def self.main
    t = Carat::Testing.new("editor_finder_grep")

    # Rows are [label, keys, floats]. Ten lines are stored: the guide's 2,
    # alpha's 3, beta's 2, utf's 1, ctrl's 2.
    t.table([
      # Scenario: Space f g opens the grep picker
      ["Space f g opens the picker: an empty query lists nothing", "<Space>fg", ["Grep 0 of 0 files, 0 of 10 lines|Type to search the files' lines"]],
      # Scenario: Typing lists the matching lines best first
      ["a match and its rank order: whole-word hits, the shorter path first among equals, then listing order", "<Space>fghello", ["Grep 3 of 3 files, 3 of 10 lines|▎ lib/beta.rb:2: hello world\n  lib/alpha.rb:2:   puts 'hello'\n  lib/ctrl.txt:1: hello  [31mred "]],
      ["case is ignored", "<Space>fgHELLO", ["Grep 3 of 3 files, 3 of 10 lines|▎ lib/beta.rb:2: hello world\n  lib/alpha.rb:2:   puts 'hello'\n  lib/ctrl.txt:1: hello  [31mred "]],
      # Scenario: Scattered letters do not match
      ["scattered letters do not match", "<Space>fgwrt", ["Grep 0 of 0 files, 0 of 10 lines|No match"]],
      ["a substring matches", "<Space>fgwrite", ["Grep 1 of 1 files, 1 of 10 lines|▎ docs/guide.md:2: Todo: write"]],
      # Scenario: A query of only spaces lists nothing
      ["a query of spaces lists nothing", "<Space>fg   ", ["Grep 0 of 0 files, 0 of 10 lines|Type to search the files' lines"]],
      # Scenario: No line matches
      ["no match", "<Space>fgzzz", ["Grep 0 of 0 files, 0 of 10 lines|No match"]],
      ["a backspace widens the match again", "<Space>fgzzz<BS><BS><BS>", ["Grep 0 of 0 files, 0 of 10 lines|Type to search the files' lines"]],
      # Scenario: Lines are shown safely
      ["CRLF lines show without the carriage return", "<Space>fga = 1", ["Grep 2 of 2 files, 2 of 10 lines|▎ lib/beta.rb:1: a = 1\n  lib/utf.rb:1: café x = 1"]],
      ["a multi-byte line is shown whole", "<Space>fgcaf", ["Grep 1 of 1 files, 1 of 10 lines|▎ lib/utf.rb:1: café x = 1"]],
      ["the last line of a file with no final newline is searched", "<Space>fgend", ["Grep 1 of 1 files, 1 of 10 lines|▎ lib/alpha.rb:3: end"]],
      ["control bytes show as spaces", "<Space>fgred", ["Grep 1 of 1 files, 1 of 10 lines|▎ lib/ctrl.txt:1: hello  [31mred "]],
      ["invalid UTF-8 shows as question marks", "<Space>fgbad", ["Grep 1 of 1 files, 1 of 10 lines|▎ lib/ctrl.txt:2: bad ??"]],
      # Scenario: Files that cannot be searched are left out
      ["a binary file, a file over the read limit, an empty file, and an ignored directory add no line", "<Space>fghello", ["Grep 3 of 3 files, 3 of 10 lines|▎ lib/beta.rb:2: hello world\n  lib/alpha.rb:2:   puts 'hello'\n  lib/ctrl.txt:1: hello  [31mred "]],
      ["Ctrl-N moves the highlight", "<Space>fghello<C-n>", ["Grep 3 of 3 files, 3 of 10 lines|  lib/beta.rb:2: hello world\n▎ lib/alpha.rb:2:   puts 'hello'\n  lib/ctrl.txt:1: hello  [31mred "]]
    ]) do |keys|
      shown(keys)
    end

    # Scenario: The rows are capped and the title says so
    h = editor_on(crowded, "")
    h.type("<Space>fgneedle")
    layer = h.state.tab.floats
    t.assert_equal("Grep 1 of 1 files, 250 of 250 lines", layer.at(0).spec.title.to_s, "the row cap: the title counts the 250 matching lines of one file")
    h.type("<C-n>" * 205)
    lines = layer.at(0).window.buffer.lines
    t.assert_equal("▎ many.txt:200: needle 200", lines[lines.length - 1].to_s, "the row cap: 200 rows kept, listing order among equals")
    h.type("<BS>")
    t.assert_equal("Grep 1 of 1 files, 250 of 250 lines", layer.at(0).spec.title.to_s, "the cap holds after a key")

    # Scenario: A file with one hit is listed beside a file with more hits than the row cap
    h = editor_on(spread, "")
    h.type("<Space>fgneedle")
    layer = h.state.tab.floats
    lines = layer.at(0).window.buffer.lines
    t.assert_equal("  z/one.txt:1: needle here", lines[2].to_s, "a file with one hit is the second row, ahead of the 250-hit file's second line")
    # Scenario: The title counts files and lines
    t.assert_equal("Grep 2 of 2 files, 251 of 251 lines", layer.at(0).spec.title.to_s, "the title counts 2 of 2 files and 251 of 251 lines")
    h.type("<C-n>" * 205)
    lines = layer.at(0).window.buffer.lines
    t.assert_equal("▎ many.txt:199: needle 199", lines[lines.length - 1].to_s, "the 200th row is the crowded file's 199th line, the one-hit file kept")

    # Scenario: Lines of equal rank keep their order in each file
    t.assert_equal(["Grep 2 of 2 files, 6 of 7 lines|▎ a.txt:1: k 1\n  b.txt:1: k 4\n  a.txt:2: k 2\n  b.txt:2: k 5\n  a.txt:3: k 3\n  b.txt:3: k 6"], shown_in(even, "<Space>fgk"), "each file's first line, then each second line, then each third, in line order within a file")

    # Scenario: Invisible format and separator characters show as spaces
    # Rows are [label, keys, floats].
    t.table([
      ["U+202A shows as a space", "<Space>fgp202a", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:1: p202a q"]],
      ["U+202B shows as a space", "<Space>fgp202b", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:2: p202b q"]],
      ["U+202C shows as a space", "<Space>fgp202c", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:3: p202c q"]],
      ["U+202D shows as a space", "<Space>fgp202d", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:4: p202d q"]],
      ["U+202E shows as a space", "<Space>fgp202e", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:5: p202e q"]],
      ["U+2066 shows as a space", "<Space>fgp2066", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:6: p2066 q"]],
      ["U+2067 shows as a space", "<Space>fgp2067", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:7: p2067 q"]],
      ["U+2068 shows as a space", "<Space>fgp2068", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:8: p2068 q"]],
      ["U+2069 shows as a space", "<Space>fgp2069", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:9: p2069 q"]],
      ["U+061C shows as a space", "<Space>fgp061c", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:10: p061c q"]],
      ["U+200B shows as a space", "<Space>fgp200b", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:11: p200b q"]],
      ["U+200C shows as a space", "<Space>fgp200c", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:12: p200c q"]],
      ["U+200D shows as a space", "<Space>fgp200d", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:13: p200d q"]],
      ["U+200E shows as a space", "<Space>fgp200e", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:14: p200e q"]],
      ["U+200F shows as a space", "<Space>fgp200f", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:15: p200f q"]],
      ["U+2028 shows as a space", "<Space>fgp2028", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:16: p2028 q"]],
      ["U+2029 shows as a space", "<Space>fgp2029", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:17: p2029 q"]],
      ["U+FEFF shows as a space", "<Space>fgpfeff", ["Grep 1 of 1 files, 1 of 19 lines|▎ bidi.txt:18: pfeff q"]]
    ]) do |keys|
      shown_in(bidi, keys)
    end

    # Rows are [label, keys, config, [file, row, column, windows, tabs, floats]].
    t.cases([
      # Scenario: Picking a row opens the file at its line and column
      ["Enter opens the file at the line", ["<Space>fghello<CR>", ""], ["lib/beta.rb", 1, 0, 1, 1, 0]],
      ["Enter opens at the first matched byte, counted in characters", ["<Space>fgx = 1<CR>", ""], ["lib/utf.rb", 0, 5, 1, 1, 0]],
      ["Enter opens a line past the first", ["<Space>fgwrite<CR>", ""], ["docs/guide.md", 1, 6, 1, 1, 0]],
      ["Enter on no match keeps the prompt", ["<Space>fgzzz<CR>", ""], ["docs/guide.md", 0, 0, 1, 1, 1]],
      ["Esc opens nothing", ["<Space>fghello<Esc>", ""], ["docs/guide.md", 0, 0, 1, 1, 0]],
      # Scenario: The split, vertical split, and tab picks open at the line
      ["Ctrl-X opens a split at the line", ["<Space>fghello<C-x>", ""], ["lib/beta.rb", 1, 0, 2, 1, 0]],
      ["Ctrl-V opens a vertical split at the line", ["<Space>fghello<C-v>", ""], ["lib/beta.rb", 1, 0, 2, 1, 0]],
      ["Ctrl-T opens a tab page at the line", ["<Space>fghello<C-t>", "option.gt tabpages\n"], ["lib/beta.rb", 1, 0, 1, 2, 0]],
      ["Ctrl-T opens a buffer tab at the line", ["<Space>fghello<C-t>", ""], ["lib/beta.rb", 1, 0, 1, 1, 0]]
    ]) do |input|
      opened(input[0], input[1])
    end

    # Scenario: The column is the first byte of the first term's hit
    # Rows are [label, [keys, config], [file, row, column, windows, tabs, floats]].
    t.cases([
      ["a hit after scattered letters opens at the hit, not at the scattered start", ["<Space>fgexplorer<C-n><C-n><CR>", ""], ["bb.txt", 0, 26, 1, 1, 0]],
      ["the first term of two sets the column", ["<Space>fgopen explorer<CR>", ""], ["a.txt", 0, 9, 1, 1, 0]],
      ["the terms swapped set the column of the other", ["<Space>fgexplorer open<CR>", ""], ["a.txt", 0, 0, 1, 1, 0]],
      ["case is ignored in the column", ["<Space>fgEXPLORER<C-n><C-n><CR>", ""], ["bb.txt", 0, 26, 1, 1, 0]]
    ]) do |input|
      opened_in(terms, input[0], input[1])
    end

    # Terms: a line matches when it holds every term as a substring
    # Rows are [label, keys, floats]. Nine lines are stored: the guide's and
    # one in each of the eight files.
    t.table([
      # Scenario: A whole-word hit ranks above a part-word hit
      ["a whole-word hit ranks above a part-word hit with more hits, then more hits, then the shorter path, then listing order; scattered letters and a diverging prefix match nothing", "<Space>fgexplorer", ["Grep 6 of 6 files, 6 of 9 lines|▎ g.txt:1: Explorer Explorer\n  a.txt:1: explorer open\n  bb.txt:1: e x p l o r e r and later Explorer here\n  eeeee.txt:1: my_explorer_x\n  h:1: xexplorer explorerx explorerz\n  ffffff.txt:1: unexplorered"]],
      # Scenario: Case is ignored in the query
      ["case is ignored in the query", "<Space>fgEXPLORER", ["Grep 6 of 6 files, 6 of 9 lines|▎ g.txt:1: Explorer Explorer\n  a.txt:1: explorer open\n  bb.txt:1: e x p l o r e r and later Explorer here\n  eeeee.txt:1: my_explorer_x\n  h:1: xexplorer explorerx explorerz\n  ffffff.txt:1: unexplorered"]],
      # Scenario: Two terms match in any order
      ["two terms match in either order", "<Space>fgopen explorer", ["Grep 1 of 1 files, 1 of 9 lines|▎ a.txt:1: explorer open"]],
      ["the terms swapped match the same line", "<Space>fgexplorer open", ["Grep 1 of 1 files, 1 of 9 lines|▎ a.txt:1: explorer open"]],
      ["extra spaces between and around the terms are ignored", "<Space>fg  open   explorer  ", ["Grep 1 of 1 files, 1 of 9 lines|▎ a.txt:1: explorer open"]],
      ["a line holding one of two terms does not match", "<Space>fgexplorer zzz", ["Grep 0 of 0 files, 0 of 9 lines|No match"]],
      # Scenario: Scattered letters do not match
      ["scattered letters match nothing", "<Space>fgezxplzorzer", ["Grep 0 of 0 files, 0 of 9 lines|No match"]]
    ]) do |keys|
      shown_in(terms, keys)
    end

    # Scenario: A whole-word hit ranks above a part-word hit (the hit count is clamped, so 300 hits stay below one whole word)
    h = editor_on(dense, "")
    h.type("<Space>fgx")
    t.assert_equal("Grep 2 of 2 files, 2 of 3 lines|▎ long/path.txt:1: x\n  a:1: " + "x" * 300, floats(h)[0].to_s, "a line of 300 part-word hits ranks below a whole-word line on a longer path")

    # Scenario: The picker stores only bounded lines of each file (the shown-safely rows of invalid bytes and C1 controls too)
    h = editor_on(bounded, "")
    h.type("<Space>fgcaf")
    t.assert_equal("Grep 1 of 1 files, 1 of 1206 lines|▎ u8.txt:1: café ?", floats(h)[0].to_s, "a valid character beside an invalid byte stays whole")
    h = editor_on(bounded, "")
    h.type("<Space>fgaaaa")
    t.assert_equal("Grep 1 of 1 files, 1 of 1206 lines|▎ long.txt:1: " + "a" * 400, floats(h)[0].to_s, "a 500-byte line is cut at 400 bytes")
    h = editor_on(bounded, "")
    h.type("<Space>fgx")
    t.assert_equal("Grep 1 of 1 files, 1 of 1206 lines|▎ wide.txt:1: x" + "é" * 199, floats(h)[0].to_s, "the cut falls back to a character boundary")
    h = editor_on(bounded, "")
    h.type("<Space>fgz")
    t.assert_equal("Grep 1 of 1 files, 1 of 1206 lines|▎ bad.txt:1: z" + "?" * 399, floats(h)[0].to_s, "a line of continuation bytes is cut at 400 bytes, not emptied")
    h = editor_on(bounded, "")
    h.type("<Space>fgc d")
    t.assert_equal("Grep 1 of 1 files, 1 of 1206 lines|▎ c1.txt:1: c d", floats(h)[0].to_s, "a C1 control (the CSI U+009B) shows as a space, the two terms on either side of it")
    h = editor_on(bounded, "")
    h.type("<Space>fghit")
    t.assert_equal("Grep 1 of 1 files, 1000 of 1206 lines", h.state.tab.floats.at(0).spec.title.to_s, "all 1200 lines of a file are stored, past the 1000th")
    shown = floats(h)[0].to_s
    t.assert_equal(true, shown.start_with?("Grep 1 of 1 files, 1000 of 1206 lines|▎ rows.txt:1: hit"), "the first shown row is the first line of the file")
    h.type("<C-n>" * 250)
    shown = floats(h)[0].to_s
    t.assert_equal(true, shown.end_with?("rows.txt:200: hit"), "the last shown row is the 200th line, the cap")
    h = editor_on(huge(400), "")
    h.type("<Space>fgx")
    t.assert_equal("Grep 30 of 30+ files, 29999+ of 400000+ lines", h.state.tab.floats.at(0).spec.title.to_s, "the 400,000-line store cap is marked when it cuts a file")
    # Scenario: A match past the 1000th line is found
    t.assert_equal(["Grep 1 of 1 files, 1 of 2001 lines|▎ t.txt:1500: needle 1500"], shown_in(long_file, "<Space>fgneedle"), "a match on line 1500 of a 2000-line file is listed")
    t.assert_equal(["t.txt", 1499, 0, 1, 1, 0], opened_in(long_file, "<Space>fgneedle<CR>", ""), "its pick opens the file on line 1500")
    # Scenario: A tree the size of this repository is searched whole, 30,000 lines a key
    # Scenario: A key checks at most 30,000 lines
    h = editor_on(huge(150), "")
    h.type("<Space>fgx")
    t.assert_equal("Grep 30 of 30+ files, 29999+ of 150001 lines", h.state.tab.floats.at(0).spec.title.to_s, "150,001 lines are all stored with no cap mark, and a key checks 30,000 of them, its counts marked")

    # Scenario: The files read are bounded by their bytes
    h = editor_on(heavy, "")
    h.type("<Space>fgneedle")
    t.assert_equal("Grep 0 of 0 files, 0 of 65+ lines|No match", floats(h)[0].to_s, "the read stops once the files read hold 16 MiB, so the last file is never read, and the title marks the store cut")

    # Scenario: An extended query continues the search
    h = editor_on(far, "")
    h.type("<Space>fga")
    t.assert_equal("Grep 30 of 30+ files, 29999+ of 40002 lines", h.state.tab.floats.at(0).spec.title.to_s, "a checks 30,000 lines")
    h.type("b")
    t.assert_equal("Grep 30 of 30+ files, 30000+ of 40002 lines", h.state.tab.floats.at(0).spec.title.to_s, "ab checks the 29,999 matches of a again and one line more, the budget they leave")
    h.type("c")
    t.assert_equal("Grep 1 of 1 files, 1 of 40002 lines|▎ z.txt:1: abc", floats(h)[0].to_s, "abc checks the kept matches again and scans on to the last line")
    # Scenario: A backspace starts the search again
    h.type("<BS>")
    t.assert_equal("Grep 30 of 30+ files, 29999+ of 40002 lines", h.state.tab.floats.at(0).spec.title.to_s, "a backspace starts again from the first line, within the budget")

    # Scenario: The grep list is sized as the file finder's list (test/editor_finder_grep_preview.rb holds the preview rows)
    h = editor_on(disk, "", 120)
    h.type("<Space>fghello")
    t.assert_equal(2, h.state.tab.floats.count, "the preview float shows beside the grep list at 120 columns")
    t.assert_equal(true, h.state.tab.floats.at(0).spec.width.to_i < 60, "the grep list is about half of 120 columns")

    # The file finder is unchanged beside it.
    h = editor_on(disk, "")
    h.type("<Space>ff")
    t.assert_equal(true, floats(h)[0].to_s.start_with?("Files "), "Space f f still opens the file finder")
    t.finish
  end
end

EditorFinderGrepTest.main if __FILE__ == $0
