require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# The language server as the completion source: the whole editor over
# the production ServerCompletions and the doubles, FakeProcesses
# recording what is sent and MemoryQueue carrying what the server
# answers. Every idle read advances the manual clock by its timeout.
module AdaptersServerCompletionsTest
  J = Carat::Json
  D = Carat::Domain

  # The editor over the production source, with readers for the doubles.
  class Rig
    attr_reader :clock #: Carat::Doubles::ManualClock
    attr_reader :terminal #: Carat::Doubles::FakeTerminal
    attr_reader :processes #: Carat::Doubles::FakeProcesses
    attr_reader :messages #: Carat::Doubles::MemoryQueue
    attr_reader :completions #: Carat::Adapters::ServerCompletions
    attr_reader :assembly #: Carat::Adapters::EditorAssembly

    #: (clock: Carat::Doubles::ManualClock, terminal: Carat::Doubles::FakeTerminal, processes: Carat::Doubles::FakeProcesses, messages: Carat::Doubles::MemoryQueue, completions: Carat::Adapters::ServerCompletions, assembly: Carat::Adapters::EditorAssembly) -> void
    def initialize(clock:, terminal:, processes:, messages:, completions:, assembly:)
      @clock = clock
      @terminal = terminal
      @processes = processes
      @messages = messages
      @completions = completions
      @assembly = assembly
    end

    # Types keys in Vim notation, one read per key, as EditorHarness does.
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
      @assembly.render(12, 40)
    end

    # The methods sent, in order.
    #: () -> Array[String]
    def sent
      @processes.methods_sent
    end

    # The labels the popup shows in order, empty when it does not show.
    #: () -> Array[String]
    def popup
      menu = @assembly.completion_menu
      out = [""]
      out.clear
      return out unless menu.showing?
      i = 0
      while i < menu.matches.length
        out << menu.candidates.at(menu.matches[i]).label
        i += 1
      end
      out
    end
  end

  # An editor over an empty a.rb in the trusted /project with ruby-lsp
  # installed, its initialize answered with the capabilities given.
  def self.rig(capabilities)
    files = Carat::Doubles::MemoryFiles.new
    files.move_to("/project")
    files.put("a.rb", "\n")
    clock = Carat::Doubles::ManualClock.new
    terminal = Carat::Doubles::FakeTerminal.new(clock: clock, rows: 12, cols: 40)
    processes = Carat::Doubles::FakeProcesses.new
    processes.install("ruby-lsp")
    messages = Carat::Doubles::MemoryQueue.new
    completions = Carat::Adapters::ServerCompletions.new
    config = Carat::Doubles::FixedConfig.new(value: Carat::Doubles::FixedConfig.with_user("language.trusted_roots /project\noption.icons ascii\n"))
    assembly = Carat::Adapters::EditorAssembly.new(terminal: terminal, clock: clock, files: files, config: config, processes: processes, messages: messages, completions: completions, plugin_list: [])
    r = Rig.new(clock: clock, terminal: terminal, processes: processes, messages: messages, completions: completions, assembly: assembly)
    assembly.screen_presenter.enter
    assembly.open("a.rb")
    r.wait
    init = { "capabilities" => capabilities, "serverInfo" => { "name" => "ruby-lsp" } }
    messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => 1, "result" => init }))
    r.wait
    r
  end

  # A server that completes.
  def self.completing
    rig({ "completionProvider" => { "triggerCharacters" => ["."] } })
  end

  # Idle ticks until a request of the method was sent, at most limit.
  def self.until_sent(r, name, limit)
    n = 0
    while n < limit.to_i && !r.sent.include?(name.to_s)
      r.wait
      n += 1
    end
    nil
  end

  # The last body sent with the method, parsed.
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

  # Answers the request of an id with the items.
  def self.answer(r, id, items)
    r.messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => id.to_i, "result" => { "isIncomplete" => false, "items" => items } }))
  end

  def self.item(label, kind)
    { "label" => label.to_s, "kind" => kind.to_i }
  end

  def self.three
    [item("file_name", 6), item("filter", 3), item("final", 14)]
  end

  # How many times a method was sent.
  def self.count_of(r, name)
    r.sent.count(name.to_s)
  end

  def self.main
    t = Carat::Testing.new("adapters_server_completions")

    # The request record.
    q = D::CompletionRequest.new
    q.ask(1, 0, 2)
    q.ask(1, 0, 2)
    t.assert_equal([1, true, false, true], [q.want, q.wanted?(1, 0, 2), q.answer_for?(1, 0, 2, "a fi"), q.waiting?], "asking the same word twice is one want, unanswered and waiting")
    q.ask(1, 0, 4)
    t.assert_equal([2, false], [q.want, q.wanted?(1, 0, 2)], "another word is a new want")
    q.sent = 2
    q.word = "fi"
    q.answered = 2
    t.assert_equal([true, true, false, false], [q.answer_for?(1, 0, 4, "a = fi"), q.answer_for?(1, 0, 4, "a = fil"), q.answer_for?(1, 0, 4, "a = ba"), q.answer_for?(1, 0, 4, "a = f")], "the answer serves the word while it begins with the typed part it was sent for")
    q.ask(1, 0, 4)
    t.assert_equal([3, true], [q.want, q.waiting?], "another word typed at the same start is a new want")
    q.sent = 3
    q.ask(1, 0, 4)
    t.assert_equal(4, q.want, "a want marked sent with no request in flight and no answer is asked again")

    # No completing server: typing costs nothing more.
    r = rig({})
    t.assert_equal(false, r.completions.ready?(r.assembly.state.buffer), "a server without a completion provider is not ready")
    r.type("ifi")
    8.times { r.wait }
    t.assert_equal([0, 0, []], [r.completions.request.want, count_of(r, "textDocument/completion"), r.popup], "typing with no completing server asks nothing and shows no popup")
    before = r.clock.now
    r.wait
    t.assert_equal(25, ((r.clock.now - before) * 100).round, "with nothing wanted an idle read waits 0.25 seconds")

    # A completing server: the debounced request and the answer.
    r = completing
    t.assert_equal(true, r.completions.ready?(r.assembly.state.buffer), "a server with a completion provider is ready for its file type")
    r.type("ifi")
    t.assert_equal([1, 0, []], [r.completions.request.want, count_of(r, "textDocument/completion"), r.popup], "typing records the word and no key waits on the server")
    before = r.clock.now
    r.wait
    t.assert_equal(2, ((r.clock.now - before) * 100).round, "while a word is wanted an idle read waits 0.02 seconds")
    t.assert_equal(0, count_of(r, "textDocument/completion"), "the first idle tick only starts the debounce")
    until_sent(r, "textDocument/completion", 20)
    asked = last_of(r, "textDocument/completion")
    t.assert_equal([2, 0, 2, 1, true], [asked["id"], asked["params"]["position"]["line"], asked["params"]["position"]["character"], asked["params"]["context"]["triggerKind"], asked["params"]["textDocument"]["uri"].to_s.end_with?("/a.rb")], "the request names the document and the cursor after 0.1 seconds")
    t.assert_equal(true, r.sent.index("textDocument/didChange").to_i < r.sent.index("textDocument/completion").to_i, "the typed text is sent before the request")
    before = r.clock.now
    r.wait
    t.assert_equal(2, ((r.clock.now - before) * 100).round, "while a request is in flight an idle read waits 0.02 seconds")
    answer(r, 2, three)
    r.wait
    t.assert_equal(["final", "filter", "file_name"], r.popup, "the answer fills the popup at the next idle tick with no key")
    menu = r.assembly.completion_menu
    t.assert_equal(["keyword", "function", "variable"], [menu.chosen.kind, menu.candidates.at(1).kind, menu.candidates.at(0).kind], "the LSP kinds read as the menu's kinds")
    t.assert_equal(false, r.assembly.services.waiting?, "an answered request waits no more")
    r.type("l")
    t.assert_equal([["filter", "file_name", "final"], 1], [r.popup, count_of(r, "textDocument/completion")], "typing on ranks the answer again without another request")
    r.type("<CR>")
    t.assert_equal("filter", r.assembly.state.buffer.line(0), "Enter inserts the server's item")

    # An answer arriving between keys typed 0.1 seconds apart.
    r = completing
    r.type("ifi")
    until_sent(r, "textDocument/completion", 20)
    answer(r, 2, three)
    r.wait
    t.assert_equal(3, r.popup.length, "an answer arriving after a key shows within 0.02 seconds, before the next key")

    # Debounce: words typed less than 0.1 seconds apart send one request.
    r = completing
    r.type("ia")
    r.wait
    r.wait
    r.type(" b")
    r.wait
    r.wait
    r.type(" c")
    until_sent(r, "textDocument/completion", 20)
    10.times { r.wait }
    asked = last_of(r, "textDocument/completion")
    t.assert_equal([1, 5], [count_of(r, "textDocument/completion"), asked["params"]["position"]["character"]], "words typed within the debounce send one request, for the last")

    # A stale request is cancelled and its answer dropped.
    r = completing
    r.type("ifi")
    until_sent(r, "textDocument/completion", 20)
    r.type(" ba")
    r.wait
    cancel = last_of(r, "$/cancelRequest")
    t.assert_equal(2, cancel.nil? ? 0 : cancel["params"]["id"], "another word cancels the request in flight")
    answer(r, 2, three)
    r.wait
    t.assert_equal([], r.popup, "the cancelled request's answer opens no popup")
    until_sent(r, "textDocument/completion", 20)
    10.times { r.wait } if count_of(r, "textDocument/completion") < 2
    t.assert_equal(2, count_of(r, "textDocument/completion"), "the new word is asked once the debounce passed")
    answer(r, 3, [item("bar", 6), item("baz", 6)])
    r.wait
    t.assert_equal(["bar", "baz"], r.popup, "the new word's answer fills the popup")
    answer(r, 9, three)
    r.wait
    t.assert_equal(["bar", "baz"], r.popup, "an answer to no request in flight changes nothing")

    # Another word typed later at the same start asks again.
    r = completing
    r.type("ifi")
    until_sent(r, "textDocument/completion", 20)
    answer(r, 2, three)
    r.wait
    r.type("<BS><BS>")
    t.assert_equal([], r.popup, "deleting the word closes the popup")
    r.type("ba")
    until_sent(r, "textDocument/completion", 20)
    10.times { r.wait } if count_of(r, "textDocument/completion") < 2
    asked = last_of(r, "textDocument/completion")
    t.assert_equal([2, 2], [count_of(r, "textDocument/completion"), asked["params"]["position"]["character"]], "a second word typed at the same column sends a request of its own")
    answer(r, 3, [item("bar", 6), item("baz", 6)])
    r.wait
    t.assert_equal(["bar", "baz"], r.popup, "the second word's answer fills the popup, not the first word's")

    # A want whose send was skipped, the mode left within the debounce,
    # is asked again by the next typed key.
    r = completing
    r.type("ifi<Esc>")
    10.times { r.wait }
    t.assert_equal(0, count_of(r, "textDocument/completion"), "leaving insert mode within the debounce sends no request")
    r.type("al")
    until_sent(r, "textDocument/completion", 20)
    t.assert_equal(1, count_of(r, "textDocument/completion"), "typing the word again asks the server")

    # A request left unanswered is cancelled after two seconds.
    r = completing
    r.type("ifi")
    until_sent(r, "textDocument/completion", 20)
    110.times { r.wait }
    t.assert_equal([1, false], [count_of(r, "$/cancelRequest"), r.assembly.services.waiting?], "an unanswered request is cancelled after two seconds and waits no more")

    # An error answers nothing.
    r = completing
    r.type("ifi")
    until_sent(r, "textDocument/completion", 20)
    r.messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => 2, "error" => { "code" => -32_800, "message" => "cancelled" } }))
    r.wait
    t.assert_equal([[], false], [r.popup, r.assembly.services.waiting?], "an error answer opens no popup")

    # Untrusted and bounded answers.
    r = completing
    r.type("ifi")
    until_sent(r, "textDocument/completion", 20)
    hostile = { "label" => "fi\e[31m\e]0;t\a" + ("l" * 5000), "kind" => 99, "detail" => "\e[2J" + ("d" * 500), "textEdit" => { "newText" => "fil\e[0m" + ("x" * 900) } }
    answer(r, 2, [hostile, { "kind" => 6 }, item("fit", 6)])
    r.wait
    menu = r.assembly.completion_menu
    shown = menu.candidates.at(0)
    t.assert_equal([2, false, 80, "text", 80, 200], [menu.candidates.count, shown.label.include?("\e") || shown.detail.include?("\e") || shown.text.include?("\e"), shown.label.bytesize, shown.kind, shown.detail.bytesize, shown.text.bytesize], "escape sequences are dropped, each string is cut, an unknown kind is text, and an item without a label is skipped")
    t.assert_equal(true, shown.text.start_with?("filx"), "the text edit's new text is the text inserted")
    r = completing
    r.type("ifi")
    until_sent(r, "textDocument/completion", 20)
    many = []
    300.times { |i| many << item("fi#{i}", 6) }
    answer(r, 2, many)
    r.wait
    t.assert_equal([200, 200], [r.completions.request.list.count, r.assembly.completion_menu.candidates.count], "at most 200 items of an answer are kept")

    # A server that crashes completes no more.
    r = completing
    r.messages.push(D::ServiceMessage.new(handle: 1, kind: "exit", text: ""))
    r.wait
    t.assert_equal(false, r.completions.ready?(r.assembly.state.buffer), "a crashed server's language is not ready")

    t.finish
  end
end

AdaptersServerCompletionsTest.main if __FILE__ == $0
