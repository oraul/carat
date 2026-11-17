require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainMarkdownTextTest
  D = Carat::Domain

  # The rows of a document at 40 cells, joined with "|". A typed helper:
  # a table value is untyped, and an untyped argument widens the library
  # method it reaches for every test (docs/spinel-notes.md).
  def self.rows(text)
    texts(text.to_s, "unicode").join("|")
  end

  # The rows of a document in an icon set at 40 cells, through parse and
  # wrap with the documentation caps, as FormatDocs reads them.
  def self.texts(text, set)
    raw = D::MarkdownText::RAW_LIMIT
    limit = D::MarkdownText::ROW_LIMIT
    D::MarkdownText.wrap(D::MarkdownText.parse(text, set, raw, limit, 40), 40, set, limit).texts
  end

  # The rows of a document in the ascii set, joined with "|". A typed
  # helper, as rows is.
  def self.ascii_rows(text)
    texts(text.to_s, "ascii").join("|")
  end

  # The rows of a file read with the reading caps at 80 cells.
  def self.reading(text)
    raw = D::MarkdownText::READING_RAW_LIMIT
    limit = D::MarkdownText::READING_ROW_LIMIT
    D::MarkdownText.wrap(D::MarkdownText.parse(text, "unicode", raw, limit, 80), 80, "unicode", limit).texts
  end

  # The spans of a document wrapped at width cells, each as row:start+
  # length name, joined with spaces. A typed helper, as rows is.
  def self.spans(text, width)
    doc = D::MarkdownText.wrap(D::MarkdownText.parse(text.to_s, "unicode", D::MarkdownText::RAW_LIMIT, D::MarkdownText::ROW_LIMIT, width.to_i), width.to_i, "unicode", D::MarkdownText::ROW_LIMIT)
    quads = doc.spans
    out = []
    i = 0
    while i + 3 < quads.length
      out << "#{quads[i]}:#{quads[i + 1]}+#{quads[i + 2]} #{D::Highlight.name_of(quads[i + 3])}"
      i += 4
    end
    out.join(" ")
  end

  # A three-column table, one column of each alignment.
  TABLE = "| Name | Kind | Size |\n|:-----|:----:|-----:|\n| alpha | file | 12 |\n| be | directory | 3,400 |"
  # The same kind of table, wider than 60 columns.
  WIDE = "| Option | Default | Meaning |\n|:--|:-:|--:|\n| option.icons | unicode | the glyph set the borders, bullets, and bars are drawn from |\n| option.jumptab | keep | where a jump to a file with no tab opens it |"

  # The rows of a document read with the reading caps in an icon set at
  # width cells, joined with newlines, as a reading view shows them. A
  # typed helper, as rows is.
  def self.drawn(text, set, width)
    raw = D::MarkdownText::READING_RAW_LIMIT
    limit = D::MarkdownText::READING_ROW_LIMIT
    cells = width.to_i
    D::MarkdownText.wrap(D::MarkdownText.parse(text.to_s, set.to_s, raw, limit, cells), cells, set.to_s, limit).texts.join("\n")
  end

  # Whether every row of the text, split at newlines, is width
  # characters wide.
  def self.even?(text, width)
    rows = text.split("\n")
    i = 0
    while i < rows.length
      return false unless rows[i].length == width
      i += 1
    end
    !rows.empty?
  end

  def self.main
    t = Carat::Testing.new("domain_markdown_text")

    # Rows are [label, document, rows joined with "|"].
    t.table([
      ["plain text is one row", "Ends the block.", "Ends the block."],
      ["heading markers go", "# Title\n### Part", "Title|Part"],
      ["seven markers are no heading", "####### x", "####### x"],
      ["inline code and strong emphasis go", "Use **`map`** or __each__.", "Use map or each."],
      ["emphasis at word boundaries goes", "*one* and _two_", "one and two"],
      ["a marker inside a word or between spaces stays", "file_name is a * b", "file_name is a * b"],
      ["a link reads as its text", "See [each](#each) now.", "See each now."],
      ["an image reads as its alt text", "![logo](a.png)", "logo"],
      ["brackets that are no link stay", "array[0] and [x] y", "array[0] and [x] y"],
      ["a link without a closing parenthesis stays", "[a](b", "[a](b"],
      ["a backslash escape is its character", "\\*not\\* \\` x", "*not* ` x"],
      ["list markers are bullets", "- one\n* two\n+ three", "• one|• two|• three"],
      ["a nested list keeps its indentation", "- a\n  - b", "• a|  • b"],
      ["indentation is capped at four levels", "                    - deep", "        • deep"],
      ["an ordered item stays", "1. first", "1. first"],
      ["a block quote is a bar per level", "> a\n>> b", "│ a|│ │ b"],
      ["quote nesting is capped at four levels", ">" * 10_000 + "x", "│ │ │ │ x"],
      ["a thematic break is a rule", "a\n\n---\n\nb", "a||────────────────────||b"],
      ["fenced code is indented without its fences", "```ruby\nx = **1**\n```", "  x = **1**"],
      ["tilde fences too", "~~~\ny\n~~~", "  y"],
      ["blank runs read as one, none leads or trails", "\n\na\n\n\n\nb\n\n", "a||b"],
      ["escape sequences and controls go", "\e[31mred\e[0m\e]0;title\a\x01!", "red!"],
      ["an illegal byte reads as U+FFFD", "a\xFFb", "a\u{FFFD}b"],
      ["a long row wraps at its last space", "one two three four five six seven eight nine ten", "one two three four five six seven eight|nine ten"],
      ["a word longer than the width is cut", "x" * 50, "x" * 40 + "|" + "x" * 10],
      ["a code row before a long word is cut on a character, not its indent", "```\n" + "y" * 45 + "\n```", "  " + "y" * 38 + "|" + "y" * 7],
      ["a bullet stays with the long word after it, its text hung under it", "- " + "z" * 45, "• " + "z" * 38 + "|  " + "z" * 7],
      ["a quote bar stays with the long word after it and starts its next row", "> " + "w" * 45, "│ " + "w" * 38 + "|│ " + "w" * 7],
      ["a bullet's text still wraps at a space", "- " + "a" * 30 + " " + "b" * 20, "• " + "a" * 30 + "|  " + "b" * 20],
      ["wide characters wrap by cells", "\u{6F22}" * 25, "\u{6F22}" * 20 + "|" + "\u{6F22}" * 5],
      ["a document reads as plain rows", "# Title\n\nUse **`map`** or [each](#each).\n\n- one\n\n```ruby\nx = 1\n```", "Title||Use map or each.||• one||  x = 1"]
    ]) do |text|
      rows(text)
    end

    # The markers of the ascii set (hover-docs, scenario "Documentation
    # markers under ascii"). Rows are [label, document, rows joined with "|"].
    t.table([
      ["ascii list markers are stars", "- one\n  - two", "* one|  * two"],
      ["an ascii quote is a pipe per level", "> a\n> > b", "| a|| | b"],
      ["an ascii thematic break is a rule of hyphens", "a\n\n***\n\nb", "a||--------------------||b"],
      ["an ascii bullet stays with the long word after it", "- " + "w" * 45, "* " + "w" * 38 + "|  " + "w" * 7],
      ["an ascii quote wraps after its bar, its bar on each row", "> " + "q " * 25, "| " + "q " * 18 + "q|| " + "q " * 5 + "q"]
    ]) do |text|
      ascii_rows(text)
    end
    ascii = texts("# T\n\n- a\n\n> > b\n\n---\n\n```\nc\n```", "ascii").join
    t.assert_equal(true, ascii.bytesize == ascii.length && !ascii.empty?, "an ascii document under the ascii set holds no code point above 127")

    # The spans of the markup. Rows are [label, [document, width], spans].
    t.cases([
      ["a heading", ["## Title", 40], "0:0+5 @markup.heading"],
      ["strong and emphasized runs", ["Use **map** or _each_.", 40], "0:4+3 @markup.strong 0:11+4 @markup.italic"],
      ["a code span", ["Call `x.y` now", 40], "0:5+3 @markup.raw"],
      ["a link's and an image's text", ["See [each](#e) or ![logo](a.png)", 40], "0:4+4 @markup.link.label 0:12+4 @markup.link.label"],
      ["emphasis inside a code span is no run", ["`a *b* c`", 40], "0:0+5 @markup.raw"],
      ["a run left open has no span", ["**open and `shut`", 40], "0:9+4 @markup.raw"],
      ["a heading's run over the heading", ["# Use *map*", 40], "0:0+7 @markup.heading 0:4+3 @markup.italic"],
      ["a bullet's and a quote's runs after their prefix", ["- **a**\n\n> `b`", 40], "0:2+1 @markup.strong 2:2+1 @markup.raw"],
      ["fenced code rows after a gap", ["text\n\n```ruby\nx = 1\n```", 40], "2:2+5 @markup.raw.block"],
      ["a run cut where its row wraps", ["aaaa **bbbb cccc** dd", 10], "0:5+4 @markup.strong 1:0+4 @markup.strong"],
      ["a run cut where a quote wraps, moved past the repeated bar", ["> aaaa **bbbb cccc** dd", 12], "0:7+4 @markup.strong 1:2+4 @markup.strong"],
      ["the runs of a flowed line after the row it joins", ["**a**\nb `c`", 40], "0:0+1 @markup.strong 0:4+1 @markup.raw"],
      ["characters, not bytes", ["\u{6F22}\u{6F22} **x**", 40], "0:3+1 @markup.strong"]
    ]) do |input|
      spans(input[0], input[1])
    end
    doc = D::MarkdownText.parse("```ruby\nx = 1\n```\n\n~~~ rb extra\ny\n~~~\n```\nz\n```", "unicode", D::MarkdownText::RAW_LIMIT, D::MarkdownText::ROW_LIMIT, 40)
    t.assert_equal([4, "ruby", 1, "", 0, "rb", 2, "", 3], [doc.count, doc.syntax(0), doc.block(0), doc.syntax(1), doc.block(1), doc.syntax(2), doc.block(2), doc.syntax(3), doc.block(3)], "a fence's first word is its language, and each fenced block has its number")
    styled = D::MarkdownText.wrap(D::MarkdownText.parse("# T\n\nx", "unicode", D::MarkdownText::RAW_LIMIT, D::MarkdownText::ROW_LIMIT, 40), 40, "unicode", D::MarkdownText::ROW_LIMIT)
    buffer = D::Buffer.new(lines: styled.texts, path: nil, line_ending: "\n")
    buffer.styles = styled.styles
    t.assert_equal([true, [0, 1, D::Highlight::MARKUP_HEADING], 0, false], [buffer.styled?, buffer.style_at(0, buffer.line(0)).tokens, buffer.style_at(2, buffer.line(2)).tokens.length, buffer.style_at(0, "T").equal?(buffer.style_at(0, buffer.line(0)))], "styles gives each row its tokens, kept for the row's own string")

    kept = texts("a\n\n" * 400_000, "unicode")
    t.assert_equal([99, "a"], [kept.length, kept[kept.length - 1].to_s], "a megabyte of short lines keeps at most 100 rows, no blank last")
    t.assert_equal(true, texts("y" * 1_000_000, "unicode").join.bytesize <= D::MarkdownText::RAW_LIMIT, "at most 16,384 bytes are read")
    t.assert_equal(100, texts("x" * 16_000, "unicode").length, "a long line wraps to at most 100 rows")
    t.assert_equal([], texts("", "unicode"), "an empty document has no rows")

    # The reading caps (markdown-reading, scenario "An over-cap document").
    long = reading("a\n\n" * 400_000)
    t.assert_equal([true, "a"], [long.length <= D::MarkdownText::READING_ROW_LIMIT, long[long.length - 1].to_s], "a megabyte of short lines keeps at most 10,000 reading rows")
    t.assert_equal(true, reading("y" * 1_000_000).join.bytesize <= D::MarkdownText::READING_RAW_LIMIT, "at most 262,144 bytes of a file are read")
    t.assert_equal(299, reading("a\n\n" * 150).length, "a file under the caps keeps every row, beyond the docs caps")

    # markdown-reading, scenario "A three-column table at 100 columns".
    at_100 = ["┌" + "─" * 7 + "┬" + "─" * 11 + "┬" + "─" * 7 + "┐",
      "│ Name  │   Kind    │  Size │",
      "├" + "─" * 7 + "┼" + "─" * 11 + "┼" + "─" * 7 + "┤",
      "│ alpha │   file    │    12 │",
      "│ be    │ directory │ 3,400 │",
      "└" + "─" * 7 + "┴" + "─" * 11 + "┴" + "─" * 7 + "┘"].join("\n")
    t.assert_equal(at_100, drawn(TABLE, "unicode", 100), "a three-column table at 100 columns, left, center, and right aligned:\n#{at_100}")

    # markdown-reading, scenario "A three-column table wider than 60 columns".
    at_60 = ["┌" + "─" * 16 + "┬" + "─" * 9 + "┬" + "─" * 31 + "┐",
      "│ Option         │ Default │" + " " * 23 + "Meaning │",
      "├" + "─" * 16 + "┼" + "─" * 9 + "┼" + "─" * 31 + "┤",
      "│ option.icons   │ unicode │    the glyph set the borders, │",
      "│                │         │   bullets, and bars are drawn │",
      "│                │         │" + " " * 26 + "from │",
      "│ option.jumptab │  keep   │   where a jump to a file with │",
      "│                │         │" + " " * 15 + "no tab opens it │",
      "└" + "─" * 16 + "┴" + "─" * 9 + "┴" + "─" * 31 + "┘"].join("\n")
    wide = drawn(WIDE, "unicode", 60)
    t.assert_equal([at_60, true], [wide, even?(wide, 60)], "a three-column table wider than 60 columns wraps its widest column, every row 60 wide:\n#{at_60}")

    # markdown-reading, scenario "A table under ascii".
    plain = ["+-------+-----------+-------+",
      "| Name  |   Kind    |  Size |",
      "+-------+-----------+-------+",
      "| alpha |   file    |    12 |",
      "| be    | directory | 3,400 |",
      "+-------+-----------+-------+"].join("\n")
    t.assert_equal([plain, true], [drawn(TABLE, "ascii", 100), drawn(WIDE, "ascii", 60).bytesize == drawn(WIDE, "ascii", 60).length], "a table under ascii has plain borders and no box character:\n#{plain}")

    # The edges of a table. Rows are [label, [document, width], rows joined with newlines].
    t.cases([
      ["a separator of another cell count makes no table, its line flowing as text", ["a | b\n|---|", 40], "a | b |---|"],
      ["a measure too narrow for two cells a column keeps the source", ["| a | b | c |\n|---|---|---|", 15], "| a | b | c |||---|---|---|"],
      # markdown-reading-c, requirement "The reading view flows paragraphs
      # and quotes to the measure": a table the width cannot draw ends
      # the flow, each of its lines its own row.
      ["a measure too narrow keeps each table line its own row, unflowed", ["| a | b | c |\n|---|---|---|\n| alpha | bc |\ntext", 15], "| a | b | c |||---|---|---||| alpha | bc ||text"],
      ["a short row is padded, a long one cut, markup and escapes read out", ["a | b\n---|---\n**x** |\n`y` | z \\| w | extra", 40], "┌────┬───────┐|│ a  │ b     │|├────┼───────┤|│ x  │       │|│ y  │ z | w │|└────┴───────┘"],
      ["text right after a table is its own row", ["| a |\n| - |\n| b |\nafter", 40], "┌────┐|│ a  │|├────┤|│ b  │|└────┘|after"],
      ["a table after text is parted by a blank row", ["before\n\n| a |\n|:-:|", 40], "before||┌────┐|│ a  │|└────┘"],
      ["a pipe inside fenced code is code", ["```\n| a |\n|---|\n```", 40], "  | a ||  |---|"]
    ]) do |input|
      drawn(input[0], "unicode", input[1]).split("\n").join("|")
    end

    # A table ends where another block starts (markdown-reading-c,
    # scenario "A heading with a pipe right after a table"). Rows are
    # [label, document, rows joined with "|"].
    t.table([
      ["a heading with a pipe right after a table is its own row", "| a |\n| - |\n| b |\n# x | y", "┌────┐|│ a  │|├────┤|│ b  │|└────┘|x | y"],
      ["a quote with a pipe right after a table is its own row", "| a |\n| - |\n| b |\n> q | r", "┌────┐|│ a  │|├────┤|│ b  │|└────┘|│ q | r"],
      ["a list item with a pipe right after a table is its own row", "| a |\n| - |\n| b |\n- i | j", "┌────┐|│ a  │|├────┤|│ b  │|└────┘|• i | j"],
      ["a plain line with a pipe right after a table is a table row", "| a |\n| - |\n| b |\nc | d", "┌────┐|│ a  │|├────┤|│ b  │|│ c  │|└────┘"]
    ]) do |text|
      drawn(text, "unicode", 40).split("\n").join("|")
    end
    capped = D::MarkdownText.parse("a\n\n| x |\n|---|\n| y |", "unicode", D::MarkdownText::RAW_LIMIT, 2, 40)
    t.assert_equal(2, capped.count, "a table after a gap at a cap of two rows keeps the parsed rows at the cap")

    # Paragraphs and quotes flow (markdown-reading-c, scenarios "A
    # two-line paragraph at 60 columns" and "A two-line quote at 60
    # columns"). Rows are [label, document, rows at 60 joined with "|"].
    t.table([
      ["a two-line paragraph flows as one row at 60 columns", "The reading view joins\nthe lines of a paragraph.", "The reading view joins the lines of a paragraph."],
      ["a two-line quote flows as one row at 60 columns", "> A quote written\n> on two lines.", "│ A quote written on two lines."],
      ["an indented paragraph flows at its indentation", "  one\n  two", "  one two"],
      # markdown-reading-c, scenario "Two lines indented four spaces".
      ["lines indented four spaces keep their rows as code", "    x = 1\n    y = 2", "    x = 1|    y = 2"],
      ["a line ending in two spaces breaks the flow", "one  \ntwo", "one|two"],
      ["a heading after a paragraph is its own row", "text\n# Head\nmore", "text|Head|more"],
      ["a list item after a paragraph is its own row", "text\n- item\nmore", "text|• item|more"],
      ["ordered items stay apart", "1. one\n2. two", "1. one|2. two"],
      ["a rule after a paragraph is its own row", "text\n***\nmore", "text|────────────────────|more"],
      ["quote lines of another depth stay apart", "> a\n> > b\nc", "│ a|│ │ b|c"],
      ["a bare quote marker parts a quote's paragraphs", "> a\n>\n> b", "│ a|│|│ b"],
      ["code and an empty fence end the flow", "a\n```\nx\n```\nb\nc\n```\n```\nd", "a|  x|b c|d"],
      ["a line after a table does not join the text before it", "text\n| a |\n| - |\n| b |\nafter\nmore", "text|┌────┐|│ a  │|├────┤|│ b  │|└────┘|after more"]
    ]) do |text|
      drawn(text, "unicode", 60).split("\n").join("|")
    end
    # markdown-reading-c, scenario "A flowed quote wider than the measure".
    quote = drawn("> The reading view flows the lines of a block quote\n> into one text, and wraps it at the measure of the\n> window, its bar starting every row.", "unicode", 60).split("\n")
    t.assert_equal([3, true, true], [quote.length, quote.all? { |row| row.start_with?("│ ") }, quote.all? { |row| row.length <= 60 }], "a flowed quote wider than 60 columns keeps its bar on every row:\n#{quote.join("\n")}")

    # markdown-reading, scenario "An over-cap line": the gathering reads
    # a line crossing the cap only up to it, on a character boundary.
    cap = D::MarkdownText::READING_RAW_LIMIT
    huge = D::MarkdownText.gather(["x" * 1_000_000, "after"], cap)
    t.assert_equal([cap, "x"], [huge.bytesize, huge[huge.length - 1].to_s], "a megabyte line is gathered only to the 262,144-byte cap")
    t.assert_equal(["ab\ncd", "ab\ncd", "a\u{E9}"], [D::MarkdownText.gather(["ab", "cd"], 100), D::MarkdownText.gather(["ab", "cdef"], 5), D::MarkdownText.gather(["a\u{E9}\u{E9}"], 4)], "lines under the cap are joined whole, a crossing line cut to the cap on a character boundary")

    t.finish
  end
end

DomainMarkdownTextTest.main if __FILE__ == $0
