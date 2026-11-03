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

      SYNTAX_FIRST = 11
      COMMENT = 11
      CONSTANT = 12
      STRING = 13
      CHARACTER = 14
      NUMBER = 15
      BOOLEAN = 16
      FLOAT = 17
      IDENTIFIER = 18
      FUNCTION = 19
      STATEMENT = 20
      CONDITIONAL = 21
      REPEAT = 22
      LABEL = 23
      OPERATOR = 24
      KEYWORD = 25
      EXCEPTION = 26
      PRE_PROC = 27
      INCLUDE = 28
      DEFINE = 29
      MACRO = 30
      TYPE = 31
      STORAGE_CLASS = 32
      STRUCTURE = 33
      TYPEDEF = 34
      SPECIAL = 35
      SPECIAL_CHAR = 36
      DELIMITER = 37
      SPECIAL_COMMENT = 38
      TODO = 39
      ERROR = 40
      COUNT = 41

      NAMES = [
        "Normal", "LineNr", "StatusLine", "ErrorMsg", "NonText", "StatusLineNC", "TabLine", "TabLineSel", "TabLineFill", "Visual", "SignColumn",
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
