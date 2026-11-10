require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
#
# gd, the peek float, the pick list, and the jump list: the whole editor
# over the production gateway and the doubles, FakeProcesses recording
# what is sent and MemoryQueue carrying what the server answers. Every
# idle read advances the manual clock by its timeout.
module AdaptersDefinitionsTest
  J = Carat::Json
  D = Carat::Domain

  # The editor with readers for the doubles and the last frame.
  class Rig
    attr_reader :files #: Carat::Doubles::MemoryFiles
    attr_reader :terminal #: Carat::Doubles::FakeTerminal
    attr_reader :processes #: Carat::Doubles::FakeProcesses
    attr_reader :messages #: Carat::Doubles::MemoryQueue
    attr_reader :assembly #: Carat::Adapters::EditorAssembly
    attr_reader :frame #: Carat::Domain::Frame

    #: (files: Carat::Doubles::MemoryFiles, terminal: Carat::Doubles::FakeTerminal, processes: Carat::Doubles::FakeProcesses, messages: Carat::Doubles::MemoryQueue, assembly: Carat::Adapters::EditorAssembly) -> void
    def initialize(files:, terminal:, processes:, messages:, assembly:)
      @files = files
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

    #: () -> Integer
    def sent
      @processes.methods_sent.count("textDocument/definition")
    end

    #: () -> Integer
    def float_count
      @assembly.state.tab.floats.count
    end

    #: () -> String
    def message
      @assembly.state.message
    end

    # The current buffer's path, or its title for a scratch buffer, and
    # the cursor, as "name row:col".
    #: () -> String
    def where
      buffer = @assembly.state.buffer
      cursor = @assembly.state.window.cursor
      name = buffer.scratch? ? buffer.title : buffer.path_text
      "#{name} #{cursor.row}:#{cursor.col}"
    end
  end

  # An editor over a.rb in the trusted /project with ruby-lsp installed,
  # b.rb beside it and c.rb outside, its initialize answered with the
  # capabilities given.
  #: (Hash[String, untyped]) -> Rig
  def self.rig(capabilities)
    files = Carat::Doubles::MemoryFiles.new
    files.move_to("/project")
    files.put("a.rb", "def greet\n  puts 1\nend\ngreet\n")
    files.put("b.rb", "# b\ndef other\n  2\nend\n")
    files.put("lib/x.rb", "x\n")
    files.put("/gems/c.rb", "# c\ndef far\n  3\nend\n")
    clock = Carat::Doubles::ManualClock.new
    terminal = Carat::Doubles::FakeTerminal.new(clock: clock, rows: 12, cols: 40)
    processes = Carat::Doubles::FakeProcesses.new
    processes.install("ruby-lsp")
    messages = Carat::Doubles::MemoryQueue.new
    completions = Carat::Adapters::ServerCompletions.new
    config = Carat::Doubles::FixedConfig.new(value: Carat::Doubles::FixedConfig.with_user("language.trusted_roots /project\noption.icons ascii\n"))
    assembly = Carat::Adapters::EditorAssembly.new(terminal: terminal, clock: clock, files: files, config: config, processes: processes, messages: messages, completions: completions, plugin_list: [])
    r = Rig.new(files: files, terminal: terminal, processes: processes, messages: messages, assembly: assembly)
    assembly.screen_presenter.enter
    assembly.open("a.rb")
    r.wait
    init = { "capabilities" => capabilities, "serverInfo" => { "name" => "ruby-lsp" } }
    messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => 1, "result" => init }))
    r.wait
    r
  end

  # A server that offers definitions, the cursor on the call of greet.
  #: () -> Rig
  def self.defining
    r = rig({ "definitionProvider" => true })
    r.type("3j")
    r
  end

  # The file URI of an absolute path, joined so no link is in the source.
  #: (String) -> String
  def self.uri(path)
    "file:" + "//" + path
  end

  #: (String, Integer, Integer) -> Hash[String, untyped]
  def self.location(path, line, character)
    at = { "line" => line, "character" => character }
    { "uri" => uri(path), "range" => { "start" => at, "end" => at } }
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

  #: (Rig) -> Integer
  def self.request_id(r)
    last_of(r, "textDocument/definition")["id"].to_i
  end

  # Answers the last definition request with the result.
  def self.answer(r, result)
    r.messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => request_id(r), "result" => result }))
  end

  # The keys, their request sent at the next idle tick, the answer read
  # at the one after.
  def self.asked(r, keys, result)
    r.type(keys.to_s)
    r.wait
    answer(r, result)
    r.wait
    nil
  end

  # The rows of the float with the id, empty when it does not show.
  #: (Rig, Integer) -> Array[String]
  def self.float_lines(r, id)
    out = [""]
    out.clear
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

  def self.main
    t = Carat::Testing.new("adapters_definitions")

    # No server offers definitions.
    r = rig({})
    link = last_of(r, "initialize")["params"]["capabilities"]["textDocument"]["definition"]["linkSupport"]
    t.assert_equal(true, link, "initialize advertises definitions with links")
    r.type("gd")
    r.wait
    t.assert_equal(["method textDocument/definition is not supported by any of the servers registered for the current buffer", 0], [r.message, r.sent], "gd with no defining server is refused")

    # The request and one target in the same file.
    r = defining
    r.type("gd")
    t.assert_equal([0, true], [r.sent, r.assembly.services.waiting?], "gd records the ask and no key waits on the server")
    r.wait
    request = last_of(r, "textDocument/definition")
    t.assert_equal([3, 0, true], [request["params"]["position"]["line"], request["params"]["position"]["character"], request["params"]["textDocument"]["uri"].to_s.end_with?("/a.rb")], "gd sends the request at the next idle tick")
    answer(r, location("/project/a.rb", 0, 4))
    r.wait
    t.assert_equal(["a.rb 0:4", 1, 3], [r.where, r.assembly.jumps.count, r.assembly.jumps.rows[0]], "One target in the same file moves the cursor")
    r.type("<C-o>")
    t.assert_equal("a.rb 3:0", r.where, "Ctrl-O returns to the position gd left")
    r.type("<C-i>")
    t.assert_equal("a.rb 0:4", r.where, "Ctrl-O returns and Ctrl-I goes forward again")

    # Another project file, and the jump back across buffers.
    r = defining
    asked(r, "gd", [location("/project/b.rb", 1, 4)])
    t.assert_equal(["b.rb 1:4", "\"b.rb\" 4L, 22B"], [r.where, r.message], "One target in another project file opens it")
    r.type("<C-o>")
    t.assert_equal("a.rb 3:0", r.where, "Ctrl-O from another file shows the buffer gd left")
    r.type("<C-i>")
    t.assert_equal("b.rb 1:4", r.where, "Ctrl-I shows the target's buffer again")

    # A LocationLink, a character past the line, and one after multibyte
    # characters, the column counted in code points.
    r = defining
    link_target = { "targetUri" => uri("/project/b.rb"), "targetRange" => { "start" => { "line" => 0, "character" => 0 } }, "targetSelectionRange" => { "start" => { "line" => 3, "character" => 9 } } }
    asked(r, "gd", [link_target])
    t.assert_equal("b.rb 3:2", r.where, "a location link goes to its selection range, the column clamped to the line")
    r = defining
    r.files.put("m.rb", "s = \"\u{E9}\u{1F600}\"; t\n")
    asked(r, "gd", location("/project/m.rb", 0, 11))
    t.assert_equal("m.rb 0:10", r.where, "a character after multibyte characters lands on its code point column")

    # Answers that go nowhere.
    r = defining
    asked(r, "gd", nil)
    first = r.message
    asked(r, "gd", [])
    second = r.message
    asked(r, "gd", [{ "uri" => "untitled:x", "range" => { "start" => { "line" => 0, "character" => 0 } } }])
    third = r.message
    r.type("gd")
    r.wait
    r.messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => request_id(r), "error" => { "code" => -32_603, "message" => "boom" } }))
    r.wait
    t.assert_equal([["No locations found", "No locations found", "No locations found", "No locations found"], "a.rb 3:0", 0], [[first, second, third, r.message], r.where, r.assembly.jumps.count], "An empty answer shows No locations found")

    # A modified buffer refuses another file, not its own.
    r = defining
    r.type("x")
    asked(r, "gd", location("/project/b.rb", 1, 0))
    t.assert_equal(["E37: No write since last change (add ! to override)", "a.rb 3:0"], [r.message, r.where], "A modified buffer refuses a jump to another file")

    # Stale answers.
    r = defining
    r.type("gd")
    r.wait
    first_id = request_id(r)
    r.type("gd")
    r.wait
    r.messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => first_id, "result" => location("/project/b.rb", 1, 0) }))
    r.wait
    t.assert_equal(["a.rb 3:0", first_id, 2], [r.where, last_of(r, "$/cancelRequest")["params"]["id"], r.sent], "A new gd cancels the request in flight")
    r = defining
    r.type("gd")
    r.wait
    first_id = request_id(r)
    r.type("gd")
    r.messages.body(1, J.generate({ "jsonrpc" => "2.0", "id" => first_id, "result" => location("/project/b.rb", 1, 0) }))
    r.wait
    t.assert_equal(["a.rb 3:0", 2], [r.where, r.sent], "an answer to a replaced ask is dropped though it arrives before the next request goes out")
    r = defining
    r.type("gd")
    r.wait
    r.type("k")
    answer(r, location("/project/b.rb", 1, 0))
    r.wait
    t.assert_equal(["a.rb 2:0", 0, false], [r.where, r.float_count, r.assembly.services.waiting?], "An answer after the cursor moved is dropped")
    r = defining
    r.type("gd")
    r.wait
    n = 0
    while n < 200 && r.assembly.services.waiting?
      r.wait
      n += 1
    end
    t.assert_equal([request_id(r), false, true], [last_of(r, "$/cancelRequest")["params"]["id"], r.assembly.services.waiting?, n >= 99 && n <= 102], "An unanswered request is cancelled after two seconds")

    # The peek float.
    r = defining
    asked(r, "<Space>dd", location("/project/b.rb", 1, 4))
    peek = r.assembly.definition.float_id
    t.assert_equal([["def other", "  2", "end"], "a.rb 3:0", 0, false], [float_lines(r, peek), r.where, r.assembly.jumps.count, r.assembly.state.tab.floats.focused?], "Peek shows the target lines and keeps the cursor")
    t.assert_equal(true, r.frame.text_rows.join("\n").include?("b.rb:2"), "the peek float is titled with the path and line")
    r.type("<Esc>")
    t.assert_equal([0, 0], [r.float_count, r.assembly.definition.float_id], "Esc closes the peek float")
    asked(r, "<Space>dd", location("/project/b.rb", 1, 4))
    r.type("k")
    t.assert_equal([0, 0], [r.float_count, r.assembly.definition.float_id], "a cursor move closes the peek float")
    asked(r, "<Space>dd", location("/gems/c.rb", 1, 0))
    t.assert_equal(["def far", "  3", "end"], float_lines(r, r.assembly.definition.float_id), "peek shows a file outside the project")

    # The pick list.
    r = defining
    asked(r, "gd", [location("/project/a.rb", 0, 4), location("/project/b.rb", 1, 4)])
    pick = r.assembly.definition.pick_id
    rows = float_lines(r, pick)
    r.type("j")
    r.type("<CR>")
    t.assert_equal([["1 a.rb:1", "2 b.rb:2"], "b.rb 1:4", 0, 0], [rows, r.where, r.float_count, r.assembly.definition.pick_id], "Several targets list them and Enter picks one")
    r.type("<C-o>")
    t.assert_equal("a.rb 3:0", r.where, "Ctrl-O after a pick returns to where gd was typed")
    asked(r, "gd", [location("/project/a.rb", 0, 4), location("/project/b.rb", 1, 4)])
    focused = r.assembly.state.tab.floats.focused?
    r.type("<Esc>")
    t.assert_equal([true, 0, "a.rb 3:0"], [focused, r.float_count, r.where], "Esc closes the pick list")
    asked(r, "<Space>dd", [location("/project/a.rb", 0, 4), location("/project/b.rb", 1, 4)])
    r.type("j<CR>")
    t.assert_equal([["def other", "  2", "end"], "a.rb 3:0"], [float_lines(r, r.assembly.definition.float_id), r.where], "Enter in a peek's pick list peeks at the row's target")

    # Paths.
    r = defining
    asked(r, "gd", location("/gems/c.rb", 1, 4))
    title = r.where
    scratch = r.assembly.state.buffer.scratch?
    r.type(":w<CR>")
    t.assert_equal(["/gems/c.rb 1:4", true, true], [title, scratch, r.message.start_with?("E382")], "A target outside the project opens read-only")
    r.type("<C-o>")
    t.assert_equal("a.rb 3:0", r.where, "Ctrl-O leaves the read-only view")
    r = defining
    r.files.put("/project/out.rb", "# c\ndef far\n  3\nend\n")
    r.files.link_to("/project/out.rb", "/gems/c.rb")
    asked(r, "gd", location("/project/out.rb", 0, 0))
    t.assert_equal(["/project/out.rb 0:0", true], [r.where, r.assembly.state.buffer.scratch?], "a target linked out of the project opens read-only")
    r = defining
    asked(r, "gd", location("/project/lib", 0, 0))
    t.assert_equal(["\"lib\" is a directory", "a.rb 3:0", 0], [r.message, r.where, r.assembly.jumps.count], "A target that is not a regular file is refused")
    r = defining
    asked(r, "gd", location("/gems", 0, 0))
    t.assert_equal(["\"/gems\" is a directory", "a.rb 3:0"], [r.message, r.where], "a directory outside the project is refused")
    r = defining
    asked(r, "gd", [{ "uri" => uri("/project/b%2Erb"), "range" => { "start" => { "line" => 2, "character" => 2 } } }, { "uri" => uri("relative/x.rb"), "range" => { "start" => { "line" => 0, "character" => 0 } } }, { "uri" => uri("/project/a%00.rb"), "range" => { "start" => { "line" => 0, "character" => 0 } } }, { "uri" => uri("/project/b.rb"), "range" => { "start" => { "line" => -1, "character" => 0 } } }])
    t.assert_equal("b.rb 2:2", r.where, "escapes are decoded and relative, NUL, and negative targets are dropped")

    # The jump list's ends.
    r = defining
    r.type("<C-o>")
    t.assert_equal("a.rb 3:0", r.where, "Ctrl-O past the oldest entry does nothing in the editor")
    r = defining
    asked(r, "gd", location("/project/b.rb", 1, 4))
    r.type("x")
    r.type("<C-o>")
    t.assert_equal(["E37: No write since last change (add ! to override)", "b.rb 1:4"], [r.message, r.where], "Ctrl-O refuses another buffer over a modified one")
    r.type(":w<CR>")
    r.type("<C-o>")
    t.assert_equal(["a.rb 3:0", 2], [r.where, r.assembly.jumps.count], "A refused Ctrl-O leaves the jump list as it was")
    r.type("<C-i>")
    t.assert_equal("b.rb 1:4", r.where, "Ctrl-I after a refused Ctrl-O returns to the start")
    r = defining
    gone = r.assembly.state.buffer.id
    asked(r, "gd", location("/project/b.rb", 1, 4))
    r.type(":bd #{gone}<CR>")
    r.type("<C-o>")
    t.assert_equal(["b.rb 1:4", 1], [r.where, r.assembly.jumps.count], "Ctrl-O drops an entry whose buffer is gone and stays")
    r = defining
    r.type("4l")
    asked(r, "gd", location("/project/a.rb", 0, 4))
    r.assembly.state.buffer.set_lines(3, 4, ["\u{E9}\u{E9}"])
    r.type("<C-o>")
    t.assert_equal("a.rb 3:1", r.where, "Ctrl-O clamps the column to a line shortened since, in code points")

    t.finish
  end
end

AdaptersDefinitionsTest.main if __FILE__ == $0
