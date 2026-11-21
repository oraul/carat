require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# <Tab> and <S-Tab> at the `:` prompt over a working directory in memory
# (/project) holding a.txt, lib/ with a.rb and b.rb, "my notes.txt",
# .hidden, and wide/ with 1001 entries, beside /tmp-free paths above it.
module EditorCmdlineCompleteTest
  D = Carat::Domain

  def self.editor
    config = Carat::Doubles::FixedConfig.with("option.number false\noption.relativenumber false\n")
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "abc\n")
    files.put("lib/a.rb", "a\n")
    files.put("lib/b.rb", "b\n")
    files.put("my notes.txt", "n\n")
    files.put(".hidden", "h\n")
    files.put("/up.txt", "u\n")
    files.put("/home/user/home.rb", "h\n")
    h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 20, cols: 60, plugins: [])
    h.open("a.txt")
    h
  end

  # The mode, the bottom row, the cursor column, and the labels of the
  # popup's rows (" " between them, "-" for none) after the keys, as one
  # string, typed because a table value is untyped (docs/spinel-notes.md).
  def self.typed(keys)
    h = editor
    h.type(keys.to_s)
    "#{h.mode}|#{h.message_row}|#{h.frame.cursor_col}|#{popup(h)}"
  end

  # The rows of the popup joined by ",", "-" when none shows.
  def self.popup(h)
    menu = h.assembly.cmdline_menu
    return "-" unless menu.showing?
    float = h.state.tab.floats.at(0)
    buffer = float.window.buffer
    out = []
    i = 0
    while i < buffer.line_count
      out << buffer.line(i)
      i += 1
    end
    out.join(",")
  end

  def self.main
    t = Carat::Testing.new("editor_cmdline_complete")

    # Rows are [label, keys, "mode|bottom row|cursor column|popup rows"].
    t.table([
      ["Tab completes a command name", ":vs<Tab>", "cmdline|:vsplit|7|vsplit"],
      ["Tab completes a command name: tabe", ":tabe<Tab>", "cmdline|:tabedit|8|tabedit"],
      ["Tab completes a command name: Shift-Tab takes the last", ":vs<S-Tab>", "cmdline|:vsplit|7|vsplit"],
      ["Many matches", ":tab<Tab>", "cmdline|:tabnew|7|tabnew,tabedit,tabclose,tabonly,tabnext,tabprevious,tabNext,tabfirst,tablast"],
      ["Cycling back", ":vs<Tab><Tab>", "cmdline|:vs|3|vsplit"],
      ["Cycling back: Shift-Tab from the typed text", ":vs<Tab><Tab><S-Tab>", "cmdline|:vsplit|7|vsplit"],
      ["Cycling back: through every match", ":tabc<Tab>", "cmdline|:tabclose|9|tabclose"],
      ["A directory", ":e li<Tab>", "cmdline|:e lib/|7|lib/"],
      ["A file", ":e lib/<Tab>", "cmdline|:e lib/a.rb|11|a.rb,b.rb"],
      ["A file: the next match", ":e lib/<Tab><Tab>", "cmdline|:e lib/b.rb|11|a.rb,b.rb"],
      ["A file: back to the typed text", ":e lib/<Tab><Tab><Tab>", "cmdline|:e lib/|7|a.rb,b.rb"],
      ["A file: every entry of the working directory, no dot file", ":e <Tab>", "cmdline|:e a.txt|8|a.txt,lib/,my notes.txt"],
      ["A file: a dot file for a typed dot", ":e .<Tab>", "cmdline|:e .hidden|10|.hidden"],
      ["A file: after w, sp, vs, and tabe", ":sp lib/b<Tab>", "cmdline|:sp lib/b.rb|12|b.rb"],
      ["A file: after a bang", ":w! lib/b<Tab>", "cmdline|:w! lib/b.rb|12|b.rb"],
      ["A path with a space", ":e my<Tab>", "cmdline|:e my notes.txt|15|my notes.txt"],
      ["A path with a space: completed past the space", ":e my n<Tab>", "cmdline|:e my notes.txt|15|my notes.txt"],
      ["A path outside the working directory as typed", ":e ../u<Tab>", "cmdline|:e ../up.txt|12|up.txt"],
      ["A path outside the working directory as typed: absolute", ":e /u<Tab>", "cmdline|:e /up.txt|10|up.txt"],
      ["A path outside the working directory as typed: home", ":e ~/h<Tab>", "cmdline|:e ~/home.rb|12|home.rb"],
      ["A path outside the working directory as typed: not otherwise", ":e u<Tab>", "cmdline|:e u|4|No matches  Esc close"],
      ["No match", ":e zz<Tab>", "cmdline|:e zz|5|No matches  Esc close"],
      ["No match: Tab again keeps the line", ":e zz<Tab><Tab>", "cmdline|:e zz|5|No matches  Esc close"],
      ["No match: no command begins so", ":zq<Tab>", "cmdline|:zq|3|No matches  Esc close"],
      ["An argument of another command is not completed", ":set ft<Tab>", "cmdline|:set ft|7|-"],
      ["Completing in the middle of the line", ":vsx<Home><Right><Right><Tab>", "cmdline|:vsplitx|7|vsplit"],
      ["Escape closes the menu first", ":e lib/<Tab><Esc>", "cmdline|:e lib/a.rb|11|-"],
      ["Escape closes the menu first: a second Escape leaves", ":e lib/<Tab><Esc><Esc>", "normal||0|-"],
      ["Typing closes the menu", ":e lib/<Tab>x", "cmdline|:e lib/a.rbx|12|-"],
      ["Typing closes the menu: a cursor move", ":e lib/<Tab><Left>", "cmdline|:e lib/a.rb|10|-"],
      ["Typing closes the menu: a deletion", ":e lib/<Tab><BS>", "cmdline|:e lib/a.r|10|-"],
      ["Typing closes the menu: a Tab after it completes afresh", ":e lib/<Tab><BS><Tab>", "cmdline|:e lib/a.rb|11|a.rb"],
      ["Tab at another prompt does nothing", "/a<Tab>", "cmdline|/a|2|-"],
      ["Tab at another prompt does nothing: the palette", "<F1>sp<Tab>", "cmdline|>sp|3|-"]
    ]) { |keys| typed(keys) }

    # Scenario: The bounded directory read: 1001 entries, 1000 read.
    h = editor
    i = 0
    while i < 1001
      h.files.put("wide/f#{i}.txt", "")
      i += 1
    end
    h.type(":e wide/<Tab>")
    t.assert_equal(1000, h.assembly.cmdline_menu.matches.length, "The bounded directory read offers 1000 of 1001 entries")

    # Scenario: The popup stands above the command line.
    h = editor
    h.type(":e lib/<Tab>")
    float = h.state.tab.floats.at(0)
    # Rows 0 to 17 are the window and its status bar's row is 18 above
    # the command line's 19; ":e lib/" puts the last name at column 7.
    t.assert_equal([true, 14, 18, 15, 7], [float.edged?, float.box_top, float.box_bottom, float.window.row, float.window.col], "The popup stands above the command line: bordered, ending above the status bar, its text under the word's last name")
    t.assert_equal([D::Highlight::POPUP_MENU_SELECTED, D::Highlight::POPUP_MENU, "a.rb", "b.rb"], [h.frame.hl_at(15, 7), h.frame.hl_at(16, 7), h.row(15)[7, 4].to_s, h.row(16)[7, 4].to_s], "The popup stands above the command line: the match in PmenuSel, the others in Pmenu")
    h = editor
    h.type(":tab<Tab>")
    float = h.state.tab.floats.at(0)
    top = float.window.row
    col = float.window.col
    # A style on a float is drawn on the float layer; a box at the left
    # keeps the editor's margin, so its text starts at column 3.
    layer = D::Highlight::FLOAT_LAYER
    t.assert_equal([layer + D::Highlight::POPUP_MENU_MATCH_SELECTED, D::Highlight::POPUP_MENU_SELECTED, layer + D::Highlight::POPUP_MENU_MATCH, D::Highlight::POPUP_MENU, 3], [h.frame.hl_at(top, col + 2), h.frame.hl_at(top, col + 3), h.frame.hl_at(top + 1, col + 2), h.frame.hl_at(top + 1, col + 3), col], "The popup stands above the command line: the typed characters in PmenuMatch")
    h = editor
    h.type(":e lib/<Tab>")
    h.type("<Tab><Tab>")
    float = h.state.tab.floats.at(0)
    t.assert_equal([true, -1], [float.menu?, h.assembly.cmdline_menu.selected], "The popup stands above the command line: the typed text keeps the rows a menu, none selected")

    # <C-n> and <C-p> keep the palette's meaning at the > prompt.
    h = editor
    h.type("<F1><C-n>")
    t.assert_equal([1, false], [h.assembly.palette.selected, h.assembly.cmdline_menu.showing?], "Tab at another prompt does nothing: Ctrl-N moves the palette")

    t.finish
  end
end

EditorCmdlineCompleteTest.main if __FILE__ == $0
