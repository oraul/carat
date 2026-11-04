require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainOptionsConfigTest
  D = Carat::Domain

  # The options of text read as the project file, and its problems.
  def self.options_of(text)
    config = D::Config.new
    config.read(".caratrc", text, false)
    options = D::Options.from_config(config)
    [[options.number, options.relativenumber, options.tabstop, options.shiftwidth, options.expandtab, options.autoindent, options.scrolloff, options.timeoutlen, options.undolevels], config.report]
  end

  VIM = [false, false, 8, 8, false, false, 0, 1000, 1000]

  def self.main
    t = Carat::Testing.new("domain_options_config")

    # Rows are [label, project lines, [members, problems]]; the members are
    # number, relativenumber, tabstop, shiftwidth, expandtab, autoindent,
    # scrolloff, timeoutlen, and undolevels.
    t.table([
      ["no line keeps Vim's defaults", "", [VIM, []]],
      ["flags", "option.number true\noption.relativenumber true\noption.expandtab true\noption.autoindent true\n", [[true, true, 8, 8, true, true, 0, 1000, 1000], []]],
      ["numbers", "option.tabstop 4\noption.shiftwidth 0\noption.scrolloff 3\noption.timeoutlen 100\noption.undolevels 5\n", [[false, false, 4, 0, false, false, 3, 100, 5], []]],
      ["a later line wins", "option.tabstop 4\noption.tabstop 3\noption.number true\noption.number false\n", [[false, false, 3, 8, false, false, 0, 1000, 1000], []]],
      ["the options read later are checked", "option.ignorecase true\noption.smartcase false\noption.hlsearch true\noption.incsearch true\noption.wrap false\noption.clipboard unnamedplus\n", [VIM, []]],
      ["an unknown option", "option.tabsize 4\noption.tab.stop 4\n", [VIM, [".caratrc:1: unknown option tabsize", ".caratrc:2: unknown option tab.stop"]]],
      ["a word for a number", "option.tabstop wide\n", [VIM, [".caratrc:1: option.tabstop takes a number"]]],
      ["no value", "option.tabstop\n", [VIM, [".caratrc:1: option.tabstop takes a number"]]],
      ["a flag that is not true or false", "option.number yes\noption.wrap 1\n", [VIM, [".caratrc:1: option.number takes true or false", ".caratrc:2: option.wrap takes true or false"]]],
      ["two words for one", "option.clipboard a b\n", [VIM, [".caratrc:1: option.clipboard takes one word"]]],
      ["a bad line keeps the value before it", "option.tabstop 4\noption.tabstop -1\n", [[false, false, 4, 8, false, false, 0, 1000, 1000], [".caratrc:2: option.tabstop takes a number"]]],
      ["other scopes are not options", "keymap.normal j cursor.down\nplugin.hello.greeting Hi\n", [VIM, []]],
      ["a huge tabstop keeps the value before it", "option.tabstop 4\noption.tabstop 999999999\n", [[false, false, 4, 8, false, false, 0, 1000, 1000], [".caratrc:2: option.tabstop takes a number from 1 to 9999"]]],
      ["a tabstop one above the limit", "option.tabstop 10000\n", [VIM, [".caratrc:1: option.tabstop takes a number from 1 to 9999"]]],
      ["a zero tabstop", "option.tabstop 0\n", [VIM, [".caratrc:1: option.tabstop takes a number from 1 to 9999"]]],
      ["a huge shiftwidth", "option.shiftwidth 999999999\noption.shiftwidth 10000\n", [VIM, [".caratrc:1: option.shiftwidth takes a number from 0 to 9999", ".caratrc:2: option.shiftwidth takes a number from 0 to 9999"]]],
      ["the limits themselves", "option.tabstop 9999\noption.shiftwidth 9999\n", [[false, false, 9999, 9999, false, false, 0, 1000, 1000], []]],
      ["the smallest values", "option.tabstop 1\noption.shiftwidth 0\n", [[false, false, 1, 0, false, false, 0, 1000, 1000], []]]
    ]) do |text|
      options_of(text.to_s)
    end

    shipped = D::Config.new
    shipped.read_defaults("config/default.caratrc", D::DEFAULT_CARATRC)
    options = D::Options.from_config(shipped)
    t.assert_equal([[true, false, 2, 2, true, true, 5, 500, 1000], "nerd", "carat-dark", []], [[options.number, options.relativenumber, options.tabstop, options.shiftwidth, options.expandtab, options.autoindent, options.scrolloff, options.timeoutlen, options.undolevels], options.icons, options.theme, shipped.report], "the shipped defaults set Carat's options cleanly")

    # The scroll option: rows are [label, project lines, [scroll, problems]].
    t.table([
      ["scroll is 0 by default, half the window", "", [0, []]],
      ["scroll takes a number", "option.scroll 4\n", [4, []]],
      ["scroll refuses a word", "option.scroll half\n", [0, [".caratrc:1: option.scroll takes a number"]]]
    ]) do |text|
      config = D::Config.new
      config.read(".caratrc", text.to_s, false)
      [D::Options.from_config(config).scroll, config.report]
    end
    t.assert_equal(0, options.scroll, "the shipped scroll is 0")
    t.assert_equal([false, true, true, true], [options.ignorecase, options.smartcase, options.hlsearch, options.incsearch], "the shipped search options")

    # The search options: rows are [label, project lines, [ignorecase,
    # smartcase, hlsearch, incsearch]].
    t.table([
      ["Neovim's search defaults", "", [false, false, true, true]],
      ["the search options are stored", "option.ignorecase true\noption.smartcase true\noption.hlsearch false\noption.incsearch false\n", [true, true, false, false]]
    ]) do |text|
      config = D::Config.new
      config.read(".caratrc", text.to_s, false)
      read = D::Options.from_config(config)
      [read.ignorecase, read.smartcase, read.hlsearch, read.incsearch]
    end

    t.finish
  end
end

DomainOptionsConfigTest.main if __FILE__ == $0
