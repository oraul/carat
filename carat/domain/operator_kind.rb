module Carat
  module Domain
    # The action names of the pending operators: the five edits and the
    # three case changes g~ gu gU, whose handlers the action table
    # registers under them, the command grammar holding one in a command's
    # operator and the standalone edits x s S C D Y naming one for their
    # fixed operand, and zf, which makes a fold of the lines its motion
    # covers.
    module OperatorKind
      DELETE = "operator.delete"
      CHANGE = "operator.change"
      YANK = "operator.yank"
      INDENT = "operator.indent"
      DEDENT = "operator.dedent"
      SWAP_CASE = "operator.swap_case"
      LOWERCASE = "operator.lowercase"
      UPPERCASE = "operator.uppercase"
      COMMENT = "operator.comment"
      FOLD = "fold.create"
    end
  end
end
