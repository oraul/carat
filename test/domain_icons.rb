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

    I::SETS.each do |set|
      I::NAMES.each do |name|
        expected = set == "nerd" ? "pua" : set
        t.assert_equal(expected, classify(I.glyph(name, set)), "#{set} #{name} is a #{expected} glyph")
      end
    end

    # Rows are [label, [name, set], glyph].
    t.table([
      ["ascii closed folder", ["folder_closed", "ascii"], "+"],
      ["ascii open folder", ["folder_open", "ascii"], "-"],
      ["ascii error", ["error", "ascii"], "X"],
      ["ascii info", ["info", "ascii"], "i"],
      ["unicode closed folder", ["folder_closed", "unicode"], "▸"],
      ["nerd closed folder", ["folder_closed", "nerd"], "\u{F07B}"],
      ["unknown name", ["nope", "nerd"], ""],
      ["unknown name in ascii", ["nope", "ascii"], ""],
      ["unknown set reads as nerd", ["folder_closed", "emoji"], "\u{F07B}"],
      ["ascii function kind", ["kind_function", "ascii"], "f"],
      ["ascii variable kind", ["kind_variable", "ascii"], "v"],
      ["unicode class kind", ["kind_class", "unicode"], "◈"]
    ]) do |pair|
      I.glyph(pair[0], pair[1])
    end

    t.assert_equal(33, I::NAMES.length, "thirty-three icon names, twelve of them completion kinds")
    t.assert_equal(">", I.glyph("current", "ascii"), "the ascii current marker is >")
    t.assert_equal(true, I.set?("unicode"), "unicode is a set")
    t.assert_equal(false, I.set?("emoji"), "emoji is not a set")

    # The option: rows are [label, project lines, [icons value, problems]].
    t.table([
      ["default is nerd", "", ["nerd", []]],
      ["unicode", "option.icons unicode\n", ["unicode", []]],
      ["ascii", "option.icons ascii\n", ["ascii", []]],
      ["invalid keeps the set before it", "option.icons ascii\noption.icons emoji\n", ["ascii", [".caratrc:2: unknown icon set emoji"]]],
      ["two words keep the default", "option.icons nerd font\n", ["nerd", [".caratrc:1: option.icons takes one word"]]]
    ]) do |text|
      config = D::Config.new
      config.read(".caratrc", text.to_s, false)
      [D::Options.from_config(config).icons, config.report]
    end
    t.assert_equal("nerd", D::Options.new.icons, "fresh options use nerd")
    config = D::Config.new
    config.read_defaults("config/default.caratrc", D::DEFAULT_CARATRC)
    t.assert_equal("nerd", D::Options.from_config(config).icons, "the shipped configuration selects nerd")

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
