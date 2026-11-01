require_relative "position"

module Carat
  module Domain
    # The result of a motion: where it lands, whether it is linewise, whether
    # an operator includes the target character, and what happens to the
    # wanted column (:set for horizontal motions, :keep for vertical ones,
    # :end for "$"). A Data value.
    class Motion < Data.define(:target, :linewise, :inclusive, :want)
    end
  end
end
