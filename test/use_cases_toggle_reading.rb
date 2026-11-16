require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# <leader>dr, the reading view of a Markdown file: the whole editor over
# MemoryFiles, keys typed as a user types them.
module UseCasesToggleReadingTest
  D = Carat::Domain
  NOTES = "# Notes\n\nRead **the** guide.\n\n- one\n- two\n\n> quoted\n> > twice\n\n---\n\n```ruby\nx = 1\n```\n"
  # A three-column table, one column of each alignment, and one wider
  # than 60 columns.
  TABLES = "| Name | Kind | Size |\n|:-----|:----:|-----:|\n| alpha | file | 12 |\n| be | directory | 3,400 |\n\n| Option | Default | Meaning |\n|:--|:-:|--:|\n| option.icons | unicode | the glyph set the borders, bullets, and bars are drawn from |\n| option.jumptab | keep | where a jump to a file with no tab opens it |\n"

  # A 24 by cols editor on path holding text, "main.rb" beside it.
  def self.session(path, text, cols)
    files = Carat::Doubles::MemoryFiles.new
    files.put(path, text)
    files.put("main.rb", "puts 1\n")
    h = Carat::Doubles::EditorHarness.default(files, 24, cols)
    h.open(path)
    h
  end

  # The current buffer's lines joined with "|".
  def self.view(h)
    h.lines.join("|")
  end

  # The path the current window shows, "" for none.
  def self.path(h)
    current = h.buffer.path
    current.nil? ? "" : current
  end

  # Whether the text holds only bytes below 0x80.
  def self.ascii?(text)
    text.bytesize == text.length
  end

  # Whether the text holds an escape byte or another control character.
  def self.controls?(text)
    i = 0
    while i < text.bytesize
      return true if text.getbyte(i).to_i < 0x20 || text.getbyte(i).to_i == 0x7F
      i += 1
    end
    false
  end

  # The widest row of the lines, in characters.
  def self.widest(lines)
    most = 0
    i = 0
    while i < lines.length
      most = lines[i].length if lines[i].length > most
      i += 1
    end
    most
  end

  def self.main
    t = Carat::Testing.new("use_cases_toggle_reading")

    # markdown-reading, scenario "Toggling a Markdown buffer into the reading view".
    h = session("notes.md", NOTES, 80)
    h.type("<Space>dr")
    shown = "Notes||Read the guide.||• one|• two||│ quoted|│ │ twice||────────────────────||  x = 1"
    t.assert_equal(shown, view(h), "the reading view of notes.md reads #{shown}")
    t.assert_equal(["[reading] notes.md", true, ""], [h.buffer.title, h.buffer.scratch?, path(h)], "the view is a scratch buffer titled [reading] notes.md")
    t.assert_equal([0, 5, D::Highlight::MARKUP_HEADING], h.buffer.style_at(0, h.buffer.line(0)).tokens, "the heading row is drawn in @markup.heading")
    t.assert_equal("Notes", h.row(0).strip, "the window draws the view's first row with no line number")

    wide = session("long.md", "word " * 60 + "\n", 120)
    wide.type("<Space>dr")
    t.assert_equal([true, 4], [widest(wide.lines) <= 80, wide.lines.length], "a 120-column window reads at a measure of at most 80 columns")

    # markdown-reading, scenario "Toggling back to the source".
    back = session("notes.md", NOTES, 80)
    back.type("jjll<Space>dr")
    back.type("<Space>dr")
    t.assert_equal(["notes.md", [2, 2], false], [path(back), back.cursor, back.buffer.scratch?], "the toggle again shows notes.md with its cursor where it was")

    # markdown-reading, scenario "Toggling back to the source": a source
    # closed while its view shows is refused and the view stays.
    closed = session("notes.md", NOTES, 80)
    source = closed.buffer.id
    closed.type("<Space>dr")
    closed.type(":bd #{source}<CR>")
    t.assert_equal(nil, closed.assembly.buffers.with_id(source), "the source notes.md left the buffer list")
    closed.type("<Space>dr")
    t.assert_equal(["The Markdown file is closed", "[reading] notes.md", true], [closed.message, closed.buffer.title, closed.buffer.scratch?], "the toggle in a view whose source is closed is refused and the view still shows")

    # markdown-reading, scenario "A buffer that is not Markdown".
    plain = session("main.rb", "puts 1\n", 80)
    plain.type("<Space>dr")
    t.assert_equal(["Not a Markdown buffer", "main.rb"], [plain.message, path(plain)], "a Ruby buffer is refused with Not a Markdown buffer")
    upper = session("README.MARKDOWN", "*hi*\n", 80)
    upper.type("<Space>dr")
    t.assert_equal("hi", view(upper), "a .MARKDOWN path is Markdown in any case")

    # markdown-reading, scenario "The ascii set draws plain characters".
    a = session("notes.md", NOTES, 80)
    a.state.options.icons = "ascii"
    a.type("<Space>dr")
    plain_view = "Notes||Read the guide.||* one|* two||| quoted|| | twice||--------------------||  x = 1"
    t.assert_equal(plain_view, view(a), "under ascii the view reads #{plain_view}")
    t.assert_equal([true, true], [ascii?(view(a)), ascii?(a.screen.join)], "under ascii the view and the whole screen hold no code point above 127, so no box cell")

    # markdown-reading, scenario "Hostile text in a Markdown file".
    hostile = session("evil.md", "# T\e[31mred\e[0m\n\nbell\a here\e]0;title\a\n", 80)
    hostile.type("<Space>dr")
    t.assert_equal([false, "Tred||bell here"], [controls?(hostile.lines.join), view(hostile)], "escape sequences and controls in the file are dropped")

    # markdown-reading, scenario "An over-cap document".
    many = session("many.md", "a\n\n" * 20_000, 80)
    many.type("<Space>dr")
    t.assert_equal(true, many.lines.length <= D::MarkdownText::READING_ROW_LIMIT, "40,000 lines keep at most 10,000 reading rows")
    big = session("big.md", "words " * 200_000 + "\n", 80)
    big.type("<Space>dr")
    t.assert_equal([true, true], [big.lines.join.bytesize <= D::MarkdownText::READING_RAW_LIMIT, big.lines.length <= D::MarkdownText::READING_ROW_LIMIT], "a megabyte line reads at most 262,144 bytes into at most 10,000 rows")

    # markdown-reading, scenario "A three-column table at 100 columns": at
    # a 100-column window the measure is 80, so the narrow table keeps its
    # width and the wide one fills the measure.
    narrow = ["┌" + "─" * 7 + "┬" + "─" * 11 + "┬" + "─" * 7 + "┐",
      "│ Name  │   Kind    │  Size │",
      "├" + "─" * 7 + "┼" + "─" * 11 + "┼" + "─" * 7 + "┤",
      "│ alpha │   file    │    12 │",
      "│ be    │ directory │ 3,400 │",
      "└" + "─" * 7 + "┴" + "─" * 11 + "┴" + "─" * 7 + "┘"]
    hundred = session("tables.md", TABLES, 100)
    hundred.type("<Space>dr")
    rows = hundred.lines
    t.assert_equal([narrow.join("\n"), "", 7, true], [rows[0, 6].join("\n"), rows[6], rows.length - 7, rows[7, 7].all? { |row| row.length == 80 }], "a 100-column window draws the table aligned:\n#{narrow.join("\n")}\nand the wide one at the 80-column measure")

    # markdown-reading, scenario "A three-column table wider than 60 columns".
    at_60 = ["┌" + "─" * 16 + "┬" + "─" * 9 + "┬" + "─" * 31 + "┐",
      "│ Option         │ Default │" + " " * 23 + "Meaning │",
      "├" + "─" * 16 + "┼" + "─" * 9 + "┼" + "─" * 31 + "┤",
      "│ option.icons   │ unicode │    the glyph set the borders, │",
      "│                │         │   bullets, and bars are drawn │",
      "│                │         │" + " " * 26 + "from │",
      "│ option.jumptab │  keep   │   where a jump to a file with │",
      "│                │         │" + " " * 15 + "no tab opens it │",
      "└" + "─" * 16 + "┴" + "─" * 9 + "┴" + "─" * 31 + "┘"]
    sixty = session("tables.md", TABLES, 60)
    sixty.type("<Space>dr")
    t.assert_equal([(narrow + [""] + at_60).join("\n"), 60], [sixty.lines.join("\n"), widest(sixty.lines)], "a 60-column window wraps the wide table's cells within 60 columns:\n#{at_60.join("\n")}")

    # markdown-reading, scenario "A table under ascii".
    boxed = session("tables.md", TABLES, 60)
    boxed.state.options.icons = "ascii"
    boxed.type("<Space>dr")
    t.assert_equal(["+-------+-----------+-------+", true, true], [boxed.lines[0], ascii?(boxed.lines.join), ascii?(boxed.screen.join)], "under ascii the tables' borders are +, -, and |, and the screen holds no box character")

    t.finish
  end
end

UseCasesToggleReadingTest.main if __FILE__ == $0
