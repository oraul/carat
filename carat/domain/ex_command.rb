module Carat
  module Domain
    # A parsed command line: the range as typed ("" for none, resolved by
    # ExRange when the command runs), the name, bang, the argument text
    # trimmed, and the literal argument, only its leading blanks skipped,
    # which :normal reads with its trailing blanks. A Data value: equal by
    # value and frozen.
    class ExCommand < Data.define(:range, :name, :bang, :args, :literal)
    end
  end
end
