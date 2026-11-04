module Carat
  module Domain
    # A parsed command line: the range as typed ("" for none, resolved by
    # ExRange when the command runs), the name, bang, and the argument
    # text. A Data value: equal by value and frozen.
    class ExCommand < Data.define(:range, :name, :bang, :args)
    end
  end
end
