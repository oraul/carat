require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("domain_selection")
D = Carat::Domain

def buffer_of(lines)
  Carat::Domain::Buffer.new(lines, nil, "\n")
end

def pos(pair)
  Carat::Domain::Position.new(pair[0], pair[1])
end

def selection_of(anchor, head, kind, to_end)
  Carat::Domain::Selection.new(pos(anchor), pos(head), kind, to_end)
end

# Display columns of a line.
t.table([
  ["column after a tab", ["a\tb", 2, :column], 4],
  ["column of the tab", ["a\tb", 1, :column], 1],
  ["column after a wide character", ["a中b", 2, :column], 3],
  ["column past the end is the width", ["ab", 9, :column], 2],
  ["col_at inside a tab", ["a\tb", 2, :col_at], 1],
  ["col_at on the second cell of a wide character", ["a中b", 2, :col_at], 1],
  ["col_at past the end", ["ab", 5, :col_at], 2]
]) do |input|
  if input[2] == :column
    D::DisplayWidth.column(input[0], input[1], 4)
  else
    D::DisplayWidth.col_at(input[0], input[1], 4)
  end
end
t.assert_equal([3, 2, 2, 1], [D::DisplayWidth.cell("\t", 1, 4), D::DisplayWidth.cell("中", 0, 4), D::DisplayWidth.cell("\u0001", 0, 4), D::DisplayWidth.cell("a", 0, 4)], "cell widths of a tab, a wide character, a control, and a letter")

# The span of one row: rows are [label, [lines, anchor, head, kind, to_end, row], [from, to, eol]].
t.table([
  ["charwise on one row", [["abcd"], [0, 1], [0, 2], :charwise, false, 0], [1, 3, false]],
  ["charwise first row of several", [["abc", "def", "ghi"], [0, 1], [2, 1], :charwise, false, 0], [1, 3, true]],
  ["charwise middle row", [["abc", "def", "ghi"], [0, 1], [2, 1], :charwise, false, 1], [0, 3, true]],
  ["charwise last row", [["abc", "def", "ghi"], [0, 1], [2, 1], :charwise, false, 2], [0, 2, false]],
  ["charwise with the cursor before the anchor", [["abc", "def", "ghi"], [2, 1], [0, 1], :charwise, false, 0], [1, 3, true]],
  ["charwise outside the rows", [["abc", "def", "ghi"], [0, 1], [1, 1], :charwise, false, 2], [0, 0, false]],
  ["charwise ending on the end of the line", [["ab", "cd"], [0, 1], [0, 2], :charwise, false, 0], [1, 2, true]],
  ["charwise on an empty line", [["a", "", "b"], [1, 0], [1, 0], :charwise, false, 1], [0, 0, true]],
  ["linewise covers the whole row", [["abc", "de"], [0, 1], [1, 0], :linewise, false, 1], [0, 2, true]],
  ["block on plain text", [["abcd", "efgh"], [0, 1], [1, 2], :blockwise, false, 1], [1, 3, false]],
  ["block over a tab in a middle row", [["abcd", "a\tb", "abcd"], [0, 1], [2, 2], :blockwise, false, 1], [1, 2, false]],
  ["block whose corner is a tab", [["a\tb", "abcdef"], [0, 1], [1, 1], :blockwise, false, 1], [1, 4, false]],
  ["block whose corner is a wide character", [["a中b", "abcd"], [0, 1], [1, 1], :blockwise, false, 1], [1, 3, false]],
  ["block over a wide character in a middle row", [["abcd", "a中b", "abcd"], [0, 2], [2, 2], :blockwise, false, 1], [1, 2, false]],
  ["block selecting a line end inside it", [["ab", "abcd"], [0, 1], [1, 3], :blockwise, false, 0], [1, 2, true]],
  ["block after $ reaches the end", [["abc", "a"], [0, 1], [1, 1], :blockwise, true, 0], [1, 3, true]],
  ["block after $ on a short row", [["abc", "a"], [0, 1], [1, 1], :blockwise, true, 1], [1, 1, true]],
  ["no selection", [["abc"], [0, 0], [0, 0], :none, false, 0], [0, 0, false]]
]) do |input|
  span = selection_of(input[1], input[2], input[3], input[4]).span(buffer_of(input[0]), input[5], 4)
  [span.from, span.to, span.eol]
end

