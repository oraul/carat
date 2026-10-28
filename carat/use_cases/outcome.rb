module Carat
  module UseCases
    # What a file or ex use case reports back: whether it succeeded and the
    # message to show, which may be empty. A Data value: equal by value and
    # frozen.
    class Outcome < Data.define(:ok, :message)
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
