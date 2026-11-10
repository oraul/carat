require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainFloatLayerTest
  D = Carat::Domain

  def self.spec(anchor, row, col, height, width, border, z)
    D::FloatSpec.new(anchor: anchor, row: row, col: col, height: height, width: width, border: border, title: "", z: z)
  end

  def self.float_with(id, z)
    window = D::Window.new(buffer: D::Buffer.new(lines: ["x"], path: nil, line_ending: "\n"))
    window.id = id
    D::FloatWindow.new(window: window, spec: spec("editor", 0, 0, 1, 1, false, z))
  end

  # The box of a float placed at (top, left) in rows by cols, as
  # [top, bottom, left, right] of the box and [row, col, height, width]
  # of its text area.
  def self.placed(s, top, left, rows, cols)
    window = D::Window.new(buffer: D::Buffer.new(lines: ["x"], path: nil, line_ending: "\n"))
    float = D::FloatWindow.new(window: window, spec: s)
    float.place(top, left, rows, cols, true)
    [float.box_top, float.box_bottom, float.box_left, float.box_right, window.row, window.col, window.height, window.width]
  end

  def self.ids(layer)
    out = []
    i = 0
    while i < layer.count
      out << layer.at(i).id
      i += 1
    end
    out
  end

  def self.main
    t = Carat::Testing.new("domain_float_layer")

    # Placement: the box at the offset, cut to fit, then moved in.
    t.assert_equal([2, 6, 4, 18, 3, 6, 2, 10], placed(spec("editor", 2, 4, 2, 10, true, 50), 0, 0, 11, 40), "a bordered box sits at its offset, the text inside its border and a column of padding")
    t.assert_equal([4, 5, 5, 15, 4, 6, 1, 8], placed(spec("cursor", 1, 0, 1, 8, false, 50), 3, 5, 11, 40), "a cursor offset counts from the anchor cell")
    t.assert_equal([0, 11, 0, 40, 1, 2, 9, 36], placed(spec("editor", 5, 50, 30, 100, true, 50), 0, 0, 11, 40), "a box larger than the area is cut to it and moved in")
    t.assert_equal([8, 11, 32, 40, 9, 34, 1, 4], placed(spec("cursor", 1, 0, 1, 4, true, 50), 9, 38, 11, 40), "a box past the bottom right corner moves up and left")
    t.assert_equal([0, 3, 0, 5, 1, 2, 1, 1], placed(spec("editor", 0, 0, 3, 3, true, 50), 0, 0, 1, 2), "an area too small for the border keeps a one-cell text area and overflows it")

    # Spec checks.
    t.table([
      ["editor is an anchor", ["editor", 1, 1, 0], ""],
      ["cursor is an anchor", ["cursor", 1, 1, 1000], ""],
      ["window is not", ["window", 1, 1, 0], "No anchor window: editor or cursor"],
      ["no rows", ["editor", 0, 1, 0], "A float needs at least one row and one column"],
      ["no columns", ["editor", 1, 0, 0], "A float needs at least one row and one column"],
      ["a negative z", ["editor", 1, 1, -1], "No z order -1: 0 to 1000"],
      ["a z past the top", ["editor", 1, 1, 1001], "No z order 1001: 0 to 1000"]
    ]) do |row|
      D::FloatSpec.refusal(row[0].to_s, row[1].to_i, row[2].to_i, row[3].to_i)
    end
    t.assert_equal([7, 9, 3], [spec("editor", 1, 2, 3, 4, true, 5).moved(7, 9).row, spec("editor", 1, 2, 3, 4, true, 5).moved(7, 9).col, spec("editor", 1, 2, 3, 4, true, 5).moved(7, 9).height], "moving keeps the size")

    # The layer: z order, focus, closing.
    layer = D::FloatLayer.new
    layer.add(float_with(1, 50), false)
    layer.add(float_with(2, 10), false)
    layer.add(float_with(3, 50), true)
    t.assert_equal([2, 1, 3], ids(layer), "lower z first, a later float above an earlier one of its z")
    t.assert_equal([true, 3], [layer.focused?, layer.focused.id], "entering focuses the new float")
    layer.add(float_with(4, 0), false)
    t.assert_equal([4, 2, 1, 3, 3], ids(layer) + [layer.focused.id], "a float added below keeps the focus on its float")
    t.assert_equal([true, false], [layer.close_top, layer.focused?], "closing the focused topmost float gives the focus back")
    t.assert_equal([4, 2, 1], ids(layer), "the topmost is gone")
    t.assert_equal([true, 2], [layer.enter(2), layer.focused.id], "a float is entered by its id")
    t.assert_equal([true, 2], [layer.close(4), layer.focused.id], "closing a float below keeps the focus")
    t.assert_equal([false, false], [layer.enter(9), layer.close(9)], "an unknown id is refused")
    layer.leave
    t.assert_equal([false, false], [layer.focused?, layer.close_focused], "leaving gives the focus to the layout")
    t.assert_equal([true, 6, 7], [layer.move(1, 6, 7), layer.at(layer.index_of(1)).spec.row, layer.at(layer.index_of(1)).spec.col], "moving changes the offset")
    i = 0
    i += 1 while layer.add(float_with(10 + i, 0), false)
    t.assert_equal([16, true], [layer.count, layer.full?], "a layer holds sixteen floats")

    # The tab page: the focused float is the current window, focusing a
    # leaf leaves it.
    buffer = D::Buffer.new(lines: ["a"], path: "a.txt", line_ending: "\n")
    tabs = D::TabList.new(window: D::Window.new(buffer: buffer))
    float = float_with(0, 50)
    tabs.adopt(float.window)
    page = tabs.tab
    page.floats.add(float, true)
    t.assert_equal([2, 1, 0, -1], [page.window.id, page.layout_window.id, tabs.float_tab(2), tabs.float_tab(1)], "the focused float is the current window and is found by its id")
    page.focus(page.current)
    t.assert_equal([1, false], [page.window.id, page.floats.focused?], "focusing a leaf leaves the float")

    t.finish
  end
end

DomainFloatLayerTest.main if __FILE__ == $0
