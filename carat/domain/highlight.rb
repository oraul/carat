module Carat
  module Domain
    # Highlight group ids carried by frame cells; a theme maps each to its
    # colors. The editor's own groups come first, then the syntax groups a
    # tokenizer may give its tokens, from SYNTAX_FIRST on, with Neovim's
    # standard names in the order of its group-name help. NAMES is
    # indexed by id. Ids are integers so a frame stays three integer
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

      SYNTAX_FIRST = 13
      COMMENT = 13
      CONSTANT = 14
      STRING = 15
      CHARACTER = 16
      NUMBER = 17
      BOOLEAN = 18
      FLOAT = 19
      IDENTIFIER = 20
      FUNCTION = 21
      STATEMENT = 22
      CONDITIONAL = 23
      REPEAT = 24
      LABEL = 25
      OPERATOR = 26
      KEYWORD = 27
      EXCEPTION = 28
      PRE_PROC = 29
      INCLUDE = 30
      DEFINE = 31
      MACRO = 32
      TYPE = 33
      STORAGE_CLASS = 34
      STRUCTURE = 35
      TYPEDEF = 36
      SPECIAL = 37
      SPECIAL_CHAR = 38
      DELIMITER = 39
      SPECIAL_COMMENT = 40
      TODO = 41
      ERROR = 42
      COUNT = 43

      NAMES = [
        "Normal", "LineNr", "StatusLine", "ErrorMsg", "NonText", "StatusLineNC", "TabLine", "TabLineSel", "TabLineFill", "Visual", "SignColumn", "Search", "IncSearch",
        "Comment", "Constant", "String", "Character", "Number", "Boolean", "Float", "Identifier", "Function",
        "Statement", "Conditional", "Repeat", "Label", "Operator", "Keyword", "Exception",
        "PreProc", "Include", "Define", "Macro",
        "Type", "StorageClass", "Structure", "Typedef",
        "Special", "SpecialChar", "Delimiter", "SpecialComment",
        "Todo", "Error"
      ]

      # The id of the syntax group with that name, -1 for an editor group
      # or an unknown name.
      #: (String) -> Integer
      def self.syntax_id(name)
        i = SYNTAX_FIRST
        while i < COUNT
          return i if NAMES[i] == name
          i += 1
        end
        -1
      end

      # Whether id is a syntax group, one a token may carry.
      #: (Integer) -> bool
      def self.syntax?(id)
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
