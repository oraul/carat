module Carat
  module Domain
    # Highlight group ids carried by frame cells; a theme maps each to its
    # colors. The editor's own UI groups come first, with Neovim's names,
    # the status bar's mode pills and slots after them, then the indent
    # guides' two, then FloatTitle, then the popup menu's
    # match and extra groups, then Neovim's Added, Changed, and Removed,
    # which the git signs are drawn in, LineNrFifth, MsgDim, Folded, the
    # finder's selected row mark and label PmenuMarkSel and PmenuLabelSel,
    # and StatusLineDim; then the syntax
    # groups, from SYNTAX_FIRST on, with Neovim's standard
    # names in the order of its group-name help; then the file-icon groups,
    # from ICON_FIRST on, named as nvim-web-devicons names them; then the
    # documentation markup groups, from MARKUP_FIRST on, named as Neovim's
    # tree-sitter captures. A plugin's tokens may carry a syntax, a
    # file-icon, or a markup group. NAMES is indexed by
    # id. Ids are integers so a frame stays three integer
    # arrays and a theme a few arrays indexed by id.
    module Highlight
      NORMAL = 0
      LINE_NUMBER = 1
      STATUS = 2
      MESSAGE_ERROR = 3
      NON_TEXT = 4
      STATUS_NC = 5
      TAB_LINE = 6
      TAB_LINE_SELECTED = 7
      TAB_LINE_FILL = 8
      VISUAL = 9
      SIGN_COLUMN = 10
      SEARCH = 11
      INC_SEARCH = 12
      CURRENT_SEARCH = 13
      CURSOR_LINE = 14
      CURSOR_LINE_NUMBER = 15
      COLOR_COLUMN = 16
      END_OF_BUFFER = 17
      WINDOW_SEPARATOR = 18
      DIRECTORY = 19
      TITLE = 20
      MESSAGE_WARNING = 21
      MESSAGE_MODE = 22
      MESSAGE_MORE = 23
      QUESTION = 24
      MATCH_PAREN = 25
      POPUP_MENU = 26
      POPUP_MENU_SELECTED = 27
      POPUP_MENU_SCROLLBAR = 28
      POPUP_MENU_THUMB = 29
      NORMAL_FLOAT = 30
      FLOAT_BORDER = 31
      DIFF_ADD = 32
      DIFF_CHANGE = 33
      DIFF_DELETE = 34
      DIFF_TEXT = 35
      WHITESPACE = 36
      DIAGNOSTIC_ERROR = 37
      DIAGNOSTIC_WARN = 38
      DIAGNOSTIC_INFO = 39
      DIAGNOSTIC_HINT = 40
      STATUS_MODE_NORMAL = 41
      STATUS_MODE_INSERT = 42
      STATUS_MODE_VISUAL = 43
      STATUS_MODE_REPLACE = 44
      STATUS_MODE_COMMAND = 45
      STATUS_LSP_STARTING = 46
      STATUS_LSP_READY = 47
      STATUS_LSP_ERROR = 48
      STATUS_DIAGNOSTIC_ERROR = 49
      STATUS_DIAGNOSTIC_WARN = 50
      STATUS_DIAGNOSTIC_INFO = 51
      STATUS_DIAGNOSTIC_HINT = 52
      INDENT_GUIDE = 53
      INDENT_GUIDE_SCOPE = 54
      FLOAT_TITLE = 55
      POPUP_MENU_MATCH = 56
      POPUP_MENU_MATCH_SELECTED = 57
      POPUP_MENU_EXTRA = 58
      POPUP_MENU_EXTRA_SELECTED = 59
      ADDED = 60
      CHANGED = 61
      REMOVED = 62
      LINE_NUMBER_FIFTH = 63
      MESSAGE_DIM = 64
      FOLDED = 65
      POPUP_MENU_MARK_SELECTED = 66
      POPUP_MENU_LABEL_SELECTED = 67
      STATUS_DIM = 68

      SYNTAX_FIRST = 69
      COMMENT = 69
      CONSTANT = 70
      STRING = 71
      CHARACTER = 72
      NUMBER = 73
      BOOLEAN = 74
      FLOAT = 75
      IDENTIFIER = 76
      FUNCTION = 77
      STATEMENT = 78
      CONDITIONAL = 79
      REPEAT = 80
      LABEL = 81
      OPERATOR = 82
      KEYWORD = 83
      EXCEPTION = 84
      PRE_PROC = 85
      INCLUDE = 86
      DEFINE = 87
      MACRO = 88
      TYPE = 89
      STORAGE_CLASS = 90
      STRUCTURE = 91
      TYPEDEF = 92
      SPECIAL = 93
      SPECIAL_CHAR = 94
      DELIMITER = 95
      SPECIAL_COMMENT = 96
      TODO = 97
      ERROR = 98

      ICON_FIRST = 99
      ICON_DEFAULT = 99
      ICON_FOLDER = 100
      ICON_SYMLINK = 101
      ICON_RUBY = 102
      ICON_JSON = 103
      ICON_MARKDOWN = 104
      ICON_TOML = 105
      ICON_MAKEFILE = 106
      ICON_SHELL = 107
      ICON_C = 108
      ICON_YAML = 109
      ICON_GIT = 110
      ICON_LOCK = 111

      MARKUP_FIRST = 112
      MARKUP_HEADING = 112
      MARKUP_STRONG = 113
      MARKUP_ITALIC = 114
      MARKUP_RAW = 115
      MARKUP_LINK = 116
      MARKUP_RAW_BLOCK = 117
      COUNT = 118

      # A cell on the cursor line carries its group's id plus this layer:
      # the group drawn over the CursorLine background, unless it has a
      # background of its own. Ids below LIMIT are the ones a frame cell
      # may carry.
      CURSOR_LINE_LAYER = COUNT

      # A cell inside a float carries its group's id plus this layer: the
      # group drawn over NormalFloat's background, unless it has a
      # background of its own.
      FLOAT_LAYER = COUNT * 2
      LIMIT = COUNT * 3

      NAMES = [
        "Normal", "LineNr", "StatusLine", "ErrorMsg", "NonText", "StatusLineNC", "TabLine", "TabLineSel", "TabLineFill", "Visual", "SignColumn", "Search", "IncSearch",
        "CurSearch", "CursorLine", "CursorLineNr", "ColorColumn", "EndOfBuffer", "WinSeparator", "Directory", "Title", "WarningMsg", "ModeMsg", "MoreMsg", "Question", "MatchParen",
        "Pmenu", "PmenuSel", "PmenuSbar", "PmenuThumb", "NormalFloat", "FloatBorder", "DiffAdd", "DiffChange", "DiffDelete", "DiffText", "Whitespace",
        "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo", "DiagnosticHint",
        "StatusLineModeNormal", "StatusLineModeInsert", "StatusLineModeVisual", "StatusLineModeReplace", "StatusLineModeCommand",
        "StatusLineLspStarting", "StatusLineLspReady", "StatusLineLspError",
        "StatusLineDiagnosticError", "StatusLineDiagnosticWarn", "StatusLineDiagnosticInfo", "StatusLineDiagnosticHint",
        "IblIndent", "IblScope", "FloatTitle", "PmenuMatch", "PmenuMatchSel", "PmenuExtra", "PmenuExtraSel", "Added", "Changed", "Removed", "LineNrFifth", "MsgDim", "Folded", "PmenuMarkSel", "PmenuLabelSel", "StatusLineDim",
        "Comment", "Constant", "String", "Character", "Number", "Boolean", "Float", "Identifier", "Function",
        "Statement", "Conditional", "Repeat", "Label", "Operator", "Keyword", "Exception",
        "PreProc", "Include", "Define", "Macro",
        "Type", "StorageClass", "Structure", "Typedef",
        "Special", "SpecialChar", "Delimiter", "SpecialComment",
        "Todo", "Error",
        "DevIconDefault", "DevIconFolder", "DevIconSymlink", "DevIconRb", "DevIconJson", "DevIconMd", "DevIconToml", "DevIconMakefile", "DevIconSh", "DevIconC", "DevIconYml", "DevIconGitIgnore", "DevIconLock",
        "@markup.heading", "@markup.strong", "@markup.italic", "@markup.raw", "@markup.link.label", "@markup.raw.block"
      ]

      # The id of the group a plugin token may carry, a syntax, a
      # file-icon, or a markup group, with that name; -1 for a UI group or an unknown
      # name.
      #: (String) -> Integer
      def self.token_id(name)
        i = SYNTAX_FIRST
        while i < COUNT
          return i if NAMES[i] == name
          i += 1
        end
        -1
      end

      # Whether id is a group a plugin token may carry: a syntax, a
      # file-icon, or a markup group.
      #: (Integer) -> bool
      def self.token?(id)
        id >= SYNTAX_FIRST && id < COUNT
      end

      # The UI groups a plugin float's span may carry beside a token's.
      FLOAT_GROUPS = [POPUP_MENU_SELECTED, POPUP_MENU_MATCH, POPUP_MENU_MARK_SELECTED, POPUP_MENU_LABEL_SELECTED]
      private_constant :FLOAT_GROUPS

      # Whether id is a group a plugin float's span may carry: a token's
      # group or one of FLOAT_GROUPS (PmenuSel, PmenuMatch, PmenuMarkSel,
      # PmenuLabelSel); every other
      # UI group is refused.
      #: (Integer) -> bool
      def self.float_style?(id)
        return true if token?(id)
        i = 0
        while i < FLOAT_GROUPS.length
          return true if FLOAT_GROUPS[i] == id
          i += 1
        end
        false
      end

      # The id of the group a plugin float's span may carry with that
      # name, as float_style? admits; -1 for any other name.
      #: (String) -> Integer
      def self.float_style_id(name)
        i = 0
        while i < FLOAT_GROUPS.length
          id = FLOAT_GROUPS[i]
          return id if name == NAMES[id]
          i += 1
        end
        token_id(name)
      end

      # The name of the group with that id, "" for none.
      #: (Integer) -> String
      def self.name_of(id)
        return "" if id < 0 || id >= COUNT
        NAMES[id]
      end

      # The group of a cell's id, without the cursor-line or float layer.
      #: (Integer) -> Integer
      def self.base(id)
        return id - FLOAT_LAYER if id >= FLOAT_LAYER
        id >= CURSOR_LINE_LAYER ? id - CURSOR_LINE_LAYER : id
      end

      # The group a sign placed with the icon name is drawn in: the
      # diagnostic icons in their Diagnostic groups, as Neovim's
      # DiagnosticSign groups link to them, the git icons in Added,
      # Changed, and Removed, as gitsigns links its own; SignColumn for
      # any other icon.
      #: (String) -> Integer
      def self.sign_group(icon)
        return DIAGNOSTIC_ERROR if icon == "error"
        return DIAGNOSTIC_WARN if icon == "warning"
        return DIAGNOSTIC_INFO if icon == "info"
        return DIAGNOSTIC_HINT if icon == "hint"
        return ADDED if icon == "git_added"
        return CHANGED if icon == "git_changed"
        return REMOVED if icon == "git_deleted"
        SIGN_COLUMN
      end

      # The group a diagnostic sign of the severity (1 error to 4 hint)
      # is drawn in, DiagnosticError to DiagnosticHint; a severity outside
      # 1 to 3 is drawn as a hint.
      #: (Integer) -> Integer
      def self.diagnostic_group(severity)
        return DIAGNOSTIC_HINT if severity < 1 || severity > 3
        DIAGNOSTIC_ERROR + severity - 1
      end
    end
  end
end
