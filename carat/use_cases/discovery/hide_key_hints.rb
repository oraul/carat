require_relative "../../domain/editor_state"
require_relative "../../domain/key_hints"
require_relative "../windows/close_float"

module Carat
  module UseCases
    # Closes the key hints float, which the next key does before it is
    # handled, as does a binding resolved by timeoutlen. HandleKey calls
    # it only while the hints show.
    class HideKeyHints
      attr_reader :hints #: Domain::KeyHints
      attr_reader :close_float #: CloseFloat

      #: (hints: Domain::KeyHints, close_float: CloseFloat) -> void
      def initialize(hints:, close_float:)
        @hints = hints
        @close_float = close_float
      end

      #: (Domain::EditorState) -> void
      def call(state)
        hints = @hints
        return unless hints.showing?
        @close_float.call(state, hints.float_id)
        hints.float_id = 0
      end
    end
  end
end
