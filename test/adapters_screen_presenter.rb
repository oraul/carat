require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("adapters_screen_presenter")
D = Carat::Domain

clock = Carat::Doubles::ManualClock.new
terminal = Carat::Doubles::FakeTerminal.new(clock, 4, 10)
screen = Carat::Adapters::ScreenPresenter.new(terminal)

screen.enter
t.assert_equal(1, terminal.entered, "enter reaches the terminal")
t.assert_equal("\e[?1049h\e[H\e[2J", terminal.last_write, "enter switches to the alternate screen and clears it")

frame = D::Frame.new(3, 6)
frame.put(0, 0, "hello", D::Highlight::NORMAL)
frame.put(1, 0, "two", D::Highlight::LINE_NUMBER)
frame.cursor_row = 1
frame.cursor_col = 2
screen.present(frame)
first = terminal.last_write
t.assert_true(first.include?("\e[2J"), "first frame clears the screen")
t.assert_true(first.include?("\e[1;1H\e[0mhello"), "first frame writes row 1 with the normal highlight")
t.assert_true(first.include?("\e[2;1H\e[0;33mtwo"), "line number highlight is emitted before the text")
t.assert_true(first.include?("\e[3;1H"), "first frame writes every row")
t.assert_true(first.end_with?("\e[2;3H\e[2 q\e[?25h"), "cursor position, block shape, and cursor shown last")
t.assert_true(first.start_with?("\e[?25l"), "cursor hidden while drawing")

same = D::Frame.new(3, 6)
same.put(0, 0, "hello", D::Highlight::NORMAL)
same.put(1, 0, "two", D::Highlight::LINE_NUMBER)
same.cursor_row = 1
same.cursor_col = 2
screen.present(same)
second = terminal.last_write
t.assert_equal(false, second.include?("hello"), "identical frame writes no cell text")
t.assert_equal(false, second.include?("two"), "identical frame writes no second row")
t.assert_true(second.include?("\e[2;3H"), "identical frame still positions the cursor")
t.assert_equal(false, second.include?(" q"), "unchanged shape is not repeated")

changed = D::Frame.new(3, 6)
changed.put(0, 0, "hello", D::Highlight::NORMAL)
changed.put(1, 0, "two", D::Highlight::LINE_NUMBER)
changed.put(2, 0, "three", D::Highlight::STATUS)
changed.cursor_row = 1
changed.cursor_col = 2
changed.cursor_shape = :bar
screen.present(changed)
third = terminal.last_write
t.assert_true(third.include?("\e[3;1H\e[0;7mthree"), "changed row is written with its highlight")
t.assert_equal(false, third.include?("hello"), "unchanged row is not written")
t.assert_true(third.include?("\e[6 q"), "bar shape is emitted when it changes")

resized = D::Frame.new(2, 6)
resized.put(0, 0, "hello", D::Highlight::NORMAL)
screen.present(resized)
fourth = terminal.last_write
t.assert_true(fourth.include?("\e[2J"), "a size change clears the screen")
t.assert_true(fourth.include?("hello"), "a size change repaints every row")

wide = D::Frame.new(1, 4)
wide.put(0, 0, "日x", D::Highlight::NORMAL)
screen.present(wide)
t.assert_true(terminal.last_write.include?("日x "), "a wide character is written once and its continuation cell skipped")

# A frame drawn from a line with C1 controls reaches the terminal as markers:
# the only control byte in the output is the escape that starts the
# presenter's own sequences.
def only_escapes?(bytes)
  clean = true
  bytes.each_codepoint do |code|
    clean = false if code != 27 && Carat::Domain::DisplayWidth.control?(code)
  end
  clean
end

buffer = D::Buffer.new(["a\u009Bb\u009Dc"], "a.txt", "\n")
options = D::Options.new
options.number = false
state = D::EditorState.new(buffer, options, 500)
drawn = Carat::Adapters::FramePresenter.new.call(state, 3, 12)
screen.present(drawn)
bytes = terminal.last_write
t.assert_true(bytes.include?("a<9b>b<9d>c"), "C1 controls are written as markers")
t.assert_true(only_escapes?(bytes), "the output holds no C0 or C1 code point outside the escape sequences")
t.assert_equal(false, bytes.include?("\u009B"), "no raw CSI introducer is written")
t.assert_equal(false, bytes.include?("\u009D"), "no raw OSC introducer is written")

screen.leave
t.assert_equal(1, terminal.left, "leave reaches the terminal")
t.assert_true(terminal.output.end_with?("\e[0m\e[2 q\e[?25h\e[?1049l"), "leave restores the block cursor and the main screen last")
t.assert_true(terminal.output.start_with?("\e[?1049h"), "output begins with the alternate screen")

t.finish
