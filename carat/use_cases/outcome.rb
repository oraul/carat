module Carat
  module UseCases
    # What a use case reports back: whether it succeeded and the message to
    # show, which may be empty. Every action and ex command handler returns
    # one, and the Reporting concern shows it in the message row. A Data
    # value: equal by value and frozen, so the one empty success, none, is
    # shared and a key that reports nothing allocates no outcome. printed
    # says the message is lines :p showed, which a global shows together.
    class Outcome < Data.define(:ok, :message, :printed)
      # @rbs @ok: bool
      # @rbs @message: String
      # @rbs @printed: bool

      #: (String) -> Outcome
      def self.success(message)
        Outcome.new(ok: true, message: message, printed: false)
      end

      #: (String) -> Outcome
      def self.failure(message)
        Outcome.new(ok: false, message: message, printed: false)
      end

      # The lines :p showed, one per line of message.
      #: (String) -> Outcome
      def self.from_print(message)
        Outcome.new(ok: true, message: message, printed: true)
      end

      # The empty success: nothing to report.
      #: () -> Outcome
      def self.none
        NONE
      end

      NONE = Outcome.new(ok: true, message: "", printed: false)
      private_constant :NONE
    end
  end
end
