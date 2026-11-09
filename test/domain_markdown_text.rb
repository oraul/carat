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
    D::MarkdownText.rows(text.to_s, 40).join("|")
  end

  # The spans of a document wrapped at width cells, each as row:start+
  # length name, joined with spaces. A typed helper, as rows is.
  def self.spans(text, width)
    doc = D::MarkdownText.wrap(D::MarkdownText.parse(text.to_s), width.to_i)
    quads = doc.spans
    out = []
    i = 0
    while i + 3 < quads.length
      out << "#{quads[i]}:#{quads[i + 1]}+#{quads[i + 2]} #{D::Highlight.name_of(quads[i + 3])}"
      i += 4
    end
    out.join(" ")
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
      ["a bullet stays with the long word after it", "- " + "z" * 45, "• " + "z" * 38 + "|" + "z" * 7],
      ["a quote bar stays with the long word after it", "> " + "w" * 45, "│ " + "w" * 38 + "|" + "w" * 7],
      ["a bullet's text still wraps at a space", "- " + "a" * 30 + " " + "b" * 20, "• " + "a" * 30 + "|" + "b" * 20],
      ["wide characters wrap by cells", "\u{6F22}" * 25, "\u{6F22}" * 20 + "|" + "\u{6F22}" * 5],
      ["a document reads as plain rows", "# Title\n\nUse **`map`** or [each](#each).\n\n- one\n\n```ruby\nx = 1\n```", "Title||Use map or each.||• one||  x = 1"]
    ]) do |text|
      rows(text)
    end

    # The spans of the markup. Rows are [label, [document, width], spans].
    t.table([
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
      ["characters, not bytes", ["\u{6F22}\u{6F22} **x**", 40], "0:3+1 @markup.strong"]
    ]) do |input|
      spans(input[0], input[1])
    end
    doc = D::MarkdownText.parse("```ruby\nx = 1\n```\n\n~~~ rb extra\ny\n~~~\n```\nz\n```")
    t.assert_equal([4, "ruby", 1, "", 0, "rb", 2, "", 3], [doc.count, doc.syntax(0), doc.block(0), doc.syntax(1), doc.block(1), doc.syntax(2), doc.block(2), doc.syntax(3), doc.block(3)], "a fence's first word is its language, and each fenced block has its number")
    styled = D::MarkdownText.wrap(D::MarkdownText.parse("# T\n\nx"), 40)
    buffer = D::Buffer.new(lines: styled.texts, path: nil, line_ending: "\n")
    buffer.styles = styled.styles
    t.assert_equal([true, [0, 1, D::Highlight::MARKUP_HEADING], 0, false], [buffer.styled?, buffer.style_at(0, buffer.line(0)).tokens, buffer.style_at(2, buffer.line(2)).tokens.length, buffer.style_at(0, "T").equal?(buffer.style_at(0, buffer.line(0)))], "styles gives each row its tokens, kept for the row's own string")

    kept = D::MarkdownText.rows("a\n\n" * 400_000, 40)
    t.assert_equal([99, "a"], [kept.length, kept[kept.length - 1].to_s], "a megabyte of short lines keeps at most 100 rows, no blank last")
    t.assert_equal(true, D::MarkdownText.rows("y" * 1_000_000, 40).join.bytesize <= D::MarkdownText::RAW_LIMIT, "at most 16,384 bytes are read")
    t.assert_equal(100, D::MarkdownText.rows("x" * 16_000, 40).length, "a long line wraps to at most 100 rows")
    t.assert_equal([], D::MarkdownText.rows("", 40), "an empty document has no rows")

    t.finish
  end
end

DomainMarkdownTextTest.main if __FILE__ == $0
