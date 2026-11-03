require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainThemeTest
  D = Carat::Domain
  H = D::Highlight

  # Every group of a theme but Normal has a color in both depths, and
  # Normal keeps the terminal's colors. A method rather than a block, so
  # Spinel types the theme.
  #: (Carat::Testing, Carat::Domain::Theme) -> void
  def self.check_theme(t, theme)
    t.assert_equal([-1, -1, -1, -1, 0], [theme.fg(H::NORMAL), theme.bg(H::NORMAL), theme.fg16(H::NORMAL), theme.bg16(H::NORMAL), theme.attr(H::NORMAL)], "#{theme.name}: Normal keeps the terminal's colors")
    missing = []
    id = 1
    while id < H::COUNT
      missing << H::NAMES[id] if theme.fg(id) < 0 && theme.bg(id) < 0
      missing << "#{H::NAMES[id]} (16)" if theme.fg16(id) < 0 && theme.bg16(id) < 0
      id += 1
    end
    t.assert_equal([], missing, "#{theme.name}: every other group has a color in both depths")
  end

  # The options of text read as the project file.
  def self.theme_of(text)
    config = D::Config.new
    config.read(".caratrc", text, false)
    D::Options.from_config(config)
  end

  def self.main
    t = Carat::Testing.new("domain_theme")

    # The group table: editor groups first, the thirty syntax groups after.
    t.assert_equal(H::COUNT, H::NAMES.length, "every id has a name")
    t.assert_equal(30, H::COUNT - H::SYNTAX_FIRST, "thirty syntax groups")
    t.assert_equal(["Comment", "Error", "SignColumn"], [H::NAMES[H::COMMENT], H::NAMES[H::ERROR], H::NAMES[H::SIGN_COLUMN]], "names by id")
    t.table([
      ["Comment", "Comment", H::COMMENT],
      ["String", "String", H::STRING],
      ["Define", "Define", H::DEFINE],
      ["Todo", "Todo", H::TODO],
      ["an editor group is not a syntax group", "StatusLine", -1],
      ["Normal is not either", "Normal", -1],
      ["an unknown name", "Banana", -1],
      ["names are case sensitive", "comment", -1]
    ]) { |name| H.syntax_id(name.to_s) }
    t.assert_equal([false, true, true, false], [H.syntax?(H::VISUAL), H.syntax?(H::COMMENT), H.syntax?(H::ERROR), H.syntax?(H::COUNT)], "syntax? covers the syntax ids only")
    t.assert_equal(["Visual", ""], [H.name_of(H::VISUAL), H.name_of(99)], "name_of")

    # The themes: every group of both themes, Normal left to the terminal.
    dark = D::Themes.find("carat-dark")
    light = D::Themes.find("carat-light")
    t.assert_equal(["carat-dark", "carat-light", "carat-dark"], [dark.name, light.name, D::Themes.find("nope").name], "find, carat-dark for an unknown name")
    t.assert_equal([true, true, false], [D::Themes.known?("carat-dark"), D::Themes.known?("carat-light"), D::Themes.known?("nope")], "known?")
    check_theme(t, dark)
    check_theme(t, light)
    t.assert_equal([0x7f849c, D::Theme::ITALIC], [dark.fg(H::COMMENT), dark.attr(H::COMMENT)], "carat-dark comments are grey and italic")
    t.assert_equal(0x8c8fa1, light.fg(H::COMMENT), "carat-light has its own comment color")
    t.assert_equal(D::Theme::BOLD, dark.attr(H::STATUS) & D::Theme::BOLD, "the status line is bold")

    # Options read the theme from the option.theme line.
    t.assert_equal(["carat-dark", true], [D::Options.new.theme, D::Options.new.syntax_on], "the defaults: carat-dark, syntax on")
    t.assert_equal("carat-light", theme_of("option.theme carat-light\n").theme, "the theme line selects a theme")
    unknown = D::Config.new
    unknown.read(".caratrc", "option.theme solarized\n", false)
    t.assert_equal(["carat-dark", [".caratrc:1: unknown theme solarized"]], [D::Options.from_config(unknown).theme, unknown.report], "an unknown theme keeps the default and is reported")
    t.assert_equal("carat-dark", theme_of("option.theme \"carat light\" x\n").theme, "a theme of the wrong kind keeps the default")
    shipped = D::Config.new
    shipped.read_defaults("config/default.caratrc", D::DEFAULT_CARATRC)
    t.assert_equal("carat-dark", D::Options.from_config(shipped).theme, "the shipped configuration names carat-dark")

    # The color depth from COLORTERM and TERM.
    t.table([
      ["truecolor", ["truecolor", "xterm-256color"], D::ColorDepth::TRUECOLOR],
      ["24bit", ["24bit", "linux"], D::ColorDepth::TRUECOLOR],
      ["256 colors", ["", "xterm-256color"], D::ColorDepth::COLORS_256],
      ["an unset TERM", ["", ""], D::ColorDepth::COLORS_256],
      ["plain xterm", ["", "xterm"], D::ColorDepth::COLORS_256],
      ["the console", ["", "linux"], D::ColorDepth::COLORS_16],
      ["vt100", ["", "vt100"], D::ColorDepth::COLORS_16],
      ["xterm-color", ["", "xterm-color"], D::ColorDepth::COLORS_16],
      ["a -16color name", ["", "rxvt-16color"], D::ColorDepth::COLORS_16],
      ["another COLORTERM", ["yes", "linux"], D::ColorDepth::COLORS_16]
    ]) { |input| D::ColorDepth.detect(input[0].to_s, input[1].to_s) }

    t.finish
  end
end

DomainThemeTest.main if __FILE__ == $0
