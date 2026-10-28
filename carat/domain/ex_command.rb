module Carat
  module Domain
    # A parsed command line: name, bang, and the argument text. Ranges arrive
    # with the editing commands.
    class ExCommand
      attr_reader :name #: String
      attr_reader :bang #: bool
      attr_reader :args #: String

      #: (String, bool, String) -> void
      def initialize(name, bang, args)
        @name = name
        @bang = bang
        @args = args
      end
    end
  end
end
