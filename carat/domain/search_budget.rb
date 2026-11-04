module Carat
  module Domain
    # The work a search or a frame's highlighting may still do, in units
    # of one character scanned by one state of the pattern. A scan is
    # charged its worst case before the engine runs and refunded what it
    # did not use, so no scan starts that the budget cannot pay for; once
    # one could not, or the engine failed, the budget is stopped. A Struct
    # record: mutable, with a reader and a writer per member.
    class SearchBudget < Struct.new(:left, :stopped, keyword_init: true)
      # @rbs @left: Integer
      # @rbs @stopped: bool

      # A search: about one and a half seconds for the largest pattern.
      SEARCH = 400_000_000
      # The highlighting of one frame.
      FRAME = 20_000_000

      #: (left: Integer) -> void
      def initialize(left:)
        super(left: left, stopped: false)
      end

      # Starts again with units left.
      #: (Integer) -> void
      def reset(units)
        self.left = units
        self.stopped = false
      end

      # Pays units, or stops the budget when they are more than is left.
      #: (Integer) -> void
      def charge(units)
        return if stopped
        if units > left
          self.stopped = true
          return
        end
        self.left = left - units
      end

      #: (Integer) -> void
      def refund(units)
        self.left = left + units if units > 0
      end

      #: () -> void
      def stop
        self.stopped = true
      end
    end
  end
end
