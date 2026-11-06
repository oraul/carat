require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorNormalTest
  H = Carat::Doubles::EditorHarness

  def self.editor(text)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", text)
    h = Carat::Doubles::EditorHarness.default(files, 10, 80)
    h.open("a.txt")
    h
  end

  def self.main
    t = Carat::Testing.new("editor_normal")

    h = editor("one\ntwo\nthree\n")
    t.assert_equal(:normal, h.mode, "starts in normal mode")
    t.assert_equal([0, 0], h.cursor, "starts at the first line")
    t.assert_equal("\"a.txt\" 3L, 14B", h.message_row, "shows the opened message")

    # Motions: rows are [label, [text, start, keys], expected cursor].
    t.table([
      ["right at line end does nothing", ["abc\n", [0, 2], "l"], [0, 2]],
      ["left at line start does nothing", ["abc\n", [0, 0], "h"], [0, 0]],
      ["right moves one column", ["abc\n", [0, 0], "ll"], [0, 2]],
      ["arrows move too", ["abc\n", [0, 0], "<Right><Right><Left>"], [0, 1]],
      ["empty line stays at 0", ["\n", [0, 0], "l"], [0, 0]],
      ["shorter line clamps the column", ["abcdef\nxy\n123456\n", [0, 4], "j"], [1, 1]],
      ["desired column returns", ["abcdef\nxy\n123456\n", [0, 4], "jj"], [2, 4]],
      ["horizontal motion resets the desired column", ["abcdef\nxy\n123456\n", [0, 4], "hjj"], [2, 3]],
      ["down at the last line does nothing", ["a\nb\n", [1, 0], "j"], [1, 0]],
      ["up at the first line does nothing", ["a\nb\n", [0, 0], "k"], [0, 0]],
      ["up and down arrows", ["a\nb\nc\n", [0, 0], "<Down><Down><Up>"], [1, 0]],
      ["zero goes to column 0", ["abc\n", [0, 2], "0"], [0, 0]],
      ["caret goes to the first non-blank", ["   abc\n", [0, 0], "^"], [0, 3]],
      ["dollar goes to the last character", ["abc\n", [0, 0], "$"], [0, 2]],
      ["dollar then down sticks to line ends", ["abc\nabcdef\n", [0, 0], "$j"], [1, 5]],
      ["G goes to the last line", ["a\nb\nc\n", [1, 0], "G"], [2, 0]],
      ["gg goes to the first line", ["a\nb\nc\n", [2, 0], "gg"], [0, 0]],
      ["unbound key changes nothing", ["abc\n", [0, 1], "Q"], [0, 1]]
    ]) do |input|
      h = editor(input[0])
      h.state.cursor.move_to(input[1][0], input[1][1])
      h.type(input[2])
      h.cursor
    end

    # Entering insert mode: rows are [label, [text, start, keys], [lines, cursor, mode]].
    t.table([
      ["i before the cursor", ["ab\n", [0, 1], "i"], [["ab"], [0, 1], :insert]],
      ["a after the cursor", ["ab\n", [0, 0], "a"], [["ab"], [0, 1], :insert]],
      ["a on an empty line", ["\n", [0, 0], "a"], [[""], [0, 0], :insert]],
      ["A past the end", ["ab\n", [0, 0], "A"], [["ab"], [0, 2], :insert]],
      ["I at the first non-blank", ["  ab\n", [0, 3], "I"], [["  ab"], [0, 2], :insert]],
      ["o opens a line below", ["ab\ncd\n", [0, 0], "o"], [["ab", "", "cd"], [1, 0], :insert]],
      ["O opens a line above", ["ab\ncd\n", [1, 0], "O"], [["ab", "", "cd"], [1, 0], :insert]]
    ]) do |input|
      h = editor(input[0])
      h.state.cursor.move_to(input[1][0], input[1][1])
      h.type(input[2])
      [h.lines, h.cursor, h.mode]
    end

    h = editor("ab\n")
    h.type("o")
    t.assert_true(h.buffer.modified?, "o marks the buffer modified")

    # The quit hint.
    h = editor("ab\n")
    h.type("<C-c>")
    t.assert_equal("Type  :q!  and press <Enter> to abandon all changes and exit Carat", h.message_row, "ctrl-c shows the quit hint")
    t.assert_equal([["ab"], [0, 0], :normal], [h.lines, h.cursor, h.mode], "ctrl-c changes nothing else")

    # A message stays until the next key.
    h = editor("ab\n")
    h.type(":foo<CR>")
    t.assert_equal("E492: Not an editor command: foo", h.message_row, "an error shows in the message row")
    t.assert_equal(["ab"], h.lines, "and changes nothing")
    h.type("l")
    t.assert_equal("", h.message_row, "the message clears on the next key")

    # Prefix waiting and timeoutlen.
    h = editor("a\nb\nc\n")
    h.type("G")
    h.type("g")
    t.assert_equal([2, 0], h.cursor, "g alone dispatches nothing")
    t.assert_equal([103], h.assembly.input.pending_keys, "g is pending")
    h.type("g")
    t.assert_equal([0, 0], h.cursor, "gg completes the sequence")
    t.assert_equal([], h.assembly.input.pending_keys, "nothing pending after gg")
    h.type("G")
    h.type("g")
    h.wait
    h.wait
    h.wait
    t.assert_equal([[2, 0], [103]], [h.cursor, h.assembly.input.pending_keys], "a lone prefix still waits after timeoutlen has passed")
    h.type("g")
    t.assert_equal([[0, 0], []], [h.cursor, h.assembly.input.pending_keys], "the second key completes the command however late it comes")
    h.type("G")
    h.type("g")
    h.wait
    h.wait
    h.wait
    h.type("<Esc>")
    t.assert_equal([[2, 0], [], :normal], [h.cursor, h.assembly.input.pending_keys, h.mode], "Escape after a waiting prefix drops it and changes nothing")

    jk = Carat::Doubles::FixedConfig.with("keymap.insert jk mode.normal\n")
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "ab\n")
    h = H.new(files: files, config: jk, rows: 10, cols: 80, plugins: [])
    h.open("a.txt")
    h.type("ij")
    t.assert_equal([["ab"], [106]], [h.lines, h.assembly.input.pending_keys], "a prefix in insert mode waits")
    h.wait
    t.assert_equal([["jab"], [], :insert], [h.lines, h.assembly.input.pending_keys, h.mode], "a prefix in insert mode is inserted as text after timeoutlen")
    h.type("jk")
    t.assert_equal(:normal, h.mode, "the insert-mode binding completes in time")

    config = Carat::Doubles::FixedConfig.with("keymap.normal a cursor.right\nkeymap.normal ab cursor.line_end\n")
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "abcdef\n")
    h = H.new(files: files, config: config, rows: 10, cols: 80, plugins: [])
    h.open("a.txt")
    h.type("a")
    t.assert_equal([0, 0], h.cursor, "ambiguous prefix waits")
    h.wait
    t.assert_equal([0, 1], h.cursor, "shorter binding fires after timeoutlen")
    h.type("ab")
    t.assert_equal([0, 5], h.cursor, "longer binding fires when completed in time")

    # Remaps: the user line that brings back the old leader w replays :w,
    # after timeoutlen, since the window group's keys begin with it.
    remap_files = Carat::Doubles::MemoryFiles.new
    remap_files.put("a.txt", "ab\n")
    h = H.new(files: remap_files, config: Carat::Doubles::FixedConfig.with_user("keymap.normal <leader>w :w<CR>\n"), rows: 10, cols: 80, plugins: [])
    h.open("a.txt")
    h.type("x<Space>w")
    h.wait
    h.wait
    h.wait
    t.assert_equal("\"a.txt\" 1L, 2B written", h.message_row, "a user binding of leader w to :w<CR> writes the file after timeoutlen, as the window group's keys follow it")
    t.assert_equal("b\n", h.files.get("a.txt"), "the file was written")
    loop_config = Carat::Doubles::FixedConfig.with_user("keymap.normal q q\n")
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "ab\n")
    h = H.new(files: files, config: loop_config, rows: 10, cols: 80, plugins: [])
    h.open("a.txt")
    h.type("q")
    t.assert_equal("E223: Recursive mapping", h.message_row, "a self-referencing remap stops")

    t.finish
  end
end

EditorNormalTest.main if __FILE__ == $0
