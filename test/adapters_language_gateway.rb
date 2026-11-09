require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# The language server client over the doubles: FakeProcesses records what
# the editor sends, and MemoryQueue carries what a server's reader thread
# would push. Every exchange happens at an idle tick (wait).
module AdaptersLanguageGatewayTest
  J = Carat::Json
  INIT = "{\"jsonrpc\":\"2.0\",\"id\":1,\"result\":{\"capabilities\":{},\"serverInfo\":{\"name\":\"ruby-lsp\"}}}"

  # An editor over a.rb in /project, a trusted root, with ruby-lsp
  # installed when installed is true.
  def self.editor(installed)
    in_dir("/project", "/project", installed)
  end

  # An editor over a.rb in a working directory, the user file trusting
  # roots ("" for no trusted_roots line).
  def self.in_dir(cwd, roots, installed)
    files = Carat::Doubles::MemoryFiles.new
    files.move_to(cwd.to_s)
    files.put("a.rb", "x = 1\n")
    files.put("b.txt", "text\n")
    user = roots.to_s.empty? ? "" : "language.trusted_roots #{roots}\n"
    config = Carat::Doubles::FixedConfig.with_user(user)
    h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 10, cols: 60, plugins: [])
    h.processes.install("ruby-lsp") if installed
    h
  end

  # What opening a.rb in a directory starts: the commands spawned and the
  # slot.
  def self.opened(cwd, roots)
    h = in_dir(cwd, roots, true)
    h.open("a.rb")
    h.wait
    h.wait
    "#{h.processes.spawned.join(",")}|#{label(h)}"
  end

  # An editor whose server answered initialize.
  def self.ready
    h = editor(true)
    h.open("a.rb")
    h.wait
    h.messages.body(1, INIT)
    h.wait
    h
  end

  # The methods sent since a count of bodies.
  def self.sent_since(h, from)
    h.processes.methods_sent.drop(from.to_i)
  end

  # The last body sent, parsed.
  def self.last_body(h)
    J.parse(h.processes.bodies.last.to_s)
  end

  def self.label(h)
    h.assembly.status_slots.lsp_label
  end

  # What an initialize answer leaves after a typed key and an idle tick:
  # the slot, the methods sent, and the handles stopped.
  def self.after_init(body)
    h = editor(true)
    h.open("a.rb")
    h.wait
    h.messages.body(1, body.to_s)
    h.wait
    h.type("ix")
    h.wait
    "#{label(h)}|#{h.processes.methods_sent.join(",")}|#{h.processes.stopped.join(",")}"
  end

  def self.notify(h, method, params)
    h.messages.body(1, J.generate({ "jsonrpc" => "2.0", "method" => method, "params" => params }))
    h.wait
  end

  def self.main
    t = Carat::Testing.new("adapters_language_gateway")

    # Start and initialize.
    h = editor(true)
    h.open("a.rb")
    h.wait
    t.assert_equal([["ruby-lsp"], ["initialize"], "ruby-lsp starting"], [h.processes.spawned, h.processes.methods_sent, label(h)], "a Ruby buffer starts ruby-lsp and sends initialize")
    init = last_body(h)
    t.assert_equal([1, true, true], [init["id"], init["params"]["rootUri"].to_s.start_with?("file:" + "/" * 3), init["params"]["capabilities"]["window"]["workDoneProgress"]], "initialize names the root and the progress capability")
    h.wait
    t.assert_equal([1, 1], [h.processes.spawned.length, h.processes.bodies.length], "the next idle tick starts nothing more and sends nothing before the answer")
    h.messages.body(1, INIT)
    h.wait
    t.assert_equal([["initialize", "initialized", "textDocument/didOpen"], "ruby-lsp"], [h.processes.methods_sent, label(h)], "the answer makes it ready and opens the buffer")
    opened = last_body(h)["params"]["textDocument"]
    t.assert_equal(["ruby", 1, "x = 1\n", true], [opened["languageId"], opened["version"], opened["text"], opened["uri"].to_s.end_with?("/a.rb")], "didOpen carries the language, version 1, the text, and the file URI")
    t.assert_equal([false, true], [init["params"]["capabilities"]["textDocument"]["completion"]["completionItem"]["snippetSupport"], init["params"]["capabilities"]["textDocument"]["completion"]["contextSupport"]], "initialize advertises completion without snippets")

    # A failed initialize is a crash: nothing more is sent. Rows are
    # [label, the answer, "slot|methods sent|handles stopped"].
    t.table([
      ["a result makes the server ready", INIT, "ruby-lsp|initialize,initialized,textDocument/didOpen,textDocument/didChange|"],
      ["an initialize error stops the server as crashed and sends nothing more", "{\"jsonrpc\":\"2.0\",\"id\":1,\"error\":{\"code\":-32603,\"message\":\"boom\"}}", "ruby-lsp crashed :LspRestart|initialize|1"],
      ["an error beside a result is still an error", "{\"jsonrpc\":\"2.0\",\"id\":1,\"result\":{},\"error\":{\"code\":1}}", "ruby-lsp crashed :LspRestart|initialize|1"],
      ["a null result is a crash", "{\"jsonrpc\":\"2.0\",\"id\":1,\"result\":null}", "ruby-lsp crashed :LspRestart|initialize|1"],
      ["an answer to another id changes nothing", "{\"jsonrpc\":\"2.0\",\"id\":7,\"error\":{\"code\":1}}", "ruby-lsp starting|initialize|"]
    ]) { |body| after_init(body.to_s) }

    # Trust: a server starts on its own only under a trusted root, which a
    # project file cannot set. Rows are [label, "cwd|roots", what opening
    # a.rb starts].
    untrusted = "|ruby-lsp untrusted :LspStart"
    t.table([
      ["no trusted_roots line spawns nothing", "/project|", untrusted],
      ["the root itself", "/project|/project", "ruby-lsp|ruby-lsp starting"],
      ["a directory under a root", "/project/app|/other /project/", "ruby-lsp|ruby-lsp starting"],
      ["a sibling sharing the prefix", "/projectx|/project", untrusted],
      ["a root under the home", "/home/user/src/app|~/src", "ruby-lsp|ruby-lsp starting"],
      ["a relative root is no root", "/project|project", untrusted],
      ["a root with a .. segment is no root", "/etc|/project/..", untrusted],
      ["the filesystem root trusts everything", "/project|/", "ruby-lsp|ruby-lsp starting"]
    ]) do |dirs|
      parts = dirs.to_s.split("|", -1)
      opened(parts[0].to_s, parts[1].to_s)
    end
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.rb", "x = 1\n")
    h = Carat::Doubles::EditorHarness.new(files: files, config: Carat::Doubles::FixedConfig.with("language.trusted_roots /project\n"), rows: 10, cols: 60, plugins: [])
    h.processes.install("ruby-lsp")
    h.open("a.rb")
    h.wait
    t.assert_equal([[], "ruby-lsp untrusted :LspStart"], [h.processes.spawned, label(h)], "a project file cannot trust its own directory")

    # Change, save, close.
    h = ready
    n = h.processes.bodies.length
    h.wait
    t.assert_equal([], sent_since(h, n), "an unchanged buffer sends nothing")
    h.type("x")
    h.wait
    change = last_body(h)["params"]
    t.assert_equal([["textDocument/didChange"], 2, " = 1\n"], [sent_since(h, n), change["textDocument"]["version"], change["contentChanges"][0]["text"]], "an edit sends the whole text at the next idle tick with version 2")
    h.type("u")
    h.wait
    t.assert_equal([3, "x = 1\n"], [last_body(h)["params"]["textDocument"]["version"], last_body(h)["params"]["contentChanges"][0]["text"]], "an undo is a change with a higher version")
    n = h.processes.bodies.length
    h.type(":w<CR>")
    h.wait
    t.assert_equal(["textDocument/didSave"], sent_since(h, n), "a write sends didSave")
    n = h.processes.bodies.length
    h.type(":e b.txt<CR>")
    h.wait
    t.assert_equal([[], "", true], [sent_since(h, n), label(h), h.assembly.services.server_for("ruby").running?], "a text buffer hides the slot and keeps the server")
    h.type(":e a.rb<CR>:bd<CR>")
    h.wait
    t.assert_equal(["textDocument/didClose"], sent_since(h, n), "closing the buffer sends didClose")

    # Progress and server requests.
    h = ready
    n = h.processes.bodies.length
    h.messages.body(1, "{\"jsonrpc\":\"2.0\",\"id\":\"tok\",\"method\":\"window/workDoneProgress/create\",\"params\":{\"token\":\"t\"}}")
    h.wait
    reply = last_body(h)
    t.assert_equal(["tok", true, nil], [reply["id"], reply.key?("result"), reply["result"]], "a progress token request gets a null result")
    h.messages.body(1, "{\"jsonrpc\":\"2.0\",\"id\":7,\"method\":\"workspace/applyEdit\",\"params\":{}}")
    h.wait
    t.assert_equal([7, -32_601], [last_body(h)["id"], last_body(h)["error"]["code"]], "another request is refused as not found")
    notify(h, "$/progress", { "token" => "t", "value" => { "kind" => "begin", "title" => "Indexing" } })
    t.assert_equal("ruby-lsp indexing 0%", label(h), "progress begins")
    notify(h, "$/progress", { "token" => "t", "value" => { "kind" => "report", "percentage" => 42 } })
    t.assert_equal("ruby-lsp indexing 42%", label(h), "progress reports a percent")
    notify(h, "$/progress", { "token" => "t", "value" => { "kind" => "report", "percentage" => 900 } })
    t.assert_equal("ruby-lsp indexing 100%", label(h), "a percent over 100 is capped")
    notify(h, "$/progress", { "token" => "t", "value" => { "kind" => "end" } })
    t.assert_equal("ruby-lsp", label(h), "progress ends")
    slots = h.assembly.status_slots
    notify(h, "$/progress", { "token" => "t", "value" => { "kind" => "begin", "title" => "Indexing", "percentage" => 10 } })
    notify(h, "$/progress", { "token" => "t", "value" => { "kind" => "report", "message" => "3/7 files", "percentage" => 42 } })
    t.assert_equal([true, "Indexing 3/7 files", 42], [slots.progress?, slots.progress_label, slots.progress_percent], "the progress segment takes the title, the message, and the percent")
    notify(h, "$/progress", { "token" => "t", "value" => { "kind" => "report", "message" => "\e[31mred\e[0m\nnext" } })
    t.assert_equal(["Indexing red next", 42], [slots.progress_label, slots.progress_percent], "a message is one line without escape sequences, the percent kept")
    notify(h, "$/progress", { "token" => "t", "value" => { "kind" => "end" } })
    t.assert_equal([false, false], [slots.progress?, h.status_row.include?("Indexing")], "the progress segment goes at the end")

    # Server messages as notifications.
    notices = h.assembly.notices
    notify(h, "window/showMessage", { "type" => 1, "message" => "Bundle failed" })
    notify(h, "window/showMessage", { "type" => 2, "message" => "slow \e]0;title\a disk\nnow" })
    notify(h, "window/showMessage", { "type" => 9, "message" => "x" * 300 })
    t.assert_equal([3, "Bundle failed", 2, "slow  disk now", 1, 200, 0], [notices.count, notices.text_at(0), notices.level_at(0), notices.text_at(1), notices.level_at(1), notices.text_at(2).length, notices.level_at(2)], "type 1 an error, 2 a warning, another info, on one line without sequences, cut at 200")
    t.assert_true(h.state.history.to_s.include?("Bundle failed"), "a server message is kept in the history")
    notify(h, "window/showMessage", { "type" => 1, "message" => 7 })
    notify(h, "window/showMessage", { "type" => 1, "message" => "  " })
    t.assert_equal([3, "Bundle failed"], [notices.count, notices.text_at(0)], "a message that is not text, or blank, shows nothing")

    # Diagnostics as values.
    path = h.buffer.path
    two = [{ "range" => { "start" => { "line" => 2, "character" => 4 } }, "severity" => 1, "message" => "bad\e[31m" }, { "range" => { "start" => { "line" => 0, "character" => 0 } }, "severity" => 9, "message" => "x" }]
    uri = J.parse(h.processes.bodies[2])["params"]["textDocument"]["uri"]
    notify(h, "textDocument/publishDiagnostics", { "uri" => uri, "diagnostics" => two })
    got = h.assembly.services.diagnostics(path)
    t.assert_equal([2, 2, 4, 1, "bad[31m", 4], [got.count, got.at(0).row, got.at(0).col, got.at(0).severity, got.at(0).message, got.at(1).severity], "diagnostics are kept stripped, the severity bounded")
    slots = h.assembly.status_slots
    hint = Carat::Domain::Icons.glyph("hint", h.state.options.icons)
    t.assert_equal([hint, "x", 1, 0, 1], [h.buffer.sign_at(0), h.buffer.diagnostic_at(0).message, slots.errors, slots.warnings, slots.hints], "a publish is drawn at the idle tick: a sign on a row inside the buffer, its message, and the counts")
    notify(h, "textDocument/publishDiagnostics", { "uri" => uri, "diagnostics" => [{ "range" => { "start" => { "line" => 5, "character" => 1 } }, "message" => "only" }] })
    got = h.assembly.services.diagnostics(path)
    t.assert_equal([1, 5, "only", 1], [got.count, got.at(0).row, got.at(0).message, got.at(0).severity], "a later publish replaces the file's diagnostics, an error when no severity is given")
    t.assert_equal([false, true, 1, 0], [h.buffer.signs?, h.buffer.diagnostic_at(0).nil?, slots.errors, slots.hints], "the later publish replaces the signs and the counts, a row past the end counted but not drawn")
    t.assert_equal([true, false], [Carat::Domain::Diagnostic.new(row: 0, col: 0, severity: 1, message: "").error?, Carat::Domain::Diagnostic.new(row: 0, col: 0, severity: 2, message: "").error?], "a diagnostic of severity 1 is an error")
    many = []
    1100.times { many << { "range" => { "start" => { "line" => 0, "character" => 0 } }, "message" => "m" * 600 } }
    notify(h, "textDocument/publishDiagnostics", { "uri" => uri, "diagnostics" => many })
    got = h.assembly.services.diagnostics(path)
    t.assert_equal([1000, 500], [got.count, got.at(0).message.bytesize], "at most 1,000 diagnostics of at most 500 bytes")
    notify(h, "textDocument/publishDiagnostics", { "uri" => uri, "diagnostics" => [] })
    t.assert_equal([false, false, true], [h.buffer.signs?, slots.diagnostics?, h.buffer.diagnostic_at(0).nil?], "an empty publish clears the signs and the counts")
    notify(h, "textDocument/publishDiagnostics", { "uri" => uri + "x", "diagnostics" => two })
    t.assert_equal([false, false], [h.buffer.signs?, slots.diagnostics?], "a publish for a file no buffer shows draws nothing")
    notify(h, "textDocument/publishDiagnostics", { "uri" => uri, "diagnostics" => two })
    h.type(":LspRestart<CR>")
    h.wait
    t.assert_equal([false, false], [h.buffer.signs?, slots.diagnostics?], "a restart clears the drawn diagnostics")

    # Hostile output.
    h = editor(true)
    h.open("a.rb")
    h.wait
    h.messages.body(1, "{not json")
    h.messages.body(1, "[1,2]")
    h.messages.body(1, "\"\xFF\"")
    h.messages.body(1, ("[" * 70) + ("]" * 70))
    h.messages.body(9, INIT)
    h.messages.body(1, "{\"jsonrpc\":\"2.0\",\"id\":1,\"result\":{\"serverInfo\":{\"name\":\"evil\\u001b]0;x\\u0007\"}}}")
    h.wait
    t.assert_equal("evil]0;x", label(h), "malformed bodies are dropped, another handle is ignored, and the name loses its controls")
    70.times { h.messages.body(1, "{}") }
    h.wait
    t.assert_equal(6, h.messages.count, "one idle tick reads at most 64 messages")

    # Crash, overflow, and stop.
    h = ready
    h.messages.push(Carat::Domain::ServiceMessage.new(handle: 1, kind: "exit", text: ""))
    h.wait
    t.assert_equal(["ruby-lsp crashed :LspRestart", [1]], [label(h), h.processes.stopped], "output that ends crashes the server")
    h.wait
    t.assert_equal(1, h.processes.spawned.length, "a crashed server is not started again on its own")
    h = ready
    h.messages.push(Carat::Domain::ServiceMessage.new(handle: 1, kind: "overflow", text: ""))
    h.wait
    t.assert_equal("ruby-lsp crashed :LspRestart", label(h), "an oversized frame crashes the server")
    h = ready
    h.processes.break_input(1)
    h.type("x")
    h.wait
    t.assert_equal("ruby-lsp crashed :LspRestart", label(h), "a broken input crashes the server")
    h = ready
    n = h.processes.bodies.length
    h.assembly.services.stop
    t.assert_equal([["shutdown", "exit"], [1], "ruby-lsp stopped"], [sent_since(h, n), h.processes.stopped, label(h)], "stop sends shutdown and exit and stops the child")

    # Nothing starts without a command.
    h = editor(false)
    h.open("a.rb")
    h.wait
    h.wait
    t.assert_equal([[], ""], [h.processes.spawned, label(h)], "a missing command leaves the slot empty")
    h = editor(true)
    h.open("b.txt")
    h.wait
    t.assert_equal([], h.processes.spawned, "a text file starts nothing")

    t.finish
  end
end

AdaptersLanguageGatewayTest.main if __FILE__ == $0
