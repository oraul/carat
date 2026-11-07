require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# :LspRestart and the lsp slot on the drawn status bar.
module EditorLspTest
  INIT = "{\"jsonrpc\":\"2.0\",\"id\":1,\"result\":{\"capabilities\":{}}}"

  # An editor over a file, ruby-lsp installed when installed is true.
  def self.editor(path, installed)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.rb", "x = 1\n")
    files.put("b.txt", "text\n")
    h = Carat::Doubles::EditorHarness.default(files, 10, 60)
    h.processes.install("ruby-lsp") if installed
    h.open(path.to_s)
    h.wait
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
      [":LspRestart refuses arguments", "arguments", "E488: Trailing characters: x|NORMAL  a.rb      ruby-lsp starting  ruby  utf-8  1:1  All"]
    ]) { |name| run(name) }

    t.finish
  end
end

EditorLspTest.main if __FILE__ == $0
