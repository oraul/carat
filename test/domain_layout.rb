require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("domain_layout")
D = Carat::Domain

def buffer_named(name)
  Carat::Domain::Buffer.new(["a", "b", "c"], name, "\n")
end

# A layout of one window arranged in rows by cols.
def layout_in(rows, cols)
  layout = Carat::Domain::Layout.new(Carat::Domain::Window.new(buffer_named("a.txt")))
  layout.arrange(0, 0, rows, cols)
  layout
end

# Every leaf's rectangle in layout order: [row, col, text rows, columns].
def rects(layout)
  out = []
  ids = layout.leaves
  i = 0
  while i < ids.length
    w = layout.window_at(ids[i])
    out << [w.row, w.col, w.height, w.width]
    i += 1
  end
  out
end

MIN = 5 # one text column plus the default gutter

# One window.
l = layout_in(23, 80)
t.assert_equal([[0, 0, 22, 80]], rects(l), "one window takes the area minus its status line")
t.assert_equal([0], l.leaves, "the root leaf has id 0")
t.assert_equal(1, l.number_of(0), "the only window is number 1")
t.assert_equal(-1, l.close(0), "the last window cannot be closed")

# Horizontal split: the new window goes above with half the text rows.
l = layout_in(23, 80)
top = l.split(0, false, 0, MIN)
t.assert_equal(2, top, "the new leaf takes the next slot after the inner node")
l.arrange(0, 0, 23, 80)
t.assert_equal([top, 0], l.leaves, "the new window comes first in layout order")
t.assert_equal([[0, 0, 11, 80], [12, 0, 10, 80]], rects(l), "11 text rows above, 10 below, a status line each")
t.assert_equal([1, 2], [l.number_of(top), l.number_of(0)], "windows are numbered in layout order")
t.assert_equal(0, l.leaf_number(9), "a number past the last window gives the last window")
t.assert_true(l.window_at(top).buffer.equal?(l.window_at(0).buffer), "both windows show the same buffer")

# Horizontal split with a count.
l = layout_in(23, 80)
top = l.split(0, false, 5, MIN)
l.arrange(0, 0, 23, 80)
t.assert_equal([[0, 0, 5, 80], [6, 0, 16, 80]], rects(l), "a count sets the new window's text rows")
l = layout_in(23, 80)
l.split(0, false, 50, MIN)
l.arrange(0, 0, 23, 80)
t.assert_equal([[0, 0, 20, 80], [21, 0, 1, 80]], rects(l), "a large count leaves the old window one text row")

# E36.
l = layout_in(3, 80)
t.assert_equal(-1, l.split(0, false, 0, MIN), "two text rows cannot be split horizontally")
t.assert_equal([0], l.leaves, "nothing changed")
l = layout_in(4, 80)
t.assert_true(l.split(0, false, 0, MIN) >= 0, "three text rows can be split")
l = layout_in(23, 9)
t.assert_equal(-1, l.split(0, true, 0, MIN), "nine columns cannot hold two gutters, two text columns, and a separator")
l = layout_in(23, 11)
t.assert_true(l.split(0, true, 0, MIN) >= 0, "eleven columns can")

# Vertical split: the new window goes left with half the columns.
l = layout_in(23, 80)
left = l.split(0, true, 0, MIN)
l.arrange(0, 0, 23, 80)
t.assert_equal([[0, 0, 22, 40], [0, 41, 22, 39]], rects(l), "40 columns left, a separator, 39 right")
l = layout_in(23, 80)
l.split(0, true, 30, MIN)
l.arrange(0, 0, 23, 80)
t.assert_equal([[0, 0, 22, 30], [0, 31, 22, 49]], rects(l), "a count sets the new window's columns")
l = layout_in(23, 80)
l.split(0, true, 100, MIN)
l.arrange(0, 0, 23, 80)
t.assert_equal([[0, 0, 22, 74], [0, 75, 22, 5]], rects(l), "a large count leaves the old window its minimum")

# Closing gives the space to the window after, or before when last.
l = layout_in(23, 80)
top = l.split(0, false, 0, MIN)
l.arrange(0, 0, 23, 80)
t.assert_equal(0, l.close(top), "closing the top window hands its rows to the one below")
l.arrange(0, 0, 23, 80)
t.assert_equal([[0, 0, 22, 80]], rects(l), "the remaining window takes the whole area")
t.assert_equal(0, l.root, "the remaining leaf is the root again")
l = layout_in(23, 80)
a = l.split(0, false, 0, MIN)
l.arrange(0, 0, 23, 80)
b = l.split(0, false, 0, MIN)
l.arrange(0, 0, 23, 80)
t.assert_equal([a, b, 0], l.leaves, "three stacked windows")
t.assert_equal([[0, 0, 11, 80], [12, 0, 5, 80], [18, 0, 4, 80]], rects(l), "the second split halves the bottom window")
t.assert_equal(0, l.close(b), "closing the middle window gives its rows to the one after it")
l.arrange(0, 0, 23, 80)
t.assert_equal([[0, 0, 11, 80], [12, 0, 10, 80]], rects(l), "the bottom window grew")
t.assert_equal(a, l.close(0), "closing the last window gives its rows to the one before it")
l.arrange(0, 0, 23, 80)
t.assert_equal([[0, 0, 22, 80]], rects(l), "one window again")

