require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# Parameter info: the whole editor over the production gateway and the
# doubles, FakeProcesses recording what is sent and MemoryQueue carrying
# what the server answers. Every idle read advances the manual clock by
# its timeout.
module AdaptersSignatureTest
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

    #: () -> Integer
    def sent
      @processes.methods_sent.count("textDocument/signatureHelp")
    end

    #: () -> Integer
    def float_count
      @assembly.state.tab.floats.count
    end
  end

  # An editor over a.rb in the trusted /project with ruby-lsp installed,
  # its initialize answered with the capabilities given.
  def self.rig(capabilities)
    files = Carat::Doubles::MemoryFiles.new
    files.move_to("/project")
    files.put("a.rb", "x = 1\ny = 2\nz = 3\n")
    clock = Carat::Doubles::ManualClock.new
    terminal = Carat::Doubles::FakeTerminal.new(clock: clock, rows: 12, cols: 40)
    processes = Carat::Doubles::FakeProcesses.new
    processes.install("ruby-lsp")
    messages = Carat::Doubles::MemoryQueue.new
    completions = Carat::Adapters::ServerCompletions.new
    config = Carat::Doubles::FixedConfig.new(value: Carat::Doubles::FixedConfig.with_user("language.trusted_roots /project\noption.icons ascii\n"))
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

  # A server that gives signature help.
  def self.signing
    rig({ "signatureHelpProvider" => { "triggerCharacters" => ["(", ","] } })
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

  # The id of the last signature request sent.
  def self.request_id(r)
    last_of(r, "textDocument/signatureHelp")["id"].to_i
  end

  # Idle ticks until the debounce passed and the wanted request is sent.
  def self.settle(r)
    count = r.sent
    n = 0
    while n < 20 && r.sent == count
      r.wait
      n += 1
    end
    nil
  end

  # A signature help result of one signature with the parameters' labels
  # and the active one.
  def self.help(label, parameters, active)
    list = []
    i = 0
    while i < parameters.length
      list << { "label" => parameters[i] }
      i += 1
    end
    { "signatures" => [{ "label" => label.to_s, "parameters" => list }], "activeParameter" => active }
  end

  # Answers the request with the id with the result.
  def self.answer_id(r, id, result)
    r.messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => id.to_i, "result" => result }))
  end

  # Answers the last signature request and reads the answer.
  def self.answer(r, result)
    answer_id(r, request_id(r), result)
    r.wait
    nil
  end

  # The float showing the signature, or nil.
  def self.float(r)
    id = r.assembly.signature.float_id
    floats = r.assembly.state.tab.floats
    i = id == 0 ? -1 : floats.index_of(id)
    i < 0 ? nil : floats.at(i)
  end

  # The float's row, "" when none shows.
  def self.shown(r)
    f = float(r)
    f.nil? ? "" : f.window.buffer.line(0)
  end

  # The float's marked display columns, [-1, -1] when none shows.
  def self.mark(r)
    f = float(r)
    f.nil? ? [-1, -1] : [f.mark_from, f.mark_to]
  end

  # A server giving signature help, insert mode on a new last row with
  # foo( typed, the request sent and answered with a first parameter.
  def self.opened
    r = signing
    r.type("Gofoo(")
    settle(r)
    answer(r, help("foo(a, b)", ["a", "b"], 0))
    r
  end

  # The float's text width, the width its rows were laid out at, its
  # first row as the screen shows it from the text area's first column,
  # and the screen's last column on that row: the right border when the
  # row is not cut.
  #: (Rig, Carat::Domain::FloatWindow) -> Array[untyped]
  def self.drawn(r, float)
    window = float.window
    row = r.frame.text_rows[window.row].to_s
    [window.width, float.spec.width, row[window.col, window.width].to_s.rstrip, row[row.length - 1, 1].to_s]
  end

  def self.main
    t = Carat::Testing.new("adapters_signature")

    # No server gives signature help.
    r = rig({})
    help_caps = last_of(r, "initialize")["params"]["capabilities"]["textDocument"]["signatureHelp"]
    t.assert_equal([true, true], [help_caps["signatureInformation"]["parameterInformation"]["labelOffsetSupport"], help_caps["signatureInformation"]["activeParameterSupport"]], "initialize advertises signature help with label offsets")
    r.type("Gofoo(")
    settle(r)
    t.assert_equal([0, 0, false], [r.sent, r.float_count, r.assembly.signature.active?], "with no server giving signature help ( asks nothing")

    # Opening.
    r = signing
    r.type("Gofoo")
    t.assert_equal([0, false], [r.assembly.signature.want, r.assembly.signature.active?], "other characters ask nothing")
    r.type("(")
    r.wait
    t.assert_equal([0, true, true], [r.sent, r.assembly.signature.active?, r.assembly.services.waiting?], "( records the ask and the first idle tick only starts the debounce")
    settle(r)
    asked = last_of(r, "textDocument/signatureHelp")
    t.assert_equal([1, 3, 4], [r.sent, asked["params"]["position"]["line"], asked["params"]["position"]["character"]], "the request is sent once the debounce passed, at the cursor")
    answer(r, help("foo(a, b)", ["a", "b"], 0))
    t.assert_equal(["foo(a, b)", [4, 5], 1], [shown(r), mark(r), r.float_count], "the answer opens the float with no key, the first parameter marked")
    f = float(r)
    top = f.nil? ? -1 : f.box_top
    t.assert_equal([true, true], [r.frame.text_rows[top + 1].include?("foo(a, b)"), top + 3 <= 4], "the float is bordered above the cursor")
    col = r.frame.text_rows[top + 1].index("a,").to_i
    t.assert_equal([D::Highlight::VISUAL, D::Highlight::NORMAL_FLOAT], [r.frame.hl_at(top + 1, col), r.frame.hl_at(top + 1, col + 3)], "the marked parameter is drawn in Visual, the rest in NormalFloat")

    # Following.
    r.type("x, ")
    settle(r)
    asked = last_of(r, "textDocument/signatureHelp")
    t.assert_equal([7, "foo(a, b)"], [asked["params"]["position"]["character"], shown(r)], "typing an argument asks again and the float stays until the answer")
    answer(r, { "signatures" => [{ "label" => "foo(a, b)", "parameters" => [{ "label" => [4, 5] }, { "label" => [7, 8] }], "activeParameter" => 1 }] })
    t.assert_equal([7, 8], mark(r), "the answer moves the mark to the second parameter, given as offsets")
    r.type("bar(")
    settle(r)
    t.assert_equal(10, r.assembly.signature.open_col, "an inner call is followed")
    r.type("1)")
    settle(r)
    t.assert_equal(3, r.assembly.signature.open_col, "closing the inner call follows the outer one again")
    r.type(")")
    t.assert_equal([0, 0, false], [r.float_count, r.assembly.signature.float_id, r.assembly.signature.active?], "closing the call closes the float")

    r = opened
    r.type("<Esc>")
    t.assert_equal([:normal, 0, false], [r.assembly.state.mode, r.float_count, r.assembly.signature.active?], "Esc leaves insert mode and closes the float")
    r = opened
    r.type("<CR>")
    t.assert_equal([0, false], [r.float_count, r.assembly.signature.active?], "another row closes the float")
    r = opened
    r.type("<BS>")
    t.assert_equal([0, false], [r.float_count, r.assembly.signature.active?], "erasing the parenthesis closes the float")

    r = signing
    r.type("Gofoo(")
    settle(r)
    answer(r, nil)
    t.assert_equal([0, false, ""], [r.float_count, r.assembly.signature.active?, r.assembly.state.message], "a null answer closes the float with no message")
    r = opened
    r.type("a")
    settle(r)
    answer(r, { "signatures" => [] })
    t.assert_equal([0, false], [r.float_count, r.assembly.signature.active?], "an empty list closes the float")

    # Staleness.
    r = opened
    r.type("y")
    settle(r)
    first = request_id(r)
    r.type("q")
    settle(r)
    t.assert_equal([first, first + 1], [last_of(r, "$/cancelRequest")["params"]["id"], request_id(r)], "a newer ask cancels the request in flight and sends its own")
    answer_id(r, first, help("stale(a)", ["a"], 0))
    r.wait
    t.assert_equal(["foo(a, b)", true], [shown(r), r.assembly.services.waiting?], "an older answer arriving after the newer request was sent is dropped")
    answer(r, help("foo(a, b)", ["a", "b"], 1))
    t.assert_equal([7, 8], mark(r), "the newer answer is shown")

    r = opened
    r.type("y")
    settle(r)
    first = request_id(r)
    r.type("z")
    answer_id(r, first, help("stale(a)", ["a"], 0))
    r.wait
    t.assert_equal(["foo(a, b)", 2, 0], [shown(r), r.sent, r.assembly.signature.sent_id], "an older answer arriving before the newer request was sent is dropped")
    settle(r)
    t.assert_equal([3, 6], [r.sent, last_of(r, "textDocument/signatureHelp")["params"]["position"]["character"]], "the newer request is sent once the debounce passed")

    r = signing
    r.type("Gofoo(")
    settle(r)
    first = request_id(r)
    n = 0
    while n < 200 && r.assembly.services.waiting?
      r.wait
      n += 1
    end
    t.assert_equal([first, false], [last_of(r, "$/cancelRequest")["params"]["id"], r.assembly.services.waiting?], "an unanswered request is cancelled after two seconds and waits no more")

    # Hostile text.
    r = signing
    r.type("Gofoo(")
    settle(r)
    hostile = "f\e[2J\e]0;owned\u0007(" + ("w" * 5000) + ")\u009b31m"
    answer(r, { "signatures" => [{ "label" => hostile, "parameters" => [{ "label" => [6000, 6001] }] }], "activeSignature" => 7, "activeParameter" => 0 })
    line = shown(r)
    t.assert_equal([false, true, true, [-1, -1]], [line.include?("\e"), line.bytesize <= 1024, line.start_with?("f(www"), mark(r)], "escape sequences are dropped, the label capped, and offsets past it mark nothing")
    t.assert_equal(false, r.terminal.writes.join.include?("owned"), "no escape reaches the screen")

    # Scenario: The signature and the peek fit a narrow screen.
    r = signing
    r.type("Gofoo(")
    settle(r)
    label = "foo(alpha, bravo, charlie, delta, echo, foxtrot)"
    answer(r, help(label, ["alpha", "bravo"], 0))
    f = float(r)
    t.assert_equal([36, 36, label[0, 36].to_s, "|"], f.nil? ? [] : drawn(r, f), "The signature and the peek fit a narrow screen: a long label is 36 columns at 40, its border in the last column")
    t.finish
  end
end

AdaptersSignatureTest.main if __FILE__ == $0
