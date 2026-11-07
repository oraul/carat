require_relative "completion_item"

module Carat
  module Domain
    # The candidates a completion source gives for a word, in its order,
    # at most LIMIT: a candidate past the limit is not added. A list of
    # program objects with a typed reader, as DiagnosticList is.
    class CompletionList
      # @rbs @items: Array[untyped]

      LIMIT = 200

      #: () -> void
      def initialize
        @items = []
      end

      # Adds the candidate unless the list is full; answers whether it was
      # added.
      #: (CompletionItem) -> bool
      def add(item)
        return false if @items.length >= LIMIT
        @items << item
        true
      end

      #: (Integer) -> CompletionItem
      def at(i)
        @items[i]
      end

      #: () -> Integer
      def count
        @items.length
      end

      #: () -> void
      def clear
        @items.clear
      end
    end
  end
end
