module Carat
  module UseCases
    # Which window FocusWindow makes current: target :left, :down, :up, or
    # :right moves count times (at least once) to a neighbour; :next and
    # :previous cycle in layout order, or go to window number count when
    # it is not 0; :last_accessed goes back to the window used before. A
    # Data value.
    class FocusRequest < Data.define(:target, :count)
      # @rbs @target: Symbol
      # @rbs @count: Integer

      # The neighbour steps of a direction: the count, at least one.
      #: () -> Integer
      def steps
        count > 0 ? count : 1
      end
    end
  end
end
