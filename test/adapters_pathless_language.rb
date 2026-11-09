require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# A buffer without a path beside a running language server: the whole
# editor over the production gateway and ServerCompletions, FakeProcesses
# recording what is sent and MemoryQueue carrying what the server says.
# Every idle read advances the manual clock by its timeout.
module AdaptersPathlessLanguageTest
  J = Carat::Json
  D = Carat::Domain

  # The editor with readers for the doubles.
  class Rig
    attr_reader :processes #: Carat::Doubles::FakeProcesses
    attr_reader :messages #: Carat::Doubles::MemoryQueue
    attr_reader :assembly #: Carat::Adapters::EditorAssembly
    attr_reader :terminal #: Carat::Doubles::FakeTerminal

    #: (terminal: Carat::Doubles::FakeTerminal, processes: Carat::Doubles::FakeProcesses, messages: Carat::Doubles::MemoryQueue, assembly: Carat::Adapters::EditorAssembly) -> void
    def initialize(terminal:, processes:, messages:, assembly:)
      @terminal = terminal
      @processes = processes
      @messages = messages
      @assembly = assembly
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

    # Idle reads with no key.
    #: (Integer) -> void
    def wait(count)
      i = 0
      while i < count
        pump
        i += 1
      end
    end

    #: () -> void
    def pump
      @assembly.controller.pump(@assembly.state)
      @assembly.render(12, 40)
    end
  end

  # An editor over a.rb in the trusted /project whose ruby-lsp answered
  # initialize offering completion, hover, and signature help.
  def self.rig
    files = Carat::Doubles::MemoryFiles.new
    files.move_to("/project")
    files.put("a.rb", "x = 1\n")
    clock = Carat::Doubles::ManualClock.new
    terminal = Carat::Doubles::FakeTerminal.new(clock: clock, rows: 12, cols: 40)
    processes = Carat::Doubles::FakeProcesses.new
    processes.install("ruby-lsp")
    messages = Carat::Doubles::MemoryQueue.new
    completions = Carat::Adapters::ServerCompletions.new
    config = Carat::Doubles::FixedConfig.new(value: Carat::Doubles::FixedConfig.with_user("language.trusted_roots /project\noption.icons ascii\n"))
    assembly = Carat::Adapters::EditorAssembly.new(terminal: terminal, clock: clock, files: files, config: config, processes: processes, messages: messages, completions: completions, plugin_list: [])
    r = Rig.new(terminal: terminal, processes: processes, messages: messages, assembly: assembly)
    assembly.screen_presenter.enter
    assembly.open("a.rb")
    r.wait(1)
    capabilities = { "completionProvider" => { "triggerCharacters" => ["."] }, "hoverProvider" => true, "signatureHelpProvider" => { "triggerCharacters" => ["(", ","] } }
    messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => 1, "result" => { "capabilities" => capabilities, "serverInfo" => { "name" => "ruby-lsp" } } }))
    r.wait(1)
    r
  end

  # What a pathless Ruby buffer leaves after the keys, idle ticks past
  # every debounce, and a publish for the working directory's URI when
  # publish is true: the methods sent once the buffer existed, whether the
  # server still runs, and whether the current buffer shows a sign.
  def self.pathless(keys, publish)
    r = rig
    r.type(":new<CR>:set filetype=ruby<CR>")
    r.wait(2)
    from = r.processes.bodies.length
    r.type(keys.to_s)
    r.wait(20)
    if publish
      diagnostic = { "range" => { "start" => { "line" => 0, "character" => 0 } }, "severity" => 1, "message" => "bad" }
      params = { "uri" => "file:" + "/" * 3 + "project/", "diagnostics" => [diagnostic] }
      r.messages.body(1, J.generate({ "jsonrpc" => "2.0", "method" => "textDocument/publishDiagnostics", "params" => params }))
      r.wait(2)
    end
    sent = r.processes.methods_sent.drop(from).join(",")
    server = r.assembly.services.server_for("ruby")
    running = !server.nil? && server.running?
    "#{sent}|#{running}|#{r.assembly.state.buffer.signs?}"
  end

  def self.main
    t = Carat::Testing.new("adapters_pathless_language")

    # Rows are [label, "keys|publish", "methods sent|server running|a
    # sign shown"]; each row is a fresh editor whose current buffer is a
    # :new buffer given the Ruby file type.
    t.table([
      ["sync: a pathless buffer is never opened on the server", "ifoo<Esc>|", "|true|false"],
      ["completion: a word typed in a pathless buffer asks no completion", "ifoo|", "|true|false"],
      ["hover: K in a pathless buffer asks no hover", "ifoo<Esc>K|", "|true|false"],
      ["signature: an open paren in a pathless buffer asks no signature help", "ifoo(|", "|true|false"],
      ["diagnostics: a publish draws nothing on a pathless buffer", "ifoo<Esc>|publish", "|true|false"],
      ["control: a pathless buffer written to a name is opened", "ifoo<Esc>:w c.rb<CR>|", "textDocument/didOpen|true|false"]
    ]) do |input|
      parts = input.to_s.split("|", -1)
      pathless(parts[0].to_s, parts[1].to_s == "publish")
    end

    t.finish
  end
end

AdaptersPathlessLanguageTest.main if __FILE__ == $0
