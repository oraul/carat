module Carat
  module Domain
    # The action names of the pending operators: the five edits, whose
    # handlers the action table registers under them, the command grammar
    # holding one in a command's operator and the standalone edits x s S
    # C D Y naming one for their fixed operand, and zf, which makes a fold
    # of the lines its motion covers.
    module OperatorKind
      DELETE = "operator.delete"
      CHANGE = "operator.change"
      YANK = "operator.yank"
      INDENT = "operator.indent"
      DEDENT = "operator.dedent"
      FOLD = "fold.create"
    end
  end
end
