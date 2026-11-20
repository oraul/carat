require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module AdaptersWhitespaceMarksTest
  D = Carat::Domain
  H = Carat::Domain::Highlight
  UI = Carat::Domain::PluginUi.new
  CACHE = Carat::Domain::LineCache.new
  LISTED = Carat::Domain::BufferList.new(tabs: Carat::Domain::TabList.new(window: Carat::Domain::Window.new(buffer: Carat::Domain::Buffer.new(lines: [""], path: nil, line_ending: "\n"))))
  ARRANGE = Carat::UseCases::ArrangeView.new(cache: CACHE, buffers: LISTED)
  P = Carat::Adapters::FramePresenter.new(input: Carat::Domain::InputState.new, plugin_ui: UI, cache: CACHE, last_search: Carat::Domain::LastSearch.new, search_prompt: Carat::Domain::SearchPrompt.new, palette: Carat::Domain::Palette.new, start_screen: Carat::Domain::StartScreen.new, status_bar: Carat::Adapters::StatusBar.new(plugin_ui: UI, slots: Carat::Domain::StatusSlots.new), tab_bar: Carat::Adapters::TabBar.new(buffers: LISTED), winbar: Carat::Adapters::Winbar.new(symbols: Carat::Domain::SymbolRequest.new), notices: Carat::Domain::Notices.new(history: Carat::Domain::MessageHistory.new))

  ROWS = 10
  COLS = 16
  SHIPPED = "tab:→ ,trail:·,nbsp:␣"
  # A tab, a, a no-break space, b, and two trailing spaces; a line of
  # spaces only; an empty line.
  MIXED = ["\ta b  ", "   ", ""]

  # A file window over the lines, no gutter, tabstop 4, the guides off,
  # list on with the shipped listchars, the cursor at its row and column.
  #: (Array[String], Integer, Integer) -> Carat::Domain::EditorState
  def self.state_for(lines, row, col)
    buffer = D::Buffer.new(lines: lines, path: "a.txt", line_ending: "\n")
    options = D::Options.new
    options.tabstop = 4
    options.breadcrumbs = "never"
    options.list = true
    options.listchars = SHIPPED
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

  # The first rows of a frame, each as its text (the marks as themselves,
  # other ASCII as is, any other code point ?, trailing blanks cut) and
  # its groups (w for a cell in Whitespace, a blank otherwise, trailing
  # blanks cut).
  #: (Carat::Domain::Frame, Integer) -> Array[String]
  def self.rows_of(frame, rows)
    out = []
    r = 0
    while r < rows
      text = +""
      groups = +""
      c = 0
      while c < COLS
        cell = frame.cell(r, c)
        text << cell_text(cell.code)
        groups << (H.base(cell.hl) == H::WHITESPACE ? "w" : " ")
        c += 1
      end
      out << text.rstrip
      out << groups.rstrip
      r += 1
    end
    out
  end

  # A code point as one character: the shipped marks as themselves,
  # a guide as |, a
  # no-break space, a blank, or a control as a blank, printable ASCII as
  # is, the rest ?.
  #: (Integer) -> String
  def self.cell_text(code)
    return "→" if code == 0x2192
    return "·" if code == 0xb7
    return "␣" if code == 0x2423
    return "|" if code == 0x250a || code == 0x2502
    return " " if code == 0xa0 || code == 0x202f
    return code.chr if code > 32 && code < 127
    return " " if code <= 32
    "?"
  end

  # The rows a case draws, text and groups alternating. Each case starts
  # a new state, but MIXED's strings are the same objects, so a case
  # also proves the rows the case before drew are repainted.
  #: (String) -> Array[String]
  def self.rows_for(name)
    case name
    when "on"
      rows_of(draw(state_for(MIXED, 0, 0)), 3)
    when "off"
      s = state_for(MIXED, 0, 0)
      s.options.list = false
      rows_of(draw(s), 3)
    when "tab last"
      s = state_for(["\tx", "abc\ty"], 0, 0)
      s.options.listchars = "tab:<->"
      rows_of(draw(s), 2)
    when "scrolled"
      s = state_for(["\tab  " + "z" * 20, "abcd  "], 0, 6)
      s.resize(ROWS, COLS)
      ARRANGE.call(s)
      s.window.left = 2
      rows_of(P.call(s), 2)
    when "left out"
      s = state_for(["\tx "], 0, 0)
      s.options.listchars = "trail:-"
      rows_of(draw(s), 1)
    when "ascii"
      s = state_for(MIXED, 0, 0)
      s.options.icons = "ascii"
      rows_of(draw(s), 1)
    when "multibyte"
      rows_of(draw(state_for(["é\t   ", "a b"], 0, 0)), 2)
    when "over a guide"
      s = state_for(["\tx", "    y"], 0, 0)
      s.options.indentguides = true
      s.options.shiftwidth = 4
      rows_of(draw(s), 2)
    when "plugin"
      s = state_for(MIXED, 0, 0)
      s.window.buffer.owner = "explorer"
      rows_of(draw(s), 1)
    when "fold"
      s = state_for(["x y  ", "z", "w  "], 2, 0)
      s.window.folds.create(0, 1)
      s.window.folds.close_at(0)
      rows_of(draw(s), 2)
    when "after a plugin window"
      s = state_for(MIXED, 0, 0)
      s.window.buffer.owner = "explorer"
      draw(s)
      draw(s)
      s.window.buffer.owner = ""
      rows_of(draw(s), 1)
    when "no color"
      P.plain = true
      rows = rows_of(draw(state_for(MIXED, 0, 0)), 1)
      P.plain = false
      rows
    when "turned on"
      s = state_for(MIXED, 0, 0)
      s.options.list = false
      draw(s)
      draw(s)
      s.options.list = true
      rows_of(draw(s), 1)
    when "changed"
      s = state_for(MIXED, 0, 0)
      draw(s)
      draw(s)
      s.options.listchars = "tab:<->,trail:~,nbsp:%"
      rows_of(draw(s), 1)
    when "icons switched"
      s = state_for(MIXED, 0, 0)
      draw(s)
      draw(s)
      s.options.icons = "ascii"
      rows_of(draw(s), 1)
    else
      ["unknown case #{name}"]
    end
  end

  def self.main
    t = Carat::Testing.new("adapters_whitespace_marks")

    # The whitespace-marks spec: rows are [label, case, the first rows,
    # each as its text and then its groups (w for Whitespace)].
    t.table([
      ["Marks with list on: the tab's first mark and blanks, ␣, two ·, a line of spaces all trailing, an empty line none", "on", ["→   a␣b··", "wwww w ww", "···", "www", "", ""]],
      ["No marks with list off", "off", ["    a b", "", "", "", "", ""]],
      ["A tab with a last mark: <--> over four cells, > alone on one", "tab last", ["<-->x", "wwww", "abc>y", "   w"]],
      ["Marks move with the horizontal scroll: the tab's visible cells, then the trail of a plain line", "scrolled", ["  ab  zzzzzzzzzz", "ww", "cd··", "  ww"]],
      ["A key left out draws no mark: the tab blank, the trailing space -", "left out", ["    x-", "     w"]],
      ["The ASCII marks: > and blanks, +, -- with no code point above 127", "ascii", [">   a+b--", "wwww w ww"]],
      ["Multi-byte: a tab after é, a space before a no-break space is not trailing, U+202F marked", "multibyte", ["?→   ␣·", " www ww", "a␣b", " w"]],
      ["A tab's mark shows over an indent guide; spaces keep the guide", "over a guide", ["→   x", "wwww", "|   y", ""]],
      ["A plugin window draws no marks", "plugin", ["    a b", ""]],
      ["A closed fold's row draws no marks; the row after it does", "fold", ["+--  2 lines: x", "", "w··", " ww"]],
      ["A row drawn in a plugin window draws its marks once the buffer is a file's", "after a plugin window", ["→   a␣b··", "wwww w ww"]],
      ["Marks under NO_COLOR", "no color", ["→   a␣b··", "wwww w ww"]],
      ["Turning list on repaints the rows drawn without marks", "turned on", ["→   a␣b··", "wwww w ww"]],
      ["A new listchars repaints the rows", "changed", ["<-->a%b~~", "wwww w ww"]],
      ["Switching to the ascii icon set repaints the marks", "icons switched", [">   a+b--", "wwww w ww"]]
    ]) do |name|
      rows_for(name.to_s)
    end

    t.finish
  end
end

AdaptersWhitespaceMarksTest.main if __FILE__ == $0
