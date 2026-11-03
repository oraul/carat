module Carat
  module UseCases
    # Which tab page SwitchTab makes current: target :next goes to the
    # next one, wrapping, or to tab page number count when it is not 0;
    # :previous goes count tab pages back (at least one), wrapping; :first
    # and :last go to the ends. A Data value.
    class TabRequest < Data.define(:target, :count)
      # @rbs @target: Symbol
      # @rbs @count: Integer

      # Whether a count was given.
      #: () -> bool
      def counted?
        count > 0
      end
    end
  end
end
