module Carat
  module Domain
    # Two positions plus a kind (:charwise, :linewise, :blockwise) and an
    # inclusive flag. Every operator will receive one; this change uses only
    # the exclusive charwise kind. Inside Carat::Domain the bare name Range is
    # this class; only literal ranges of Ruby's own are used here. A Data
    # value: equal by value and frozen.
    class Range < Data.define(:from, :to, :kind, :inclusive)
      #: (Position, Position) -> Range
      def self.charwise(from, to)
        new(from: from, to: to, kind: :charwise, inclusive: false)
      end

      # The range with from before to and an exclusive end.
      #: () -> Range
      def normalized
        a = from
        b = to
        if b.before?(a)
          a = to
          b = from
        end
        b = Position.new(row: b.row, col: b.col + 1) if inclusive
        Range.new(from: a, to: b, kind: kind, inclusive: false)
      end
    end
  end
end
