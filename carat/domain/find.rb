module Carat
  module Domain
    # The last f, F, t, or T motion, for ";" and ",". A Data value.
    class Find < Data.define(:char, :forward, :till)
      #: () -> Find
      def reversed
        Find.new(char, !forward, till)
      end
    end
  end
end
