require_relative "../carat/test_support"
require_relative "../carat/testing"

t = Carat::Testing.new("adapters_dirty_rows")

# The rows of each frame marked dirty against the frame drawn before it,
# in a 10-row, 40-column editor: text rows 0 to 7, the status line on row
# 8, the message row 9.
files = Carat::Doubles::MemoryFiles.new
text = +""
i = 0
while i < 30
  text << "line #{i}\n"
  i += 1
end
files.put("a.txt", text)
h = Carat::Doubles::EditorHarness.default(files, 10, 40)
h.open("a.txt")
t.assert_equal([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], h.frame.dirty_rows, "the first frame is dirty everywhere")
h.type("l")
h.type("l")
t.assert_equal([0, 8], h.frame.dirty_rows, "a cursor move along a line dirties its row and the status line")
h.type("j")
t.assert_equal([0, 1, 8], h.frame.dirty_rows, "a cursor move down dirties the row it left, the row it entered, and the status line")
h.type("x")
t.assert_equal([1, 8], h.frame.dirty_rows, "an edit dirties the row it changed and the status line's modified marker")
h.type("dd")
t.assert_equal([1, 2, 3, 4, 5, 6, 7, 8, 9], h.frame.dirty_rows, "deleting a line dirties it, every row that moved up, the status line, and the pending-keys display it clears")
h.state.show("hello", false)
h.wait
t.assert_equal([9], h.frame.dirty_rows, "a message dirties the message row")
h.wait
t.assert_equal([], h.frame.dirty_rows, "a frame with no change has no dirty row")

# Scrolling: the frame records the region and where each row came from.
h.type("gg")
h.type("jjjjj")
h.type("j")
frame = h.frame
t.assert_equal([0, 7, 1], frame.scrolls, "j past the scrolloff records a scroll of the text rows by one")
t.assert_equal([1, 2, 3, 4, 5, 6, 7, -1], frame.sources[0, 8], "each text row comes from the row below it, the last from nowhere")
dirty = frame.dirty_rows
t.assert_true(dirty.include?(7) && dirty.include?(8), "the row that came into view and the status line are dirty")
t.assert_equal(false, dirty.include?(0) || dirty.include?(1) || dirty.include?(6), "rows that only moved are not")
h.type("k")
h.type("k")
h.type("k")
frame = h.frame
t.assert_equal([0, 7, -1], frame.scrolls, "k past the scrolloff records a scroll down by one")
t.assert_equal(-1, frame.sources[0], "the top row came into view")

# A window beside another never scrolls with a region.
h.type(":vsplit<CR>")
h.type("G")
h.type("gg")
h.type("jjjjj")
h.type("j")
t.assert_equal(0, h.frame.scroll_count, "a window narrower than the screen records no scroll")
t.assert_true(h.frame.dirty_rows.include?(0), "its moved rows are dirty instead")

# Relative numbers change every row's number when the cursor row moves.
h = Carat::Doubles::EditorHarness.default(files, 10, 40)
h.open("a.txt")
h.state.options.relativenumber = true
h.type("l")
h.type("j")
t.assert_equal([0, 1, 2, 3, 4, 5, 6, 7, 8], h.frame.dirty_rows, "with relative numbers a cursor row change dirties every text row")
t.assert_equal(["  1 line 0", "  2 line 1", "  1 line 2"], h.screen[0, 3], "and the numbers are redrawn")

t.finish
