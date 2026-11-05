module Carat
  module Domain
    # Highlight group ids carried by frame cells; a theme maps each to its
    # colors. The editor's own UI groups come first, with Neovim's names,
    # the status bar's mode pills and slots after them; then the syntax
    # groups, from SYNTAX_FIRST on, with Neovim's standard
    # names in the order of its group-name help; then the file-icon groups,
    # from ICON_FIRST on, named as nvim-web-devicons names them. A plugin's
    # tokens may carry a syntax or a file-icon group. NAMES is indexed by
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

      SYNTAX_FIRST = 49
      COMMENT = 49
      CONSTANT = 50
      STRING = 51
      CHARACTER = 52
      NUMBER = 53
      BOOLEAN = 54
      FLOAT = 55
      IDENTIFIER = 56
      FUNCTION = 57
      STATEMENT = 58
      CONDITIONAL = 59
      REPEAT = 60
      LABEL = 61
      OPERATOR = 62
      KEYWORD = 63
      EXCEPTION = 64
      PRE_PROC = 65
      INCLUDE = 66
      DEFINE = 67
      MACRO = 68
      TYPE = 69
      STORAGE_CLASS = 70
      STRUCTURE = 71
      TYPEDEF = 72
      SPECIAL = 73
      SPECIAL_CHAR = 74
      DELIMITER = 75
      SPECIAL_COMMENT = 76
      TODO = 77
      ERROR = 78

      ICON_FIRST = 79
      ICON_DEFAULT = 79
      ICON_FOLDER = 80
      ICON_SYMLINK = 81
      ICON_RUBY = 82
      ICON_JSON = 83
      ICON_MARKDOWN = 84
      ICON_TOML = 85
      ICON_MAKEFILE = 86
      ICON_SHELL = 87
      ICON_C = 88
      ICON_YAML = 89
      ICON_GIT = 90
      ICON_LOCK = 91
      COUNT = 92

      # A cell on the cursor line carries its group's id plus this layer:
      # the group drawn over the CursorLine background, unless it has a
      # background of its own. Ids below LIMIT are the ones a frame cell
      # may carry.
      CURSOR_LINE_LAYER = COUNT
      LIMIT = COUNT * 2

      NAMES = [
        "Normal", "LineNr", "StatusLine", "ErrorMsg", "NonText", "StatusLineNC", "TabLine", "TabLineSel", "TabLineFill", "Visual", "SignColumn", "Search", "IncSearch",
        "CurSearch", "CursorLine", "CursorLineNr", "ColorColumn", "EndOfBuffer", "WinSeparator", "Directory", "Title", "WarningMsg", "ModeMsg", "MoreMsg", "Question", "MatchParen",
        "Pmenu", "PmenuSel", "PmenuSbar", "PmenuThumb", "NormalFloat", "FloatBorder", "DiffAdd", "DiffChange", "DiffDelete", "DiffText", "Whitespace",
        "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo", "DiagnosticHint",
        "StatusLineModeNormal", "StatusLineModeInsert", "StatusLineModeVisual", "StatusLineModeReplace", "StatusLineModeCommand",
        "StatusLineLspStarting", "StatusLineLspReady", "StatusLineLspError",
        "Comment", "Constant", "String", "Character", "Number", "Boolean", "Float", "Identifier", "Function",
        "Statement", "Conditional", "Repeat", "Label", "Operator", "Keyword", "Exception",
        "PreProc", "Include", "Define", "Macro",
        "Type", "StorageClass", "Structure", "Typedef",
        "Special", "SpecialChar", "Delimiter", "SpecialComment",
        "Todo", "Error",
        "DevIconDefault", "DevIconFolder", "DevIconSymlink", "DevIconRb", "DevIconJson", "DevIconMd", "DevIconToml", "DevIconMakefile", "DevIconSh", "DevIconC", "DevIconYml", "DevIconGitIgnore", "DevIconLock"
      ]

      # The id of the group a plugin token may carry, a syntax or a
      # file-icon group, with that name; -1 for a UI group or an unknown
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

      # Whether id is a group a plugin token may carry: a syntax or a
      # file-icon group.
      #: (Integer) -> bool
      def self.token?(id)
        id >= SYNTAX_FIRST && id < COUNT
      end

      # The name of the group with that id, "" for none.
      #: (Integer) -> String
      def self.name_of(id)
        return "" if id < 0 || id >= COUNT
        NAMES[id]
      end

      # The group of a cell's id, without the cursor-line layer.
      #: (Integer) -> Integer
      def self.base(id)
        id >= CURSOR_LINE_LAYER ? id - CURSOR_LINE_LAYER : id
      end
    end
  end
end
