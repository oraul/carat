module Carat
  module Domain
    # What a substitute made of one line: its new text, holding a "\n"
    # where a line break was inserted, and the number of matches replaced
    # or counted; the line itself and 0 when nothing matched. A Data value.
    class SubstitutedLine < Data.define(:text, :count)
      # @rbs @text: String
      # @rbs @count: Integer

      #: () -> bool
      def changed?
        count > 0
      end
    end
  end
end
