module Carat
  module Domain
    # The code point columns one row of a selection covers, from inclusive
    # to exclusive, and whether the row's line break is selected too. A
    # Data value.
    class Span < Data.define(:from, :to, :eol)
      # @rbs @from: Integer
      # @rbs @to: Integer
      # @rbs @eol: bool

      # A row the selection does not reach.
      #: () -> Span
      def self.empty
        Span.new(0, 0, false)
      end

      #: () -> bool
      def empty?
        to <= from && !eol
      end
    end
  end
end
