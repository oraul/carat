require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module AdaptersIndentGuidesTest
  D = Carat::Domain
  H = Carat::Domain::Highlight
  UI = Carat::Domain::PluginUi.new
  CACHE = Carat::Domain::LineCache.new
  LISTED = Carat::Domain::BufferList.new(tabs: Carat::Domain::TabList.new(window: Carat::Domain::Window.new(buffer: Carat::Domain::Buffer.new(lines: [""], path: nil, line_ending: "\n"))))
  ARRANGE = Carat::UseCases::ArrangeView.new(cache: CACHE, buffers: LISTED)
  P = Carat::Adapters::FramePresenter.new(input: Carat::Domain::InputState.new, plugin_ui: UI, cache: CACHE, last_search: Carat::Domain::LastSearch.new, search_prompt: Carat::Domain::SearchPrompt.new, palette: Carat::Domain::Palette.new, start_screen: Carat::Domain::StartScreen.new, status_bar: Carat::Adapters::StatusBar.new(plugin_ui: UI, slots: Carat::Domain::StatusSlots.new), tab_bar: Carat::Adapters::TabBar.new(buffers: LISTED), winbar: Carat::Adapters::Winbar.new(symbols: Carat::Domain::SymbolRequest.new), notices: Carat::Domain::Notices.new(history: Carat::Domain::MessageHistory.new))

  ROWS = 10
  COLS = 16

  # A file window over the lines, no gutter, tabstop 4, shiftwidth 2, the
  # guides on, the cursor at its row and column.
  #: (Array[String], Integer, Integer) -> Carat::Domain::EditorState
  def self.state_for(lines, row, col)
    buffer = D::Buffer.new(lines: lines, path: "a.txt", line_ending: "\n")
    options = D::Options.new
    options.tabstop = 4
    options.shiftwidth = 2
    options.indentguides = true
    options.breadcrumbs = "never"
    state = D::EditorState.new(tabs: D::TabList.new(window: D::Window.new(buffer: buffer)), options: options)
    state.cursor.move_to(row, col)
    state
  end

  #: (Carat::Domain::EditorState) -> Carat::Domain::Frame
  def self.draw(state)
    state.resize(ROWS, COLS)
    ARRANGE.call(state)
    P.call(state)
  end

  # The first rows of a frame as text, a guide cell in IblIndent as | and
  # one in IblScope as !, whatever its character, trailing blanks cut.
  #: (Carat::Domain::Frame, Integer) -> Array[String]
  def self.marks(frame, rows)
    out = []
    r = 0
    while r < rows
      line = +""
      c = 0
      while c < COLS
        cell = frame.cell(r, c)
        hl = H.base(cell.hl)
        if hl == H::INDENT_GUIDE
          line << "|"
        elsif hl == H::INDENT_GUIDE_SCOPE
          line << "!"
        elsif cell.code > 32 && cell.code < 127
          line << cell.code.chr
        else
          line << " "
        end
        c += 1
      end
      out << line.rstrip
      r += 1
    end
    out
  end

  NESTED = ["x", "  a", "    b", "    c", "    d", "  e", "f"]

  # The guides a case draws, as marks of its first rows.
  #: (String) -> Array[String]
  def self.guides(name)
    case name
    when "levels"
      marks(draw(state_for(["a", "    b", "  c"], 0, 0)), 3)
    when "shiftwidth 0"
      s = state_for(["x", "        y"], 0, 0)
      s.options.shiftwidth = 0
      marks(draw(s), 2)
    when "tab"
      marks(draw(state_for(["x", "\ty"], 0, 0)), 2)
    when "scrolled"
      s = state_for(["x", "    b" + "z" * 20], 1, 4)
      s.resize(ROWS, COLS)
      ARRANGE.call(s)
      s.window.left = 1
      marks(P.call(s), 2)
    when "blank inside"
      marks(draw(state_for(["x", "    b", "", "    c"], 0, 0)), 4)
    when "blank before dedent"
      marks(draw(state_for(["x", "    b", "", "  c"], 0, 0)), 4)
    when "whitespace only"
      marks(draw(state_for(["x", "    b", "      ", "    c"], 0, 0)), 4)
    when "blank at the end"
      marks(draw(state_for(["x", "    b", ""], 0, 0)), 3)
    when "nested"
      marks(draw(state_for(NESTED, 3, 4)), 7)
    when "top level"
      marks(draw(state_for(NESTED, 0, 0)), 7)
    when "blank cursor"
      marks(draw(state_for(["x", "  a", "    b", "", "    c", "y"], 3, 0)), 6)
    when "moves"
      s = state_for(NESTED, 3, 4)
      draw(s)
      draw(s)
      s.cursor.move_to(1, 2)
      marks(draw(s), 7)
    when "j inside"
      s = state_for(NESTED, 2, 4)
      draw(s)
      s.cursor.move_to(3, 4)
      f = draw(s)
      s.cursor.move_to(4, 4)
      f = draw(s)
      # Only the row the cursor left and the row it entered changed.
      [f.dirty_rows.to_s]
    when "off"
      s = state_for(["x", "    b"], 0, 0)
      s.options.indentguides = false
      marks(draw(s), 2)
    when "turned off"
      s = state_for(["x", "    b"], 0, 0)
      draw(s)
      draw(s)
      s.options.indentguides = false
      marks(draw(s), 2)
    when "plugin"
      s = state_for(["x", "    b"], 0, 0)
      s.window.buffer.owner = "explorer"
      marks(draw(s), 2)
    when "float"
      s = state_for(["x", "    b", "    c", "    d", "    e"], 0, 0)
      spec = D::FloatSpec.new(anchor: "editor", row: 2, col: 2, height: 2, width: 10, border: false, title: "", z: 50)
      float = D::FloatWindow.new(window: D::Window.new(buffer: D::Buffer.new(lines: ["    f", "    g"], path: nil, line_ending: "\n")), spec: spec)
      s.tab.floats.add(float, false)
      marks(draw(s), 5)
    else
      []
    end
  end

  # The code point of the cell at row 1, column 0 of a case.
  #: (String) -> Integer
  def self.glyph(name)
    s = state_for(["x", "    b"], 0, 0)
    case name
    when "default"
      s.options.indentguides = true
    when "another"
      s.options.indentguides_char = "▏"
    when "ascii"
      s.options.icons = "ascii"
    when "ascii kept"
      s.options.icons = "ascii"
      s.options.indentguides_char = ":"
    end
    draw(s).cell(1, 0).code
  end

  def self.main
    t = Carat::Testing.new("adapters_indent_guides")

    # The guides of the indent-guides spec: rows are [label, case, the
    # first rows with IblIndent guides as | and IblScope as !].
    t.table([
      ["Guides at each level: columns 0 and 2 of four spaces, shiftwidth 2", "levels", ["a", "| | b", "| c"]],
      ["Shiftwidth 0 uses tabstop", "shiftwidth 0", ["x", "|   |   y"]],
      ["A tab indent: one tab at tabstop 4 has guides at 0 and 2", "tab", ["x", "| | y"]],
      ["Scrolled sideways: one column right, column 2's guide, the cursor's block, at the first text column plus 1", "scrolled", ["", " ! bzzzzzzzzzzzz"]],
      ["A blank line inside a block carries both guides", "blank inside", ["x", "| | b", "| |", "| | c"]],
      ["A blank line before a dedent carries the smaller indent", "blank before dedent", ["x", "| | b", "|", "| c"]],
      ["a whitespace-only line carries the indent around it, not its own", "whitespace only", ["x", "| | b", "| |", "| | c"]],
      ["a blank line with no text below has no guide", "blank at the end", ["x", "| | b", ""]],
      ["The cursor in a nested block: column 2 in IblScope over its three lines", "nested", ["x", "| a", "| ! b", "| ! c", "| ! d", "| e", "f"]],
      ["The cursor at the top level highlights no guide", "top level", ["x", "| a", "| | b", "| | c", "| | d", "| e", "f"]],
      ["a cursor on a blank line takes its carried indent", "blank cursor", ["x", "| a", "| ! b", "| !", "| ! c", "y"]],
      ["The cursor moves to another block: the rows are repainted", "moves", ["x", "! a", "! | b", "! | c", "! | d", "! e", "f"]],
      ["j inside one block dirties only the rows the cursor left and entered", "j inside", ["[3, 4]"]],
      ["Off draws none", "off", ["x", "    b"]],
      ["turning the guides off repaints every row", "turned off", ["x", "    b"]],
      ["A plugin's window draws no guide", "plugin", ["x", "    b"]],
      ["A float shows no guide over a file window", "float", ["x", "| | b", "|     f", "|     g", "| | e"]]
    ]) { |name| guides(name.to_s) }

    # The guide character: rows are [label, case, the code point drawn].
    t.table([
      ["the default guide is ┊", "default", 0x250a],
      ["Another character: ▏", "another", 0x258f],
      ["The ASCII fallback: | with the ascii icon set", "ascii", 124],
      ["An ASCII character is kept with the ascii icon set", "ascii kept", 58]
    ]) { |name| glyph(name.to_s) }

    # On the cursor line: the guides are drawn on the cursor-line layer
    # of their groups.
    s = state_for(NESTED, 3, 4)
    s.options.cursorline = true
    f = draw(s)
    lit = H::CURSOR_LINE_LAYER
    t.assert_equal([H::INDENT_GUIDE + lit, H::INDENT_GUIDE_SCOPE + lit, H::INDENT_GUIDE, H::INDENT_GUIDE_SCOPE], [f.cell(3, 0).hl, f.cell(3, 2).hl, f.cell(2, 0).hl, f.cell(2, 2).hl], "On the cursor line the guides take the cursor-line layer of their groups")

    t.finish
  end
end

AdaptersIndentGuidesTest.main if __FILE__ == $0
