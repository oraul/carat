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

  def self.editor_on(files, config)
    fixed = Carat::Doubles::FixedConfig.with(config.to_s)
    h = Carat::Doubles::EditorHarness.new(files: files, config: fixed, rows: 24, cols: 80, plugins: [Carat::Plugins::Finder::Plugin.new])
    h.open("docs/guide.md")
    h
  end

  # Each float of the current tab page as its title, "|", and its lines.
  def self.floats(h)
    layer = h.state.tab.floats
    out = []
    i = 0
    while i < layer.count
      f = layer.at(i)
      out << "#{f.spec.title}|#{f.window.buffer.lines.join("\n")}"
      i += 1
    end
    out
  end

  def self.shown(keys)
    h = editor_on(disk, "")
    h.type(keys.to_s)
    floats(h)
  end

  # The file, the cursor row and column, the window count, the tab count,
  # and the floats left after the keys.
  def self.opened(keys, config)
    h = editor_on(disk, config)
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
      ["Space f g opens the picker: an empty query lists nothing", "<Space>fg", ["Grep 0/10|Type to search the files' lines"]],
      # Scenario: Typing lists the matching lines best first
      ["a match and its rank order: a line starting with the query first, the shorter path first among equals", "<Space>fghello", ["Grep 3/10|> lib/beta.rb:2: hello world\n  lib/ctrl.txt:1: hello  [31mred \n  lib/alpha.rb:2:   puts 'hello'"]],
      ["case is ignored", "<Space>fgHELLO", ["Grep 3/10|> lib/beta.rb:2: hello world\n  lib/ctrl.txt:1: hello  [31mred \n  lib/alpha.rb:2:   puts 'hello'"]],
      ["a query matches by bytes in order, not as a substring", "<Space>fgwrt", ["Grep 1/10|> docs/guide.md:2: Todo: write"]],
      # Scenario: No line matches
      ["no match", "<Space>fgzzz", ["Grep 0/10|No match"]],
      ["a backspace widens the match again", "<Space>fgzzz<BS><BS><BS>", ["Grep 0/10|Type to search the files' lines"]],
      # Scenario: Lines are shown safely
      ["CRLF lines show without the carriage return", "<Space>fga = 1", ["Grep 2/10|> lib/beta.rb:1: a = 1\n  lib/utf.rb:1: café x = 1"]],
      ["a multi-byte line is shown whole", "<Space>fgcaf", ["Grep 1/10|> lib/utf.rb:1: café x = 1"]],
      ["the last line of a file with no final newline is searched", "<Space>fgend", ["Grep 1/10|> lib/alpha.rb:3: end"]],
      ["control bytes show as spaces", "<Space>fgred", ["Grep 1/10|> lib/ctrl.txt:1: hello  [31mred "]],
      ["invalid UTF-8 shows as question marks", "<Space>fgbad", ["Grep 1/10|> lib/ctrl.txt:2: bad ??"]],
      # Scenario: Files that cannot be searched are left out
      ["a binary file, a file over the read limit, an empty file, and an ignored directory add no line", "<Space>fghello", ["Grep 3/10|> lib/beta.rb:2: hello world\n  lib/ctrl.txt:1: hello  [31mred \n  lib/alpha.rb:2:   puts 'hello'"]],
      ["Ctrl-N moves the highlight", "<Space>fghello<C-n>", ["Grep 3/10|  lib/beta.rb:2: hello world\n> lib/ctrl.txt:1: hello  [31mred \n  lib/alpha.rb:2:   puts 'hello'"]]
    ]) do |keys|
      shown(keys)
    end

    # Scenario: The rows are capped and the title says so
    h = editor_on(crowded, "")
    h.type("<Space>fgneedle")
    layer = h.state.tab.floats
    t.assert_equal("Grep 200+/250", layer.at(0).spec.title.to_s, "the row cap: the title counts 200+ of 250")
    h.type("<C-n>" * 205)
    lines = layer.at(0).window.buffer.lines
    t.assert_equal("> many.txt:200: needle 200", lines[lines.length - 1].to_s, "the row cap: 200 rows kept, listing order among equals")
    h.type("<BS>")
    t.assert_equal("Grep 200+/250", layer.at(0).spec.title.to_s, "the cap holds after a key")

    # Rows are [label, keys, config, [file, row, column, windows, tabs, floats]].
    t.cases([
      # Scenario: Picking a row opens the file at its line and column
      ["Enter opens the file at the line", ["<Space>fghello<CR>", ""], ["lib/beta.rb", 1, 0, 1, 1, 0]],
      ["Enter opens at the first matched byte, counted in characters", ["<Space>fgx = 1<CR>", ""], ["lib/utf.rb", 0, 5, 1, 1, 0]],
      ["Enter opens a line past the first", ["<Space>fgwrt<CR>", ""], ["docs/guide.md", 1, 6, 1, 1, 0]],
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

    # The file finder is unchanged beside it.
    h = editor_on(disk, "")
    h.type("<Space>ff")
    t.assert_equal(true, floats(h)[0].to_s.start_with?("Files "), "Space f f still opens the file finder")
    t.finish
  end
end

EditorFinderGrepTest.main if __FILE__ == $0
