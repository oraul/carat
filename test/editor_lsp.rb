require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# :LspStart, :LspRestart, and the lsp slot on the drawn status bar.
module EditorLspTest
  INIT = "{\"jsonrpc\":\"2.0\",\"id\":1,\"result\":{\"capabilities\":{}}}"

  # An editor over a file in /project, which the user file trusts,
  # ruby-lsp installed when installed is true.
  def self.editor(path, installed)
    open_in(path, installed, "language.trusted_roots /project\n")
  end

  # An editor over a file in /project, which nothing trusts.
  def self.untrusted(path)
    open_in(path, true, "")
  end

  # An editor over a file, the user file holding user.
  def self.open_in(path, installed, user)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.rb", "x = 1\n")
    files.put("b.txt", "text\n")
    config = Carat::Doubles::FixedConfig.with_user(user.to_s)
    h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 10, cols: 60, plugins: [])
    h.processes.install("ruby-lsp") if installed
    h.open(path.to_s)
    h.wait
    h
  end

  # An editor whose server answered initialize and then published an
  # error on row 0, with the ascii icons, its message two lines with an escape sequence, and a
  # hint on the same row.
  def self.published
    h = open_in("a.rb", true, "language.trusted_roots /project\noption.icons ascii\n")
    h.messages.body(1, INIT)
    h.wait
    uri = Carat::Json.parse(h.processes.bodies[2])["params"]["textDocument"]["uri"]
    start = { "start" => { "line" => 0, "character" => 0 } }
    list = [{ "range" => start, "severity" => 4, "message" => "a hint" }, { "range" => start, "severity" => 1, "message" => "expected end\nfound EOF\e[31m" }]
    h.messages.body(1, Carat::Json.generate({ "jsonrpc" => "2.0", "method" => "textDocument/publishDiagnostics", "params" => { "uri" => uri, "diagnostics" => list } }))
    h.wait
    h.type("0")
    h
  end

  # What a case shows: the message and the status row's lsp part.
  def self.run(name)
    case name.to_s
    when "starting"
      h = editor("a.rb", true)
    when "ready"
      h = editor("a.rb", true)
      h.messages.body(1, INIT)
      h.wait
    when "crashed"
      h = editor("a.rb", true)
      h.messages.push(Carat::Domain::ServiceMessage.new(handle: 1, kind: "exit", text: ""))
      h.wait
    when "restart after a crash"
      h = editor("a.rb", true)
      h.messages.push(Carat::Domain::ServiceMessage.new(handle: 1, kind: "exit", text: ""))
      h.wait
      h.type(":LspRestart<CR>")
      h.wait
      return "#{h.processes.spawned.length} #{h.message}|#{h.assembly.status_slots.lsp_label}"
    when "restart a running server"
      h = editor("a.rb", true)
      h.messages.body(1, INIT)
      h.wait
      h.type(":LspRestart<CR>")
      h.wait
      return "#{h.processes.methods_sent.join(",")}|#{h.assembly.status_slots.lsp_label}"
    when "untrusted"
      h = untrusted("a.rb")
      h.wait
      h.redraw
      return "#{h.processes.spawned.length}|#{h.status_row.strip}"
    when "start untrusted"
      h = untrusted("a.rb")
      h.type(":LspStart<CR>")
      h.wait
      return "#{h.processes.spawned.join(",")} #{h.message}|#{h.assembly.status_slots.lsp_label}"
    when "start a running server"
      h = editor("a.rb", true)
      h.type(":LspStart<CR>")
      h.wait
      return "#{h.processes.spawned.join(",")} #{h.message}|#{h.assembly.status_slots.lsp_label}"
    when "start after a crash"
      h = editor("a.rb", true)
      h.messages.push(Carat::Domain::ServiceMessage.new(handle: 1, kind: "exit", text: ""))
      h.wait
      h.type(":LspStart<CR>")
      h.wait
      return "#{h.processes.spawned.length} #{h.message}|#{h.assembly.status_slots.lsp_label}"
    when "diagnostics"
      h = published
      h.redraw
      return "#{h.message_row.strip}|#{h.row(0)[0, 6]}|#{h.status_row.strip}"
    when "diagnostics after an edit"
      h = published
      h.type("O<Esc>")
      h.redraw
      above = "#{h.message_row.strip}|#{h.row(0)[0, 6]}|#{h.row(1)[0, 6]}"
      h.type("j")
      h.redraw
      return "#{above}|#{h.message_row.strip}"
    when "diagnostics after a crash and a start"
      h = published
      h.messages.push(Carat::Domain::ServiceMessage.new(handle: 1, kind: "exit", text: ""))
      h.wait
      h.redraw
      before = h.row(0)[0, 6]
      h.type(":LspStart<CR>")
      h.wait
      h.redraw
      return "#{before}|#{h.row(0)[0, 6]}|#{h.status_row.strip}"
    when "start a text buffer"
      h = untrusted("b.txt")
      h.type(":LspStart<CR>")
    when "start arguments"
      h = untrusted("a.rb")
      h.type(":LspStart x<CR>")
    when "a text buffer"
      h = editor("b.txt", true)
      h.type(":LspRestart<CR>")
    when "a missing command"
      h = editor("a.rb", false)
      h.type(":LspRestart<CR>")
    when "arguments"
      h = editor("a.rb", true)
      h.type(":LspRestart x<CR>")
    else
      return "unknown case"
    end
    h.redraw
    "#{h.message}|#{h.status_row.strip}"
  end

  def self.main
    t = Carat::Testing.new("editor_lsp")

    t.table([
      ["the bar shows the server starting", "starting", "\"a.rb\" 1L, 6B|NORMAL  a.rb      ruby-lsp starting  ruby  utf-8  1:1  All"],
      ["the bar shows the ready server by name", "ready", "\"a.rb\" 1L, 6B|NORMAL  a.rb               ruby-lsp  ruby  utf-8  1:1  All"],
      ["the bar names the restart after a crash, the encoding dropped at 60 columns", "crashed", "\"a.rb\" 1L, 6B|NORMAL  a.rb  ruby-lsp crashed :LspRestart  ruby  1:1  All"],
      [":LspRestart starts the server again", "restart after a crash", "2 |ruby-lsp starting"],
      [":LspRestart stops a running server first", "restart a running server", "initialize,initialized,textDocument/didOpen,shutdown,exit,initialize|ruby-lsp starting"],
      [":LspRestart on a buffer without a server", "a text buffer", "No language server for this buffer|NORMAL  b.txt                              utf-8  1:1  All"],
      [":LspRestart with a command that cannot start", "a missing command", "Cannot start ruby-lsp|NORMAL  a.rb                         ruby  utf-8  1:1  All"],
      [":LspRestart refuses arguments", "arguments", "E488: Trailing characters: x|NORMAL  a.rb      ruby-lsp starting  ruby  utf-8  1:1  All"],
      ["an untrusted directory starts nothing and names :LspStart", "untrusted", "0|NORMAL  a.rb  ruby-lsp untrusted :LspStart  ruby  1:1  All"],
      [":LspStart starts the server in an untrusted directory", "start untrusted", "ruby-lsp |ruby-lsp starting"],
      [":LspStart leaves a running server alone", "start a running server", "ruby-lsp |ruby-lsp starting"],
      [":LspStart starts the server again after a crash", "start after a crash", "2 |ruby-lsp starting"],
      [":LspStart on a buffer without a server", "start a text buffer", "No language server for this buffer|NORMAL  b.txt                              utf-8  1:1  All"],
      ["a published error is drawn as a sign, the cursor line's message, and a count", "diagnostics", "expected end found EOF[31m|X   1 |NORMAL  a.rb  X 1 ? 1      ruby-lsp  ruby  utf-8  1:1  All"],
      ["the sign and the message move with an inserted line", "diagnostics after an edit", "|    1|X   2 |expected end found EOF[31m"],
      ["a start after a crash clears the drawn diagnostics", "diagnostics after a crash and a start", "X   1 |  1 x |NORMAL  a.rb      ruby-lsp starting  ruby  utf-8  1:1  All"],
      [":LspStart refuses arguments", "start arguments", "E488: Trailing characters: x|NORMAL  a.rb  ruby-lsp untrusted :LspStart  ruby  1:1  All"]
    ]) { |name| run(name) }

    t.finish
  end
end

EditorLspTest.main if __FILE__ == $0
