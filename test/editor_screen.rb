require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorScreenTest
  def self.main
    t = Carat::Testing.new("editor_screen")

    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\ntwo\nthree\n")
    h = Carat::Doubles::EditorHarness.default(files, 6, 12)
    h.open("a.txt")

    t.assert_equal(["  1 one", "  2 two", "  3 three", "~"], h.screen[0, 4], "three lines with numbers and a tilde")
    t.assert_equal(" NORMAL  a.t", h.status_row, "the status bar shows the mode and the file, cut at 12 columns")
    t.assert_equal("\"a.txt\" 3L", h.message_row[0, 10], "message row shows the opened message")
    t.assert_true(h.terminal.output.start_with?("\e[?1049h"), "output begins with the alternate screen")
    t.assert_true(h.terminal.output.include?("\e[1;1H"), "first frame paints row 1")
    t.assert_true(h.terminal.output.include?("  2 \e[0mtwo"), "first frame carries the gutter and the text")
    t.assert_equal(1, h.terminal.entered, "terminal entered once")

    before = h.terminal.writes.length
    h.type("j")
    t.assert_equal(before + 1, h.terminal.writes.length, "one write per frame")
    last = h.terminal.last_write
    t.assert_equal(false, last.include?("  1 one"), "unchanged text row is not rewritten")
    t.assert_true(last.include?("\e[2;5H"), "cursor moved to row 2 after the gutter")
    layer = Carat::Domain::Highlight::CURSOR_LINE_LAYER
    t.assert_equal([false, true], [h.frame.hl_at(0, 4) >= layer, h.frame.hl_at(1, 4) >= layer], "the shipped cursor line moves with the cursor")

    h.type("i")
    t.assert_true(h.terminal.last_write.include?("\e[6 q"), "insert mode switches to the bar cursor")
    t.assert_equal("-- INSERT --", h.message_row, "message row shows insert")
    h.type("<Esc>")
    t.assert_true(h.terminal.last_write.include?("\e[2 q"), "normal mode switches back to the block cursor")

    h.resize(10, 20)
    t.assert_equal(10, h.frame.rows, "frame has 10 rows after resizing")
    t.assert_equal("a.txt", h.row(8)[9, 5], "the status bar moved to row 8")
    t.assert_true(h.terminal.last_write.include?("\e[2J"), "resize repaints in full")
    h.resize(24, 80)
    t.assert_equal("a.txt", h.row(22)[9, 5], "the status bar on row 22 at 24 rows")

    # Scrolling through a long file with the default scrolloff of 5.
    lines = +""
    30.times { |i| lines << "line #{i + 1}\n" }
    files.put("long.txt", lines)
    h = Carat::Doubles::EditorHarness.default(files, 12, 20)
    h.open("long.txt")
    h.type("G")
    t.assert_equal(" 30 line 30", h.row(9), "G shows the last line at the bottom of the window")
    h.resize(12, 40)
    t.assert_equal("Bot", h.status_row[-3, 3], "position is Bot")
    h.type("gg")
    t.assert_equal("  1 line 1", h.row(0), "gg scrolls back to the top")
    t.assert_equal("Top", h.status_row[-3, 3], "position is Top")
    h.resize(12, 20)
    h.type("jjjjjjjj")
    t.assert_equal([8, 0], h.cursor, "cursor on row 8")
    t.assert_equal(" 4 line 4", h.row(0)[1, 9], "window scrolled with scrolloff capped at half the window")

    h.assembly.screen_presenter.leave
    t.assert_true(h.terminal.output.end_with?("\e[?1049l"), "leaving restores the main screen last")
    t.assert_true(h.terminal.output.end_with?("\e[0 q\e[?25h\e[?1049l"), "leaving gives the cursor back the terminal's own shape and shows it")
    t.assert_equal(1, h.terminal.left, "terminal left once")

    t.finish
  end
end

EditorScreenTest.main if __FILE__ == $0
