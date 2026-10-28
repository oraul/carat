module Carat
  module UseCases
    # What a file or ex use case reports back: whether it succeeded and the
    # message to show, which may be empty.
    class Outcome
      attr_reader :ok #: bool
      attr_reader :message #: String

      #: (bool, String) -> void
      def initialize(ok, message)
        @ok = ok
        @message = message
      end

      #: (String) -> Outcome
      def self.success(message)
        Outcome.new(true, message)
      end

      #: (String) -> Outcome
      def self.failure(message)
        Outcome.new(false, message)
      end
    end
  end
end
