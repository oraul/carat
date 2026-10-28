module Carat
  module Domain
    # A parsed command line: name, bang, and the argument text. Ranges arrive
    # with the editing commands. A Data value: equal by value and frozen.
    class ExCommand < Data.define(:name, :bang, :args)
    end
  end
end
