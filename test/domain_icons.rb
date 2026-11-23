require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainIconsTest
  D = Carat::Domain
  I = Carat::Domain::Icons

  # Every name has a glyph in every set, with the set's character class.
  def self.classify(glyph)
    codes = glyph.codepoints
    return "empty" if codes.empty?
    kinds = []
    codes.each do |code|
      if Carat::Domain::DisplayWidth.private_use?(code)
        kinds << "pua"
      elsif code < 128
        kinds << "ascii"
      else
        kinds << "unicode"
      end
    end
    kinds.uniq.join(",")
  end

  def self.main
    t = Carat::Testing.new("domain_icons")

    # Scenarios: Every name in every set and Nerd set.
    I::SETS.each do |set|
      I::NAMES.each do |name|
        expected = set == "nerd" ? "pua" : set
        t.assert_equal(expected, classify(I.glyph(name, set)), "#{set} #{name} is a #{expected} glyph")
      end
    end

    # Rows are [label, [name, set], glyph].
    t.cases([
      ["ascii closed folder", ["folder_closed", "ascii"], "+"],
      ["ascii open folder", ["folder_open", "ascii"], "-"],
      ["ascii error", ["error", "ascii"], "X"],
      ["ascii info", ["info", "ascii"], "i"],
      ["unicode closed folder", ["folder_closed", "unicode"], "▸"],
      ["nerd closed folder", ["folder_closed", "nerd"], "\u{F07B}"],
      ["unknown name", ["nope", "nerd"], ""],
      ["unknown name in ascii", ["nope", "ascii"], ""],
      ["unknown set reads as the default, unicode", ["folder_closed", "emoji"], "▸"],
      ["ascii function kind", ["kind_function", "ascii"], "f"],
      ["ascii variable kind", ["kind_variable", "ascii"], "v"],
      ["unicode class kind", ["kind_class", "unicode"], "◈"],
      # The ahead and behind glyphs per set
      ["the ahead and behind glyphs per set: unicode ahead", ["ahead", "unicode"], "↑"],
      ["unicode behind", ["behind", "unicode"], "↓"],
      ["ascii ahead", ["ahead", "ascii"], "+"],
      ["ascii behind", ["behind", "ascii"], "-"],
      # Scenario "The git sign glyphs per set"
      ["the git sign glyphs per set: unicode git_added", ["git_added", "unicode"], "┃"],
      ["unicode git_changed", ["git_changed", "unicode"], "┇"],
      ["unicode git_deleted", ["git_deleted", "unicode"], "▁"],
      ["ascii git_added", ["git_added", "ascii"], "+"],
      ["ascii git_changed", ["git_changed", "ascii"], "~"],
      ["ascii git_deleted", ["git_deleted", "ascii"], "_"],
      ["nerd git_added", ["git_added", "nerd"], "\u{F457}"],
      ["nerd git_changed", ["git_changed", "nerd"], "\u{F459}"],
      ["nerd git_deleted", ["git_deleted", "nerd"], "\u{F458}"]
    ]) do |pair|
      I.glyph(pair[0], pair[1])
    end

    # Every default glyph is one cell outside the private use areas: each
    # name in the default set is one character, one cell wide, and in
    # neither private use area, so any terminal font draws it. Rows are
    # [name, [characters, cells, private use]].
    default_set = D::Options.new.icons
    t.table(I::NAMES.map { |name| ["the default #{name} is one cell outside the private use areas", name, [1, 1, false]] }) do |name|
      glyph = I.glyph(name.to_s, default_set)
      code = glyph.codepoints.empty? ? 0 : glyph.codepoints[0]
      [glyph.codepoints.length, D::DisplayWidth.of(code), D::DisplayWidth.private_use?(code)]
    end

    t.assert_equal(38, I::NAMES.length, "thirty-eight icon names, twelve of them completion kinds, two the branch counts, and three the git line signs")
    t.assert_equal(["|", "▎"], [I.glyph("current", "ascii"), I.glyph("current", "unicode")], "the current marker is the bar ▎, a vertical bar in ascii")
    t.assert_equal(true, I.set?("unicode"), "unicode is a set")
    t.assert_equal(false, I.set?("emoji"), "emoji is not a set")

    # The option: rows are [label, project lines, [icons value, problems]].
    # Default set; Nerd stays selectable; Invalid value.
    t.table([
      ["default is unicode", "", ["unicode", []]],
      ["nerd stays selectable", "option.icons nerd\n", ["nerd", []]],
      ["invalid keeps the default", "option.icons emoji\n", ["unicode", [".caratrc:1: unknown icon set emoji"]]],
      ["unicode", "option.icons unicode\n", ["unicode", []]],
      ["ascii", "option.icons ascii\n", ["ascii", []]],
      ["invalid keeps the set before it", "option.icons ascii\noption.icons emoji\n", ["ascii", [".caratrc:2: unknown icon set emoji"]]],
      ["two words keep the default", "option.icons nerd font\n", ["unicode", [".caratrc:1: option.icons takes one word"]]]
    ]) do |text|
      config = D::Config.new
      config.read(".caratrc", text.to_s, false)
      [D::Options.from_config(config).icons, config.report]
    end
    t.assert_equal("unicode", D::Options.new.icons, "fresh options use unicode")
    config = D::Config.new
    config.read_defaults("config/default.caratrc", D::DEFAULT_CARATRC)
    t.assert_equal("unicode", D::Options.from_config(config).icons, "the shipped configuration selects unicode")
    config = D::Config.new
    config.read(".caratrc", "option.icons nerd\n", false)
    t.assert_equal("\u{F07B}", I.glyph("folder_closed", D::Options.from_config(config).icons), "nerd stays selectable: its closed folder is the Nerd Font glyph")

    # Display width of the private use areas, where Nerd Font glyphs live.
    t.table([
      ["nerd folder", 0xF07B, 1],
      ["start of the basic plane area", 0xE000, 1],
      ["end of the basic plane area", 0xF8FF, 1],
      ["supplementary area", 0xF0001, 1],
      ["end of the supplementary area", 0xFFFFD, 1],
      ["past the supplementary area", 0xFFFFE, 1],
      ["a wide character is still wide", 0x4E00, 2],
      ["a unicode icon", 0x25B8, 1]
    ]) do |code|
      D::DisplayWidth.of(code)
    end
    t.assert_equal(true, D::DisplayWidth.private_use?(0xF07B), "private_use? for a nerd glyph")
    t.assert_equal(false, D::DisplayWidth.private_use?(0x41), "private_use? for a letter")

    t.finish
  end
end

DomainIconsTest.main if __FILE__ == $0
