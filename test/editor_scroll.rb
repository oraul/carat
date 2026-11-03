require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorScrollTest
  # "line 1" to "line 100".
  def self.hundred
    text = +""
    i = 1
    while i <= 100
      text << "line #{i}\n"
      i += 1
    end
    text
  end

  # A 12 by 40 editor, so its one window has 10 text rows, on text with
  # the shipped configuration and more lines.
  def self.editor(text, more)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", text)
    config = Carat::Doubles::FixedConfig.with(more)
    h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 12, cols: 40, plugins: [])
    h.open("a.txt")
    h
  end

  # The editor on the hundred lines with scrolloff, the window showing
  # from row top and the cursor on row, column 0, drawn once.
  def self.placed(scrolloff, top, row)
    h = editor(hundred, "option.scrolloff #{scrolloff}\n")
    h.state.cursor.move_to(row, 0)
    h.state.window.top = top
    h.wait
    h
  end

  def self.main
    t = Carat::Testing.new("editor_scroll")
    t.assert_equal(10, placed(0, 0, 0).state.window.height, "the window has 10 text rows")

    # Rows are [label, [scrolloff, top, cursor row, keys], [top, cursor row]],
    # rows counted from 0, over 100 lines in a window of 10 text rows.
    t.table([
      ["Ctrl-F scrolls forward a page of the rows minus two", [0, 0, 0, "<C-f>"], [8, 8]],
      ["PageDown scrolls as Ctrl-F", [0, 0, 0, "<PageDown>"], [8, 8]],
      ["Ctrl-B scrolls back a page, the cursor kept where it is in view", [0, 8, 8, "<C-b>"], [0, 8]],
      ["PageUp scrolls as Ctrl-B", [0, 8, 8, "<PageUp>"], [0, 8]],
      ["a count scrolls that many pages", [0, 0, 0, "2<PageDown>"], [16, 16]],
      ["Ctrl-B with a count stops at the first line", [0, 10, 12, "5<C-b>"], [0, 9]],
      ["Ctrl-F with the last line shown goes to the last line", [0, 90, 90, "<C-f>"], [90, 99]],
      ["Ctrl-F stops at the last full window", [0, 85, 85, "<C-f>"], [90, 90]],
      ["Ctrl-B at the first line changes nothing", [0, 0, 5, "<C-b>"], [0, 5]],
      ["Ctrl-F keeps scrolloff rows above the cursor", [2, 0, 0, "<C-f>"], [8, 10]],
      ["Ctrl-D scrolls and moves the cursor half a window", [0, 0, 1, "<C-d>"], [5, 6]],
      ["Ctrl-U scrolls and moves the cursor back", [0, 5, 6, "<C-u>"], [0, 1]],
      ["Ctrl-D at the end moves only the cursor", [0, 90, 91, "<C-d>"], [90, 96]],
      ["Ctrl-D stops at the last line", [0, 90, 97, "<C-d>"], [90, 99]],
      ["Ctrl-U at the start moves only the cursor", [0, 0, 7, "<C-u>"], [0, 2]],
      ["a count before Ctrl-D scrolls that many lines", [0, 0, 0, "3<C-d>"], [3, 3]],
      ["Ctrl-E scrolls a line and the cursor stays on its line", [0, 0, 5, "<C-e>"], [1, 5]],
      ["a count before Ctrl-E scrolls that many lines", [0, 0, 4, "3<C-e>"], [3, 4]],
      ["Ctrl-E pushes the cursor down when its line leaves the window", [0, 0, 0, "<C-e>"], [1, 1]],
      ["Ctrl-E pushes the cursor scrolloff rows in", [2, 0, 0, "<C-e>"], [1, 3]],
      ["Ctrl-Y pulls the cursor up when its line leaves the window", [0, 5, 14, "<C-y>"], [4, 13]],
      ["Ctrl-Y at the first line changes nothing", [0, 0, 3, "<C-y>"], [0, 3]],
      ["Ctrl-E at the last full window changes nothing", [0, 90, 95, "<C-e>"], [90, 95]],
      ["zt puts the cursor line at the top", [0, 45, 50, "zt"], [50, 50]],
      ["zz puts the cursor line in the middle", [0, 45, 50, "zz"], [46, 50]],
      ["zb puts the cursor line at the bottom", [0, 45, 50, "zb"], [41, 50]],
      ["zt keeps scrolloff rows above", [2, 45, 50, "zt"], [48, 50]],
      ["zb keeps scrolloff rows below", [2, 45, 50, "zb"], [43, 50]],
      ["a count before zt goes to that line first", [0, 0, 0, "20zt"], [19, 19]],
      ["zt near the end stops at the last full window", [0, 90, 97, "zt"], [90, 97]],
      ["zb near the start stops at the first line", [0, 0, 3, "zb"], [0, 3]],
      ["zz near the start stops at the first line", [0, 0, 2, "zz"], [0, 2]]
    ]) do |input|
      h = placed(input[0].to_i, input[1].to_i, input[2].to_i)
      h.type(input[3].to_s)
      [h.state.window.top, h.cursor[0]]
    end

    # In the visual modes the cursor end of the selection moves, and in
    # insert mode PageDown and PageUp scroll too: rows are [label, keys,
    # [top, cursor, mode]], from the first line with scrolloff 0.
    t.table([
      ["Ctrl-D in visual mode moves the end of the selection", "v<C-d>", [5, [5, 0], :visual]],
      ["Ctrl-F in linewise visual mode", "V<C-f>", [8, [8, 0], :visual_line]],
      ["zt in blockwise visual mode keeps the selection", "<C-v>jzt", [1, [1, 0], :visual_block]],
      ["PageDown in insert mode", "i<PageDown>", [8, [8, 0], :insert]],
      ["PageUp in insert mode", "i<PageDown><PageUp>", [0, [8, 0], :insert]],
      ["Ctrl-E in insert mode is not a scroll", "i<C-e>", [0, [0, 0], :insert]]
    ]) do |keys|
      h = placed(0, 0, 0)
      h.type(keys.to_s)
      [h.state.window.top, h.cursor, h.mode]
    end

    # The wanted column: Ctrl-E pushes the cursor from column 5 onto a
    # short line, and k back onto the long one returns it to column 5.
    h = editor("abcdefghij\nab\nab\nab\nab\nab\nab\nab\nab\nab\nab\nab\n", "option.scrolloff 0\n")
    h.type("5l<C-e>")
    t.assert_equal([1, [1, 1]], [h.state.window.top, h.cursor], "Ctrl-E puts the cursor on the short line's last character")
    h.type("k")
    t.assert_equal([0, 5], h.cursor, "the wanted column survives the scroll")
    h.type("$<C-d>")
    t.assert_equal([[5, 1], -1], [h.cursor, h.state.cursor.want_col], "after $ the scroll keeps the cursor at the line end")

    # The scroll option.
    h = placed(0, 0, 0)
    h.type("3<C-d>")
    t.assert_equal([3, 3, 3], [h.state.options.scroll, h.state.window.top, h.cursor[0]], "a count before Ctrl-D sets the scroll option")
    h.type("<C-d>")
    t.assert_equal([6, 6], [h.state.window.top, h.cursor[0]], "the next Ctrl-D scrolls as many lines")
    h.type("<C-u>")
    t.assert_equal([3, 3], [h.state.window.top, h.cursor[0]], "Ctrl-U scrolls as many lines too")
    h = editor(hundred, "option.scrolloff 0\noption.scroll 4\n")
    h.type("<C-d>")
    t.assert_equal([4, 4], [h.state.window.top, h.cursor[0]], "option.scroll sets the lines Ctrl-D scrolls")

    # A short buffer: nothing scrolls, Ctrl-F goes to the last line.
    h = editor("a\nb\nc\n", "")
    h.type("<C-f>")
    t.assert_equal([0, [2, 0]], [h.state.window.top, h.cursor], "Ctrl-F in a buffer that fits goes to the last line")
    h.type("<C-e><C-y>")
    t.assert_equal([0, [2, 0]], [h.state.window.top, h.cursor], "Ctrl-E and Ctrl-Y in a buffer that fits change nothing")

    # Before the first render the window has no height and nothing scrolls.
    h = placed(0, 0, 3)
    h.state.window.height = 0
    Carat::UseCases::ScrollWindow.new.call(h.state, Carat::UseCases::ScrollRequest.new(target: :page_down, count: 0))
    t.assert_equal([0, 3], [h.state.window.top, h.cursor[0]], "a window with no height does not scroll")

    # A scroll is no change: the buffer stays unmodified.
    h = placed(0, 0, 0)
    h.type("<C-f>zz<C-e>")
    t.assert_equal(false, h.buffer.modified?, "scrolling leaves the buffer unmodified")

    t.finish
  end
end

EditorScrollTest.main if __FILE__ == $0
