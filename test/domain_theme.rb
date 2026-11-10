require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainThemeTest
  D = Carat::Domain
  H = D::Highlight

  PALETTES = ["one_dark", "one_light", "dark_plus", "light_plus"]

  # The groups drawn as decorations, held to 3:1 rather than 4.5:1, and
  # the groups that carry no text, exempt from the contrast rule.
  DECORATIONS = [H::NON_TEXT, H::END_OF_BUFFER, H::WINDOW_SEPARATOR, H::FLOAT_BORDER, H::WHITESPACE, H::SIGN_COLUMN, H::INDENT_GUIDE, H::INDENT_GUIDE_SCOPE]
  NO_TEXT = [H::TAB_LINE_FILL, H::POPUP_MENU_SCROLLBAR, H::POPUP_MENU_THUMB]

  # The linear light of one sRGB component, WCAG 2's formula.
  #: (Integer) -> Float
  def self.channel(value)
    c = value / 255.0
    c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4
  end

  #: (Integer) -> Float
  def self.luminance(rgb)
    0.2126 * channel((rgb >> 16) & 255) + 0.7152 * channel((rgb >> 8) & 255) + 0.0722 * channel(rgb & 255)
  end

  # The WCAG contrast ratio of two 24-bit colors, times 100 and rounded
  # down, so 4.5:1 is 450.
  #: (Integer, Integer) -> Integer
  def self.contrast(a, b)
    la = luminance(a)
    lb = luminance(b)
    high = la > lb ? la : lb
    low = la > lb ? lb : la
    ((high + 0.05) / (low + 0.05) * 100).floor
  end

  # The 24-bit color of a 256-color index above the basic 16: a color of
  # the 6x6x6 cube or a gray of the ramp.
  #: (Integer) -> Integer
  def self.rgb_256(index)
    if index >= 232
      gray = 8 + 10 * (index - 232)
      return (gray << 16) | (gray << 8) | gray
    end
    cube = Carat::Adapters::SgrTable::CUBE
    i = index - 16
    (cube[i / 36] << 16) | (cube[(i / 6) % 6] << 8) | cube[i % 6]
  end

  # The 24-bit color the terminal shows for a color at 256 colors: the
  # palette's own index, or the nearest one SgrTable writes.
  #: (Integer, Integer) -> Integer
  def self.shown_256(rgb, index)
    rgb_256(index < 0 ? Carat::Adapters::SgrTable.index_256(rgb) : index)
  end

  #: (Integer) -> bool
  def self.decoration?(id)
    DECORATIONS.include?(id) || (id >= H::ICON_FIRST && id < H::MARKUP_FIRST)
  end

  # The syntax and markup groups of a theme drawn inside a float, over
  # NormalFloat's background unless they have their own, whose foreground
  # falls below 4.5:1 there, at 24 bits or at 256 colors, each with its
  # ratio.
  #: (Carat::Domain::Theme, bool) -> Array[String]
  def self.float_low_contrast(theme, at256)
    out = []
    id = H::SYNTAX_FIRST
    while id < H::COUNT
      if id < H::ICON_FIRST || id >= H::MARKUP_FIRST
        inside = id + H::FLOAT_LAYER
        fg = theme.fg(inside)
        bg = theme.bg(inside)
        if at256
          fg = shown_256(fg, theme.fg256(inside))
          bg = shown_256(bg, theme.bg256(inside))
        end
        ratio = contrast(fg, bg)
        out << "#{H::NAMES[id]} #{ratio}" if ratio < 450
      end
      id += 1
    end
    out
  end

  # The groups of a theme drawn with its background whose foreground
  # falls below WCAG AA on their background, 4.5:1 for text and 3:1 for
  # decorations, at 24 bits or at 256 colors, each with its ratio; with
  # layer H::CURSOR_LINE_LAYER, each group as drawn on the cursor line,
  # held to 3:1 as the selection's background is.
  #: (Carat::Domain::Theme, bool, Integer) -> Array[String]
  def self.low_contrast(theme, at256, layer)
    out = []
    id = 0
    while id < H::COUNT
      unless NO_TEXT.include?(id)
        fg = theme.fg(id + layer)
        bg = theme.bg(id + layer)
        if at256
          fg = shown_256(fg, theme.fg256(id + layer))
          bg = shown_256(bg, theme.bg256(id + layer))
        end
        ratio = contrast(fg, bg)
        out << "#{H::NAMES[id]} #{ratio}" if ratio < (decoration?(id) || layer > 0 ? 300 : 450)
      end
      id += 1
    end
    out
  end

  # The groups of a theme with no 24-bit foreground or background.
  #: (Carat::Domain::Theme) -> Array[String]
  def self.uncolored(theme)
    out = []
    id = 0
    while id < H::COUNT
      out << H::NAMES[id] if theme.fg(id) < 0 || theme.bg(id) < 0
      id += 1
    end
    out
  end

  # The groups of a theme that would look like Normal text at 16 colors:
  # no basic color and no attribute.
  #: (Carat::Domain::Theme) -> Array[String]
  def self.plain_16(theme)
    out = []
    id = 0
    while id < H::COUNT
      out << H::NAMES[id] if theme.fg16(id) < 0 && theme.bg16(id) < 0 && theme.attr16(id) == 0
      id += 1
    end
    out
  end

  # Whether the three search groups have a background at every depth.
  #: (Carat::Domain::Theme) -> bool
  def self.search_backgrounds?(theme)
    [H::SEARCH, H::INC_SEARCH, H::CURRENT_SEARCH].all? { |id| theme.bg(id) >= 0 && theme.bg16(id) >= 0 }
  end

  # The options of text read as the project file.
  def self.theme_of(text)
    config = D::Config.new
    config.read(".caratrc", text, false)
    D::Options.from_config(config)
  end

  def self.main
    t = Carat::Testing.new("domain_theme")

    # The color-themes scenarios these checks prove: The UI groups (the
    # counts and names), A plugin asks for an editor group (token_id of a
    # UI group is -1), The search groups have colors, Every UI group has a
    # color in every palette, Every palette passes (the contrast tables),
    # and Comments are readable.
    # The group table: UI groups first, then the thirty syntax groups,
    # then the file-icon groups.
    t.assert_equal(H::COUNT, H::NAMES.length, "every id has a name")
    t.assert_equal([51, 30, 13, 6], [H::SYNTAX_FIRST, H::ICON_FIRST - H::SYNTAX_FIRST, H::MARKUP_FIRST - H::ICON_FIRST, H::COUNT - H::MARKUP_FIRST], "51 UI groups, thirty syntax groups, thirteen file-icon groups, six markup groups")
    t.assert_equal(["@markup.heading", "@markup.strong", "@markup.italic", "@markup.raw", "@markup.link.label", "@markup.raw.block"], [H::NAMES[H::MARKUP_HEADING], H::NAMES[H::MARKUP_STRONG], H::NAMES[H::MARKUP_ITALIC], H::NAMES[H::MARKUP_RAW], H::NAMES[H::MARKUP_LINK], H::NAMES[H::MARKUP_RAW_BLOCK]], "the markup groups after the file-icon groups")
    t.assert_equal(["StatusLineModeNormal", "StatusLineLspError"], [H.name_of(H::STATUS_MODE_NORMAL), H.name_of(H::STATUS_LSP_ERROR)], "the status bar's groups follow Neovim's")

    t.assert_equal(["Comment", "Error", "SignColumn", "CursorLine", "DiagnosticHint", "DevIconRb"], [H::NAMES[H::COMMENT], H::NAMES[H::ERROR], H::NAMES[H::SIGN_COLUMN], H::NAMES[H::CURSOR_LINE], H::NAMES[H::DIAGNOSTIC_HINT], H::NAMES[H::ICON_RUBY]], "names by id")
    t.table([
      ["Comment", "Comment", H::COMMENT],
      ["String", "String", H::STRING],
      ["Define", "Define", H::DEFINE],
      ["Todo", "Todo", H::TODO],
      ["a file-icon group", "DevIconRb", H::ICON_RUBY],
      ["the last file-icon group", "DevIconLock", H::ICON_LOCK],
      ["a markup group", "@markup.heading", H::MARKUP_HEADING],
      ["the last markup group", "@markup.raw.block", H::MARKUP_RAW_BLOCK],
      ["a UI group is not a token group", "StatusLine", -1],
      ["nor is a new UI group", "CursorLine", -1],
      ["nor an indent guide group", "IblIndent", -1],
      ["Normal is not either", "Normal", -1],
      ["an unknown name", "Banana", -1],
      ["names are case sensitive", "comment", -1]
    ]) { |name| H.token_id(name.to_s) }
    t.assert_equal([false, true, true, true, false], [H.token?(H::VISUAL), H.token?(H::COMMENT), H.token?(H::ERROR), H.token?(H::MARKUP_RAW_BLOCK), H.token?(H::COUNT)], "token? covers the syntax, file-icon, and markup ids only")
    t.assert_equal(["Visual", ""], [H.name_of(H::VISUAL), H.name_of(H::COUNT + 1)], "name_of")

    # The palettes, their aliases, and the backgrounds.
    t.assert_equal(["one_dark", "one_light", "dark_plus", "light_plus", "one_dark", "one_light", "one_dark"], [D::Themes.find("one_dark", "terminal").name, D::Themes.find("one_light", "terminal").name, D::Themes.find("dark_plus", "terminal").name, D::Themes.find("light_plus", "terminal").name, D::Themes.find("carat-dark", "terminal").name, D::Themes.find("carat-light", "terminal").name, D::Themes.find("nope", "terminal").name], "find, the aliases, and one_dark for an unknown name")
    t.assert_equal([true, true, true, true, true, true, false, false], [D::Themes.known?("one_dark"), D::Themes.known?("one_light"), D::Themes.known?("dark_plus"), D::Themes.known?("light_plus"), D::Themes.known?("carat-dark"), D::Themes.known?("carat-light"), D::Themes.known?("nope"), D::Themes.known?("One_Dark")], "known?")
    t.assert_equal([true, true, false], [D::Themes.background?("terminal"), D::Themes.background?("theme"), D::Themes.background?("dark")], "background?")
    dark = D::Themes.find("one_dark", "terminal")
    painted = D::Themes.find("one_dark", "theme")
    # The status bar's groups per mode and state: the pills' text on the
    # mode's accent, bold, the lsp slot's accent on the editor's background.
    t.table([
      ["normal pill", [H::STATUS_MODE_NORMAL], [0x282c34, 0x61afef, D::Theme::BOLD, 0, 12]],
      ["insert pill", [H::STATUS_MODE_INSERT], [0x282c34, 0x98c379, D::Theme::BOLD, 0, 10]],
      ["visual pill", [H::STATUS_MODE_VISUAL], [0x282c34, 0xc678dd, D::Theme::BOLD, 0, 13]],
      ["replace pill", [H::STATUS_MODE_REPLACE], [0x282c34, 0xe8757e, D::Theme::BOLD, 0, 9]],
      ["command pill", [H::STATUS_MODE_COMMAND], [0x282c34, 0xe5c07b, D::Theme::BOLD, 0, 11]],
      ["lsp starting", [H::STATUS_LSP_STARTING], [0xe5c07b, -1, 0, 11, -1]],
      ["lsp ready", [H::STATUS_LSP_READY], [0x98c379, -1, 0, 10, -1]],
      ["lsp error", [H::STATUS_LSP_ERROR], [0xe8757e, -1, D::Theme::BOLD, 9, -1]]
    ]) { |input| id = input[0].to_i; [dark.fg(id), dark.bg(id), dark.attr(id), dark.fg16(id), dark.bg16(id)] }
    light = D::Themes.find("one_light", "terminal")
    t.assert_equal([0xfafafa, 0x2f63d6, 15, 4], [light.fg(H::STATUS_MODE_NORMAL), light.bg(H::STATUS_MODE_NORMAL), light.fg16(H::STATUS_MODE_NORMAL), light.bg16(H::STATUS_MODE_NORMAL)], "a light palette's pill is light text on its dark accent, even with the terminal's background")

    t.assert_equal([-1, -1, -1, -1, -1, -1, 0, false], [dark.fg(H::NORMAL), dark.bg(H::NORMAL), dark.fg256(H::NORMAL), dark.bg256(H::NORMAL), dark.fg16(H::NORMAL), dark.bg16(H::NORMAL), dark.attr(H::NORMAL), dark.paints_background?], "with the terminal's background Normal keeps the terminal's colors")
    t.assert_equal([0xabb2bf, 0x282c34, 7, 0, true], [painted.fg(H::NORMAL), painted.bg(H::NORMAL), painted.fg16(H::NORMAL), painted.bg16(H::NORMAL), painted.paints_background?], "with the theme's background Normal is the palette's")
    t.assert_equal([-1, 0x282c34], [dark.bg(H::COMMENT), painted.bg(H::COMMENT)], "a group without a background of its own is drawn on the painted one")
    t.assert_equal([-1, 0xabb2bf], [dark.fg(H::VISUAL), painted.fg(H::VISUAL)], "a group without a foreground of its own takes the palette's text color when painted")
    PALETTES.each do |name|
      t.assert_equal([], uncolored(D::Themes.find(name, "theme")), "#{name}: every group has a 24-bit foreground and background on the theme's background")
      t.assert_equal(["Normal", "Delimiter"], plain_16(D::Themes.find(name, "terminal")), "#{name}: every group but Normal and Delimiter shows at 16 colors")
      t.assert_true(search_backgrounds?(D::Themes.find(name, "terminal")), "#{name}: Search, IncSearch, and CurSearch have a background at every depth")
    end
    t.assert_equal([0x959ca8, D::Theme::ITALIC], [dark.fg(H::COMMENT), dark.attr(H::COMMENT)], "one_dark comments are gray and italic")
    t.assert_true(dark.fg(H::KEYWORD) != D::Themes.find("dark_plus", "terminal").fg(H::KEYWORD), "palettes have their own syntax colors")
    t.assert_equal([-1, 71], [dark.fg256(H::COMMENT), D::Themes.find("dark_plus", "terminal").fg256(H::COMMENT)], "a palette gives a 256-color index only where it needs one")
    t.assert_equal([0, D::Theme::REVERSE, 0, D::Theme::UNDERLINE], [dark.attr(H::VISUAL), dark.attr16(H::VISUAL), dark.attr(H::CURSOR_LINE), dark.attr16(H::CURSOR_LINE)], "16-color attributes stand in for the selection and cursor line colors")
    t.assert_equal(D::Theme::BOLD, dark.attr(H::STATUS) & D::Theme::BOLD, "the status line is bold")

    # WCAG AA: 4.5:1 for text, 3:1 for decorations, on the theme's
    # background, at 24 bits and at the 256 colors written.
    t.table([
      ["one_dark at 24 bits", ["one_dark", "24"], []],
      ["one_dark at 256 colors", ["one_dark", "256"], []],
      ["one_light at 24 bits", ["one_light", "24"], []],
      ["one_light at 256 colors", ["one_light", "256"], []],
      ["dark_plus at 24 bits", ["dark_plus", "24"], []],
      ["dark_plus at 256 colors", ["dark_plus", "256"], []],
      ["light_plus at 24 bits", ["light_plus", "24"], []],
      ["light_plus at 256 colors", ["light_plus", "256"], []]
    ]) { |input| low_contrast(D::Themes.find(input[0].to_s, "theme"), input[1].to_s == "256", 0) }

    # On the cursor line, over CursorLine's background where a group has
    # none of its own, every group keeps 3:1.
    t.table([
      ["one_dark on the cursor line at 24 bits", ["one_dark", "24"], []],
      ["one_dark on the cursor line at 256 colors", ["one_dark", "256"], []],
      ["one_light on the cursor line at 24 bits", ["one_light", "24"], []],
      ["one_light on the cursor line at 256 colors", ["one_light", "256"], []],
      ["dark_plus on the cursor line at 24 bits", ["dark_plus", "24"], []],
      ["dark_plus on the cursor line at 256 colors", ["dark_plus", "256"], []],
      ["light_plus on the cursor line at 24 bits", ["light_plus", "24"], []],
      ["light_plus on the cursor line at 256 colors", ["light_plus", "256"], []]
    ]) { |input| low_contrast(D::Themes.find(input[0].to_s, "theme"), input[1].to_s == "256", H::CURSOR_LINE_LAYER) }
    lit = H::CURSOR_LINE_LAYER
    t.assert_equal([painted.fg(H::COMMENT), painted.bg(H::CURSOR_LINE), dark.bg(H::CURSOR_LINE), painted.attr(H::COMMENT)], [painted.fg(H::COMMENT + lit), painted.bg(H::COMMENT + lit), dark.bg(H::NORMAL + lit), painted.attr(H::COMMENT + lit)], "a group on the cursor line keeps its color and attributes over CursorLine's background")
    t.assert_equal([dark.bg(H::VISUAL), dark.bg16(H::SEARCH), dark.attr16(H::VISUAL)], [dark.bg(H::VISUAL + lit), dark.bg16(H::SEARCH + lit), dark.attr16(H::VISUAL + lit)], "a group with a background of its own keeps it on the cursor line")
    t.assert_equal([D::Theme::ITALIC | D::Theme::UNDERLINE, D::Theme::UNDERLINE], [dark.attr16(H::COMMENT + lit), dark.attr16(H::NORMAL + lit)], "at 16 colors the cursor line underlines a group without a background")
    t.assert_equal([painted.bg16(H::NORMAL), painted.bg16(H::NORMAL), painted.fg16(H::NORMAL), D::Theme::UNDERLINE], [painted.bg16(H::NORMAL + lit), painted.bg16(H::COMMENT + lit), painted.fg16(H::NORMAL + lit), painted.attr16(H::NORMAL + lit)], "at 16 colors a painted theme keeps Normal's background on the cursor line")
    PALETTES.each do |name|
      theme = D::Themes.find(name, "theme")
      t.assert_true(theme.bg16(H::NORMAL + lit) >= 0 && theme.bg16(H::COMMENT + lit) == theme.bg16(H::NORMAL), "#{name}: at 16 colors the painted cursor line keeps the background")
    end
    t.assert_equal([H::COMMENT, H::COMMENT, H::NORMAL, 3 * H::COUNT], [H.base(H::COMMENT), H.base(H::COMMENT + lit), H.base(lit), H::LIMIT], "base strips the cursor-line layer")
    inside = H::FLOAT_LAYER
    t.assert_equal([H::MARKUP_HEADING, H::NORMAL, 2 * H::COUNT], [H.base(H::MARKUP_HEADING + inside), H.base(inside), inside], "base strips the float layer")

    # Inside a float a group keeps its foreground and attributes over
    # NormalFloat's background, at every depth, unless it has its own.
    t.assert_equal([dark.fg(H::COMMENT), dark.bg(H::NORMAL_FLOAT), dark.bg256(H::NORMAL_FLOAT), dark.bg16(H::NORMAL_FLOAT), dark.attr(H::COMMENT)], [dark.fg(H::COMMENT + inside), dark.bg(H::COMMENT + inside), dark.bg256(H::COMMENT + inside), dark.bg16(H::COMMENT + inside), dark.attr(H::COMMENT + inside)], "a group in a float is drawn over NormalFloat's background")
    t.assert_equal([dark.bg(H::TODO), dark.fg(H::NORMAL_FLOAT)], [dark.bg(H::TODO + inside), dark.fg(H::MARKUP_STRONG + inside)], "a group with a background of its own keeps it in a float, one without a foreground takes NormalFloat's")
    t.assert_equal([0x61afef, D::Theme::BOLD, 0xabb2bf, D::Theme::BOLD, D::Theme::ITALIC, 0x98c379, 0x56b6c2, D::Theme::UNDERLINE, 0x959ca8], [painted.fg(H::MARKUP_HEADING), painted.attr(H::MARKUP_HEADING), painted.fg(H::MARKUP_STRONG), painted.attr(H::MARKUP_STRONG), painted.attr(H::MARKUP_ITALIC), painted.fg(H::MARKUP_RAW), painted.fg(H::MARKUP_LINK), painted.attr(H::MARKUP_LINK), painted.fg(H::MARKUP_RAW_BLOCK)], "one_dark's markup groups: blue bold headings, bold and italic text, green code, underlined cyan links, gray blocks")

    # WCAG AA inside a float: every syntax and markup group at 4.5:1 over
    # NormalFloat's background, at 24 bits and at the 256 colors written.
    t.table([
      ["one_dark in a float at 24 bits", ["one_dark", "24"], []],
      ["one_dark in a float at 256 colors", ["one_dark", "256"], []],
      ["one_light in a float at 24 bits", ["one_light", "24"], []],
      ["one_light in a float at 256 colors", ["one_light", "256"], []],
      ["dark_plus in a float at 24 bits", ["dark_plus", "24"], []],
      ["dark_plus in a float at 256 colors", ["dark_plus", "256"], []],
      ["light_plus in a float at 24 bits", ["light_plus", "24"], []],
      ["light_plus in a float at 256 colors", ["light_plus", "256"], []]
    ]) { |input| float_low_contrast(D::Themes.find(input[0].to_s, "theme"), input[1].to_s == "256") }
    t.assert_true(contrast(painted.fg(H::COMMENT), painted.bg(H::COMMENT)) >= 450, "one_dark comments are readable")
    t.assert_equal([454, 100], [contrast(0x767676, 0xffffff), contrast(0x777777, 0x777777)], "the contrast of WCAG's lightest AA gray on white and of a color on itself")

    # Options read the theme from the option.theme line and the
    # background from the option.background line.
    t.assert_equal(["one_dark", "terminal", true], [D::Options.new.theme, D::Options.new.background, D::Options.new.syntax_on], "the defaults: one_dark on the terminal's background, syntax on")
    t.assert_equal("light_plus", theme_of("option.theme light_plus\n").theme, "the theme line selects a palette")
    t.assert_equal("carat-light", theme_of("option.theme carat-light\n").theme, "an alias is accepted")
    unknown = D::Config.new
    unknown.read(".caratrc", "option.theme solarized\n", false)
    t.assert_equal(["one_dark", [".caratrc:1: unknown theme solarized"]], [D::Options.from_config(unknown).theme, unknown.report], "an unknown theme keeps the default and is reported")
    t.assert_equal("one_dark", theme_of("option.theme \"carat light\" x\n").theme, "a theme of the wrong kind keeps the default")
    t.assert_equal("theme", theme_of("option.background theme\n").background, "the background line paints the background")
    background = D::Config.new
    background.read(".caratrc", "option.background dark\n", false)
    t.assert_equal(["terminal", [".caratrc:1: unknown background dark"]], [D::Options.from_config(background).background, background.report], "an unknown background keeps the default and is reported")
    shipped = D::Config.new
    shipped.read_defaults("config/default.caratrc", D::DEFAULT_CARATRC)
    t.assert_equal(["one_dark", "terminal"], [D::Options.from_config(shipped).theme, D::Options.from_config(shipped).background], "the shipped configuration names one_dark on the terminal's background")

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
