require_relative "../../domain/editor_state"
require_relative "../../domain/tab_list"
require_relative "../outcome"

module Carat
  module UseCases
    # Closes a floating window: the topmost of the current tab page for
    # id 0, doing nothing when none is open, or the float with the window
    # id in any tab page, failing for an unknown id. A focused float gives
    # the focus back to the window under it.
    class CloseFloat
      attr_reader :tabs #: Domain::TabList

      #: (tabs: Domain::TabList) -> void
      def initialize(tabs:)
        @tabs = tabs
      end

      #: (Domain::EditorState, Integer) -> Outcome
      def call(state, id)
        if id == 0
          state.tab.floats.close_top
          return Outcome.none
        end
        index = @tabs.float_tab(id)
        return Outcome.failure("No float #{id}") if index < 0
        @tabs.tab_at(index).floats.close(id)
        Outcome.success("")
      end
    end
  end
end