# A fixed-width sibling is skipped when another can take the space.
l = layout_in(23, 80)
x = l.split(0, true, 20, MIN)
l.arrange(0, 0, 23, 80)
y = l.split(0, true, 20, MIN)
l.arrange(0, 0, 23, 80)
t.assert_equal([x, y, 0], l.leaves, "three windows side by side")
l.window_at(0).fixed_width = true
t.assert_equal(x, l.close(y), "the window before takes the space when the one after is fixed-width")
l.arrange(0, 0, 23, 80)
t.assert_equal([[0, 0, 22, 41], [0, 42, 22, 38]], rects(l), "the left window grew and the fixed one kept its width")

# Neighbours.
l = layout_in(23, 80)
left = l.split(0, true, 0, MIN)
l.arrange(0, 0, 23, 80)
t.assert_equal([0, left, -1, -1], [l.neighbour(left, :right), l.neighbour(0, :left), l.neighbour(left, :left), l.neighbour(0, :right)], "left and right neighbours")
t.assert_equal([-1, -1], [l.neighbour(left, :up), l.neighbour(left, :down)], "no neighbour above or below")
l = layout_in(23, 80)
top = l.split(0, false, 0, MIN)
l.arrange(0, 0, 23, 80)
t.assert_equal([0, top, -1, -1], [l.neighbour(top, :down), l.neighbour(0, :up), l.neighbour(top, :up), l.neighbour(0, :down)], "neighbours above and below")
# Nested: the right window is split; from the left window the neighbour depends on the cursor row.
l = layout_in(23, 80)
left = l.split(0, true, 0, MIN)
l.arrange(0, 0, 23, 80)
lower_right = 0
upper_right = l.split(0, false, 0, MIN)
l.arrange(0, 0, 23, 80)
t.assert_equal(upper_right, l.neighbour(left, :right), "with the cursor on the first row the upper right window is next")
l.window_at(left).cursor.row = 20
t.assert_equal(lower_right, l.neighbour(left, :right), "with the cursor low on the screen the lower right window is next")
t.assert_equal([left, left], [l.neighbour(upper_right, :left), l.neighbour(lower_right, :left)], "both right windows have the left window to their left")
t.assert_equal([lower_right, upper_right], [l.neighbour(upper_right, :down), l.neighbour(lower_right, :up)], "the right windows are stacked")

# Equalize.
l = layout_in(23, 80)
l.split(0, false, 5, MIN)
l.arrange(0, 0, 23, 80)
l.equalize
l.arrange(0, 0, 23, 80)
t.assert_equal([[0, 0, 11, 80], [12, 0, 10, 80]], rects(l), "equalize halves the rows, the first window taking the remainder")
l = layout_in(23, 80)
left = l.split(0, true, 20, MIN)
l.arrange(0, 0, 23, 80)
l.window_at(left).fixed_width = true
l.equalize
l.arrange(0, 0, 23, 80)
t.assert_equal([[0, 0, 22, 20], [0, 21, 22, 59]], rects(l), "a fixed-width window keeps its width")
l.window_at(left).fixed_width = false
l.equalize
l.arrange(0, 0, 23, 80)
t.assert_equal([[0, 0, 22, 40], [0, 41, 22, 39]], rects(l), "without the flag the columns are shared")
l = layout_in(23, 80)
l.split(0, false, 3, MIN)
l.split(0, false, 3, MIN)
l.arrange(0, 0, 23, 80)
l.equalize
l.arrange(0, 0, 23, 80)
t.assert_equal([[0, 0, 7, 80], [8, 0, 7, 80], [16, 0, 6, 80]], rects(l), "three windows share 23 rows as 8, 8, and 7")

# Resizing keeps the layout: the last window absorbs the difference.
l = layout_in(23, 80)
l.split(0, false, 0, MIN)
l.arrange(0, 0, 23, 80)
l.arrange(0, 0, 19, 80)
t.assert_equal([[0, 0, 11, 80], [12, 0, 6, 80]], rects(l), "the bottom window shrinks")
l.arrange(0, 0, 13, 80)
t.assert_equal([[0, 0, 10, 80], [11, 0, 1, 80]], rects(l), "at its minimum the bottom window passes the difference up")
l.arrange(0, 0, 30, 80)
t.assert_equal([[0, 0, 10, 80], [11, 0, 18, 80]], rects(l), "growth goes to the bottom window")
l = layout_in(23, 80)
left = l.split(0, true, 20, MIN)
l.window_at(left).fixed_width = true
l.arrange(0, 0, 23, 60)
t.assert_equal([[0, 0, 22, 20], [0, 21, 22, 39]], rects(l), "a fixed-width window keeps its width when the terminal shrinks")
l.arrange(0, 0, 23, 100)
t.assert_equal([[0, 0, 22, 20], [0, 21, 22, 79]], rects(l), "and when it grows")
l.window_at(0).fixed_width = true
l.arrange(0, 0, 23, 50)
t.assert_equal([[0, 0, 22, 20], [0, 21, 22, 29]], rects(l), "when every window is fixed the last one changes anyway")

