require_relative "../../domain/editor_state"
require_relative "../../domain/tab_list"
require_relative "../../domain/float_window"
require_relative "../outcome"

module Carat
  module UseCases
    # Opens a floating window over the current tab page's layout: the
    # window gets its id from the tab list, the float goes into the tab
    # page's layer by its z order, and becomes the current window when
    # enter is true. A full layer refuses it and nothing changes.
    class OpenFloat
      FULL = "Too many floating windows"
      private_constant :FULL

      attr_reader :tabs #: Domain::TabList

      #: (tabs: Domain::TabList) -> void
      def initialize(tabs:)
        @tabs = tabs
      end

      #: (Domain::EditorState, Domain::FloatWindow, bool) -> Outcome
      def call(state, float, enter)
        floats = state.tab.floats
        return Outcome.failure(FULL) if floats.full?
        @tabs.adopt(float.window)
        floats.add(float, enter)
        Outcome.success("")
      end
    end
  end
end
