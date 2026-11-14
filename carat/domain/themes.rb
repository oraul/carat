require_relative "highlight"
require_relative "theme"

module Carat
  module Domain
    # The palettes Carat ships, chosen by the option.theme line: one_dark,
    # the default, and dark_plus for a dark terminal, one_light and
    # light_plus for a light one, with carat-dark and carat-light kept as
    # aliases of the One palettes. A palette is a color per role: rows of
    # the role, its 24-bit color, its 256-color index (-1 for the nearest
    # one, given only where the nearest would lose contrast or hue), and
    # its index among the 16 basic colors (-1 for none), given by hand as
    # Vim themes give ctermfg. GROUPS says which role colors each group, the
    # same for every palette, with the group's attributes and its
    # attributes at 16 colors, so each palette's own colors, its syntax
    # colors included, reach every group. The background option decides
    # who paints the background: "terminal" leaves Normal and the
    # palette's text color to the terminal, "theme" paints them under
    # every cell. Every text group meets WCAG AA contrast on the
    # palette's background, which test/domain_theme.rb checks. They are
    # Ruby rather than configuration lines because the configuration only
    # names one; user themes are in the backlog.
    module Themes
      DEFAULT = "one_dark"
      NAMES = ["one_dark", "one_light", "dark_plus", "light_plus"]
      ALIASES = { "carat-dark" => "one_dark", "carat-light" => "one_light" }
      BACKGROUNDS = ["terminal", "theme"]

      # The color roles of a palette.
      BG = 0
      FG = 1
      DIM = 2
      FAINT = 3
      PANEL = 4
      PANEL_FG = 5
      PANEL_NC = 6
      FLOAT = 7
      SELECTION = 8
      CURSOR_LINE = 9
      SEARCH = 10
      INC_SEARCH = 11
      ON_ACCENT = 12
      RED = 13
      ORANGE = 14
      YELLOW = 15
      GREEN = 16
      CYAN = 17
      BLUE = 18
      PURPLE = 19
      DIFF_ADD = 20
      DIFF_CHANGE = 21
      DIFF_DELETE = 22
      DIFF_TEXT = 23
      COMMENT = 24
      KEYWORD = 25
      CONTROL = 26
      FUNCTION = 27
      TYPE = 28
      STRING = 29
      NUMBER = 30
      CONSTANT = 31
      OPERATOR = 32
      PREPROC = 33
      SPECIAL = 34
      IDENTIFIER = 35
      ESCAPE = 36
      # Text on a strong accent, the mode pills': the palette's background
      # color, kept when the terminal paints its own background.
      ON_STRONG = 37
      ROLES = 38
      NONE = -1

      BOLD = Theme::BOLD
      ITALIC = Theme::ITALIC
      UNDERLINE = Theme::UNDERLINE
      REVERSE = Theme::REVERSE

      # Rows of a group id, its foreground role, its background role
      # (NONE for the terminal's own, or the palette's with the theme's
      # background), its attributes, and its attributes at 16 colors.
      GROUPS = [
        Highlight::NORMAL, FG, BG, 0, 0,
        Highlight::LINE_NUMBER, DIM, NONE, 0, 0,
        Highlight::STATUS, PANEL_FG, PANEL, BOLD, BOLD,
        Highlight::MESSAGE_ERROR, RED, NONE, BOLD, BOLD,
        Highlight::NON_TEXT, FAINT, NONE, 0, 0,
        Highlight::STATUS_NC, DIM, PANEL_NC, 0, 0,
        Highlight::TAB_LINE, DIM, PANEL_NC, 0, 0,
        Highlight::TAB_LINE_SELECTED, FG, NONE, BOLD, BOLD,
        Highlight::TAB_LINE_FILL, NONE, PANEL_NC, 0, 0,
        Highlight::VISUAL, NONE, SELECTION, 0, REVERSE,
        Highlight::SIGN_COLUMN, YELLOW, NONE, 0, 0,
        Highlight::SEARCH, ON_ACCENT, SEARCH, 0, 0,
        Highlight::INC_SEARCH, ON_ACCENT, INC_SEARCH, BOLD, BOLD,
        Highlight::CURRENT_SEARCH, ON_ACCENT, INC_SEARCH, BOLD, BOLD,
        Highlight::CURSOR_LINE, NONE, CURSOR_LINE, 0, UNDERLINE,
        Highlight::CURSOR_LINE_NUMBER, FG, NONE, BOLD, BOLD,
        Highlight::COLOR_COLUMN, NONE, CURSOR_LINE, 0, REVERSE,
        Highlight::END_OF_BUFFER, FAINT, NONE, 0, 0,
        Highlight::WINDOW_SEPARATOR, FAINT, NONE, 0, 0,
        Highlight::DIRECTORY, BLUE, NONE, 0, 0,
        Highlight::TITLE, BLUE, NONE, BOLD, BOLD,
        Highlight::MESSAGE_WARNING, YELLOW, NONE, BOLD, BOLD,
        Highlight::MESSAGE_MODE, FG, NONE, BOLD, BOLD,
        Highlight::MESSAGE_MORE, GREEN, NONE, BOLD, BOLD,
        Highlight::QUESTION, GREEN, NONE, 0, 0,
        Highlight::MATCH_PAREN, NONE, SELECTION, BOLD, BOLD | UNDERLINE,
        Highlight::POPUP_MENU, FG, FLOAT, 0, 0,
        Highlight::POPUP_MENU_SELECTED, FG, SELECTION, 0, REVERSE,
        Highlight::POPUP_MENU_SCROLLBAR, NONE, FLOAT, 0, 0,
        Highlight::POPUP_MENU_THUMB, NONE, FAINT, 0, REVERSE,
        Highlight::NORMAL_FLOAT, FG, FLOAT, 0, 0,
        Highlight::FLOAT_BORDER, FAINT, FLOAT, 0, 0,
        Highlight::DIFF_ADD, NONE, DIFF_ADD, 0, 0,
        Highlight::DIFF_CHANGE, NONE, DIFF_CHANGE, 0, 0,
        Highlight::DIFF_DELETE, RED, DIFF_DELETE, 0, 0,
        Highlight::DIFF_TEXT, NONE, DIFF_TEXT, BOLD, BOLD,
        Highlight::WHITESPACE, FAINT, NONE, 0, 0,
        Highlight::DIAGNOSTIC_ERROR, RED, NONE, 0, 0,
        Highlight::DIAGNOSTIC_WARN, YELLOW, NONE, 0, 0,
        Highlight::DIAGNOSTIC_INFO, BLUE, NONE, 0, 0,
        Highlight::DIAGNOSTIC_HINT, CYAN, NONE, 0, 0,
        Highlight::STATUS_MODE_NORMAL, ON_STRONG, BLUE, BOLD, BOLD,
        Highlight::STATUS_MODE_INSERT, ON_STRONG, GREEN, BOLD, BOLD,
        Highlight::STATUS_MODE_VISUAL, ON_STRONG, PURPLE, BOLD, BOLD,
        Highlight::STATUS_MODE_REPLACE, ON_STRONG, RED, BOLD, BOLD,
        Highlight::STATUS_MODE_COMMAND, ON_STRONG, YELLOW, BOLD, BOLD,
        Highlight::STATUS_LSP_STARTING, YELLOW, NONE, 0, 0,
        Highlight::STATUS_LSP_READY, GREEN, NONE, 0, 0,
        Highlight::STATUS_LSP_ERROR, RED, NONE, BOLD, BOLD,
        Highlight::INDENT_GUIDE, FAINT, NONE, 0, 0,
        Highlight::INDENT_GUIDE_SCOPE, DIM, NONE, 0, 0,
        Highlight::FLOAT_TITLE, BLUE, FLOAT, BOLD, BOLD,
        Highlight::POPUP_MENU_MATCH, BLUE, FLOAT, BOLD, BOLD,
        Highlight::POPUP_MENU_MATCH_SELECTED, FG, SELECTION, BOLD | UNDERLINE, REVERSE | BOLD | UNDERLINE,
        Highlight::POPUP_MENU_EXTRA, DIM, FLOAT, 0, 0,
        Highlight::POPUP_MENU_EXTRA_SELECTED, FG, SELECTION, 0, REVERSE,
        Highlight::COMMENT, COMMENT, NONE, ITALIC, ITALIC,
        Highlight::CONSTANT, CONSTANT, NONE, 0, 0,
        Highlight::STRING, STRING, NONE, 0, 0,
        Highlight::CHARACTER, STRING, NONE, 0, 0,
        Highlight::NUMBER, NUMBER, NONE, 0, 0,
        Highlight::BOOLEAN, CONSTANT, NONE, 0, 0,
        Highlight::FLOAT, NUMBER, NONE, 0, 0,
        Highlight::IDENTIFIER, IDENTIFIER, NONE, 0, 0,
        Highlight::FUNCTION, FUNCTION, NONE, 0, 0,
        Highlight::STATEMENT, KEYWORD, NONE, 0, 0,
        Highlight::CONDITIONAL, CONTROL, NONE, 0, 0,
        Highlight::REPEAT, CONTROL, NONE, 0, 0,
        Highlight::LABEL, KEYWORD, NONE, 0, 0,
        Highlight::OPERATOR, OPERATOR, NONE, 0, 0,
        Highlight::KEYWORD, KEYWORD, NONE, 0, 0,
        Highlight::EXCEPTION, CONTROL, NONE, 0, 0,
        Highlight::PRE_PROC, PREPROC, NONE, 0, 0,
        Highlight::INCLUDE, PREPROC, NONE, 0, 0,
        Highlight::DEFINE, KEYWORD, NONE, 0, 0,
        Highlight::MACRO, PREPROC, NONE, 0, 0,
        Highlight::TYPE, TYPE, NONE, 0, 0,
        Highlight::STORAGE_CLASS, KEYWORD, NONE, 0, 0,
        Highlight::STRUCTURE, KEYWORD, NONE, 0, 0,
        Highlight::TYPEDEF, TYPE, NONE, 0, 0,
        Highlight::SPECIAL, SPECIAL, NONE, 0, 0,
        Highlight::SPECIAL_CHAR, ESCAPE, NONE, 0, 0,
        Highlight::DELIMITER, FG, NONE, 0, 0,
        Highlight::SPECIAL_COMMENT, COMMENT, NONE, ITALIC, ITALIC,
        Highlight::TODO, ON_ACCENT, SEARCH, BOLD, BOLD,
        Highlight::ERROR, RED, NONE, UNDERLINE, UNDERLINE,
        Highlight::ICON_DEFAULT, DIM, NONE, 0, 0,
        Highlight::ICON_FOLDER, BLUE, NONE, 0, 0,
        Highlight::ICON_SYMLINK, CYAN, NONE, 0, 0,
        Highlight::ICON_RUBY, RED, NONE, 0, 0,
        Highlight::ICON_JSON, YELLOW, NONE, 0, 0,
        Highlight::ICON_MARKDOWN, BLUE, NONE, 0, 0,
        Highlight::ICON_TOML, ORANGE, NONE, 0, 0,
        Highlight::ICON_MAKEFILE, ORANGE, NONE, 0, 0,
        Highlight::ICON_SHELL, GREEN, NONE, 0, 0,
        Highlight::ICON_C, BLUE, NONE, 0, 0,
        Highlight::ICON_YAML, PURPLE, NONE, 0, 0,
        Highlight::ICON_GIT, ORANGE, NONE, 0, 0,
        Highlight::ICON_LOCK, DIM, NONE, 0, 0,
        Highlight::MARKUP_HEADING, BLUE, NONE, BOLD, BOLD,
        Highlight::MARKUP_STRONG, FG, NONE, BOLD, BOLD,
        Highlight::MARKUP_ITALIC, FG, NONE, ITALIC, ITALIC,
        Highlight::MARKUP_RAW, STRING, NONE, 0, 0,
        Highlight::MARKUP_LINK, CYAN, NONE, UNDERLINE, UNDERLINE,
        Highlight::MARKUP_RAW_BLOCK, DIM, NONE, 0, 0
      ]

      # Atom's One Dark, its grays, red, and comments a step lighter for
      # contrast.
      ONE_DARK = [
        BG, 0x282c34, -1, 0,
        FG, 0xabb2bf, -1, 7,
        DIM, 0x959ca8, -1, 8,
        FAINT, 0x737a8a, -1, 8,
        PANEL, 0x3e4452, -1, 7,
        PANEL_FG, 0xd7dae0, -1, 0,
        PANEL_NC, 0x21252b, -1, 7,
        FLOAT, 0x21252b, -1, 0,
        SELECTION, 0x3e4452, -1, -1,
        CURSOR_LINE, 0x2c313c, -1, -1,
        SEARCH, 0xe5c07b, -1, 11,
        INC_SEARCH, 0xd19a66, -1, 9,
        ON_ACCENT, 0x282c34, -1, 0,
        ON_STRONG, 0x282c34, -1, 0,
        RED, 0xe8757e, -1, 9,
        ORANGE, 0xd19a66, -1, 11,
        YELLOW, 0xe5c07b, -1, 11,
        GREEN, 0x98c379, -1, 10,
        CYAN, 0x56b6c2, -1, 14,
        BLUE, 0x61afef, -1, 12,
        PURPLE, 0xc678dd, -1, 13,
        DIFF_ADD, 0x2f3b2e, -1, 2,
        DIFF_CHANGE, 0x2c3445, -1, 4,
        DIFF_DELETE, 0x3a2a2e, -1, 1,
        DIFF_TEXT, 0x34405a, 17, 6,
        COMMENT, 0x959ca8, -1, 8,
        KEYWORD, 0xc678dd, -1, 13,
        CONTROL, 0xc678dd, -1, 13,
        FUNCTION, 0x61afef, -1, 12,
        TYPE, 0xe5c07b, -1, 11,
        STRING, 0x98c379, -1, 10,
        NUMBER, 0xd19a66, -1, 11,
        CONSTANT, 0xd19a66, -1, 11,
        OPERATOR, 0x56b6c2, -1, 14,
        PREPROC, 0xc678dd, -1, 13,
        SPECIAL, 0x61afef, -1, 12,
        IDENTIFIER, 0xe8757e, -1, 9,
        ESCAPE, 0x56b6c2, -1, 14
      ]

      # Atom's One Light, its yellow, orange, green, cyan, and blue a step
      # darker for contrast, on its float background too.
      ONE_LIGHT = [
        BG, 0xfafafa, -1, 15,
        FG, 0x383a42, -1, 0,
        DIM, 0x696c77, -1, 8,
        FAINT, 0x84868e, -1, 8,
        PANEL, 0xe5e5e6, -1, 7,
        PANEL_FG, 0x383a42, -1, 0,
        PANEL_NC, 0xf0f0f1, -1, 7,
        FLOAT, 0xf0f0f1, -1, 7,
        SELECTION, 0xe5e5e6, -1, -1,
        CURSOR_LINE, 0xf0f0f1, -1, -1,
        SEARCH, 0xf2dc96, -1, 11,
        INC_SEARCH, 0xeeb36c, -1, 9,
        ON_ACCENT, 0x383a42, -1, 0,
        ON_STRONG, 0xfafafa, -1, 15,
        RED, 0xca1243, 125, 1,
        ORANGE, 0x986801, -1, 3,
        YELLOW, 0x8a6300, -1, 3,
        GREEN, 0x3c7a3b, 28, 2,
        CYAN, 0x0e7490, 24, 6,
        BLUE, 0x2f63d6, -1, 4,
        PURPLE, 0xa626a4, -1, 5,
        DIFF_ADD, 0xe2f2e1, 194, 10,
        DIFF_CHANGE, 0xe4ecfb, 189, 14,
        DIFF_DELETE, 0xfdeeee, 224, 9,
        DIFF_TEXT, 0xc8d8f8, -1, 12,
        COMMENT, 0x696c77, -1, 8,
        KEYWORD, 0xa626a4, -1, 5,
        CONTROL, 0xa626a4, -1, 5,
        FUNCTION, 0x2f63d6, -1, 4,
        TYPE, 0x8a6300, -1, 3,
        STRING, 0x3c7a3b, 22, 2,
        NUMBER, 0x926401, -1, 3,
        CONSTANT, 0x926401, -1, 3,
        OPERATOR, 0x0e7490, 24, 6,
        PREPROC, 0xa626a4, -1, 5,
        SPECIAL, 0x2f63d6, -1, 4,
        IDENTIFIER, 0xc0392b, 124, 1,
        ESCAPE, 0x0e7490, 24, 6
      ]

      # Visual Studio Code's Dark+, its status bar a step darker and its red
      # a step lighter for contrast.
      DARK_PLUS = [
        BG, 0x1e1e1e, -1, 0,
        FG, 0xd4d4d4, -1, 7,
        DIM, 0x8f8f8f, -1, 8,
        FAINT, 0x737373, -1, 8,
        PANEL, 0x0068ad, -1, 4,
        PANEL_FG, 0xffffff, -1, 15,
        PANEL_NC, 0x252526, -1, 7,
        FLOAT, 0x252526, -1, 0,
        SELECTION, 0x264f78, -1, -1,
        CURSOR_LINE, 0x2a2a2a, -1, -1,
        SEARCH, 0x613214, -1, 3,
        INC_SEARCH, 0x9e5a0a, -1, 1,
        ON_ACCENT, 0xffffff, -1, 15,
        ON_STRONG, 0x1e1e1e, -1, 0,
        RED, 0xf55252, -1, 9,
        ORANGE, 0xce9178, -1, 11,
        YELLOW, 0xcca700, -1, 11,
        GREEN, 0x89d185, -1, 10,
        CYAN, 0x4ec9b0, -1, 14,
        BLUE, 0x569cd6, -1, 12,
        PURPLE, 0xc586c0, -1, 13,
        DIFF_ADD, 0x373d29, -1, 2,
        DIFF_CHANGE, 0x24364b, 17, 4,
        DIFF_DELETE, 0x3c1212, 52, 1,
        DIFF_TEXT, 0x1f4a6f, -1, 6,
        COMMENT, 0x6a9955, 71, 2,
        KEYWORD, 0x569cd6, -1, 12,
        CONTROL, 0xc586c0, -1, 13,
        FUNCTION, 0xdcdcaa, -1, 11,
        TYPE, 0x4ec9b0, -1, 14,
        STRING, 0xce9178, -1, 3,
        NUMBER, 0xb5cea8, -1, 10,
        CONSTANT, 0x4fc1ff, -1, 12,
        OPERATOR, 0xd4d4d4, -1, 7,
        PREPROC, 0xc586c0, -1, 13,
        SPECIAL, 0xd7ba7d, -1, 11,
        IDENTIFIER, 0x9cdcfe, -1, 14,
        ESCAPE, 0xd7ba7d, -1, 11
      ]

      # Visual Studio Code's Light+, its status bar, red, numbers, and types
      # a step darker for contrast, on its float background too.
      LIGHT_PLUS = [
        BG, 0xffffff, -1, 15,
        FG, 0x000000, -1, 0,
        DIM, 0x1f6b82, -1, 8,
        FAINT, 0x858585, -1, 8,
        PANEL, 0x0068ad, -1, 4,
        PANEL_FG, 0xffffff, -1, 15,
        PANEL_NC, 0xf3f3f3, -1, 7,
        FLOAT, 0xf3f3f3, -1, 7,
        SELECTION, 0xadd6ff, -1, -1,
        CURSOR_LINE, 0xf3f3f3, -1, -1,
        SEARCH, 0xf8c9ab, -1, 11,
        INC_SEARCH, 0xf5a970, -1, 9,
        ON_ACCENT, 0x000000, -1, 0,
        ON_STRONG, 0xffffff, -1, 15,
        RED, 0xb52a2a, -1, 1,
        ORANGE, 0xa31515, -1, 3,
        YELLOW, 0x8a6400, -1, 3,
        GREEN, 0x008000, -1, 2,
        CYAN, 0x247790, 24, 6,
        BLUE, 0x0000ff, -1, 4,
        PURPLE, 0xaf00db, -1, 5,
        DIFF_ADD, 0xdff3d0, -1, 10,
        DIFF_CHANGE, 0xdde7f7, -1, 14,
        DIFF_DELETE, 0xfce4e4, -1, 9,
        DIFF_TEXT, 0xb8cff0, -1, 12,
        COMMENT, 0x008000, 22, 2,
        KEYWORD, 0x0000ff, -1, 4,
        CONTROL, 0xaf00db, -1, 5,
        FUNCTION, 0x795e26, -1, 3,
        TYPE, 0x247790, 24, 6,
        STRING, 0xa31515, -1, 1,
        NUMBER, 0x097f54, 23, 2,
        CONSTANT, 0x0070c1, -1, 4,
        OPERATOR, 0x000000, -1, 0,
        PREPROC, 0xaf00db, -1, 5,
        SPECIAL, 0x811f3f, -1, 1,
        IDENTIFIER, 0x001080, -1, 4,
        ESCAPE, 0xc10000, -1, 1
      ]
      # Whether a name selects a palette, an alias included.
      #: (String) -> bool
      def self.known?(name)
        NAMES.include?(name) || ALIASES.key?(name)
      end

      #: (String) -> bool
      def self.background?(word)
        BACKGROUNDS.include?(word)
      end

      # The palette's name for a name or an alias, the default for an
      # unknown one.
      #: (String) -> String
      def self.canonical(name)
        aliased = ALIASES[name]
        return aliased unless aliased.nil?
        return name if NAMES.include?(name)
        DEFAULT
      end

      # The theme of a palette, by name or alias, for a background:
      # "theme" paints the palette's background and text color, any
      # other leaves them to the terminal. An unknown name is one_dark.
      #: (String, String) -> Theme
      def self.find(name, background)
        key = canonical(name)
        from_palette(key, palette(key), background == "theme")
      end

      #: (String) -> Array[Integer]
      def self.palette(key)
        return ONE_LIGHT if key == "one_light"
        return DARK_PLUS if key == "dark_plus"
        return LIGHT_PLUS if key == "light_plus"
        ONE_DARK
      end

      # Resolves every group's roles against a palette. Without a painted
      # background the roles BG and FG are the terminal's own; with it a
      # group's missing foreground or background is the palette's. Each
      # group's cursor-line id takes its foreground and attributes and,
      # unless the group has a background of its own, the CursorLine
      # background, or at 16 colors CursorLine's attributes. Each group's
      # float id takes its foreground, NormalFloat's when it has none, its
      # attributes, and, unless it has a background of its own,
      # NormalFloat's background at every depth.
      #: (String, Array[Integer], bool) -> Theme
      def self.from_palette(name, palette, painted)
        rgbs = Array.new(ROLES, -1)
        indexes256 = Array.new(ROLES, -1)
        indexes16 = Array.new(ROLES, -1)
        i = 0
        while i + 3 < palette.length
          role = palette[i]
          rgbs[role] = palette[i + 1]
          indexes256[role] = palette[i + 2]
          indexes16[role] = palette[i + 3]
          i += 4
        end
        unless painted
          rgbs[BG] = -1
          rgbs[FG] = -1
          indexes16[BG] = -1
          indexes16[FG] = -1
        end
        fgs = Array.new(Highlight::LIMIT, -1)
        bgs = Array.new(Highlight::LIMIT, -1)
        fgs256 = Array.new(Highlight::LIMIT, -1)
        bgs256 = Array.new(Highlight::LIMIT, -1)
        fgs16 = Array.new(Highlight::LIMIT, -1)
        bgs16 = Array.new(Highlight::LIMIT, -1)
        attrs = Array.new(Highlight::LIMIT, 0)
        attrs16 = Array.new(Highlight::LIMIT, 0)
        i = 0
        while i + 4 < GROUPS.length
          id = GROUPS[i]
          fg = GROUPS[i + 1]
          bg = GROUPS[i + 2]
          fg = FG if fg < 0 && painted
          bg = BG if bg < 0 && painted
          if fg >= 0
            fgs[id] = rgbs[fg]
            fgs256[id] = indexes256[fg]
            fgs16[id] = indexes16[fg]
          end
          if bg >= 0
            bgs[id] = rgbs[bg]
            bgs256[id] = indexes256[bg]
            bgs16[id] = indexes16[bg]
          end
          attrs[id] = GROUPS[i + 3]
          attrs16[id] = GROUPS[i + 4]
          i += 5
        end
        line16 = attrs16[Highlight::CURSOR_LINE]
        # No palette has a 16-color CursorLine background, which the
        # underline stands in for: a group without its own background
        # keeps the one it has off the line, the painted Normal's included.
        lit16 = indexes16[CURSOR_LINE]
        i = 0
        while i + 4 < GROUPS.length
          id = GROUPS[i]
          lit = id + Highlight::CURSOR_LINE_LAYER
          fgs[lit] = fgs[id]
          fgs256[lit] = fgs256[id]
          fgs16[lit] = fgs16[id]
          attrs[lit] = attrs[id]
          own = GROUPS[i + 2] >= 0 && GROUPS[i + 2] != BG
          bgs[lit] = own ? bgs[id] : rgbs[CURSOR_LINE]
          bgs256[lit] = own ? bgs256[id] : indexes256[CURSOR_LINE]
          bgs16[lit] = own || lit16 < 0 ? bgs16[id] : lit16
          attrs16[lit] = own ? attrs16[id] : attrs16[id] | line16
          i += 5
        end
        float = Highlight::NORMAL_FLOAT
        i = 0
        while i + 4 < GROUPS.length
          id = GROUPS[i]
          inside = id + Highlight::FLOAT_LAYER
          has_fg = GROUPS[i + 1] >= 0 && GROUPS[i + 1] != FG
          fgs[inside] = has_fg ? fgs[id] : fgs[float]
          fgs256[inside] = has_fg ? fgs256[id] : fgs256[float]
          fgs16[inside] = has_fg ? fgs16[id] : fgs16[float]
          own = GROUPS[i + 2] >= 0 && GROUPS[i + 2] != BG
          bgs[inside] = own ? bgs[id] : bgs[float]
          bgs256[inside] = own ? bgs256[id] : bgs256[float]
          bgs16[inside] = own ? bgs16[id] : bgs16[float]
          attrs[inside] = attrs[id]
          attrs16[inside] = attrs16[id]
          i += 5
        end
        Theme.new(name: name, fgs: fgs, bgs: bgs, fgs256: fgs256, bgs256: bgs256, fgs16: fgs16, bgs16: bgs16, attrs: attrs, attrs16: attrs16)
      end
    end
  end
end