# Slots are reused.
l = layout_in(23, 80)
top = l.split(0, false, 0, MIN)
l.close(top)
again = l.split(0, false, 0, MIN)
t.assert_equal(3, l.nodes.length, "closed nodes' slots are reused by the next split")
t.assert_true(again >= 0, "the split after a close works")

# Fixed-width over splits.
l = layout_in(23, 80)
left = l.split(0, true, 20, MIN)
l.arrange(0, 0, 23, 80)
upper = l.split(0, false, 0, MIN)
l.window_at(upper).fixed_width = true
t.assert_equal([false, true, false], [l.fixed_width?(left), l.fixed_width?(l.node(upper).parent), l.fixed_width?(l.root)], "a column is fixed when one child is, a row when all are")

# A side window at the edge of the layout: rows are
# [label, [first, size, keys], [new id, leaves with rectangles after arrange]].
def side(first, size, split_first)
  page = D::TabPage.new(D::Window.new(buffer_named("a.txt")))
  layout = page.layout
  layout.arrange(0, 0, 23, 80)
  if split_first
    other = layout.split(0, true, 0, MIN)
    layout.arrange(0, 0, 23, 80)
  end
  side = D::Window.new(buffer_named("list"))
  side.fixed_width = true
  id = layout.split_edge(side, size, first)
  layout.arrange(0, 0, 23, 80)
  rects = []
  layout.leaves.each do |leaf|
    w = layout.window_at(leaf)
    rects << [w.row, w.col, w.height, w.width, w.buffer.path]
  end
  [id, rects]
end
t.table([
  ["left of one window", [true, 30, false], [2, [[0, 0, 22, 30, "list"], [0, 31, 22, 49, "a.txt"]]]],
  ["right of one window", [false, 30, false], [2, [[0, 0, 22, 49, "a.txt"], [0, 50, 22, 30, "list"]]]],
  ["left of an existing row joins it", [true, 20, true], [3, [[0, 0, 22, 20, "list"], [0, 21, 22, 40, "a.txt"], [0, 62, 22, 18, "a.txt"]]]],
  ["right of an existing row joins it", [false, 20, true], [3, [[0, 0, 22, 40, "a.txt"], [0, 41, 22, 18, "a.txt"], [0, 60, 22, 20, "list"]]]],
  ["too wide for one window", [true, 79, false], [-1, [[0, 0, 22, 80, "a.txt"]]]],
  ["zero width", [true, 0, false], [-1, [[0, 0, 22, 80, "a.txt"]]]]
]) do |input|
  side(input[0], input[1], input[2])
end

# The side window keeps its width through equalize and a resize.
page = D::TabPage.new(D::Window.new(buffer_named("a.txt")))
layout = page.layout
layout.arrange(0, 0, 23, 80)
side = D::Window.new(buffer_named("list"))
side.fixed_width = true
id = layout.split_edge(side, 30, true)
layout.arrange(0, 0, 23, 80)
layout.split(layout.leaves[1], true, 0, MIN)
layout.arrange(0, 0, 23, 80)
layout.equalize
layout.arrange(0, 0, 23, 80)
widths = []
layout.leaves.each { |leaf| widths << layout.window_at(leaf).width }
t.assert_equal([30, 24, 24], widths, "equalize shares the rest between the other windows")
layout.arrange(0, 0, 23, 60)
widths = []
layout.leaves.each { |leaf| widths << layout.window_at(leaf).width }
t.assert_equal([30, 24, 4], widths, "a resize takes from the last flexible window")
t.assert_equal(true, layout.window_at(id).fixed_width, "the side window stays fixed-width")

# The tab page remembers the previous window.
page = D::TabPage.new(D::Window.new(buffer_named("a.txt")))
page.layout.arrange(0, 0, 23, 80)
top = page.layout.split(0, false, 0, MIN)
page.focus(top)
t.assert_equal([top, 0, true], [page.current, page.previous, page.previous?], "focusing remembers the window left")
page.focus(top)
t.assert_equal(0, page.previous, "focusing the current window changes nothing")
page.layout.close(0)
t.assert_equal(false, page.previous?, "a closed previous window is forgotten")

# Leaves by window id and by buffer.
shown = buffer_named("shown.txt")
w = D::Window.new(shown)
w.id = 7
lay = D::Layout.new(w)
lay.arrange(0, 0, 20, 80)
other = D::Window.new(buffer_named("o.txt"))
other.id = 8
right = lay.split_edge(other, 20, false)
t.assert_equal([0, right, -1], [lay.leaf_of(7), lay.leaf_of(8), lay.leaf_of(9)], "a leaf is found by its window's id")
t.assert_equal([0, -1], [lay.leaf_showing(shown), lay.leaf_showing(buffer_named("shown.txt"))], "a leaf is found by the buffer it shows, by identity")

t.finish
