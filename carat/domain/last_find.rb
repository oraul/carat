require_relative "find"

module Carat
  module Domain
    # The last f, F, t, or T motion, which ";" and "," repeat, nil before
    # the first. A Struct record: mutable, with a reader and a writer per
    # member.
    class LastFind < Struct.new(:entry)
      # @rbs @entry: Find?

      #: () -> void
      def initialize
        super(nil)
      end

      #: (Find) -> void
      def remember(find)
        self.entry = find
      end
    end
  end
end
