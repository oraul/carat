module Carat
  module UseCases
    # What a use case reports back: whether it succeeded and the message to
    # show, which may be empty. Every action and ex command handler returns
    # one, and the Reporting concern shows it in the message row. A Data
    # value: equal by value and frozen, so the one empty success, none, is
    # shared and a key that reports nothing allocates no outcome.
    class Outcome < Data.define(:ok, :message)
      # @rbs @ok: bool
      # @rbs @message: String

      #: (String) -> Outcome
      def self.success(message)
        Outcome.new(true, message)
      end

      #: (String) -> Outcome
      def self.failure(message)
        Outcome.new(false, message)
      end

      # The empty success: nothing to report.
      #: () -> Outcome
      def self.none
        NONE
      end

      NONE = Outcome.new(true, "")
    end
  end
end
