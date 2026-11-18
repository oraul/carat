require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorFoldsTest
  # A 12 by 40 editor on text, its one window showing line numbers.
  def self.editor(text, more)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", text)
    config = Carat::Doubles::FixedConfig.with(more)
    h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 12, cols: 40, plugins: [])
    h.open("a.txt")
    h
  end

  # The text of the window's first count rows past the gutter, trailing
  # blanks dropped.
  def self.shown(h, count)
    window = h.state.window
    gutter = window.gutter_width(h.state.options)
    rows = []
    i = 0
    while i < count
      text = h.row(window.row + i)
      rows << text[gutter, text.length - gutter].to_s.rstrip
      i += 1
    end
    rows
  end

  # A 12 by 40 editor on a Ruby file, highlighted by the ruby plugin.
  def self.ruby_editor(text)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.rb", text)
    h = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with(""), rows: 12, cols: 40, plugins: [Carat::Plugins::Ruby::Plugin.new])
    h.open("a.rb")
    h
  end

  # Whether a frame row has a cell of a syntax group.
  def self.tokens?(h, row)
    frame = h.frame
    col = 0
    while col < frame.cols
      return true if Carat::Domain::Highlight.token?(Carat::Domain::Highlight.base(frame.hl_at(row, col)))
      col += 1
    end
    false
  end

  # A fold row: head filled with the fold character to the 36 columns
  # the window's text takes past its 4-column gutter.
  def self.fold_row(head)
    head + "·" * (36 - head.length)
  end

  # The window's folds as [first, last, closed] triples.
  def self.folds_of(h)
    folds = h.state.window.folds
    list = []
    i = 0
    while i < folds.count
      list << [folds.first_of(i), folds.last_of(i), folds.closed?(i)]
      i += 1
    end
    list
  end

  def self.main
    t = Carat::Testing.new("editor_folds")

    # What the window draws: rows are [label, keys, [first three rows,
    # cursor]] over the lines "one", "two", "three", "four".
    t.table([
      ["zfj leaves a closed two-line fold drawn as one row", "zfj", [[fold_row("+--  2 lines: one"), "three", "four"], [0, 0]]],
      ["j passes a closed fold", "zfjj", [[fold_row("+--  2 lines: one"), "three", "four"], [2, 0]]],
      ["k lands on the first line of a closed fold", "zfjjk", [[fold_row("+--  2 lines: one"), "three", "four"], [0, 0]]],
      ["zo opens a closed fold", "zfjzo", [["one", "two", "three"], [0, 0]]],
      ["zc closes an open fold", "zfjzojzc", [[fold_row("+--  2 lines: one"), "three", "four"], [0, 0]]],
      ["za toggles a fold open", "zfjza", [["one", "two", "three"], [0, 0]]],
      ["za toggles a fold closed again", "zfjzaza", [[fold_row("+--  2 lines: one"), "three", "four"], [0, 0]]],
      ["zd deletes the fold under the cursor", "zfjzd", [["one", "two", "three"], [0, 0]]],
      ["a fold over a text object", "zfip", [[fold_row("+--  4 lines: one"), "", ""], [0, 0]]],
      ["a nested closed fold has a dash more", "zf3jzojzfj", [["one", fold_row("+---  2 lines: two"), "four"], [1, 0]]],
      ["zd on a nested closed fold keeps the outer one", "zf3jzojzfjzd", [["one", "two", "three"], [1, 0]]],
      ["zf at the first row of an open fold nests in it", "zf3jzozfj", [[fold_row("+---  2 lines: one"), "three", "four"], [0, 0]]],
      ["a fold below the first line", "jzfj", [["one", fold_row("+--  2 lines: two"), "four"], [1, 0]]],
      ["a count G into a closed fold lands on its first line", "jzfjgg3G", [["one", fold_row("+--  2 lines: two"), "four"], [1, 0]]],
      ["G into a closed fold at the end lands on its first line", "jjzfjggG", [["one", "two", fold_row("+--  2 lines: three")], [2, 0]]]
    ]) do |keys|
      h = editor("one\ntwo\nthree\nfour\n", "")
      h.type(keys.to_s)
      [shown(h, 3), h.cursor]
    end

    h = editor("one\ntwo\nthree\nfour\n", "")
    h.type("jzfjgg3G")
    t.assert_equal(h.state.window.row + 1, h.frame.cursor_row, "a cursor moved into a closed fold is drawn on the fold row")

    h = editor("one\ntwo\nthree\nfour\n", "")
    h.type("zfjoX")
    t.assert_equal([[[0, 1, true]], [fold_row("+--  2 lines: one"), "X", "three"], [2, 1], h.state.window.row + 1], [folds_of(h), shown(h, 3), h.cursor, h.frame.cursor_row], "o on a closed fold opens below it, the insert cursor drawn on the row below the fold")

    h = editor("  one\ntwo\nthree\n", "")
    h.type("zfj")
    t.assert_equal(fold_row("+--  2 lines: one"), shown(h, 1)[0], "the fold text drops the leading blanks of the first line")

    # The folds and the lines: rows are [label, keys, [folds, lines,
    # cursor, mode]] over the lines "a" to "e".
    t.table([
      ["dd on a closed fold deletes its lines", "zfjdd", [[], ["c", "d", "e"], [0, 0], :normal]],
      ["2dd on a closed fold deletes the fold and the next line", "zfj2dd", [[], ["d", "e"], [0, 0], :normal]],
      ["dj on a closed fold deletes the fold and the next line", "zfjdj", [[], ["d", "e"], [0, 0], :normal]],
      ["dj onto a closed fold deletes all its lines", "jzfjggdj", [[], ["d", "e"], [0, 0], :normal]],
      ["yy on a closed fold yanks its lines", "zfjyyGp", [[[0, 1, true]], ["a", "b", "c", "d", "e", "a", "b"], [5, 0], :normal]],
      ["A fold moves down with a line put above it", "jzfjggyyP", [[[2, 3, true]], ["a", "a", "b", "c", "d", "e"], [0, 0], :normal]],
      ["a line opened inside an open fold extends it", "zfjzooX<Esc>", [[[0, 2, false]], ["a", "X", "b", "c", "d", "e"], [1, 0], :normal]],
      ["o on a closed fold opens a line below its last line", "zfjoX<Esc>", [[[0, 1, true]], ["a", "b", "X", "c", "d", "e"], [2, 0], :normal]],
      ["O on a closed fold opens a line above its first line", "jjzfjOX<Esc>", [[[3, 4, true]], ["a", "b", "X", "c", "d", "e"], [2, 0], :normal]],
      ["a line deleted inside an open fold shrinks it", "zf2jzojdd", [[[0, 1, false]], ["a", "c", "d", "e"], [1, 0], :normal]],
      ["zf in linewise visual mode folds the selection", "Vjjzf", [[[0, 2, true]], ["a", "b", "c", "d", "e"], [0, 0], :normal]],
      ["zf in visual mode folds the selected lines", "jvjzf", [[[1, 2, true]], ["a", "b", "c", "d", "e"], [1, 0], :normal]],
      ["zfk folds the line above too, the cursor on the first", "jzfk", [[[0, 1, true]], ["a", "b", "c", "d", "e"], [0, 0], :normal]],
      ["zE deletes every fold", "zfjjjzfjzE", [[], ["a", "b", "c", "d", "e"], [3, 0], :normal]],
      ["zf3jzozfj nests a fold at the outer fold's first row", "zf3jzozfj", [[[0, 3, false], [0, 1, true]], ["a", "b", "c", "d", "e"], [0, 0], :normal]],
      ["a fold crossing another grows to hold it", "jzfjzoggzfj", [[[0, 2, true], [1, 2, false]], ["a", "b", "c", "d", "e"], [0, 0], :normal]],
      ["u restores the lines of a deleted fold, not the fold", "zfjddu", [[], ["a", "b", "c", "d", "e"], [0, 0], :normal]]
    ]) do |keys|
      h = editor("a\nb\nc\nd\ne\n", "")
      h.type(keys.to_s)
      [folds_of(h), h.lines, h.cursor, h.mode]
    end

    # A fold key with no fold gives E490: rows are [label, keys].
    t.table([
      ["zo with no fold gives E490", "zo", "E490: No fold found"],
      ["zc with no fold gives E490", "zc", "E490: No fold found"],
      ["za with no fold gives E490", "za", "E490: No fold found"],
      ["zd with no fold gives E490", "zd", "E490: No fold found"],
      ["zd below a fold gives E490", "zfjjzd", "E490: No fold found"]
    ]) do |keys|
      h = editor("a\nb\nc\n", "")
      h.type(keys.to_s)
      h.message
    end

    # Scrolling counts a closed fold as one row: rows are [label, keys,
    # [top, cursor row, cursor screen row]] over 30 lines in a window of
    # 10 text rows with scrolloff 0.
    text = +""
    i = 1
    while i <= 30
      text << "line #{i}\n"
      i += 1
    end
    t.table([
      ["the cursor on the tenth row after a closed fold of ten lines", "zf9j9j", [0, 18, 9]],
      ["one line more scrolls the fold out", "zf9j10j", [10, 19, 9]],
      ["gg back onto the fold scrolls it in", "zf9j10jgg", [0, 0, 0]],
      ["a count passes the fold once", "jzf2jgg3j", [0, 5, 3]]
    ]) do |keys|
      h = editor(text, "option.scrolloff 0\n")
      h.type(keys.to_s)
      window = h.state.window
      [window.top, h.cursor[0], window.row_offset(h.cursor[0])]
    end

    # A split copies the folds; showing another buffer drops them.
    h = editor("a\nb\nc\n", "")
    h.type("zfj<C-w>s")
    t.assert_equal([[0, 1, true]], folds_of(h), "a split window has its parent's folds")
    h.type("zE<C-w>w")
    t.assert_equal([[0, 1, true]], folds_of(h), "zE in one window leaves the other's folds")
    h.type("dd")
    t.assert_equal(["c"], h.lines, "dd on the other window's closed fold deletes its lines")
    h = editor("a\nb\nc\n", "")
    h.files.put("b.txt", "x\ny\nz\n")
    h.type("zfj")
    old = h.state.window.buffer
    h.type(":e b.txt<CR>")
    t.assert_equal([[], ["x", "y", "z"], true], [folds_of(h), shown(h, 3), old.fold_lists.empty?], "showing another buffer drops the window's folds, untracked, and draws the new buffer's lines")

    # A window with a closed fold shows more buffer rows than its height:
    # the rows below the fold are highlighted and a float anchored at the
    # cursor counts the fold as one row.
    text = +""
    i = 1
    while i <= 20
      text << "x = #{i}\n"
      i += 1
    end
    h = ruby_editor(text)
    h.type("zf4j")
    window = h.state.window
    last = window.height - 1
    t.assert_equal([last + 5, "x = #{last + 5}", true], [window.shown_end, shown(h, window.height)[last], tokens?(h, window.row + last)], "a syntax-highlighted line below a closed fold, past top plus the height")
    h.type("5j")
    lines = Carat::Domain::Buffer.new(lines: ["one", "two"], path: nil, line_ending: "\n")
    id = h.assembly.open_definition_float.call(h.state, lines, "t", false)
    floats = h.state.tab.floats
    t.assert_equal([9, 5, 1], [h.cursor[0], window.row_offset(9), floats.at(floats.index_of(id)).spec.row], "a float opens below a cursor under a closed fold where the rows below have room")

    t.finish
  end
end

EditorFoldsTest.main if __FILE__ == $0
