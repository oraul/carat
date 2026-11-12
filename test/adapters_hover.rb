require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# K and the documentation float: the whole editor over the production
# gateway and the doubles, FakeProcesses recording what is sent and
# MemoryQueue carrying what the server answers. Every idle read advances
# the manual clock by its timeout.
module AdaptersHoverTest
  J = Carat::Json
  D = Carat::Domain

  # The editor with readers for the doubles and the last frame.
  class Rig
    attr_reader :clock #: Carat::Doubles::ManualClock
    attr_reader :terminal #: Carat::Doubles::FakeTerminal
    attr_reader :processes #: Carat::Doubles::FakeProcesses
    attr_reader :messages #: Carat::Doubles::MemoryQueue
    attr_reader :assembly #: Carat::Adapters::EditorAssembly
    attr_reader :frame #: Carat::Domain::Frame

    #: (clock: Carat::Doubles::ManualClock, terminal: Carat::Doubles::FakeTerminal, processes: Carat::Doubles::FakeProcesses, messages: Carat::Doubles::MemoryQueue, assembly: Carat::Adapters::EditorAssembly) -> void
    def initialize(clock:, terminal:, processes:, messages:, assembly:)
      @clock = clock
      @terminal = terminal
      @processes = processes
      @messages = messages
      @assembly = assembly
      @rows = 12
      @cols = 40
      @frame = assembly.render(12, 40)
    end

    # Draws the editor at rows by cols from now on.
    #: (Integer, Integer) -> void
    def resize(rows, cols)
      @rows = rows
      @cols = cols
      @frame = @assembly.render(rows, cols)
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
      @frame = @assembly.render(@rows, @cols)
    end

    #: () -> Array[String]
    def screen
      @frame.text_rows
    end

    #: () -> Integer
    def hovers_sent
      @processes.methods_sent.count("textDocument/hover")
    end

    #: () -> Integer
    def window_count
      @assembly.state.tab.layout.leaves.length
    end

    #: () -> Integer
    def float_count
      @assembly.state.tab.floats.count
    end
  end

  # An editor over a.rb in the trusted /project with ruby-lsp installed,
  # its initialize answered with the capabilities given.
  def self.rig(capabilities)
    rig_with(capabilities, [], false)
  end

  # rig with the plugins given and, when plain, NO_COLOR set.
  #: (Hash[String, untyped], Array[untyped], bool) -> Rig
  def self.rig_with(capabilities, plugins, plain)
    files = Carat::Doubles::MemoryFiles.new
    files.move_to("/project")
    files.put("a.rb", "def greet\n  puts 1\nend\n")
    clock = Carat::Doubles::ManualClock.new
    terminal = Carat::Doubles::FakeTerminal.new(clock: clock, rows: 12, cols: 40)
    terminal.no_color = plain
    processes = Carat::Doubles::FakeProcesses.new
    processes.install("ruby-lsp")
    messages = Carat::Doubles::MemoryQueue.new
    completions = Carat::Adapters::ServerCompletions.new
    config = Carat::Doubles::FixedConfig.new(value: Carat::Doubles::FixedConfig.with_user("language.trusted_roots /project\noption.icons ascii\n"))
    assembly = Carat::Adapters::EditorAssembly.new(terminal: terminal, clock: clock, files: files, config: config, processes: processes, messages: messages, completions: completions, plugin_list: plugins)
    r = Rig.new(clock: clock, terminal: terminal, processes: processes, messages: messages, assembly: assembly)
    assembly.screen_presenter.enter
    assembly.open("a.rb")
    r.wait
    init = { "capabilities" => capabilities, "serverInfo" => { "name" => "ruby-lsp" } }
    messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => 1, "result" => init }))
    r.wait
    r
  end

  # A server that hovers.
  def self.hovering
    rig({ "hoverProvider" => true })
  end

  # The last body sent with the method, parsed, or nil.
  def self.last_of(r, name)
    bodies = r.processes.bodies
    i = bodies.length - 1
    while i >= 0
      value = J.parse(bodies[i].to_s)
      return value if value["method"] == name.to_s
      i -= 1
    end
    nil
  end

  # The id of the last hover request sent.
  def self.hover_id(r)
    last_of(r, "textDocument/hover")["id"].to_i
  end

  # Answers the last hover request with the contents.
  def self.answer(r, contents)
    r.messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => hover_id(r), "result" => { "contents" => contents } }))
  end

  # K, its request sent at the next idle tick, the answer read at the one
  # after.
  def self.shown(r, contents)
    r.type("K")
    r.wait
    answer(r, contents)
    r.wait
    nil
  end

  # The rows of the documentation float, empty when none shows.
  def self.float_lines(r)
    out = [""]
    out.clear
    id = r.assembly.hover.float_id
    floats = r.assembly.state.tab.floats
    i = id == 0 ? -1 : floats.index_of(id)
    return out if i < 0
    buffer = floats.at(i).window.buffer
    n = 0
    while n < buffer.line_count
      out << buffer.line(n)
      n += 1
    end
    out
  end

  # The group the first cell of the word on the screen is drawn in, by
  # name, with " in a float" when it is on the float layer; "" when the
  # word is not shown.
  def self.group_of(r, word)
    rows = r.screen
    i = 0
    while i < rows.length
      col = rows[i].index(word.to_s)
      unless col.nil?
        hl = r.frame.hl_at(i, col.to_i)
        suffix = hl >= D::Highlight::FLOAT_LAYER ? " in a float" : ""
        return D::Highlight.name_of(D::Highlight.base(hl)) + suffix
      end
      i += 1
    end
    ""
  end

  # The current buffer's lines.
  def self.lines(r)
    buffer = r.assembly.state.buffer
    out = [""]
    out.clear
    n = 0
    while n < buffer.line_count
      out << buffer.line(n)
      n += 1
    end
    out
  end

  def self.markup(value)
    { "kind" => "markdown", "value" => value.to_s }
  end

  # The float's text width, the width its rows were laid out at, its
  # first row as the screen shows it from the text area's first column,
  # and the screen's last column on that row: the right border when the
  # row is not cut.
  #: (Rig, Carat::Domain::FloatWindow) -> Array[untyped]
  def self.drawn(r, float)
    window = float.window
    row = r.screen[window.row].to_s
    [window.width, float.spec.width, row[window.col, window.width].to_s.rstrip, row[row.length - 1, 1].to_s]
  end

  def self.main
    t = Carat::Testing.new("adapters_hover")

    # No server hovers.
    r = rig({})
    hover = last_of(r, "initialize")["params"]["capabilities"]["textDocument"]["hover"]
    t.assert_equal(["markdown", "plaintext"], hover["contentFormat"], "initialize advertises hover with markdown content")
    r.type("K")
    r.wait
    t.assert_equal(["No hover provider for this buffer", 0], [r.assembly.state.message, r.hovers_sent], "K with no hovering server is refused and asks nothing")

    # A hovering server: the request and the answer.
    r = hovering
    r.type("w")
    r.type("K")
    t.assert_equal([0, true], [r.hovers_sent, r.assembly.services.waiting?], "K records the ask and no key waits on the server")
    r.wait
    asked = last_of(r, "textDocument/hover")
    t.assert_equal([2, 0, 4, true], [asked["id"], asked["params"]["position"]["line"], asked["params"]["position"]["character"], asked["params"]["textDocument"]["uri"].to_s.end_with?("/a.rb")], "the next idle tick sends the document and the cursor")
    answer(r, markup("# greet\n\nSays **hello** with `puts`.\n\n- one\n- two\n\n```ruby\nputs 1\n```"))
    r.wait
    t.assert_equal(["greet", "", "Says hello with puts.", "", "• one", "• two", "", "  puts 1"], float_lines(r), "the answer opens the float at the next idle tick with no key, its markup laid out")
    t.assert_equal([true, true, false], [r.screen[1].include?("+"), r.screen[2].include?("greet"), r.assembly.services.waiting?], "the float is bordered below the cursor, in the ASCII form of the ascii icons, and nothing waits")
    r.type("l")
    t.assert_equal([0, 0], [r.float_count, r.assembly.hover.float_id], "moving the cursor closes the float")

    shown(r, markup("text"))
    t.assert_equal(["text"], float_lines(r), "K again asks again")
    r.type("<Esc>")
    t.assert_equal([0, 0], [r.float_count, r.assembly.hover.float_id], "Esc closes the float")

    shown(r, markup("text"))
    r.type("i")
    t.assert_equal(0, r.float_count, "leaving normal mode closes the float")
    r.type("<Esc>")

    # Answers that open no float.
    r = hovering
    shown(r, nil)
    t.assert_equal(["No information available", 0], [r.assembly.state.message, r.float_count], "an empty answer shows a message and no float")
    r.type("K")
    r.wait
    r.messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => hover_id(r), "error" => { "code" => -32_603, "message" => "boom" } }))
    r.wait
    t.assert_equal(["No information available", 0], [r.assembly.state.message, r.float_count], "an error answer shows the same message")
    r.type("K")
    r.wait
    r.type("l")
    answer(r, markup("late"))
    r.wait
    t.assert_equal([0, false], [r.float_count, r.assembly.services.waiting?], "an answer after the cursor moved opens no float")
    r.type("K")
    r.type("l")
    r.wait
    t.assert_equal([3, false], [r.hovers_sent, r.assembly.services.waiting?], "an ask the cursor left before the tick is not sent")

    # Cancellation and the timeout.
    r = hovering
    r.type("K")
    r.wait
    first = hover_id(r)
    r.type("K")
    r.wait
    t.assert_equal([first, 2, first + 1], [last_of(r, "$/cancelRequest")["params"]["id"], r.hovers_sent, hover_id(r)], "a new K cancels the request in flight by its id and sends another")
    r.messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => first, "result" => { "contents" => "old" } }))
    r.wait
    t.assert_equal(0, r.float_count, "the cancelled request's answer is dropped")
    n = 0
    while n < 200 && r.assembly.services.waiting?
      r.wait
      n += 1
    end
    t.assert_equal([first + 1, false], [last_of(r, "$/cancelRequest")["params"]["id"], r.assembly.services.waiting?], "an unanswered request is cancelled after two seconds and waits no more")
    t.assert_equal(true, n >= 99 && n <= 102, "the timeout counts from the sending")

    # Scrolling: K enters the float.
    r = hovering
    long = +""
    i = 1
    while i <= 30
      long << "- item #{i}\n"
      i += 1
    end
    shown(r, markup(long))
    t.assert_equal([30, false], [float_lines(r).length, r.screen.join("\n").include?("item 30")], "a long document shows its first rows")
    r.type("K")
    t.assert_equal(true, r.assembly.state.tab.floats.focused?, "K while the float shows enters it")
    r.type("G")
    t.assert_equal([true, 1], [r.screen.join("\n").include?("item 30"), r.float_count], "G in the float shows the last row and keeps the float")
    r.type("<Esc>")
    t.assert_equal([0, 0, false], [r.float_count, r.assembly.hover.float_id, r.assembly.state.tab.floats.focused?], "Esc in the float closes it")

    # Pinning.
    r = hovering
    r.type("<Space>dp")
    t.assert_equal(["No documentation to pin", 1], [r.assembly.state.message, r.window_count], "with no float the pin key is refused")
    shown(r, markup("# greet\n\nSays hello."))
    rows = float_lines(r)
    r.type("<Space>dp")
    t.assert_equal([2, 0, rows, "[docs]", true], [r.window_count, r.float_count, lines(r), r.assembly.state.buffer.title, r.assembly.state.buffer.scratch?], "the pin key opens the rows in a scratch split and closes the float")
    r.type("<Esc>")
    r.type("j")
    t.assert_equal([2, rows], [r.window_count, lines(r)], "the pinned split stays after Esc and a move")

    # The markup drawn in its groups, over the float's background.
    r = hovering
    shown(r, markup("# Heading\n\nUse **strongword** _italicword_\n\n`codeword` [linkword](#d)"))
    t.assert_equal(["@markup.heading in a float", "@markup.strong in a float", "@markup.italic in a float", "@markup.raw in a float", "@markup.link.label in a float", "NormalFloat"], [group_of(r, "Heading"), group_of(r, "strongword"), group_of(r, "italicword"), group_of(r, "codeword"), group_of(r, "linkword"), group_of(r, "Use")], "headings, strong and italic runs, code spans, and link texts are drawn in their groups in the float")
    r.type("<Esc>")
    shown(r, markup("# Pinned\n\n```text\nplainwords\n```\n\n```ruby\n# note\n```"))
    t.assert_equal(["@markup.raw.block in a float", "@markup.raw.block in a float"], [group_of(r, "plainwords"), group_of(r, "note")], "fenced code with no tokenizer for its language is drawn in @markup.raw.block")
    r.type("<Space>dp")
    t.assert_equal(["@markup.heading", "@markup.raw.block"], [group_of(r, "Pinned"), group_of(r, "plainwords")], "the pinned split draws the styles over the window's background")
    r = rig_with({ "hoverProvider" => true }, [Carat::Plugins::Ruby::Plugin.new], false)
    shown(r, markup("```ruby\n# note\nx = 4242\n```"))
    t.assert_equal(["Comment in a float", "Number in a float"], [group_of(r, "note"), group_of(r, "4242")], "fenced Ruby is drawn through the Ruby tokenizer over the float's background")
    r.type(":syntax off<CR>")
    r.type("K")
    r.wait
    answer(r, markup("```ruby\n# note\n```"))
    r.wait
    t.assert_equal("@markup.raw.block in a float", group_of(r, "note"), "with syntax off fenced Ruby is plain code")
    r = rig_with({ "hoverProvider" => true }, [], true)
    shown(r, markup("# Heading\n\n```text\nplainwords\n```"))
    t.assert_equal(["NormalFloat", "NormalFloat"], [group_of(r, "Heading"), group_of(r, "plainwords")], "NO_COLOR draws the documentation plain")
    r.type("<Space>dp")
    t.assert_equal(["Normal", 2], [group_of(r, "Heading"), r.window_count], "and the pinned split too")

    # Hostile and bounded text.
    r = hovering
    shown(r, markup("\e[31mred\e[0m\e]0;title\a\n\n" + ">" * 10 + " deep\n\n" + "y\n\n" * 400_000))
    rows = float_lines(r)
    t.assert_equal(["red", "│ │ │ │ deep", true], [rows[0].to_s, rows[2].to_s, rows.length <= 100], "escape sequences are dropped, nesting capped, rows capped")
    t.assert_equal(false, r.screen.join("\n").include?("\e"), "no escape reaches the screen")
    parts = [{ "language" => "ruby\e[1m\n", "value" => "x = 1" }]
    i = 0
    while i < 1000
      parts << "p#{i}"
      i += 1
    end
    r.type("<Esc>")
    shown(r, parts)
    rows = float_lines(r)
    t.assert_equal(["  x = 1", "p0", 31, "p14"], [rows[0].to_s, rows[2].to_s, rows.length, rows[rows.length - 1].to_s], "a marked string with a language is fenced code and at most 16 parts are read")
    r.type("<Esc>")
    shown(r, ["x" * 20_000, "after"])
    rows = float_lines(r)
    t.assert_equal([100, false], [rows.length, rows.include?("after")], "the joined text stops at 16,384 bytes")

    # Scenario: An 80-column hover row shows its last word.
    r = hovering
    r.resize(24, 80)
    words = []
    n = 1
    while n <= 26
      words << "wd#{n.to_s.rjust(3, "0")}"
      n += 1
    end
    shown(r, markup(words.join(" ")))
    rows = float_lines(r)
    first = words[0, 12].to_a.join(" ")
    floats = r.assembly.state.tab.floats
    float = floats.at(floats.index_of(r.assembly.hover.float_id))
    t.assert_equal([first, [71, 71, first, "|"]], [rows[0].to_s, drawn(r, float)], "An 80-column hover row shows its last word: wrapped at 76 columns, drawn whole inside the border")
    t.finish
  end
end

AdaptersHoverTest.main if __FILE__ == $0
