require_relative "../carat"
require_relative "../carat/testing"

t = Carat::Testing.new("domain_icons")
D = Carat::Domain
I = Carat::Domain::Icons

# Every name has a glyph in every set, with the set's character class.
def classify(glyph)
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
  ["unknown set reads as nerd", ["folder_closed", "emoji"], "\u{F07B}"]
]) do |pair|
  I.glyph(pair[0], pair[1])
end

t.assert_equal(21, I::NAMES.length, "twenty-one icon names")
t.assert_equal(">", I.glyph("current", "ascii"), "the ascii current marker is >")
t.assert_equal(true, I.set?("unicode"), "unicode is a set")
t.assert_equal(false, I.set?("emoji"), "emoji is not a set")

# The option: rows are [label, options object, icons value].
t.table([
  ["default is nerd", {}, "nerd"],
  ["unicode", { "icons" => "unicode" }, "unicode"],
  ["ascii", { "icons" => "ascii" }, "ascii"],
  ["invalid keeps the default", { "icons" => "emoji" }, "nerd"],
  ["wrong type keeps the default", { "icons" => 3 }, "nerd"]
]) do |hash|
  D::Options.from_config(hash).icons
end
t.assert_equal("nerd", D::Options.new.icons, "fresh options use nerd")
config = Carat::Json.parse(D::DEFAULT_CONFIG_JSON)
t.assert_equal("nerd", D::Options.from_config(config["options"]).icons, "the shipped configuration selects nerd")

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
