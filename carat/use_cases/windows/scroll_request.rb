module Carat
  module UseCases
    # How ScrollWindow scrolls: target :page_down or :page_up by count
    # pages, :half_down or :half_up by the scroll option (a count sets it
    # first), :line_down or :line_up by count lines, and :cursor_top,
    # :cursor_middle, or :cursor_bottom to place the cursor line, on line
    # count first when it is not 0. A Data value.
    class ScrollRequest < Data.define(:target, :count)
      # @rbs @target: Symbol
      # @rbs @count: Integer

      # The pages or lines to scroll: the count, at least one.
      #: () -> Integer
      def steps
        count > 0 ? count : 1
      end
    end
  end
end
