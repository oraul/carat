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
    # Scenario: The background is painted by default. With no
    # option.background line of its own the configuration paints
    # carat-dark's background: the screen is cleared and the text written
    # after its Normal sequence at the harness's 256 colors.
    painted = Carat::Adapters::SgrTable.sequence(Carat::Domain::Themes.find("carat-dark", "theme"), Carat::Domain::Highlight::NORMAL, Carat::Domain::ColorDepth::COLORS_256)
    t.assert_equal("\e[0;38;5;252;48;5;234m", painted, "carat-dark's painted Normal is its text color on its background")
    t.assert_true(h.terminal.output.include?("  2 #{painted}two"), "first frame carries the gutter and the text on the painted background")
    t.assert_true(h.terminal.output.include?("#{painted}\e[2J"), "the background is painted by default: the screen is cleared after carat-dark's Normal")
    # Scenario: A named background is kept. The terminal's background,
    # named by a line, writes the text after the bare reset.
    plain = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with("option.background terminal\n"), rows: 6, cols: 12, plugins: [])
    plain.open("a.txt")
    t.assert_true(plain.terminal.output.include?("  2 \e[0mtwo"), "a named terminal background is kept: the text follows the bare reset")
    t.assert_equal(false, plain.terminal.output.include?("#{painted}\e[2J"), "a named terminal background is kept: the screen is not cleared on the palette's")
    # Scenario: A named theme is kept. carat-light, named by a line, is
    # painted in place of carat-dark.
    light = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with("option.theme carat-light\n"), rows: 6, cols: 12, plugins: [])
    light.open("a.txt")
    light_normal = Carat::Adapters::SgrTable.sequence(Carat::Domain::Themes.find("carat-light", "theme"), Carat::Domain::Highlight::NORMAL, Carat::Domain::ColorDepth::COLORS_256)
    t.assert_true(light.terminal.output.include?("  2 #{light_normal}two"), "a named theme is kept: carat-light paints the text's background")
    t.assert_true(light.terminal.output.include?("#{light_normal}\e[2J"), "a named theme is kept: the screen is cleared after carat-light's Normal")
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
    t.assert_equal("", h.message_row, "message row stays blank in insert mode")
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
