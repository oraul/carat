module Carat
  module Domain
    # The key hints float the editor shows over a waiting prefix: float_id
    # is its window, 0 while none shows. A Struct record built with no
    # arguments.
    class KeyHints < Struct.new(:float_id, keyword_init: true)
      # @rbs @float_id: Integer

      # The owner of the scratch buffer the hints are shown in.
      OWNER = ":keyhints"

      #: () -> void
      def initialize
        super(float_id: 0)
      end

      #: () -> bool
      def showing?
        float_id != 0
      end
    end
  end
end
