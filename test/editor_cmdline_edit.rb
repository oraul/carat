require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorCmdlineEditTest
  def self.editor(text)
    config = Carat::Doubles::FixedConfig.with("option.number false\noption.relativenumber false\n")
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", text)
    h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 10, cols: 60, plugins: [])
    h.open("a.txt")
    h
  end

  # The mode, the bottom row, the cursor column, and the cursor shape after
  # the keys, as one string, typed because a table value is untyped
  # (docs/spinel-notes.md).
  def self.typed(keys)
    h = editor("abc\n")
    h.type(keys.to_s)
    "#{h.mode}|#{h.message_row}|#{h.frame.cursor_col}|#{h.frame.cursor_shape}"
  end

  def self.main
    t = Carat::Testing.new("editor_cmdline_edit")

    # Rows are [label, keys, "mode|bottom row|cursor column|cursor shape"].
    t.table([
      ["Insert in the middle of the line", ":wq<Left>ab", "cmdline|:wabq|4|bar"],
      ["Left and Right move the cursor", ":abc<Left><Left>X", "cmdline|:aXbc|3|bar"],
      ["Left and Right move the cursor: Right then Y", ":abc<Left><Left>X<Right>Y", "cmdline|:aXbYc|5|bar"],
      ["The cursor stays inside the line", ":a<Right><Left><Left><Left>X", "cmdline|:Xa|2|bar"],
      ["The cursor stays inside the line: Right at the end", ":ab<Right><Right>X", "cmdline|:abX|4|bar"],
      ["Home and End", ":bc<Home>a<End>d", "cmdline|:abcd|5|bar"],
      ["Control-b and Control-e", ":bc<C-b>a<C-e>d", "cmdline|:abcd|5|bar"],
      ["Words move by blank-separated word", ":e a/b.rb c<S-Left><C-Left>X", "cmdline|:e Xa/b.rb c|4|bar"],
      ["Words move by blank-separated word: forward", ":e a/b.rb c<Home><C-Right><S-Right>Y", "cmdline|:e a/b.rb Yc|11|bar"],
      ["Words move by blank-separated word: past the last word", ":ab cd<Home><S-Right><S-Right><S-Right>X", "cmdline|:ab cdX|7|bar"],
      ["Words move by blank-separated word: back past the first", ":ab<S-Left><C-Left>X", "cmdline|:Xab|2|bar"],
      ["Movement over multi-byte and wide text", ":é日z<Left><Left>X", "cmdline|:éX日z|3|bar"],
      ["Movement over multi-byte and wide text: one Left", ":é日z<Left>X", "cmdline|:é日Xz|5|bar"],
      ["Movement over multi-byte and wide text: Home and End", ":é日z<Home>X<End>Y", "cmdline|:Xé日zY|7|bar"],
      ["Movement over multi-byte and wide text: words", ":日本 語<S-Left>X", "cmdline|:日本 X語|7|bar"],
      ["The bar is at the cursor cell", ":ab<Left>", "cmdline|:ab|2|bar"],
      ["Recall puts the cursor at the end", ":set ft?<CR>:<Up>x", "cmdline|:set ft?x|9|bar"],
      ["Recall then edit", ":set ft?<CR>:<Up><Home><Del>", "cmdline|:et ft?|1|bar"],
      ["Recall then edit: a word", ":set ft?<CR>:<Up><C-w>X", "cmdline|:set ftX|8|bar"],
      ["Backspace removes before the cursor", ":abc<Left><BS>", "cmdline|:ac|2|bar"],
      ["Backspace at the start does nothing", ":a<Home><BS>", "cmdline|:a|1|bar"],
      ["Backspace at the start does nothing: then Backspace after a Right", ":a<Home><BS><Right><BS>", "cmdline|:|1|bar"],
      ["Delete removes the character under the cursor", ":abc<Home><Del>", "cmdline|:bc|1|bar"],
      ["Delete removes the character under the cursor: in the middle", ":abc<Left><Left><Del>", "cmdline|:ac|2|bar"],
      ["Delete at the end acts as Backspace", ":ab<Del>", "cmdline|:a|2|bar"],
      ["Control-w removes the word before the cursor", ":e app/models<C-w>", "cmdline|:e app/|7|bar"],
      ["Control-w removes the word before the cursor: second", ":e app/models<C-w><C-w>", "cmdline|:e app|6|bar"],
      ["Control-w removes the word before the cursor: third", ":e app/models<C-w><C-w><C-w>", "cmdline|:e|3|bar"],
      ["Control-w removes the word before the cursor: fourth", ":e app/models<C-w><C-w><C-w><C-w>", "cmdline|:|1|bar"],
      ["Control-w works at the cursor in the middle", ":ab cd<Left><Left><C-w>", "cmdline|:cd|1|bar"],
      ["Control-w works at the cursor in the middle: typing goes before the rest", ":ab cd<Left><Left><C-w>X", "cmdline|:Xcd|2|bar"],
      ["Control-u removes everything before the cursor", ":abcd<Left><Left><C-u>", "cmdline|:cd|1|bar"],
      ["Control-u removes everything before the cursor: at the end", ":abcd<C-u>", "cmdline|:|1|bar"],
      ["Control-w and Control-u on an empty line do nothing", ":<C-w><C-u>", "cmdline|:|1|bar"],
      ["Control-w over wide text", ":é日本<C-w>", "cmdline|:|1|bar"],
      ["Backspace on empty leaves", ":<BS>", "normal||0|block"],
      ["Delete at the end acts as Backspace: on an empty line it leaves", ":<Del>", "normal||0|block"],
      ["A visual range opens with the cursor at its end", "V:", "cmdline|:'<,'>|6|bar"],
      ["The command line keeps the cursor after an Esc and a new colon", ":ab<Left><Esc>:x", "cmdline|:x|2|bar"],
      ["A visual range after an Esc has the cursor at its end", ":ab<Home><Esc>V:", "cmdline|:'<,'>|6|bar"],
      ["The palette's prompt has the cursor", "<F1>sp<Left>x", "cmdline||7|bar"],
      ["The search prompt has the cursor", "/ac<Left>b", "cmdline|/abc|3|bar"],
      ["The search prompt: Control-u", "/abc<Left><C-u>", "cmdline|/c|1|bar"]
    ]) { |keys| typed(keys) }

    # Scenario: An unbound Ctrl or Shift arrow acts as the plain arrow.
    h = editor("abc\n")
    h.type("<C-Right>")
    t.assert_equal([0, 1], h.cursor, "An unbound Ctrl or Shift arrow acts as the plain arrow: Ctrl-Right moves right")
    h.type("<S-Right><S-Left><C-Left>")
    t.assert_equal([0, 0], h.cursor, "An unbound Ctrl or Shift arrow acts as the plain arrow: Shift and Ctrl back")
    h.type("i<C-Right>X<Esc>")
    t.assert_equal(["aXbc"], h.lines[0, 1], "An unbound Ctrl or Shift arrow acts as the plain arrow: in insert mode")

    # Scenario: The search prompt has the cursor (the preview follows the text).
    h = editor("xabc\nab\n")
    h.type("/ac<Left>b")
    t.assert_equal([0, 1], h.cursor, "The search prompt has the cursor: the preview matches abc")
    h.type("<Left><Left><Del>")
    t.assert_equal(["cmdline", "/bc", 1], [h.mode.to_s, h.message_row, h.frame.cursor_col], "The search prompt has the cursor: a deletion at the cursor")
    t.assert_equal([0, 2], h.cursor, "The search prompt previews after a deletion: the match of bc")
    h.type("<End><BS>")
    t.assert_equal([0, 2], h.cursor, "The search prompt previews after a deletion: the match of b")
    h.type("<CR>")
    t.assert_equal([:normal, [0, 2]], [h.mode, h.cursor], "The search prompt previews after a deletion: Enter searches the edited text")

    # A line edited by the keys runs as edited.
    h = editor("abc\n")
    h.type(":eb.txt<Home><Right> <CR>")
    t.assert_equal("b.txt", h.state.buffer.path, "An edited command line runs as edited")

    t.finish
  end
end

EditorCmdlineEditTest.main if __FILE__ == $0
