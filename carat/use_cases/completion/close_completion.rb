require_relative "../../domain/editor_state"
require_relative "../../domain/completion_menu"
require_relative "../windows/close_float"
require_relative "../outcome"

module Carat
  module UseCases
    # Closes the completion popup (Esc while it shows, completion.close)
    # and forgets its candidates, so the next word asks the source again;
    # the mode stays.
    class CloseCompletion
      attr_reader :menu #: Domain::CompletionMenu
      attr_reader :close_float #: CloseFloat

      #: (menu: Domain::CompletionMenu, close_float: CloseFloat) -> void
      def initialize(menu:, close_float:)
        @menu = menu
        @close_float = close_float
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        menu = @menu
        @close_float.call(state, menu.float_id) if menu.showing?
        menu.clear
        Outcome.none
      end
    end
  end
end
