module Carat
  module Plugins
    module Ruby
      # The highlight groups the Ruby tokenizer uses, by its own index;
      # NAMES are the editor's group names, which the plugin resolves to
      # ids through the host once, when it is activated.
      module Groups
        COMMENT = 0
        CONSTANT = 1
        STRING = 2
        CHARACTER = 3
        NUMBER = 4
        FLOAT = 5
        BOOLEAN = 6
        IDENTIFIER = 7
        FUNCTION = 8
        STATEMENT = 9
        CONDITIONAL = 10
        REPEAT = 11
        OPERATOR = 12
        KEYWORD = 13
        EXCEPTION = 14
        INCLUDE = 15
        DEFINE = 16
        MACRO = 17
        TYPE = 18
        STRUCTURE = 19
        SPECIAL_CHAR = 20
        DELIMITER = 21
        TODO = 22

        NAMES = [
          "Comment", "Constant", "String", "Character", "Number", "Float", "Boolean", "Identifier", "Function",
          "Statement", "Conditional", "Repeat", "Operator", "Keyword", "Exception", "Include", "Define", "Macro",
          "Type", "Structure", "SpecialChar", "Delimiter", "Todo"
        ]
      end
    end
  end
end
