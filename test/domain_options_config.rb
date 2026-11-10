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
    t.assert_equal([[true, false, 2, 2, true, true, 5, 500, 1000], "nerd", "one_dark", []], [[options.number, options.relativenumber, options.tabstop, options.shiftwidth, options.expandtab, options.autoindent, options.scrolloff, options.timeoutlen, options.undolevels], options.icons, options.theme, shipped.report], "the shipped defaults set Carat's options cleanly")

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

    # The start screen options: rows are [label, project lines,
    # [startscreen, reducedmotion, problems]].
    t.table([
      ["the start screen on, with its animation, by default", "", [true, false, []]],
      ["both are stored", "option.startscreen false\noption.reducedmotion true\n", [false, true, []]],
      ["each takes true or false", "option.startscreen yes\noption.reducedmotion 1\n", [true, false, [".caratrc:1: option.startscreen takes true or false", ".caratrc:2: option.reducedmotion takes true or false"]]]
    ]) do |text|
      config = D::Config.new
      config.read(".caratrc", text.to_s, false)
      read = D::Options.from_config(config)
      [read.startscreen, read.reducedmotion, config.report]
    end
    t.assert_equal([true, false], [options.startscreen, options.reducedmotion], "the shipped start screen options")

    # The cursorline option: rows are [label, project lines, [cursorline,
    # problems]].
    t.table([
      ["off by default, as in Neovim", "", [false, []]],
      ["turned on", "option.cursorline true\n", [true, []]],
      ["a later line wins", "option.cursorline true\noption.cursorline false\n", [false, []]],
      ["takes true or false", "option.cursorline yes\n", [false, [".caratrc:1: option.cursorline takes true or false"]]]
    ]) do |text|
      config = D::Config.new
      config.read(".caratrc", text.to_s, false)
      read = D::Options.from_config(config)
      [read.cursorline, config.report]
    end
    t.assert_equal(true, options.cursorline, "the shipped configuration turns the cursor line on")

    # The indent guides' options, A character too wide or too long among
    # them: rows are [label, project lines,
    # [indentguides, the guide character, the code drawn, problems]].
    t.table([
      ["the guides are off by default, as Neovim draws none", "", [false, "┊", 0x250a, []]],
      ["the guides turned on", "option.indentguides true\n", [true, "┊", 0x250a, []]],
      ["another character", "option.indentguides.char ▏\n", [false, "▏", 0x258f, []]],
      ["an ASCII character", "option.indentguides.char :\n", [false, ":", 58, []]],
      ["the ASCII fallback: | for a character outside ASCII with the ascii icon set", "option.icons ascii\n", [false, "┊", 124, []]],
      ["an ASCII character is kept with the ascii icon set", "option.icons ascii\noption.indentguides.char :\n", [false, ":", 58, []]],
      ["a value that is not a flag keeps the guides' earlier setting", "option.indentguides true\noption.indentguides yes\n", [true, "┊", 0x250a, [".caratrc:2: option.indentguides takes true or false"]]],
      ["a character too long is refused, the one before kept", "option.indentguides.char ab\n", [false, "┊", 0x250a, [".caratrc:1: option.indentguides.char takes one character one column wide"]]],
      ["a character too wide is refused, the one before kept", "option.indentguides.char :\noption.indentguides.char 日\n", [false, ":", 58, [".caratrc:2: option.indentguides.char takes one character one column wide"]]]
    ]) do |text|
      config = D::Config.new
      config.read(".caratrc", text.to_s, false)
      read = D::Options.from_config(config)
      [read.indentguides, read.indentguides_char, read.guide_code, config.report]
    end
    # The shipped configuration turns them on.
    t.assert_equal([true, "┊"], [options.indentguides, options.indentguides_char], "the shipped configuration turns the indent guides on, drawn in ┊")

    # option.keyhints.delay: the key hints' wait, 0 to 10000, 300 by default.
    delays = []
    reports = []
    ["", "option.keyhints.delay 0\n", "option.keyhints.delay 10000\n", "option.keyhints.delay 10001\n", "option.keyhints.delay soon\n"].each do |text|
      config = D::Config.new
      config.read(".caratrc", text, false)
      delays << D::Options.from_config(config).keyhints_delay
      reports << config.report.length
    end
    t.assert_equal([[300, 0, 10000, 300, 300], [0, 0, 0, 1, 1]], [delays, reports], "keyhints.delay takes 0 to 10000 and keeps the earlier value otherwise")

    # option.layout.*: the slot sizes, 0 to 500, 0 by default.
    t.table([
      ["the slots keep the view's size by default", "", [[0, 0, 0], []]],
      ["each slot takes its size", "option.layout.left_width 24\noption.layout.right_width 40\noption.layout.panel_height 500\n", [[24, 40, 500], []]],
      ["a size above 500 is refused", "option.layout.panel_height 501\n", [[0, 0, 0], [".caratrc:1: option.layout.panel_height takes a number from 0 to 500"]]],
      ["a word is refused", "option.layout.left_width wide\n", [[0, 0, 0], [".caratrc:1: option.layout.left_width takes a number"]]]
    ]) do |text|
      config = D::Config.new
      config.read(".caratrc", text.to_s, false)
      read = D::Options.from_config(config)
      [[read.slot_size(:left), read.slot_size(:right), read.slot_size(:bottom)], config.report]
    end

    # option.breadcrumbs: when file windows show a winbar. Rows are
    # [label, project lines, [mode, problems]].
    t.table([
      ["auto by default", "", ["auto", []]],
      ["always is stored", "option.breadcrumbs always\n", ["always", []]],
      ["never is stored", "option.breadcrumbs never\n", ["never", []]],
      ["a later line wins", "option.breadcrumbs never\noption.breadcrumbs auto\n", ["auto", []]],
      ["an unknown mode is refused and keeps auto", "option.breadcrumbs sometimes\n", ["auto", [".caratrc:1: unknown breadcrumbs mode sometimes"]]]
    ]) do |text|
      config = D::Config.new
      config.read(".caratrc", text.to_s, false)
      read = D::Options.from_config(config)
      [read.breadcrumbs, config.report]
    end
    t.assert_equal("auto", options.breadcrumbs, "the shipped configuration shows breadcrumbs with two or more file windows")

    # option.winborder: the float border. Rows are [label, project lines,
    # [style, problems]]. Scenarios: The shipped border is rounded (the
    # assertion after the table), An unknown border style.
    t.table([
      ["rounded by default", "", ["rounded", []]],
      ["single is stored", "option.winborder single\n", ["single", []]],
      ["double is stored", "option.winborder double\n", ["double", []]],
      ["solid is stored", "option.winborder solid\n", ["solid", []]],
      ["none is stored", "option.winborder none\n", ["none", []]],
      ["an unknown border style is refused and keeps the one before", "option.winborder rounded\noption.winborder thick\n", ["rounded", [".caratrc:2: unknown border style thick"]]]
    ]) do |text|
      config = D::Config.new
      config.read(".caratrc", text.to_s, false)
      read = D::Options.from_config(config)
      [read.winborder, config.report]
    end
    t.assert_equal("rounded", options.winborder, "the shipped border is rounded")

    t.finish
  end
end

DomainOptionsConfigTest.main if __FILE__ == $0