# The block's display columns: rows are [label, [lines, anchor, head, to_end], [top, bottom, left, right]].
t.table([
  ["a block on plain text", [["abcd", "efgh"], [0, 1], [1, 2], false], [0, 1, 1, 2]],
  ["a tab at the anchor widens the block", [["a\tb", "abcdef"], [0, 1], [1, 1], false], [0, 1, 1, 3]],
  ["a wide character at the cursor widens the block", [["abcd", "a中b"], [0, 3], [1, 1], false], [0, 1, 1, 3]],
  ["the cursor on the end of a line counts one cell", [["abc", "a"], [0, 0], [1, 1], false], [0, 1, 0, 1]],
  ["the anchor below the cursor", [["abcd", "efgh"], [1, 3], [0, 0], false], [0, 1, 0, 3]]
]) do |input|
  block = selection_of(input[1], input[2], :blockwise, input[3]).block(buffer_of(input[0]), 4)
  [block.top, block.bottom, block.left, block.right]
end
block = selection_of([0, 2], [1, 3], :blockwise, false).block(buffer_of(["abcd", "abcd"]), 4)
t.assert_true(block.short?("a", 4), "a row ending before the block is short")
t.assert_true(!block.short?("ab", 4), "a row ending at the block's first column is not short")

# Operator ranges.
b = buffer_of(["ab", "cd"])
r = selection_of([0, 0], [0, 1], :charwise, false).char_range(b)
t.assert_equal([[0, 0], [0, 1], :charwise, true], [r.from.to_a, r.to.to_a, r.kind, r.inclusive], "a charwise range includes its end")
r = selection_of([0, 1], [0, 2], :charwise, false).char_range(b)
t.assert_equal([[0, 1], [1, 0], false], [r.from.to_a, r.to.to_a, r.inclusive], "an end on the line end reaches the next line")
r = selection_of([1, 2], [1, 0], :charwise, false).char_range(b)
t.assert_equal([[1, 0], [1, 2], false], [r.from.to_a, r.to.to_a, r.inclusive], "on the last line there is no line break to take")
r = selection_of([1, 1], [0, 1], :linewise, false).line_range
t.assert_equal([[0, 0], [1, 0], :linewise], [r.from.to_a, r.to.to_a, r.kind], "a linewise range covers the rows")
t.assert_equal([0, 0], selection_of([0, 1], [1, 1], :linewise, false).line_start.to_a, "a linewise operand starts at column 0 of the anchor's row")
t.assert_equal([0, 1], selection_of([1, 1], [0, 1], :linewise, false).line_start.to_a, "or at the cursor when it is on top")
s = selection_of([1, 1], [0, 2], :charwise, false)
t.assert_equal([[0, 2], [1, 1], 0, 1], [s.start.to_a, s.finish.to_a, s.top, s.bottom], "start and finish are ordered")
t.assert_equal([:linewise, true], [s.as(:linewise, true).kind, s.as(:linewise, true).to_end], "as changes the kind")
t.assert_true(!D::Selection.none.active?, "no selection is inactive")

# The editor state's selection and leaving visual mode.
state = D::EditorState.new(D::TabList.new(D::Window.new(buffer_of(["abc", "de"]))), D::Options.new)
t.assert_equal(:none, state.selection.kind, "normal mode has no selection")
state.mode = D::Mode::VISUAL
state.window.anchor = pos([0, 1])
state.cursor.move_to(0, 3)
t.assert_equal(3, state.max_col(0), "the cursor may rest on the end of the line in visual mode")
t.assert_equal([:charwise, [0, 1], [0, 3]], [state.selection.kind, state.selection.anchor.to_a, state.selection.head.to_a], "the selection runs from the anchor to the cursor")
left = state.end_visual
t.assert_equal([:normal, [0, 2]], [state.mode, state.cursor.to_a], "leaving moves the cursor onto the last character")
t.assert_equal([:charwise, [0, 1], [0, 3]], [state.window.last_selection.kind, state.window.last_selection.anchor.to_a, state.window.last_selection.head.to_a], "leaving stores the selection on the window")
t.assert_equal(:charwise, left.kind, "end_visual returns the selection it left")
state.window.show(buffer_of(["x"]))
t.assert_equal(:none, state.window.last_selection.kind, "showing another buffer forgets the last selection")
state.mode = D::Mode::VISUAL_BLOCK
state.cursor.want_col = -1
t.assert_equal([:blockwise, true], [state.selection.kind, state.selection.to_end], "a wanted column at the line end is a block to the end")

# Modes.
t.assert_equal([true, true, true, false], [D::Mode.visual?(:visual), D::Mode.visual?(:visual_line), D::Mode.visual?(:visual_block), D::Mode.visual?(:normal)], "the three visual modes")
t.assert_equal([:charwise, :linewise, :blockwise, :none], [D::Mode.visual_kind(:visual), D::Mode.visual_kind(:visual_line), D::Mode.visual_kind(:visual_block), D::Mode.visual_kind(:insert)], "the kind of each mode")
t.assert_equal([:visual, :visual_line, :visual_block, :normal], [D::Mode.for_kind(:charwise), D::Mode.for_kind(:linewise), D::Mode.for_kind(:blockwise), D::Mode.for_kind(:none)], "the mode of each kind")

t.finish
