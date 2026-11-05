module Carat
  module Domain
    # Highlight group ids carried by frame cells; a theme maps each to its
    # colors. The editor's own UI groups come first, with Neovim's names;
    # then the syntax groups, from SYNTAX_FIRST on, with Neovim's standard
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

      SYNTAX_FIRST = 41
      COMMENT = 41
      CONSTANT = 42
      STRING = 43
      CHARACTER = 44
      NUMBER = 45
      BOOLEAN = 46
      FLOAT = 47
      IDENTIFIER = 48
      FUNCTION = 49
      STATEMENT = 50
      CONDITIONAL = 51
      REPEAT = 52
      LABEL = 53
      OPERATOR = 54
      KEYWORD = 55
      EXCEPTION = 56
      PRE_PROC = 57
      INCLUDE = 58
      DEFINE = 59
      MACRO = 60
      TYPE = 61
      STORAGE_CLASS = 62
      STRUCTURE = 63
      TYPEDEF = 64
      SPECIAL = 65
      SPECIAL_CHAR = 66
      DELIMITER = 67
      SPECIAL_COMMENT = 68
      TODO = 69
      ERROR = 70

      ICON_FIRST = 71
      ICON_DEFAULT = 71
      ICON_FOLDER = 72
      ICON_SYMLINK = 73
      ICON_RUBY = 74
      ICON_JSON = 75
      ICON_MARKDOWN = 76
      ICON_TOML = 77
      ICON_MAKEFILE = 78
      ICON_SHELL = 79
      ICON_C = 80
      ICON_YAML = 81
      ICON_GIT = 82
      ICON_LOCK = 83
      COUNT = 84

      NAMES = [
        "Normal", "LineNr", "StatusLine", "ErrorMsg", "NonText", "StatusLineNC", "TabLine", "TabLineSel", "TabLineFill", "Visual", "SignColumn", "Search", "IncSearch",
        "CurSearch", "CursorLine", "CursorLineNr", "ColorColumn", "EndOfBuffer", "WinSeparator", "Directory", "Title", "WarningMsg", "ModeMsg", "MoreMsg", "Question", "MatchParen",
        "Pmenu", "PmenuSel", "PmenuSbar", "PmenuThumb", "NormalFloat", "FloatBorder", "DiffAdd", "DiffChange", "DiffDelete", "DiffText", "Whitespace",
        "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo", "DiagnosticHint",
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
    end
  end
end
