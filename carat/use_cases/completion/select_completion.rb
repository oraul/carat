require_relative "../../domain/editor_state"
require_relative "../../domain/completion_menu"
require_relative "../outcome"

module Carat
  module UseCases
    # Moves the popup's selection by step rows (Ctrl-N and Down 1, Ctrl-P
    # and Up -1), wrapping at the ends; the popup's window follows the
    # selected row, so ArrangeView scrolls it into view.
    class SelectCompletion
      attr_reader :menu #: Domain::CompletionMenu

      #: (menu: Domain::CompletionMenu) -> void
      def initialize(menu:)
        @menu = menu
      end

      #: (Domain::EditorState, Integer) -> Outcome
      def call(state, step)
        menu = @menu
        return Outcome.none unless menu.showing?
        floats = state.tab.floats
        index = floats.index_of(menu.float_id)
        count = menu.matches.length
        return Outcome.none if index < 0 || count == 0
        selected = menu.selected + step
        selected = count - 1 if selected < 0
        selected = 0 if selected >= count
        menu.selected = selected
        float = floats.at(index)
        float.selected = selected
        float.window.cursor.move_to(selected, 0)
        Outcome.none
      end
    end
  end
end
