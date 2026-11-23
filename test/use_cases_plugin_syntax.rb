require_relative "../carat/test_support"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module UseCasesPluginSyntaxTest
  D = Carat::Domain
  H = D::Highlight
  A = Carat::PluginApi

  # A tokenizer for the filetype "toy" that writes what activate resolved
  # and what it was asked, and answers with a fixed list of tokens and an
  # end state.
  class Toy < Carat::PluginApi::Plugin
    attr_reader :log #: Array[String]
    attr_accessor :tokens #: Array[Integer]
    attr_accessor :finish #: Integer

    # @rbs @name: String
    # @rbs @types: Array[String]

    #: (String, Array[String]) -> void
    def initialize(name, types)
      @name = name
      @types = types
      @log = []
      @tokens = Array.new(0, 0)
      @finish = 0
    end

    # Returns the manifest.
    # @rbs skip
    def manifest
      Carat::PluginApi::Manifest.new(name: @name, version: "1.0.0", api_version: "2.0", actions: {}, commands: {}, bindings: [], events: [], options: [], option_types: {}, filetypes: @types)
    end

    #: (Carat::PluginApi::Host) -> void
    def activate(host)
      good = host.syntax_group("Comment")
      editor = host.syntax_group("StatusLine")
      bad = host.syntax_group("Banana")
      icon = host.syntax_group("DevIconRb")
      ui = host.syntax_group("CursorLine")
      @log << "Comment=#{good.ok} #{good.number}"
      @log << "StatusLine=#{editor.ok} #{editor.message}"
      @log << "Banana=#{bad.ok} #{bad.message}"
      @log << "DevIconRb=#{icon.ok} #{icon.number}"
      @log << "CursorLine=#{ui.ok} #{ui.message}"
      selected = host.syntax_group("PmenuSel")
      match = host.syntax_group("PmenuMatch")
      mark = host.syntax_group("PmenuMarkSel")
      label = host.syntax_group("PmenuLabelSel")
      visual = host.syntax_group("Visual")
      @log << "PmenuSel=#{selected.ok} #{selected.number}"
      @log << "PmenuMatch=#{match.ok} #{match.number}"
      @log << "PmenuMarkSel=#{mark.ok} #{mark.number}"
      @log << "PmenuLabelSel=#{label.ok} #{label.number}"
      @log << "Visual=#{visual.ok} #{visual.message}"
    end

    # Returns the fixed end state.
    # @rbs filetype: String
    # @rbs text: String
    # @rbs state: Integer
    # @rbs tokens: Array[Integer]
    def tokenize(filetype, text, state, tokens)
      @log << "#{filetype} #{text} #{state}"
      i = 0
      while i < @tokens.length
        tokens << @tokens[i]
        i += 1
      end
      @finish
    end
  end

  # A plugin that declares a filetype and does not implement tokenize.
  class Lazy < Carat::PluginApi::Plugin
    # Returns the manifest.
    # @rbs skip
    def manifest
      Carat::PluginApi::Manifest.new(name: "lazy", version: "1.0.0", api_version: "2.0", actions: {}, commands: {}, bindings: [], events: [], options: [], option_types: {}, filetypes: ["lazy"])
    end
  end

  # A tokenizer for "toy" whose activate raises, so the provider passes
  # over it to the next plugin declaring the syntax.
  class Broken < Carat::PluginApi::Plugin
    # Returns the manifest.
    # @rbs skip
    def manifest
      Carat::PluginApi::Manifest.new(name: "broken", version: "1.0.0", api_version: "2.0", actions: {}, commands: {}, bindings: [], events: [], options: [], option_types: {}, filetypes: ["toy"])
    end

    #: (Carat::PluginApi::Host) -> void
    def activate(host)
      raise "no grammar"
    end
  end

  def self.main
    t = Carat::Testing.new("use_cases_plugin_syntax")

    files = Carat::Doubles::MemoryFiles.new
    files.put("a.txt", "one\ntwo\n")
    first = Toy.new("first", ["toy"])
    second = Toy.new("second", ["toy", "other"])
    h = Carat::Doubles::EditorHarness.with_plugins(files, 8, 40, [first, second, Lazy.new])
    h.open("a.txt")
    t.assert_equal([false, false], [h.plugins.active?("first"), h.plugins.active?("second")], "a tokenizer is not activated before a buffer of its filetype is highlighted")
    # The requests below are asked of the plugin directly: activate it.
    h.plugins.activate("first")
    syntax = h.plugins.syntax
    # Scenario: The popup menu groups resolve (PmenuSel, PmenuMatch,
    # PmenuMarkSel, and PmenuLabelSel; Visual refused).
    t.assert_equal(["Comment=true #{H::COMMENT}", "StatusLine=false No highlight group named StatusLine", "Banana=false No highlight group named Banana", "DevIconRb=true #{H::ICON_RUBY}", "CursorLine=false No highlight group named CursorLine", "PmenuSel=true #{H::POPUP_MENU_SELECTED}", "PmenuMatch=true #{H::POPUP_MENU_MATCH}", "PmenuMarkSel=true #{H::POPUP_MENU_MARK_SELECTED}", "PmenuLabelSel=true #{H::POPUP_MENU_LABEL_SELECTED}", "Visual=false No highlight group named Visual"], first.log, "syntax_group answers syntax and file-icon groups by name and refuses others; The popup menu groups resolve: PmenuSel and PmenuMatch answer their ids and Visual is refused")

    # The provider: the first enabled plugin that declares the syntax.
    names = ["toy", "other", "lazy", "ruby"].map do |type|
      found = syntax.provider(type)
      found.nil? ? "" : found.name
    end
    t.assert_equal(["first", "second", "lazy", ""], names, "the first registered plugin declaring a syntax tokenizes it")
    t.assert_equal([["toy"], ["toy", "other"]], [h.plugins.entry(0).filetypes, h.plugins.entry(1).filetypes], "the entries hold the declared filetypes")

    # A call: the copy of the text, the start state, the tokens, the state.
    first.tokens = [0, 2, H::COMMENT, -1, 2, H::STRING, 0, 0, H::STRING, 1, 2, 9999, 2, 1, H::NORMAL, 2, 1, H::CURSOR_LINE, 1, 1, H::STRING, 2, 1, H::ICON_RUBY]
    first.finish = 7
    line = "one"
    entry = syntax.provider("toy")
    t.assert_equal(7, syntax.tokenize(entry, "toy", line, 3), "the end state is returned")
    t.assert_equal("toy one 3", first.log.last, "the plugin gets the filetype, the text, and the start state")
    t.assert_equal([0, 2, H::COMMENT, 1, 1, H::STRING, 2, 1, H::ICON_RUBY], syntax.copied_tokens, "a negative start, an empty token, a UI group, and an unknown id are dropped; a file-icon group is kept")
    # Scenario: A token starting past the longest span is dropped
    first.tokens = [1_073_741_825, 1, H::STRING, 1_073_741_824, 5, H::COMMENT, 0, 9_000_000_000, H::STRING]
    syntax.tokenize(entry, "toy", line, 0)
    t.assert_equal([1_073_741_824, 5, H::COMMENT, 0, 1_073_741_824, H::STRING], syntax.copied_tokens, "a token starting past 1 << 30 is dropped and a length past it is cut to it")
    first.tokens = [0, 2, H::COMMENT, -1, 2, H::STRING, 0, 0, H::STRING, 1, 2, 9999, 2, 1, H::NORMAL, 2, 1, H::CURSOR_LINE, 1, 1, H::STRING, 2, 1, H::ICON_RUBY]
    first.finish = -5
    t.assert_equal(0, syntax.tokenize(entry, "toy", line, 0), "a negative state counts as 0")
    first.tokens = Array.new(0, 0)
    first.finish = 1

    # Highlighting a buffer through it: :set ft=toy.
    first.tokens = [0, 3, H::COMMENT]
    h.type(":set ft=toy<CR>")
    t.assert_equal([H::COMMENT, H::COMMENT, H::NORMAL], [H.base(h.frame.hl_at(0, 4)), H.base(h.frame.hl_at(0, 6)), H.base(h.frame.hl_at(0, 7))], "the tokens color the text")
    t.assert_equal(["toy one 0", "toy two 1"], first.log.last(2), "each line starts in the state the line before ended in")

    # A plugin that declares a filetype without a tokenizer is disabled when
    # it is first asked.
    h.type(":set ft=lazy<CR>")
    t.assert_equal([false, true], [h.plugins.enabled?("lazy"), h.message.start_with?("Plugin lazy disabled:")], "a missing tokenize disables the plugin")
    t.assert_equal(H::NORMAL, H.base(h.frame.hl_at(0, 4)), "and the buffer is plain")

    # A token with an id out of range is dropped from the frame too.
    first.tokens = [0, 1, 9999]
    h.type(":set ft=toy<CR>")
    t.assert_equal(H::NORMAL, H.base(h.frame.hl_at(0, 4)), "an out of range id is drawn normal")

    # A provider whose late activate raises is disabled with its message and
    # the next plugin declaring the syntax tokenizes the visible rows in the
    # same frame.
    later = Toy.new("later", ["toy"])
    later.tokens = [0, 3, H::COMMENT]
    later.finish = 1
    h = Carat::Doubles::EditorHarness.with_plugins(files, 8, 40, [Broken.new, later])
    h.open("a.txt")
    h.type(":set ft=toy<CR>")
    t.assert_equal([false, "Plugin broken disabled: no grammar"], [h.plugins.enabled?("broken"), h.message], "a tokenizer raising in its first activate is disabled with its message")
    t.assert_equal([true, ["toy one 0", "toy two 1"], H::COMMENT, H::COMMENT], [h.plugins.active?("later"), later.log.last(2), H.base(h.frame.hl_at(0, 4)), H.base(h.frame.hl_at(1, 4))], "the next plugin declaring the syntax tokenizes the visible rows in the same frame")

    t.finish
  end
end

UseCasesPluginSyntaxTest.main if __FILE__ == $0
