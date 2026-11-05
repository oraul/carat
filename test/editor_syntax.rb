require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module EditorSyntaxTest
  D = Carat::Domain
  H = D::Highlight

  # The highlighted parts of a frame row: consecutive cells of one syntax or
  # Visual group as "Group:text", the normal text, the gutter, and the
  # chrome left out.
  #: (Carat::Doubles::EditorHarness, Integer) -> String
  def self.spans(h, row)
    frame = h.frame
    words = []
    text = +""
    group = -1
    col = 0
    while col < frame.cols
      hl = frame.hl_at(row, col)
      hl = -1 unless H.token?(hl) || hl == H::VISUAL
      if hl != group
        words << "#{H.name_of(group)}:#{text}" if group >= 0
        text = +""
        group = hl
      end
      text << frame.code_at(row, col) if group >= 0 && frame.width_at(row, col) > 0
      col += 1
    end
    words << "#{H.name_of(group)}:#{text}" if group >= 0
    words.join(" ")
  end

  #: (Array[untyped]) -> Carat::Doubles::EditorHarness
  def self.editor(plugins)
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.rb", "def go = \"hi\" # note\nx = 1\ny = 2\n")
    files.put("notes.txt", "def go\n")
    Carat::Doubles::EditorHarness.with_plugins(files, 12, 60, plugins)
  end

  # A tokenizer that raises disables its plugin and leaves the buffer plain.
  class Boom < Carat::PluginApi::Plugin
    # Returns the manifest.
    # @rbs skip
    def manifest
      Carat::PluginApi::Manifest.new(name: "boom", version: "1.0.0", api_version: "2.0", actions: {}, commands: {}, bindings: [], events: [], options: [], option_types: {}, filetypes: ["ruby"])
    end

    # Raises.
    # @rbs filetype: String
    # @rbs text: String
    # @rbs state: Integer
    # @rbs tokens: Array[Integer]
    def tokenize(filetype, text, state, tokens)
      raise ArgumentError, "bad line"
    end
  end

  # Only the visible rows and the rows above them are tokenized.
  #: (Integer) -> String
  def self.ruby_source(lines)
    out = +""
    i = 0
    while i < lines
      case i % 10
      when 0 then out << "# block #{i} TODO tidy\n"
      when 1 then out << "def method_#{i}(arg)\n"
      when 2 then out << "  text = <<~SQL\n"
      when 3 then out << "    select #{"\#{arg}"} from t#{i}\n"
      when 4 then out << "    where id = 1\n"
      when 5 then out << "  SQL\n"
      when 6 then out << "  message = \"first #{i}\n"
      when 7 then out << "    second\"\n"
      when 8 then out << "  [:a, 1.5, /x/]\n"
      else out << "end\n"
      end
      i += 1
    end
    out
  end

  def self.main
    t = Carat::Testing.new("editor_syntax")

    # A Ruby file is highlighted from the first frame.
    h = editor([Carat::Plugins::Ruby::Plugin.new])
    h.open("a.rb")
    t.assert_equal("Define:def Function:go String:\"hi\" Comment:# note", spans(h, 0), "a.rb is highlighted by the ruby plugin")
    t.assert_equal("Number:1", spans(h, 1), "every visible row is")
    t.assert_equal([H::LINE_NUMBER, H::DEFINE], [h.frame.hl_at(0, 2), h.frame.hl_at(0, 4)], "the gutter keeps its group, the text takes the token's")

    # A selection is drawn over the tokens, which come back after it.
    h.type("wve")
    t.assert_equal("Define:def Visual:g Function:o String:\"hi\" Comment:# note", spans(h, 0), "the selection covers the selected cells, the cursor cell keeps its token")
    h.type("<Esc>")
    t.assert_equal("Define:def Function:go String:\"hi\" Comment:# note", spans(h, 0), "and the tokens are back after it")

    # An opened string highlights the rows after it; undo restores them.
    h.type("j0i\"<Esc>")
    t.assert_equal(["String:\"x = 1", "String:y = 2"], [spans(h, 1), spans(h, 2)], "an unclosed quote makes the rows after it String")
    h.type("u")
    t.assert_equal(["Number:1", "Number:2"], [spans(h, 1), spans(h, 2)], "undo restores their highlights")
    h.type("<C-r>")
    t.assert_equal("String:y = 2", spans(h, 2), "redo makes them String again")
    h.type("u")

    # :syntax off and on.
    h.type(":syntax off<CR>")
    t.assert_equal(["", ""], [spans(h, 0), h.message], ":syntax off draws every buffer plain")
    h.type(":sy on<CR>")
    t.assert_equal("Define:def Function:go String:\"hi\" Comment:# note", spans(h, 0), ":sy on highlights again")
    h.type(":syntax enable<CR>")
    t.assert_equal("Define:def Function:go String:\"hi\" Comment:# note", spans(h, 0), ":syntax enable keeps it on")
    h.type(":syntax clear<CR>")
    t.assert_equal("E410: Invalid :syntax subcommand: clear", h.message, "an unknown subcommand is refused")
    h.type(":syntax<CR>")
    t.assert_equal("Not implemented: :syntax list", h.message, ":syntax alone would list the items")

    # :set filetype and syntax.
    h.type(":set ft?<CR>")
    t.assert_equal("  filetype=ruby", h.message, ":set ft? shows the filetype")
    h.type(":set filetype<CR>")
    t.assert_equal("  filetype=ruby", h.message, "so does the bare name")
    h.type(":set syntax=OFF<CR>")
    t.assert_equal("", spans(h, 0), ":set syntax=OFF turns this buffer plain")
    h.type(":set syntax?<CR>")
    t.assert_equal("  syntax=", h.message, "and its syntax is empty")
    h.type(":set syn=ON<CR>")
    t.assert_equal(["Define:def Function:go String:\"hi\" Comment:# note", "ruby"], [spans(h, 0), h.buffer.syntax], ":set syn=ON goes back to the filetype")
    h.type(":set number<CR>")
    t.assert_equal("Not implemented: :set number", h.message, "an option :set does not handle yet")
    h.type(":set bogus<CR>")
    t.assert_equal("E518: Unknown option: bogus", h.message, "an unknown option")
    h.type(":e notes.txt<CR>")
    t.assert_equal(["", ""], [spans(h, 0), h.buffer.filetype], "a text file is plain")
    h.type(":se ft=ruby<CR>")
    t.assert_equal(["Define:def Function:go", "ruby", "ruby"], [spans(h, 0), h.buffer.filetype, h.buffer.syntax], ":se ft=ruby highlights it and sets the syntax")
    h.type(":set ft= syn?<CR>")
    t.assert_equal(["", "  syntax="], [spans(h, 0), h.message], "several arguments: the filetype emptied, then the syntax shown")

    # A configuration that disables the plugin leaves Ruby plain.
    files = Carat::Doubles::MemoryFiles.new
    files.put("a.rb", "def go\n")
    config = Carat::Doubles::FixedConfig.with("plugin.ruby.enabled false\n")
    h = Carat::Doubles::EditorHarness.new(files: files, config: config, rows: 8, cols: 40, plugins: [Carat::Plugins::Ruby::Plugin.new])
    h.open("a.rb")
    t.assert_equal("", spans(h, 0), "the ruby plugin disabled in the configuration leaves Ruby plain")

    # The shipped registry highlights Ruby.
    h = editor(Carat::Plugins::Registry.all)
    h.open("a.rb")
    t.assert_equal("Define:def Function:go String:\"hi\" Comment:# note", spans(h, 0), "the registry's ruby plugin highlights a.rb")

    h = editor([Boom.new])
    h.open("a.rb")
    t.assert_equal(["", "Plugin boom disabled: bad line", false], [spans(h, 0), h.message, h.plugins.enabled?("boom")], "a raising tokenizer is disabled and the buffer is plain")
    h = editor([Boom.new, Carat::Plugins::Ruby::Plugin.new])
    h.open("a.rb")
    t.assert_equal("Define:def Function:go String:\"hi\" Comment:# note", spans(h, 0), "the next plugin declaring the filetype takes over in the same frame")

    files = Carat::Doubles::MemoryFiles.new
    files.put("big.rb", ruby_source(100_000))
    h = Carat::Doubles::EditorHarness.with_plugins(files, 30, 80, [Carat::Plugins::Ruby::Plugin.new])
    view = h.assembly.highlight_view
    h.open("big.rb")
    first = view.tokenized
    t.assert_true(first > 0 && first < 100, "opening 100,000 lines tokenizes one screen")
    h.type("G")
    jumped = view.tokenized - first
    t.assert_true(jumped >= 99_900, "G tokenizes every row above the end once")
    t.assert_equal("Keyword:end", spans(h, 27), "and the last row is highlighted with the state carried from the top")
    h.type("gg")
    before = view.tokenized
    h.type("G")
    t.assert_true(view.tokenized - before <= 60, "G again tokenizes at most the rows of one screen")
    h.type("gg15G")
    t.assert_equal("String:    where id = 1", spans(h, 14), "a heredoc body row is String")
    h.type("i")
    before = view.tokenized
    h.type("x")
    t.assert_equal(1, view.tokenized - before, "typing in a heredoc tokenizes one row")
    t.assert_equal("String:x    where id = 1", spans(h, 14), "the row is String")
    h.type("<Esc>18G")
    h.type("i")
    before = view.tokenized
    h.type("y")
    t.assert_equal(1, view.tokenized - before, "typing in a multi-line string tokenizes one row")
    h.type("<Esc>")

    t.finish
  end
end

EditorSyntaxTest.main if __FILE__ == $0
