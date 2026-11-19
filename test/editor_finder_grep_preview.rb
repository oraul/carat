require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one). The grep picker's
# preview float: its window of lines, its marked line, and its follow.
module EditorFinderGrepPreviewTest
  ROOT = "/p"

  # The guide and one file t.txt of total lines, "line K" for each K but
  # the one at, which reads "needle K".
  def self.numbered_files(total, at)
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("docs/guide.md", "guide\n")
    text = +""
    i = 1
    while i <= total
      text << (i == at ? "needle #{i}\n" : "line #{i}\n")
      i += 1
    end
    files.put("t.txt", text)
    files
  end

  # The preview float of numbered_files: lines first to last, the one at
  # marked, under the title t.txt.
  def self.expected_preview(first, last, at)
    out = []
    i = first
    while i <= last
      out << (i == at ? "> needle #{i}" : "  line #{i}")
      i += 1
    end
    "t.txt|" + out.join("\n")
  end

  # Two files, a.txt and b.txt, each with a needle line between two others.
  def self.two_files
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("docs/guide.md", "guide\n")
    files.put("a.txt", "a top\nneedle one\na bottom\n")
    files.put("b.txt", "b top\nneedle two\nb bottom\n")
    files
  end

  # A file with empty lines around its hit, one with hostile text, one with
  # a line over the cut, and one whose name holds a control byte.
  def self.hostile_files
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(ROOT)
    files.put("docs/guide.md", "guide\n")
    files.put("gap.txt", "a\n\ngapword\n\nb\n\n\n")
    files.put("ctrl.txt", "x \e[31mred\a y\nctrlword \xFF\xFE\nz" + "‮" + "z\n")
    files.put("long.txt", "longword " + "q" * 500 + "\n")
    files.put("tab\there.txt", "namedword\n")
    files
  end

  def self.editor_on(files, cols)
    h = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with(""), rows: 24, cols: cols, plugins: [Carat::Plugins::Finder::Plugin.new])
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

  # The second float of the list, or "" when there is not exactly two.
  def self.second_float(all)
    all.length == 2 ? all[1].to_s : ""
  end

  # The second float's text after the keys, or "" when there is none.
  def self.preview_text(files, keys, cols)
    h = editor_on(files, cols)
    h.type(keys.to_s)
    second_float(floats(h))
  end

  def self.main
    t = Carat::Testing.new("editor_finder_grep_preview")

    # Rows are [label, [total lines, the needle's line, columns], the preview float].
    t.cases([
      # Scenario: A wide screen previews the matched line
      ["120 columns show the preview, the needle centred among 18 lines, marked", [40, 20, 120], [expected_preview(11, 28, 20)]],
      # Scenario: The preview is centred on the matched line
      ["the needle is the tenth of the 18 lines", [100, 50, 120], [expected_preview(41, 58, 50)]],
      # Scenario: The preview is clamped at the file's start and end
      ["near the top the window starts at line 1", [40, 3, 120], [expected_preview(1, 18, 3)]],
      ["on the first line the window starts at line 1", [40, 1, 120], [expected_preview(1, 18, 1)]],
      ["near the bottom the window ends at the last line", [40, 38, 120], [expected_preview(23, 40, 38)]],
      ["on the last line the window ends at it", [40, 40, 120], [expected_preview(23, 40, 40)]],
      ["a file shorter than the window shows whole", [5, 3, 120], [expected_preview(1, 5, 3)]],
      ["a file of one line shows it", [1, 1, 120], [expected_preview(1, 1, 1)]],
      ["a file past the 1000 stored lines ends at the last stored line", [1200, 995, 120], [expected_preview(983, 1000, 995)]],
      # Scenario: A narrow screen shows no grep preview
      ["99 columns show no preview", [40, 20, 99], [""]],
      ["100 columns show the preview", [40, 20, 100], [expected_preview(11, 28, 20)]]
    ]) do |input|
      [preview_text(numbered_files(input[0].to_i, input[1].to_i), "<Space>fgneedle", input[2].to_i)]
    end

    # Rows are [label, keys, the preview float].
    t.table([
      # Scenario: The preview follows the highlight and the query
      ["the preview shows the first row's file", "<Space>fgneedle", "a.txt|  a top\n> needle one\n  a bottom"],
      ["the preview follows a move", "<Space>fgneedle<C-n>", "b.txt|  b top\n> needle two\n  b bottom"],
      ["a move past the last row keeps the last preview", "<Space>fgneedle<C-n><C-n>", "b.txt|  b top\n> needle two\n  b bottom"],
      ["the preview returns with a move back", "<Space>fgneedle<C-n><C-p>", "a.txt|  a top\n> needle one\n  a bottom"],
      ["the preview follows a query that changes the first row", "<Space>fgneedle two", "b.txt|  b top\n> needle two\n  b bottom"],
      ["the preview follows a backspace", "<Space>fgneedle two<BS><BS><BS><BS>", "a.txt|  a top\n> needle one\n  a bottom"],
      # Scenario: An empty result shows no preview
      ["a query with no match closes the preview", "<Space>fgneedle zzz", ""],
      ["an empty query shows no preview", "<Space>fg", ""],
      ["a query cleared again shows no preview", "<Space>fgneedle<BS><BS><BS><BS><BS><BS>", ""]
    ]) do |keys|
      preview_text(two_files, keys, 120)
    end

    # Scenario: The preview is built from the stored text
    # The disk changes after the picker opened: the move still previews the
    # stored lines, so no file is read per move.
    files = two_files
    h = editor_on(files, 120)
    h.type("<Space>fgneedle")
    files.put("b.txt", "other top\nneedle other\nother bottom\n")
    h.type("<C-n>")
    t.assert_equal("b.txt|  b top\n> needle two\n  b bottom", second_float(floats(h)), "a file changed after the open still previews its stored lines")

    # Rows are [label, keys, the preview float].
    t.table([
      # Scenario: The preview shows its text safely
      ["empty lines the store skipped show as empty lines", "<Space>fggapword", "gap.txt|  a\n\n> gapword\n\n  b"],
      ["control bytes, invalid UTF-8, and a bidirectional override show safely", "<Space>fgctrlword", "ctrl.txt|  x  [31mred  y\n> ctrlword ??\n  z z"],
      ["a line over 400 bytes shows cut", "<Space>fglongword", "long.txt|> longword " + "q" * 391],
      ["a path with a control byte shows it as a space in the title", "<Space>fgnamedword", "tab here.txt|> namedword"]
    ]) do |keys|
      preview_text(hostile_files, keys, 120)
    end

    # Scenario: The grep list is sized as the file finder's list
    h = editor_on(hostile_files, 120)
    h.type("<Space>fggapword")
    g = editor_on(hostile_files, 120)
    g.type("<Space>ff")
    t.assert_equal(g.state.tab.floats.at(0).spec.width.to_i, h.state.tab.floats.at(0).spec.width.to_i, "the grep list is as wide as the file finder's list")
    t.assert_equal(g.state.tab.floats.at(1).spec.width.to_i, h.state.tab.floats.at(1).spec.width.to_i, "the grep preview is as wide as the file finder's preview")
    t.assert_equal(g.state.tab.floats.at(1).spec.col.to_i, h.state.tab.floats.at(1).spec.col.to_i, "the grep preview starts where the file finder's does")
    h.type("<Esc>")
    t.assert_equal(0, h.state.tab.floats.count, "Esc closes the list and the preview")
    t.finish
  end
end

EditorFinderGrepPreviewTest.main if __FILE__ == $0
