require_relative "../carat"
require_relative "../carat/testing"

# The test is this module's main. test/runner/run_all.rb runs it by name
# with every other test in one program; the guard at the end runs it when
# the file is compiled on its own (make test-one).
module DomainThemeTest
  D = Carat::Domain
  H = D::Highlight

  # The groups drawn as decorations, held to 3:1 rather than 4.5:1 (the
  # selected row's bar among them, a glyph beside the fill and the bold
  # label that already mark the row), and
  # the groups that carry no text, exempt from the contrast rule.
  DECORATIONS = [H::LINE_NUMBER, H::NON_TEXT, H::END_OF_BUFFER, H::WINDOW_SEPARATOR, H::FLOAT_BORDER, H::WHITESPACE, H::SIGN_COLUMN, H::INDENT_GUIDE, H::INDENT_GUIDE_SCOPE, H::POPUP_MENU_MARK_SELECTED]
  NO_TEXT = [H::TAB_LINE_FILL, H::POPUP_MENU_SCROLLBAR, H::POPUP_MENU_THUMB]
  # The palettes whose indent guides recede behind the text, ordered
  # below Comment rather than held to 3:1, and whose float border keeps
  # its own 1.3:1 floor, and the guide groups, Whitespace among them since
  # the whitespace marks take the guides' color.
  RECEDING = ["carat-dark", "carat-light"]
  GUIDES = [H::INDENT_GUIDE, H::INDENT_GUIDE_SCOPE, H::WHITESPACE]

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

  # The groups of a menu's selected row.
  SELECTED = [H::POPUP_MENU_SELECTED, H::POPUP_MENU_MATCH_SELECTED, H::POPUP_MENU_EXTRA_SELECTED]

  # The selected menu row's groups inside a float whose foreground falls
  # below 4.5:1 on their background, at 24 bits or at 256 colors, each
  # with its ratio.
  #: (Carat::Domain::Theme, bool) -> Array[String]
  def self.selected_low_contrast(theme, at256)
    out = []
    SELECTED.each do |id|
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
    out
  end

  # The selected menu row's groups inside a float that at 16 colors lack
  # reverse video or differ from PmenuSel's colors.
  #: (Carat::Domain::Theme) -> Array[String]
  def self.selected_16(theme)
    out = []
    sel = H::POPUP_MENU_SELECTED + H::FLOAT_LAYER
    SELECTED.each do |id|
      inside = id + H::FLOAT_LAYER
      reverse = (theme.attr16(inside) & D::Theme::REVERSE) != 0
      same = theme.fg16(inside) == theme.fg16(sel) && theme.bg16(inside) == theme.bg16(sel)
      out << H::NAMES[id] unless reverse && same
    end
    out
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

  # The groups of a theme whose foreground falls below WCAG AA on their
  # background, 4.5:1 for text and 3:1 for decorations, at 24 bits or at
  # 256 colors, each with its ratio, and those pairing the terminal's
  # color with the palette's, "unpaired"; with layer
  # H::CURSOR_LINE_LAYER, each group as drawn on the cursor line, held to
  # the same thresholds. The guides of a RECEDING palette are left to
  # guide_order, its float border to border_low.
  #: (Carat::Domain::Theme, bool, Integer) -> Array[String]
  def self.low_contrast(theme, at256, layer)
    out = []
    id = 0
    receding = RECEDING.include?(theme.name)
    while id < H::COUNT
      unless NO_TEXT.include?(id) || (receding && (GUIDES.include?(id) || id == H::FLOAT_BORDER))
        fg = theme.fg(id + layer)
        bg = theme.bg(id + layer)
        if fg < 0 || bg < 0
          out << "#{H::NAMES[id]} unpaired" if fg >= 0 || bg >= 0
        else
          if at256
            fg = shown_256(fg, theme.fg256(id + layer))
            bg = shown_256(bg, theme.bg256(id + layer))
          end
          ratio = contrast(fg, bg)
          out << "#{H::NAMES[id]} #{ratio}" if ratio < (decoration?(id) ? 300 : 450)
        end
      end
      id += 1
    end
    out
  end

  # The entries of the guide groups (the indent guides and Whitespace)
  # among a theme's low_contrast ones.
  #: (Carat::Domain::Theme, bool, Integer) -> Array[String]
  def self.guide_low_contrast(theme, at256, layer)
    out = []
    low_contrast(theme, at256, layer).each do |entry|
      GUIDES.each do |id|
        out << entry if entry.start_with?("#{H::NAMES[id]} ")
      end
    end
    out
  end

  # What breaks the indent guides' order on a theme, on layer 0 or on
  # H::CURSOR_LINE_LAYER, at 24 bits or at 256 colors: IblIndent at or
  # above IblScope, IblScope at or above Comment, or IblIndent below
  # 1.1:1, each with the ratios.
  #: (Carat::Domain::Theme, bool, Integer) -> Array[String]
  def self.guide_order(theme, at256, layer)
    ratios = []
    [H::INDENT_GUIDE, H::INDENT_GUIDE_SCOPE, H::COMMENT].each do |id|
      fg = theme.fg(id + layer)
      bg = theme.bg(id + layer)
      if at256
        fg = shown_256(fg, theme.fg256(id + layer))
        bg = shown_256(bg, theme.bg256(id + layer))
      end
      ratios << contrast(fg, bg)
    end
    out = []
    out << "IblIndent #{ratios[0]} not below IblScope #{ratios[1]}" unless ratios[0] < ratios[1]
    out << "IblScope #{ratios[1]} not below Comment #{ratios[2]}" unless ratios[1] < ratios[2]
    out << "IblIndent #{ratios[0]} below 1.1:1" if ratios[0] < 110
    out
  end

  # FloatBorder's contrast on its background, on layer 0 or on
  # H::CURSOR_LINE_LAYER, at 24 bits or at 256 colors, when below 1.3:1.
  #: (Carat::Domain::Theme, bool, Integer) -> Array[String]
  def self.border_low(theme, at256, layer)
    id = H::FLOAT_BORDER + layer
    fg = theme.fg(id)
    bg = theme.bg(id)
    if at256
      fg = shown_256(fg, theme.fg256(id))
      bg = shown_256(bg, theme.bg256(id))
    end
    ratio = contrast(fg, bg)
    ratio < 130 ? ["FloatBorder #{ratio}"] : []
  end

  # A role's row of a palette: its 24-bit color, its 256-color index,
  # and its 16-color index, read from the palette's table, for any role,
  # drawn by a group or not.
  #: (Array[Integer], Integer) -> Array[Integer]
  def self.role_row(palette, role)
    i = 0
    while i + 3 < palette.length
      return [palette[i + 1], palette[i + 2], palette[i + 3]] if palette[i] == role
      i += 4
    end
    [-1, -1, -1]
  end

  # The groups drawn on the status bar's background: the lsp slot's and
  # the diagnostics counts'.
  LSP_GROUPS = [H::STATUS_LSP_STARTING, H::STATUS_LSP_READY, H::STATUS_LSP_ERROR]
  COUNT_GROUPS = [H::STATUS_DIAGNOSTIC_ERROR, H::STATUS_DIAGNOSTIC_WARN, H::STATUS_DIAGNOSTIC_INFO, H::STATUS_DIAGNOSTIC_HINT]

  # The 24-bit colors xterm shows for the 16 basic colors by default, the
  # reference the 16-color contrast checks measure against.
  XTERM_16 = [0x000000, 0xcd0000, 0x00cd00, 0xcdcd00, 0x0000ee, 0xcd00cd, 0x00cdcd, 0xe5e5e5, 0x7f7f7f, 0xff0000, 0x00ff00, 0xffff00, 0x5c5cff, 0xff00ff, 0x00ffff, 0xffffff]

  # The groups among ids whose background differs from StatusLine's at
  # some depth, by name.
  #: (Carat::Domain::Theme, Array[Integer]) -> Array[String]
  def self.bar_holes(theme, ids)
    out = []
    ids.each do |id|
      same = theme.bg(id) == theme.bg(H::STATUS) && theme.bg256(id) == theme.bg256(H::STATUS) && theme.bg16(id) == theme.bg16(H::STATUS)
      out << H::NAMES[id] unless same
    end
    out
  end

  # The groups on the status bar, StatusLine, StatusLineDim, the lsp groups,
  # and the count groups, whose 16-color foreground falls below 4.5:1 on their
  # 16-color background under xterm's default colors, each with its
  # ratio, or that lack a basic color on either side.
  #: (Carat::Domain::Theme) -> Array[String]
  def self.bar_low_contrast_16(theme)
    out = []
    ([H::STATUS, H::STATUS_DIM] + LSP_GROUPS + COUNT_GROUPS).each do |id|
      fg = theme.fg16(id)
      bg = theme.bg16(id)
      if fg < 0 || bg < 0
        out << "#{H::NAMES[id]} no basic color"
      else
        ratio = contrast(XTERM_16[fg], XTERM_16[bg])
        out << "#{H::NAMES[id]} #{ratio}" if ratio < 450
      end
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

  # What keeps a theme's selected tab from reading at a glance: its
  # background below 3:1 from TabLine's or TabLineFill's at 24 bits or at
  # 256 colors, the same basic background as theirs, or bold missing on
  # TabLineSel or present on TabLine at either depth.
  #: (Carat::Domain::Theme) -> Array[String]
  def self.tab_glance(theme)
    out = []
    sel = H::TAB_LINE_SELECTED
    [H::TAB_LINE, H::TAB_LINE_FILL].each do |id|
      ratio = contrast(theme.bg(sel), theme.bg(id))
      out << "#{H::NAMES[id]} #{ratio}" if ratio < 300
      ratio = contrast(shown_256(theme.bg(sel), theme.bg256(sel)), shown_256(theme.bg(id), theme.bg256(id)))
      out << "#{H::NAMES[id]} at 256 #{ratio}" if ratio < 300
      out << "#{H::NAMES[id]} at 16" if theme.bg16(sel) == theme.bg16(id)
    end
    bold = D::Theme::BOLD
    out << "TabLineSel not bold" if (theme.attr(sel) & bold) == 0 || (theme.attr16(sel) & bold) == 0
    out << "TabLine bold" if (theme.attr(H::TAB_LINE) & bold) != 0 || (theme.attr16(H::TAB_LINE) & bold) != 0
    out
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
    # UI group is -1), The search groups have colors,
    # Every UI group has a color in every palette,
    # Every palette passes (the contrast tables), and Comments are readable.
    # The group table: the 67 UI groups first, then the thirty syntax
    # groups, then the thirteen file-icon groups, then the six markup
    # groups.
    t.assert_equal(H::COUNT, H::NAMES.length, "every id has a name")
    t.assert_equal(["IblScope", "FloatTitle", "PmenuMatch", "PmenuMatchSel", "PmenuExtra", "PmenuExtraSel", "Added", "Changed", "Removed", "LineNrFifth", "MsgDim", "Folded", "StatusLineDim", "Comment"], [H::NAMES[H::INDENT_GUIDE_SCOPE], H::NAMES[H::FLOAT_TITLE], H::NAMES[H::POPUP_MENU_MATCH], H::NAMES[H::POPUP_MENU_MATCH_SELECTED], H::NAMES[H::POPUP_MENU_EXTRA], H::NAMES[H::POPUP_MENU_EXTRA_SELECTED], H::NAMES[H::ADDED], H::NAMES[H::CHANGED], H::NAMES[H::REMOVED], H::NAMES[H::LINE_NUMBER_FIFTH], H::NAMES[H::MESSAGE_DIM], H::NAMES[H::FOLDED], H::NAMES[H::STATUS_DIM], H::NAMES[H::SYNTAX_FIRST]], "FloatTitle follows the indent guides, then the popup menu's match and extra groups, and Added, Changed, Removed, LineNrFifth, MsgDim, Folded, and StatusLineDim are the last UI groups")
    t.assert_equal([69, 30, 13, 6], [H::SYNTAX_FIRST, H::ICON_FIRST - H::SYNTAX_FIRST, H::MARKUP_FIRST - H::ICON_FIRST, H::COUNT - H::MARKUP_FIRST], "69 UI groups, thirty syntax groups, thirteen file-icon groups, six markup groups")
    t.assert_equal(["@markup.heading", "@markup.strong", "@markup.italic", "@markup.raw", "@markup.link.label", "@markup.raw.block"], [H::NAMES[H::MARKUP_HEADING], H::NAMES[H::MARKUP_STRONG], H::NAMES[H::MARKUP_ITALIC], H::NAMES[H::MARKUP_RAW], H::NAMES[H::MARKUP_LINK], H::NAMES[H::MARKUP_RAW_BLOCK]], "the markup groups after the file-icon groups")
    t.assert_equal(["StatusLineModeNormal", "StatusLineLspError"], [H.name_of(H::STATUS_MODE_NORMAL), H.name_of(H::STATUS_LSP_ERROR)], "the status bar's groups follow Neovim's")
    # Scenario: The UI groups. The status bar's count groups follow the lsp groups.
    t.assert_equal(["StatusLineDiagnosticError", "StatusLineDiagnosticWarn", "StatusLineDiagnosticInfo", "StatusLineDiagnosticHint", "IblIndent"], [H::NAMES[H::STATUS_DIAGNOSTIC_ERROR], H::NAMES[H::STATUS_DIAGNOSTIC_WARN], H::NAMES[H::STATUS_DIAGNOSTIC_INFO], H::NAMES[H::STATUS_DIAGNOSTIC_HINT], H::NAMES[H::STATUS_LSP_ERROR + 5]], "the status bar's count groups follow its lsp groups")

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
      ["nor a git sign group", "Added", -1],
      ["Normal is not either", "Normal", -1],
      ["an unknown name", "Banana", -1],
      ["names are case sensitive", "comment", -1]
    ]) { |name| H.token_id(name.to_s) }
    t.assert_equal([false, true, true, true, false], [H.token?(H::VISUAL), H.token?(H::COMMENT), H.token?(H::ERROR), H.token?(H::MARKUP_RAW_BLOCK), H.token?(H::COUNT)], "token? covers the syntax, file-icon, and markup ids only")
    # Scenario: Other UI groups are refused (the predicate a float span is checked with).
    t.assert_equal([true, true, true, false, false, false, false, false], [H.float_style?(H::COMMENT), H.float_style?(H::POPUP_MENU_SELECTED), H.float_style?(H::POPUP_MENU_MATCH), H.float_style?(H::VISUAL), H.float_style?(H::POPUP_MENU_MATCH_SELECTED), H.float_style?(H::NORMAL), H.float_style?(-1), H.float_style?(H::COUNT)], "float_style? admits the token groups, PmenuSel, and PmenuMatch only")
    t.assert_equal([H::POPUP_MENU_SELECTED, H::POPUP_MENU_MATCH, H::COMMENT, -1, -1], [H.float_style_id("PmenuSel"), H.float_style_id("PmenuMatch"), H.float_style_id("Comment"), H.float_style_id("Visual"), H.float_style_id("PmenuMatchSel")], "float_style_id resolves PmenuSel, PmenuMatch, and the token groups only")
    t.assert_equal([false, false], [H.token?(H::POPUP_MENU_SELECTED), H.token?(H::POPUP_MENU_MATCH)], "token? still refuses PmenuSel and PmenuMatch, so a tokenizer cannot paint them")
    t.assert_equal([true, true, false, false, H::POPUP_MENU_MARK_SELECTED, H::POPUP_MENU_LABEL_SELECTED], [H.float_style?(H::POPUP_MENU_MARK_SELECTED), H.float_style?(H::POPUP_MENU_LABEL_SELECTED), H.token?(H::POPUP_MENU_MARK_SELECTED), H.token?(H::POPUP_MENU_LABEL_SELECTED), H.float_style_id("PmenuMarkSel"), H.float_style_id("PmenuLabelSel")], "a float span may carry PmenuMarkSel and PmenuLabelSel, which a tokenizer still cannot paint")
    t.assert_equal(["Visual", ""], [H.name_of(H::VISUAL), H.name_of(H::COUNT + 1)], "name_of")

    # The palettes and the backgrounds.
    t.assert_equal(["carat-dark", "carat-light", "one_dark", "one_light", "dark_plus", "light_plus", "carat-dark"], [D::Themes.find("carat-dark", "terminal").name, D::Themes.find("carat-light", "terminal").name, D::Themes.find("one_dark", "terminal").name, D::Themes.find("one_light", "terminal").name, D::Themes.find("dark_plus", "terminal").name, D::Themes.find("light_plus", "terminal").name, D::Themes.find("nope", "terminal").name], "find, and carat-dark for an unknown name")
    t.assert_equal([true, true, true, true, true, true, false, false], [D::Themes.known?("carat-dark"), D::Themes.known?("carat-light"), D::Themes.known?("one_dark"), D::Themes.known?("one_light"), D::Themes.known?("dark_plus"), D::Themes.known?("light_plus"), D::Themes.known?("nope"), D::Themes.known?("Carat-Dark")], "known?")
    # A name without its own palette in the lookup fails here.
    names = D::Themes::NAMES
    palettes = D::Themes::PALETTES
    shared = []
    i = 0
    while i < palettes.length
      j = i + 1
      while j < palettes.length
        shared << "#{names[i]} #{names[j]}" if palettes[i] == palettes[j]
        j += 1
      end
      i += 1
    end
    t.assert_equal([names.length, []], [palettes.length, shared], "every name has its own palette in the lookup")
    # Scenario: Alias. carat-light is Carat's own light palette, no alias:
    # its colors differ from one_light's.
    carat_light = D::Themes.find("carat-light", "theme")
    one_light = D::Themes.find("one_light", "theme")
    t.assert_true(carat_light.bg(H::NORMAL) != one_light.bg(H::NORMAL) && carat_light.fg(H::KEYWORD) != one_light.fg(H::KEYWORD), "Alias: carat-light is its own palette, not one_light's")
    t.assert_equal([true, true, false], [D::Themes.background?("terminal"), D::Themes.background?("theme"), D::Themes.background?("dark")], "background?")
    dark = D::Themes.find("one_dark", "terminal")
    painted = D::Themes.find("one_dark", "theme")
    # The status bar's groups per mode and state: the pills' text on the
    # mode's accent, bold, the lsp slot's accent on the status bar's own
    # background.
    t.cases([
      ["normal pill", [H::STATUS_MODE_NORMAL], [0x282c34, 0x61afef, D::Theme::BOLD, 0, 12]],
      ["insert pill", [H::STATUS_MODE_INSERT], [0x282c34, 0x98c379, D::Theme::BOLD, 0, 10]],
      ["visual pill", [H::STATUS_MODE_VISUAL], [0x282c34, 0xc97fe0, D::Theme::BOLD, 0, 13]],
      ["replace pill", [H::STATUS_MODE_REPLACE], [0x282c34, 0xe8757e, D::Theme::BOLD, 0, 9]],
      ["The command pill is cyan: one_dark", [H::STATUS_MODE_COMMAND], [0x282c34, 0x56b6c2, D::Theme::BOLD, 0, 14]],
      ["lsp starting", [H::STATUS_LSP_STARTING], [0xe5c07b, 0x3e4452, 0, 0, 7]],
      ["lsp ready", [H::STATUS_LSP_READY], [0x98c379, 0x3e4452, 0, 0, 7]],
      ["lsp error", [H::STATUS_LSP_ERROR], [0xf5a3a8, 0x3e4452, D::Theme::BOLD, 1, 7]]
    ]) { |input| id = input[0].to_i; [dark.fg(id), dark.bg(id), dark.attr(id), dark.fg16(id), dark.bg16(id)] }
    light = D::Themes.find("one_light", "terminal")
    t.assert_equal([0xfafafa, 0x2f63d6, 15, 4], [light.fg(H::STATUS_MODE_NORMAL), light.bg(H::STATUS_MODE_NORMAL), light.fg16(H::STATUS_MODE_NORMAL), light.bg16(H::STATUS_MODE_NORMAL)], "a light palette's pill is light text on its dark accent, even with the terminal's background")

    t.assert_equal([-1, -1, -1, -1, -1, -1, 0, false], [dark.fg(H::NORMAL), dark.bg(H::NORMAL), dark.fg256(H::NORMAL), dark.bg256(H::NORMAL), dark.fg16(H::NORMAL), dark.bg16(H::NORMAL), dark.attr(H::NORMAL), dark.paints_background?], "with the terminal's background Normal keeps the terminal's colors")
    t.assert_equal([0xabb2bf, 0x282c34, 7, 0, true], [painted.fg(H::NORMAL), painted.bg(H::NORMAL), painted.fg16(H::NORMAL), painted.bg16(H::NORMAL), painted.paints_background?], "with the theme's background Normal is the palette's")
    t.assert_equal([-1, 0x282c34], [dark.bg(H::COMMENT), painted.bg(H::COMMENT)], "a group without a background of its own is drawn on the painted one")
    t.assert_equal([-1, 0xabb2bf], [dark.fg(H::VISUAL), painted.fg(H::VISUAL)], "a group without a foreground of its own takes the palette's text color when painted")
    D::Themes::NAMES.each do |name|
      t.assert_equal([], uncolored(D::Themes.find(name, "theme")), "#{name}: every group has a 24-bit foreground and background on the theme's background")
      t.assert_equal(["Normal", "Delimiter"], plain_16(D::Themes.find(name, "terminal")), "#{name}: every group but Normal and Delimiter shows at 16 colors")
      t.assert_true(search_backgrounds?(D::Themes.find(name, "terminal")), "#{name}: Search, IncSearch, and CurSearch have a background at every depth")
    end
    t.assert_equal([0x959ca8, D::Theme::ITALIC], [dark.fg(H::COMMENT), dark.attr(H::COMMENT)], "one_dark comments are gray and italic")
    t.assert_true(dark.fg(H::KEYWORD) != D::Themes.find("dark_plus", "terminal").fg(H::KEYWORD), "palettes have their own syntax colors")
    t.assert_equal([-1, 71], [dark.fg256(H::COMMENT), D::Themes.find("dark_plus", "terminal").fg256(H::COMMENT)], "a palette gives a 256-color index only where it needs one")
    t.assert_equal([0, D::Theme::REVERSE, 0, D::Theme::UNDERLINE], [dark.attr(H::VISUAL), dark.attr16(H::VISUAL), dark.attr(H::CURSOR_LINE), dark.attr16(H::CURSOR_LINE)], "16-color attributes stand in for the selection and cursor line colors")
    t.assert_equal(D::Theme::BOLD, dark.attr(H::STATUS) & D::Theme::BOLD, "the status line is bold")

    # Scenario: Every palette passes. WCAG AA: 4.5:1 for text, 3:1 for
    # decorations, on the theme's background, at 24 bits and at the 256
    # colors written. The pills, the lsp groups, and the count groups are
    # text groups, so the
    # same rows prove three more scenarios:
    # Every palette's pills pass
    # Every palette's lsp groups pass on the bar
    # Every palette's count groups pass on the bar
    D::Themes::NAMES.each do |name|
      t.assert_equal([], low_contrast(D::Themes.find(name, "theme"), false, 0), "#{name} at 24 bits")
      t.assert_equal([], low_contrast(D::Themes.find(name, "theme"), true, 0), "#{name} at 256 colors")
    end

    # Scenario: The lsp groups share the bar's background. With either
    # background choice, at 24 bits, 256 colors, and 16 colors, the lsp
    # slot is drawn on StatusLine's background, so the bar has no hole.
    D::Themes::NAMES.each do |name|
      D::Themes::BACKGROUNDS.each do |background|
        theme = D::Themes.find(name, background)
        t.assert_equal([], bar_holes(theme, LSP_GROUPS), "The lsp groups share the bar's background: #{name} on the #{background}'s background")
        # Scenario: The count groups share the bar's background. The
        # diagnostics counts leave no hole in the bar either.
        t.assert_equal([], bar_holes(theme, COUNT_GROUPS), "The count groups share the bar's background: #{name} on the #{background}'s background")
      end
    end

    # Scenario: The bar reads at 16 colors. StatusLine, the lsp groups,
    # and the count groups reach 4.5:1 on the bar under xterm's default
    # colors, so no accent reads near 1.5:1 on a light gray bar.
    D::Themes::NAMES.each do |name|
      t.assert_equal([], bar_low_contrast_16(D::Themes.find(name, "terminal")), "The bar reads at 16 colors: #{name}")
    end
    t.assert_equal([135, 171], [contrast(XTERM_16[3], XTERM_16[7]), contrast(XTERM_16[2], XTERM_16[7])], "the basic dark yellow and green the lsp slot had on the light gray bar read below 2:1")

    # Scenario: The mark and label groups in every palette. PmenuMarkSel
    # is the sapphire bar and PmenuLabelSel the bold label of a selected
    # list row, both on PmenuSel's selection background, reverse and
    # bold at 16 colors where the selection fill is reverse.
    D::Themes::NAMES.each_with_index do |name, i|
      theme = D::Themes.find(name, "terminal")
      fill = theme.bg(H::POPUP_MENU_SELECTED)
      blue = role_row(D::Themes::PALETTES[i], D::Themes::MARK)[0]
      both = D::Theme::REVERSE | D::Theme::BOLD
      expected = [[blue, fill, D::Theme::BOLD, both], [theme.fg(H::POPUP_MENU_SELECTED), fill, D::Theme::BOLD, both], ["PmenuMarkSel", "PmenuLabelSel"]]
      got = [[theme.fg(H::POPUP_MENU_MARK_SELECTED), theme.bg(H::POPUP_MENU_MARK_SELECTED), theme.attr(H::POPUP_MENU_MARK_SELECTED), theme.attr16(H::POPUP_MENU_MARK_SELECTED)], [theme.fg(H::POPUP_MENU_LABEL_SELECTED), theme.bg(H::POPUP_MENU_LABEL_SELECTED), theme.attr(H::POPUP_MENU_LABEL_SELECTED), theme.attr16(H::POPUP_MENU_LABEL_SELECTED)], [H.name_of(H::POPUP_MENU_MARK_SELECTED), H.name_of(H::POPUP_MENU_LABEL_SELECTED)]]
      t.assert_equal(expected, got, "The mark and label groups in every palette: #{name}")
    end
    t.assert_equal([role_row(D::Themes::PALETTES[0], D::Themes::BLUE)[0], role_row(D::Themes::PALETTES[1], D::Themes::BLUE)[0]], [role_row(D::Themes::PALETTES[0], D::Themes::MARK)[0], role_row(D::Themes::PALETTES[1], D::Themes::MARK)[0]], "the bar is the carat themes' sapphire")

    # Scenario: StatusLineDim is the bar's quiet text in every palette.
    # PANEL_DIM on the bar's PANEL background reaches 4.5:1 at 24 bits, at
    # 256 colors, and at 16 colors under xterm's default colors, the
    # carat themes' values being the design's, with the bar's background
    # and no attributes, on either background choice.
    D::Themes::NAMES.each_with_index do |name, i|
      row = role_row(D::Themes::PALETTES[i], D::Themes::PANEL_DIM)
      panel = role_row(D::Themes::PALETTES[i], D::Themes::PANEL)
      D::Themes::BACKGROUNDS.each do |background|
        theme = D::Themes.find(name, background)
        t.assert_equal([row[0], panel[0], 0, 0], [theme.fg(H::STATUS_DIM), theme.bg(H::STATUS_DIM), theme.attr(H::STATUS_DIM), theme.attr16(H::STATUS_DIM)], "StatusLineDim is PANEL_DIM on the bar's background, not bold: #{name} on the #{background}'s background")
        t.assert_equal([], bar_holes(theme, [H::STATUS_DIM]), "StatusLineDim shares the bar's background: #{name} on the #{background}'s background")
      end
      theme = D::Themes.find(name, "terminal")
      ratios = [contrast(theme.fg(H::STATUS_DIM), theme.bg(H::STATUS_DIM)), contrast(shown_256(theme.fg(H::STATUS_DIM), theme.fg256(H::STATUS_DIM)), shown_256(theme.bg(H::STATUS_DIM), theme.bg256(H::STATUS_DIM))), contrast(XTERM_16[theme.fg16(H::STATUS_DIM)], XTERM_16[theme.bg16(H::STATUS_DIM)])]
      t.assert_equal([true, true, true], [ratios[0] >= 450, ratios[1] >= 450, ratios[2] >= 450], "PANEL_DIM reads on the bar at 24 bits, 256 colors, and 16 colors: #{name} #{ratios}")
      # StatusLine is bold and StatusLineDim is not, so the lead and the
      # quiet text differ at 16 colors, where their colors may match.
      t.assert_equal([D::Theme::BOLD, 0], [theme.attr16(H::STATUS) & D::Theme::BOLD, theme.attr16(H::STATUS_DIM) & D::Theme::BOLD], "StatusLine leads in bold and StatusLineDim does not at 16 colors: #{name}")
    end
    carat = [role_row(D::Themes::CARAT_DARK, D::Themes::PANEL_DIM)[0], role_row(D::Themes::CARAT_LIGHT, D::Themes::PANEL_DIM)[0]]
    t.assert_equal([0xa4aabd, 0x5c6173], carat, "the carat themes' PANEL_DIM are the design's values")
    t.assert_equal(["StatusLineDim", false], [H.name_of(H::STATUS_DIM), H.token?(H::STATUS_DIM)], "the bar's quiet group is named StatusLineDim and is a UI group")

    # Every palette's selected tab stands out: TabLineSel on its accent
    # at 3:1 from the tab row, another basic color, and bold, on either
    # background.
    D::Themes::NAMES.each do |name|
      ["theme", "terminal"].each do |background|
        t.assert_equal([], tab_glance(D::Themes.find(name, background)), "#{name} on the #{background} background: the selected tab reads at a glance")
      end
    end

    # Scenario: Every palette passes on the cursor line. Over
    # CursorLine's background where a group has none of its own, text
    # keeps 4.5:1 and decorations 3:1, with either background, and no
    # cell keeps the terminal's foreground over a palette color.
    D::Themes::BACKGROUNDS.each do |background|
      D::Themes::NAMES.each do |name|
        t.assert_equal([], low_contrast(D::Themes.find(name, background), false, H::CURSOR_LINE_LAYER), "#{name} on the cursor line on the #{background}'s background at 24 bits")
        t.assert_equal([], low_contrast(D::Themes.find(name, background), true, H::CURSOR_LINE_LAYER), "#{name} on the cursor line on the #{background}'s background at 256 colors")
      end
    end
    # Scenario: The other palettes' guides keep 3:1. IblIndent and
    # IblScope of one_dark, one_light, dark_plus, and light_plus keep 3:1
    # on the background and on the cursor line, at 24 bits and at 256
    # colors. Scenario: The other palettes' whitespace marks keep 3:1:
    # guide_low_contrast checks every group of GUIDES, Whitespace among
    # them.
    ["one_dark", "one_light", "dark_plus", "light_plus"].each do |name|
      theme = D::Themes.find(name, "theme")
      [0, H::CURSOR_LINE_LAYER].each do |layer|
        where = layer == 0 ? "the background" : "the cursor line"
        t.assert_equal([], guide_low_contrast(theme, false, layer), "The other palettes' guides keep 3:1: #{name} on #{where} at 24 bits")
        t.assert_equal([], guide_low_contrast(theme, true, layer), "The other palettes' guides keep 3:1: #{name} on #{where} at 256 colors")
      end
    end

    # Scenario: The guides order below Comment. In Carat's palettes
    # IblIndent is below IblScope, IblScope below Comment, and IblIndent
    # at least 1.1:1, on the background and on the cursor line, at 24
    # bits and at 256 colors.
    RECEDING.each do |name|
      theme = D::Themes.find(name, "theme")
      [0, H::CURSOR_LINE_LAYER].each do |layer|
        where = layer == 0 ? "the background" : "the cursor line"
        t.assert_equal([], guide_order(theme, false, layer), "The guides order below Comment: #{name} on #{where} at 24 bits")
        t.assert_equal([], guide_order(theme, true, layer), "The guides order below Comment: #{name} on #{where} at 256 colors")
      end
    end
    # Scenario: The guide colors. Carat's palettes give the guides their
    # own colors, basic color 8 at 16 colors.
    t.cases([
      ["The guide colors: carat-dark", ["carat-dark"], [0x30364b, 0x46506e, 8, 8]],
      ["The guide colors: carat-light", ["carat-light"], [0xd8dce8, 0xa9b4d6, 8, 8]]
    ]) do |input|
      theme = D::Themes.find(input[0].to_s, "terminal")
      [theme.fg(H::INDENT_GUIDE), theme.fg(H::INDENT_GUIDE_SCOPE), theme.fg16(H::INDENT_GUIDE), theme.fg16(H::INDENT_GUIDE_SCOPE)]
    end

    # Scenario: The whitespace marks take the guide color. Whitespace has
    # IblIndent's color in every palette, at 24 bits and 16 colors.
    t.cases([
      ["The whitespace marks take the guide color: carat-dark", ["carat-dark"], [0x30364b, 8, true]],
      ["The whitespace marks take the guide color: carat-light", ["carat-light"], [0xd8dce8, 8, true]],
      ["The whitespace marks take the guide color: one_dark", ["one_dark"], [0x737a8a, 8, true]],
      ["The whitespace marks take the guide color: one_light", ["one_light"], [0x84868e, 8, true]],
      ["The whitespace marks take the guide color: dark_plus", ["dark_plus"], [0x737373, 8, true]],
      ["The whitespace marks take the guide color: light_plus", ["light_plus"], [0x858585, 8, true]]
    ]) do |input|
      theme = D::Themes.find(input[0].to_s, "terminal")
      [theme.fg(H::WHITESPACE), theme.fg16(H::WHITESPACE), theme.fg256(H::WHITESPACE) == theme.fg256(H::INDENT_GUIDE)]
    end

    # Scenario: The border colors. Carat's palettes give FloatBorder its
    # own color, basic color 8 at 16 colors.
    t.cases([
      ["The border colors: carat-dark", ["carat-dark"], [0x3b4157, 0x15171e, 8]],
      ["The border colors: carat-light", ["carat-light"], [0xc9cdd9, 0xeceef3, 8]]
    ]) do |input|
      theme = D::Themes.find(input[0].to_s, "terminal")
      [theme.fg(H::FLOAT_BORDER), theme.bg(H::FLOAT_BORDER), theme.fg16(H::FLOAT_BORDER)]
    end
    # Scenario: The border stays apart from the float. Out of the 3:1
    # floor, Carat's float border keeps 1.3:1 on the float's background,
    # on its own and on the cursor line, at 24 bits and at 256 colors.
    RECEDING.each do |name|
      theme = D::Themes.find(name, "theme")
      [0, H::CURSOR_LINE_LAYER].each do |layer|
        where = layer == 0 ? "the float" : "the cursor line"
        t.assert_equal([], border_low(theme, false, layer), "The border stays apart from the float: #{name} on #{where} at 24 bits")
        t.assert_equal([], border_low(theme, true, layer), "The border stays apart from the float: #{name} on #{where} at 256 colors")
      end
    end
    t.assert_equal([177, 174, 136, 132], [contrast(0x3b4157, 0x15171e), contrast(shown_256(0x3b4157, -1), shown_256(0x15171e, -1)), contrast(0xc9cdd9, 0xeceef3), contrast(shown_256(0xc9cdd9, -1), shown_256(0xeceef3, -1))], "the borders' ratios on the float: 1.77:1 and 1.74:1 dark, 1.36:1 and 1.32:1 light, rounded down")

    # Scenario: The search colors. Search and Todo on the soft tint in
    # their own text color, black on bright yellow at 16 colors;
    # CurSearch on the strong INC_SEARCH color, bold, where Search is not.
    t.cases([
      ["The search colors: carat-dark", ["carat-dark"], [0xc8ccd8, 0x4a4129, 0, 11, 0xc8ccd8, 0x4a4129, 0xf0a35e, D::Theme::BOLD, D::Theme::BOLD, 0]],
      ["The search colors: carat-light", ["carat-light"], [0x2f3340, 0xf7e3a1, 0, 11, 0x2f3340, 0xf7e3a1, 0xf2b06e, D::Theme::BOLD, D::Theme::BOLD, 0]]
    ]) do |input|
      theme = D::Themes.find(input[0].to_s, "terminal")
      cur = H::CURRENT_SEARCH
      [theme.fg(H::SEARCH), theme.bg(H::SEARCH), theme.fg16(H::SEARCH), theme.bg16(H::SEARCH), theme.fg(H::TODO), theme.bg(H::TODO), theme.bg(cur), theme.attr(cur) & D::Theme::BOLD, theme.attr16(cur) & D::Theme::BOLD, theme.attr(H::SEARCH) & D::Theme::BOLD]
    end
    # Scenario: The light selection shows. carat-light's Visual is
    # #c2ccef, 1.5:1 from its background, where it was 1.26:1.
    light_carat = D::Themes.find("carat-light", "theme")
    selection = light_carat.bg(H::VISUAL)
    t.assert_equal([0xc2ccef, true, 126], [selection, contrast(selection, light_carat.bg(H::NORMAL)) >= 150, contrast(0xdce1f2, 0xfbfbfd)], "The light selection shows: #c2ccef at 1.5:1 or more from the background, above the old 1.26:1")
    # Scenario: The panel colors. carat-light's panels #eceef3;
    # carat-dark's panels at index 233 at 256 colors, apart from the
    # background's 234.
    dark_carat = D::Themes.find("carat-dark", "theme")
    t.cases([
      ["The panel colors: carat-dark", ["carat-dark"], [0x2e3346]],
      ["The panel colors: carat-light", ["carat-light"], [0xe3e6ef]]
    ]) do |input|
      name = input[0].to_s
      theme = D::Themes.find(name, "theme")
      [theme.bg(H::STATUS)]
    end
    t.assert_equal([0xeceef3, 0xeceef3, 0xeceef3], [light_carat.bg(H::TAB_LINE), light_carat.bg(H::STATUS_NC), light_carat.bg(H::NORMAL_FLOAT)], "The panel colors: carat-light's tab row, inactive bar, and floats are #eceef3")
    t.assert_equal([233, 233, -1], [dark_carat.bg256(H::TAB_LINE), dark_carat.bg256(H::STATUS_NC), dark_carat.bg256(H::NORMAL)], "The panel colors: carat-dark's panels are index 233 at 256 colors")
    t.assert_equal(234, Carat::Adapters::SgrTable.index_256(dark_carat.bg(H::NORMAL)), "carat-dark's background is the nearest index 234")
    # Scenario: The git sign groups are green, cyan, and red. Every
    # palette draws Added in its green, Changed in its cyan, and Removed
    # in its red, on the terminal's own background like SignColumn.
    D::Themes::NAMES.each_with_index do |name, i|
      theme = D::Themes.find(name, "terminal")
      palette = D::Themes::PALETTES[i]
      t.assert_equal([role_row(palette, D::Themes::GREEN)[0], role_row(palette, D::Themes::CYAN)[0], role_row(palette, D::Themes::RED)[0]], [theme.fg(H::ADDED), theme.fg(H::CHANGED), theme.fg(H::REMOVED)], "The git sign groups are green, cyan, and red: #{name}")
      t.assert_equal([theme.bg(H::SIGN_COLUMN), theme.bg(H::SIGN_COLUMN), theme.bg(H::SIGN_COLUMN)], [theme.bg(H::ADDED), theme.bg(H::CHANGED), theme.bg(H::REMOVED)], "the git sign groups share the sign column's background: #{name}")
    end
    # Each sign is drawn in the group of its kind: the group of each icon.
    t.table([
      ["an error sign in DiagnosticError", "error", H::DIAGNOSTIC_ERROR],
      ["a warning sign in DiagnosticWarn", "warning", H::DIAGNOSTIC_WARN],
      ["an info sign in DiagnosticInfo", "info", H::DIAGNOSTIC_INFO],
      ["a hint sign in DiagnosticHint", "hint", H::DIAGNOSTIC_HINT],
      ["git added in Added", "git_added", H::ADDED],
      ["git changed in Changed", "git_changed", H::CHANGED],
      ["git deleted in Removed", "git_deleted", H::REMOVED],
      ["another icon in SignColumn", "ruby", H::SIGN_COLUMN],
      ["an unknown name in SignColumn", "nope", H::SIGN_COLUMN]
    ]) { |icon| H.sign_group(icon.to_s) }
    t.assert_equal([H::DIAGNOSTIC_ERROR, H::DIAGNOSTIC_WARN, H::DIAGNOSTIC_INFO, H::DIAGNOSTIC_HINT], [H.diagnostic_group(1), H.diagnostic_group(2), H.diagnostic_group(3), H.diagnostic_group(4)], "a diagnostic sign's group by its severity")
    t.assert_equal([H::DIAGNOSTIC_HINT, H::DIAGNOSTIC_HINT], [H.diagnostic_group(0), H.diagnostic_group(5)], "a severity outside 1 to 4 is drawn as a hint")

    # Scenario: The groups in the carat themes. MsgDim is the dim role,
    # ErrorMsg bold red, WarningMsg yellow without bold, MoreMsg bold
    # blue, in carat-dark and carat-light and in every other palette.
    D::Themes::NAMES.each_with_index do |name, i|
      theme = D::Themes.find(name, "terminal")
      palette = D::Themes::PALETTES[i]
      fgs = [role_row(palette, D::Themes::DIM)[0], role_row(palette, D::Themes::RED)[0], role_row(palette, D::Themes::YELLOW)[0], role_row(palette, D::Themes::BLUE)[0]]
      t.assert_equal(fgs, [theme.fg(H::MESSAGE_DIM), theme.fg(H::MESSAGE_ERROR), theme.fg(H::MESSAGE_WARNING), theme.fg(H::MESSAGE_MORE)], "the message groups' colors: #{name}")
      t.assert_equal([0, D::Theme::BOLD, 0, D::Theme::BOLD], [theme.attr(H::MESSAGE_DIM), theme.attr(H::MESSAGE_ERROR), theme.attr(H::MESSAGE_WARNING), theme.attr(H::MESSAGE_MORE)], "the message groups' attributes: #{name}")
      t.assert_equal(-1, theme.bg(H::MESSAGE_DIM), "MsgDim has no background of its own: #{name}")
    end
    t.assert_equal("MsgDim", H.name_of(H::MESSAGE_DIM), "the dim message group's name")

    # Scenario: Folded in the carat themes. The closed fold's row is the
    # dim role at every depth, with no background and no attributes, in
    # every palette.
    D::Themes::NAMES.each_with_index do |name, i|
      theme = D::Themes.find(name, "terminal")
      dim = role_row(D::Themes::PALETTES[i], D::Themes::DIM)
      t.assert_equal([dim[0], theme.fg256(H::MESSAGE_DIM), dim[2], -1, -1, 0, 0], [theme.fg(H::FOLDED), theme.fg256(H::FOLDED), theme.fg16(H::FOLDED), theme.bg(H::FOLDED), theme.bg16(H::FOLDED), theme.attr(H::FOLDED), theme.attr16(H::FOLDED)], "Folded is dim at every depth, with no background and no attributes: #{name}")
    end
    t.assert_equal(["Folded", false], [H.name_of(H::FOLDED), H.token?(H::FOLDED)], "the fold row's group is named Folded and is a UI group")

    # Scenario: The command pill is cyan. Every palette's command pill,
    # which the query pickers' prompts draw too, is on its cyan.
    D::Themes::NAMES.each_with_index do |name, i|
      theme = D::Themes.find(name, "terminal")
      t.assert_equal(role_row(D::Themes::PALETTES[i], D::Themes::CYAN)[0], theme.bg(H::STATUS_MODE_COMMAND), "The command pill is cyan: #{name}")
    end

    lit = H::CURSOR_LINE_LAYER
    D::Themes::NAMES.each do |name|
      terminal = D::Themes.find(name, "terminal")
      painted_line = D::Themes.find(name, "theme")
      t.assert_equal([-1, -1, -1, -1], [terminal.fg256(H::NORMAL), terminal.bg256(H::NORMAL), terminal.fg256(H::CURSOR_LINE_NUMBER), terminal.bg256(H::COMMENT)], "#{name}: the terminal's background leaves the text color and background to it at 256 colors too")
      # Scenario: The cursor line on the terminal's background.
      t.assert_equal([painted_line.fg(H::NORMAL + lit), painted_line.bg(H::NORMAL + lit), painted_line.fg256(H::NORMAL + lit), painted_line.bg256(H::NORMAL + lit)], [terminal.fg(H::NORMAL + lit), terminal.bg(H::NORMAL + lit), terminal.fg256(H::NORMAL + lit), terminal.bg256(H::NORMAL + lit)], "The cursor line on the terminal's background: #{name}'s Normal takes the palette's text color over CursorLine's background")
    end
    t.assert_equal([painted.fg(H::COMMENT), painted.bg(H::CURSOR_LINE), dark.bg(H::CURSOR_LINE), painted.attr(H::COMMENT)], [painted.fg(H::COMMENT + lit), painted.bg(H::COMMENT + lit), dark.bg(H::NORMAL + lit), painted.attr(H::COMMENT + lit)], "a group on the cursor line keeps its color and attributes over CursorLine's background")
    t.assert_equal([dark.bg(H::VISUAL), dark.bg16(H::SEARCH), dark.attr16(H::VISUAL)], [dark.bg(H::VISUAL + lit), dark.bg16(H::SEARCH + lit), dark.attr16(H::VISUAL + lit)], "a group with a background of its own keeps it on the cursor line")
    t.assert_equal([D::Theme::ITALIC | D::Theme::UNDERLINE, D::Theme::UNDERLINE], [dark.attr16(H::COMMENT + lit), dark.attr16(H::NORMAL + lit)], "at 16 colors the cursor line underlines a group without a background")
    t.assert_equal([painted.bg16(H::NORMAL), painted.bg16(H::NORMAL), painted.fg16(H::NORMAL), D::Theme::UNDERLINE], [painted.bg16(H::NORMAL + lit), painted.bg16(H::COMMENT + lit), painted.fg16(H::NORMAL + lit), painted.attr16(H::NORMAL + lit)], "at 16 colors a painted theme keeps Normal's background on the cursor line")
    D::Themes::NAMES.each do |name|
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

    # Scenario: Every palette passes in a float. WCAG AA inside a float:
    # every syntax and markup group at 4.5:1 over
    # NormalFloat's background, at 24 bits and at the 256 colors written.
    D::Themes::NAMES.each do |name|
      t.assert_equal([], float_low_contrast(D::Themes.find(name, "theme"), false), "#{name} in a float at 24 bits")
      t.assert_equal([], float_low_contrast(D::Themes.find(name, "theme"), true), "#{name} in a float at 256 colors")
    end
    # Scenario: The selected menu row's groups at each depth. PmenuSel,
    # PmenuMatchSel, and PmenuExtraSel inside a float reach 4.5:1 at 24
    # bits and 256 colors with the theme's background, and at 16 colors,
    # under either background, carry reverse video and PmenuSel's colors.
    D::Themes::NAMES.each do |name|
      t.assert_equal([], selected_low_contrast(D::Themes.find(name, "theme"), false), "#{name}'s selected menu row at 24 bits")
      t.assert_equal([], selected_low_contrast(D::Themes.find(name, "theme"), true), "#{name}'s selected menu row at 256 colors")
    end
    D::Themes::NAMES.each do |name|
      D::Themes::BACKGROUNDS.each do |background|
        t.assert_equal([], selected_16(D::Themes.find(name, background)), "#{name}'s selected menu row at 16 colors on the #{background}'s background")
      end
    end
    carat_dark = D::Themes.find("carat-dark", "theme")
    t.assert_true(contrast(carat_dark.fg(H::COMMENT), carat_dark.bg(H::COMMENT)) >= 450, "Comments are readable: carat-dark's comments reach 4.5:1")
    t.assert_equal([454, 100], [contrast(0x767676, 0xffffff), contrast(0x777777, 0x777777)], "the contrast of WCAG's lightest AA gray on white and of a color on itself")

    # Options read the theme from the option.theme line and the
    # background from the option.background line.
    t.assert_equal(["carat-dark", "theme", true], [D::Options.new.theme, D::Options.new.background, D::Options.new.syntax_on], "the defaults: carat-dark painting its own background, syntax on")
    # Scenario: Light theme. The line selects light_plus, whose Comment
    # color adapters_screen_presenter writes.
    t.assert_equal("light_plus", theme_of("option.theme light_plus\n").theme, "the theme line selects a palette")
    t.assert_equal("carat-light", theme_of("option.theme carat-light\n").theme, "Carat's light palette is accepted")
    unknown = D::Config.new
    unknown.read(".caratrc", "option.theme solarized\n", false)
    t.assert_equal(["carat-dark", [".caratrc:1: unknown theme solarized"]], [D::Options.from_config(unknown).theme, unknown.report], "Unknown theme: it keeps the default and is reported")
    t.assert_equal("carat-dark", theme_of("option.theme \"carat light\" x\n").theme, "a theme of the wrong kind keeps the default")
    t.assert_equal("theme", theme_of("option.background theme\n").background, "the background line paints the background")
    # Scenario: Unknown value. The background stays the default, theme.
    background = D::Config.new
    background.read(".caratrc", "option.background dark\n", false)
    t.assert_equal(["theme", [".caratrc:1: unknown background dark"]], [D::Options.from_config(background).background, background.report], "an unknown background keeps the default and is reported")
    shipped = D::Config.new
    shipped.read_defaults("config/default.caratrc", D::DEFAULT_CARATRC)
    t.assert_equal(["carat-dark", "theme"], [D::Options.from_config(shipped).theme, D::Options.from_config(shipped).background], "Default theme: the shipped configuration names carat-dark painting its own background")

    # The color depth from COLORTERM and TERM.
    t.cases([
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
