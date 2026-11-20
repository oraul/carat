require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# Breadcrumbs: the winbar of file windows and the cursor's symbol path,
# the whole editor over the production gateway and the doubles,
# FakeProcesses recording what is sent and MemoryQueue carrying what the
# server answers. Every idle read advances the manual clock by its
# timeout.
module EditorBreadcrumbsTest
  J = Carat::Json
  D = Carat::Domain
  H = Carat::Domain::Highlight
  # a.rb's file URI, its slashes joined here so no link appears in the
  # source.
  A_URI = "file:" + "/" * 3 + "project/a.rb"
  SOURCE = "class Foo\n  def bar\n    1\n  end\nend\nx = 1\n"
  OUTLINE = [{ "name" => "Foo", "range" => { "start" => { "line" => 0, "character" => 0 }, "end" => { "line" => 4, "character" => 3 } }, "children" => [{ "name" => "bar", "range" => { "start" => { "line" => 1, "character" => 2 }, "end" => { "line" => 3, "character" => 5 } } }] }]

  # The editor with readers for the doubles and the last frame.
  class Rig
    attr_reader :clock #: Carat::Doubles::ManualClock
    attr_reader :processes #: Carat::Doubles::FakeProcesses
    attr_reader :messages #: Carat::Doubles::MemoryQueue
    attr_reader :assembly #: Carat::Adapters::EditorAssembly
    attr_reader :terminal #: Carat::Doubles::FakeTerminal
    attr_reader :frame #: Carat::Domain::Frame

    #: (clock: Carat::Doubles::ManualClock, terminal: Carat::Doubles::FakeTerminal, processes: Carat::Doubles::FakeProcesses, messages: Carat::Doubles::MemoryQueue, assembly: Carat::Adapters::EditorAssembly) -> void
    def initialize(clock:, terminal:, processes:, messages:, assembly:)
      @clock = clock
      @terminal = terminal
      @processes = processes
      @messages = messages
      @assembly = assembly
      @frame = assembly.render(12, 40)
    end

    # Types keys in Vim notation, one read per key.
    #: (String) -> void
    def type(notation)
      codes = D::KeyNotation.parse(notation, "").codes
      i = 0
      while i < codes.length
        @terminal.push(Carat::Adapters::KeyDecoder.encode(codes[i]))
        pump
        pump while @assembly.controller.decoder.pending?
        i += 1
      end
    end

    # One read with no key: an idle tick.
    #: () -> void
    def wait
      pump
    end

    #: () -> void
    def pump
      @assembly.controller.pump(@assembly.state)
      @frame = @assembly.render(12, 40)
    end

    #: (Integer) -> String
    def row(index)
      @frame.text_rows[index].to_s
    end

    #: () -> Integer
    def symbols_sent
      @processes.methods_sent.count("textDocument/documentSymbol")
    end

    #: () -> Integer
    def cursor_row
      @assembly.state.window.cursor.row
    end
  end

  # An editor over a.rb in the trusted /project with ruby-lsp installed
  # and the user lines given, its initialize answered with the
  # capabilities given.
  def self.rig(lines, capabilities)
    files = Carat::Doubles::MemoryFiles.new
    files.move_to("/project")
    files.put("a.rb", SOURCE)
    files.put("b.txt", "bee\n")
    clock = Carat::Doubles::ManualClock.new
    terminal = Carat::Doubles::FakeTerminal.new(clock: clock, rows: 12, cols: 40)
    processes = Carat::Doubles::FakeProcesses.new
    processes.install("ruby-lsp")
    messages = Carat::Doubles::MemoryQueue.new
    completions = Carat::Adapters::ServerCompletions.new
    config = Carat::Doubles::FixedConfig.new(value: Carat::Doubles::FixedConfig.with_user("language.trusted_roots /project\noption.icons ascii\noption.number false\n" + lines.to_s))
    assembly = Carat::Adapters::EditorAssembly.new(terminal: terminal, clock: clock, files: files, config: config, processes: processes, messages: messages, completions: completions, plugin_list: [])
    r = Rig.new(clock: clock, terminal: terminal, processes: processes, messages: messages, assembly: assembly)
    assembly.screen_presenter.enter
    assembly.open("a.rb")
    r.wait
    init = { "capabilities" => capabilities, "serverInfo" => { "name" => "ruby-lsp" } }
    messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => 1, "result" => init }))
    r.wait
    r
  end

  # An editor whose current window shows a scratch buffer, a slot's as
  # the explorer's, with the user lines given and a server without
  # capabilities.
  def self.scratch_rig(lines)
    r = rig(lines, {})
    scratch = D::Buffer.from_text("tree\n", nil)
    scratch.owner = "explorer"
    r.assembly.state.window.show(scratch)
    r.wait
    r
  end

  # A server offering document symbols, with the user lines given.
  def self.outlining(lines)
    rig(lines, { "documentSymbolProvider" => true })
  end

  # The last body sent with the method, parsed, or nil.
  def self.last_of(r, name)
    bodies = r.processes.bodies
    i = bodies.length - 1
    while i >= 0
      value = J.parse(bodies[i].to_s)
      return value if J.field(value, "method") == name.to_s
      i -= 1
    end
    nil
  end

  # The id of the last symbol request sent.
  def self.symbol_id(r)
    J.field(last_of(r, "textDocument/documentSymbol"), "id").to_i
  end

  # Answers the request with the id with the result, then an idle tick.
  def self.answer(r, id, result)
    r.messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => id, "result" => result }))
    r.wait
    nil
  end

  # The text of a frame row from col, cut to width.
  def self.cut(r, index, col, width)
    r.row(index)[col, width].to_s.rstrip
  end

  # A symbol named name over the rows from first to last, in the flat
  # SymbolInformation form.
  def self.flat(name, first, last)
    { "name" => name, "kind" => 5, "location" => { "uri" => A_URI, "range" => { "start" => { "line" => first, "character" => 0 }, "end" => { "line" => last, "character" => 0 } } } }
  end

  def self.main
    t = Carat::Testing.new("editor_breadcrumbs")

    # Counting file windows and the modes, on a tab page.
    tab = D::TabPage.new(window: D::Window.new(buffer: D::Buffer.from_text("one\n", "a.txt")))
    t.assert_equal([1, false, true, false], [tab.file_window_count, tab.winbar?("auto"), tab.winbar?("always"), tab.winbar?("never")], "one file window shows a winbar only with always")
    tab.layout.arrange(0, 0, 20, 80)
    other = tab.layout.split(0, true, 0, 1)
    t.assert_equal([2, true, true, false], [tab.file_window_count, tab.winbar?("auto"), tab.winbar?("always"), tab.winbar?("never")], "two file windows show winbars but with never")
    tab.layout.window_at(other).buffer = D::Buffer.from_text("tree\n", nil)
    tab.layout.window_at(other).buffer.owner = "explorer"
    t.assert_equal([1, false], [tab.file_window_count, tab.winbar?("auto")], "a window on a scratch buffer, a slot's or a plugin's, is not a file window")
    leaves = tab.layout.leaves
    file_leaf = leaves[0] == other ? leaves[1] : leaves[0]
    t.assert_equal([false, false], [tab.side_window?(file_leaf), tab.side_window?(other)], "a window on a scratch buffer outside a slot, as a reading view is, is not a side window")
    tab.slot(:left).attach(tab.layout.window_at(other), "explorer", 20)
    t.assert_equal([false, true], [tab.side_window?(file_leaf), tab.side_window?(other)], "the window of a shown slot is a side window")
    tab.layout.window_at(other).buffer = D::Buffer.from_text("x\n", "x.txt")
    t.assert_equal(false, tab.side_window?(other), "a slot window that took a file is no longer a side window")
    t.assert_equal([false, true, true, true, false], [tab.winbar_with?("auto", 1), tab.winbar_with?("auto", 2), tab.winbar_with?("always", 0), tab.winbar_with?("always", 1), tab.winbar_with?("never", 3)], "the one rule of the modes: auto with two or more file windows, always, never")

    # The winbar rows: rows are [label, [user lines, keys], [row 0, row 1]].
    t.cases([
      ["one window has no winbar", ["", ""], ["class Foo", "| def bar"]],
      ["two windows have winbars over their text", ["", "<C-w>v"], [" a.rb               | a.rb", "class Foo           |class Foo"]],
      ["closing back to one window removes the winbar", ["", "<C-w>s<C-w>c"], ["class Foo", "| def bar"]],
      ["always shows the winbar on one window", ["option.breadcrumbs always\n", ""], [" a.rb", "class Foo"]],
      ["never hides the winbars of two windows", ["option.breadcrumbs never\n", "<C-w>v"], ["class Foo           |class Foo", "| def bar           || def bar"]],
      ["an unknown mode keeps auto", ["option.breadcrumbs sometimes\n", "<C-w>v"], [" a.rb               | a.rb", "class Foo           |class Foo"]]
    ]) do |input|
      r = rig(input[0].to_s, {})
      r.type(input[1].to_s)
      [r.row(0).rstrip, r.row(1).rstrip]
    end

    r = rig("", {})
    r.type(":vsplit b.txt<CR>")
    t.assert_equal([" b.txt              | a.rb", "bee                 |class Foo"], [r.row(1).rstrip, r.row(2).rstrip], "windows on different files name their own, under the buffer tabs")
    # Scenario "Windows on different files named": the path is the accent in the current window and quiet in the other.
    r = rig("", {})
    r.type("<C-w>v")
    t.assert_equal([H::TAB_LINE, H::TAB_LINE_SELECTED, H::TAB_LINE_FILL, H::TAB_LINE, H::TAB_LINE_FILL], [r.frame.hl_at(0, 0), r.frame.hl_at(0, 1), r.frame.hl_at(0, 10), r.frame.hl_at(0, 22), r.frame.hl_at(0, 30)], "the current window's path with no symbol is the accent in TabLineSel, the other's in TabLine, the pad TabLine, the rest TabLineFill")
    r.type("<C-w>l")
    t.assert_equal([H::TAB_LINE, H::TAB_LINE_SELECTED], [r.frame.hl_at(0, 1), r.frame.hl_at(0, 22)], "the selected winbar follows the current window")
    r = rig("", {})
    r.type(":set breadcrumbs=never<CR>")
    t.assert_equal("Not implemented: :set breadcrumbs=never", r.assembly.state.message, "the mode is read from configuration lines, not :set")
    r = rig("", {})
    r.type("5<C-w>s")
    window = r.assembly.state.window
    t.assert_equal([1, 5, " a.rb", "class Foo"], [window.row, window.height, r.row(0).rstrip, r.row(1).rstrip], "a split count counts text rows below the winbar")
    r = rig("", {})
    r.type("8<C-w>s")
    lower = r.assembly.state.tab.layout.window_at(0)
    t.assert_equal([1, 9, "class Foo"], [lower.height, lower.row, r.row(9).rstrip], "a window of one text row keeps its row and shows no winbar")

    # A split count from a scratch window counts the new window's rows.
    r = scratch_rig("option.breadcrumbs always\n")
    r.type("5<C-w>s")
    window = r.assembly.state.window
    t.assert_equal([0, 5, "tree", false], [window.row, window.height, r.row(0).rstrip, window.winbar], "A split count from a scratch window: the new window shows the scratch buffer with no winbar and 5 text rows")
    r = scratch_rig("option.breadcrumbs always\n")
    r.type(":split b.txt<CR>")
    window = r.assembly.state.window
    t.assert_equal([2, " b.txt", "bee", true], [window.row, r.row(1).rstrip, r.row(2).rstrip, window.winbar], "A split from a scratch window to a file has its row: the winbar under the buffer tabs, the text below it")

    # The symbol path.
    r = outlining("")
    r.wait
    r.wait
    t.assert_equal(0, r.symbols_sent, "with one window and no winbar no symbol request is sent")
    init = J.parse(r.processes.bodies[0].to_s)
    t.assert_equal(true, J.reach(init, "params.capabilities.textDocument.documentSymbol.hierarchicalDocumentSymbolSupport"), "initialize advertises hierarchical document symbols")
    r.type("<C-w>v")
    t.assert_equal([0, " a.rb"], [r.symbols_sent, cut(r, 0, 0, 20)], "the key that splits sends nothing")
    r.wait
    request = last_of(r, "textDocument/documentSymbol")
    t.assert_equal([1, A_URI], [r.symbols_sent, J.reach(request, "params.textDocument.uri").to_s], "the next idle tick asks for the buffer's symbols")
    # The rig reads option.icons ascii: the ASCII separator joins these.
    answer(r, symbol_id(r), OUTLINE)
    t.assert_equal([" a.rb > Foo", " a.rb > Foo"], [cut(r, 0, 0, 20), cut(r, 0, 21, 19)], "on the class line both windows on the buffer show the class")
    r.type("j")
    t.assert_equal([" a.rb > Foo > bar", " a.rb > Foo"], [cut(r, 0, 0, 20), cut(r, 0, 21, 19)], "inside the method the current window shows the class and the method, the other its own cursor's")
    # Scenario "Only the innermost symbol is in the accent": " a.rb > Foo > bar", the path and the class quiet, only the innermost symbol in the accent, and the other window quiet throughout.
    t.assert_equal([H::TAB_LINE, H::TAB_LINE, H::TAB_LINE, H::TAB_LINE, H::TAB_LINE_SELECTED, H::TAB_LINE_SELECTED, H::TAB_LINE, H::TAB_LINE, H::TAB_LINE],
      [r.frame.hl_at(0, 1), r.frame.hl_at(0, 7), r.frame.hl_at(0, 8), r.frame.hl_at(0, 11), r.frame.hl_at(0, 14), r.frame.hl_at(0, 16), r.frame.hl_at(0, 17), r.frame.hl_at(0, 22), r.frame.hl_at(0, 27)], "only the innermost symbol of the current window's winbar is in the accent, the path and the outer symbols stay quiet")
    r.type("4j")
    r.wait
    t.assert_equal([" a.rb", 1], [cut(r, 0, 0, 20), r.symbols_sent], "outside every symbol the path only, with no new request")
    t.assert_equal([H::TAB_LINE, H::TAB_LINE_SELECTED], [r.frame.hl_at(0, 0), r.frame.hl_at(0, 1)], "with symbols held but none spanning the cursor row the path is in the accent, the pad quiet")
    r.type(":e b.txt<CR>")
    t.assert_equal([" b.txt", " a.rb > Foo"], [cut(r, 1, 0, 20), cut(r, 1, 21, 19)], "a window on another buffer shows its path only, under the buffer tabs")

    r = rig("", {})
    r.type("<C-w>v")
    r.wait
    r.wait
    t.assert_equal([0, " a.rb"], [r.symbols_sent, cut(r, 0, 0, 20)], "a server without document symbols is not asked and the winbar shows the path")

    # Slow, stale, and overdue answers.
    r = outlining("")
    r.type("<C-w>v")
    r.wait
    id = symbol_id(r)
    r.type("j")
    t.assert_equal([1, " a.rb", true], [r.cursor_row, cut(r, 0, 0, 20), r.assembly.services.waiting?], "a key before the answer moves the cursor at once, the winbar showing the path")
    r.type("x")
    r.wait
    t.assert_equal(1, r.symbols_sent, "an edit while a request is in flight sends no second request")
    answer(r, id, OUTLINE)
    t.assert_equal(" a.rb > Foo > bar", cut(r, 0, 0, 20), "the slow answer shows when it arrives")
    r.wait
    t.assert_equal(2, r.symbols_sent, "the edited text is asked at the next idle tick after the answer")
    answer(r, symbol_id(r), [])
    t.assert_equal(" a.rb", cut(r, 0, 0, 20), "an empty answer leaves the path only")

    r = outlining("")
    r.type("<C-w>v")
    r.wait
    id = symbol_id(r)
    r.clock.advance(2.5)
    r.wait
    cancel = last_of(r, "$/cancelRequest")
    t.assert_equal([id, false], [J.reach(cancel, "params.id").to_i, r.assembly.services.waiting?], "a request unanswered for two seconds is cancelled by its id")
    answer(r, id, OUTLINE)
    r.wait
    t.assert_equal([" a.rb", 1], [cut(r, 0, 0, 20), r.symbols_sent], "its late answer changes nothing and the same text is not asked again")
    r.type("x")
    r.wait
    t.assert_equal(2, r.symbols_sent, "a changed text is asked again")
    r.messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => symbol_id(r), "error" => { "code" => -32_603, "message" => "boom" } }))
    r.wait
    t.assert_equal([" a.rb", false], [cut(r, 0, 0, 20), r.assembly.services.waiting?], "an error answer holds no symbols")

    # Inside a method of a class, with the unicode icons: the symbols are
    # joined by " › ".
    r = outlining("option.icons unicode\n")
    r.type("<C-w>v")
    r.wait
    answer(r, symbol_id(r), OUTLINE)
    r.type("j")
    t.assert_equal(" a.rb › Foo › bar", cut(r, 0, 0, 20), "inside a method of a class the symbols are joined by the single angle quote")

    # Answers in the flat form and hostile ones: a flat symbol answer;
    # a hostile answer is bounded.
    r = outlining("")
    r.type("<C-w>vj")
    r.wait
    answer(r, symbol_id(r), [flat("Foo", 0, 4), flat("bar", 1, 3), flat("baz", 5, 5)])
    t.assert_equal(" a.rb > Foo > bar", cut(r, 0, 0, 20), "a flat answer shows the symbols spanning the cursor row in its order")
    r = outlining("option.breadcrumbs always\n")
    r.wait
    many = []
    many << { "name" => "a\e[31mb\u0007" + "c" * 60, "range" => { "start" => { "line" => 0 }, "end" => { "line" => 0 } } }
    many << { "name" => 7, "range" => { "start" => { "line" => 0 }, "end" => { "line" => 0 } }, "children" => [{ "name" => "kept", "range" => { "start" => { "line" => 0 }, "end" => { "line" => 0 } } }] }
    many << { "name" => "backwards", "range" => { "start" => { "line" => 3 }, "end" => { "line" => 1 } } }
    many << { "name" => "negative", "range" => { "start" => { "line" => -1 }, "end" => { "line" => 1 } } }
    700.times { |i| many << { "name" => "s#{i}", "range" => { "start" => { "line" => 9 }, "end" => { "line" => 9 } } } }
    answer(r, symbol_id(r), many)
    symbols = r.assembly.symbols
    t.assert_equal([500, true, 40, "kept"], [symbols.count, symbols.name_at(0).start_with?("a[31mb"), symbols.name_at(0).bytesize, symbols.name_at(1)], "names lose their controls and are cut to 40 bytes, a bad item is skipped but its children kept, and 500 symbols are kept")
    deep = { "name" => "d8", "range" => { "start" => { "line" => 0 }, "end" => { "line" => 9 } } }
    level = 7
    while level >= 1
      deep = { "name" => "d#{level}", "range" => { "start" => { "line" => 0 }, "end" => { "line" => 9 } }, "children" => [deep, { "name" => "x", "range" => { "start" => { "line" => 0 }, "end" => { "line" => 0 } }, "children" => [{ "name" => "y", "range" => { "start" => { "line" => 0 }, "end" => { "line" => 0 } } }] }] }
      level -= 1
    end
    deep = { "name" => "d0", "range" => { "start" => { "line" => 0 }, "end" => { "line" => 9 } }, "children" => [deep] }
    r.type("x")
    r.wait
    answer(r, symbol_id(r), [deep])
    names = []
    i = 0
    while i < symbols.count
      names << symbols.name_at(i) if symbols.name_at(i).start_with?("d")
      i += 1
    end
    t.assert_equal(["d0", "d1", "d2", "d3", "d4", "d5", "d6", "d7"], names, "symbols nested deeper than 8 levels are not read")

    # Stopping the servers forgets the symbol request in flight, as a
    # crash does.
    r = outlining("")
    r.type("<C-w>v")
    r.wait
    asked = r.assembly.services.symbols
    before = asked.sent_id != 0
    r.assembly.services.stop
    t.assert_equal([true, 0, 0], [before, asked.sent_id, asked.languages.length], "stop forgets the symbol request in flight")

    # A restart keeps the new outline: the held symbols and the text last
    # asked are dropped, the restarted server (handle 2) is asked, and the
    # old server's answer (handle 1) changes nothing.
    r = outlining("")
    r.type("<C-w>v")
    r.wait
    answer(r, symbol_id(r), OUTLINE)
    r.type("x")
    r.wait
    old = symbol_id(r)
    r.type(":LspRestart<CR>")
    t.assert_equal([2, " a.rb"], [r.symbols_sent, cut(r, 0, 0, 20)], "a restart drops the held symbols and the winbar shows the path")
    init = { "capabilities" => { "documentSymbolProvider" => true }, "serverInfo" => { "name" => "ruby-lsp" } }
    r.messages.body(2, J.generate({ "jsonrpc" => "2.0", "id" => 1, "result" => init }))
    r.wait
    t.assert_equal(3, r.symbols_sent, "the restarted server is asked for the same text once it is ready")
    fresh = symbol_id(r)
    r.messages.body(2, J.generate({ "jsonrpc" => "2.0", "id" => fresh, "result" => [flat("Baz", 0, 5)] }))
    r.wait
    r.messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => old, "result" => OUTLINE }))
    r.wait
    t.assert_equal([" a.rb > Baz", 3], [cut(r, 0, 0, 20), r.symbols_sent], "A restart keeps the new outline: the old server's late answer changes nothing")

    t.finish
  end
end

EditorBreadcrumbsTest.main if __FILE__ == $0
