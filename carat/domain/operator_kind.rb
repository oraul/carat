module Carat
  module Domain
    # The action names of the five pending operators: the action table
    # registers their handlers under them, the command grammar holds one
    # in a command's operator, and the standalone edits x s S C D Y name
    # one for their fixed operand.
    module OperatorKind
      DELETE = "operator.delete"
      CHANGE = "operator.change"
      YANK = "operator.yank"
      INDENT = "operator.indent"
      DEDENT = "operator.dedent"
    end
  end
end
