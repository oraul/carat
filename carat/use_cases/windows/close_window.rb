require_relative "../../domain/editor_state"
require_relative "../../domain/tab_list"
require_relative "../../domain/buffer_list"
require_relative "../outcome"

module Carat
  module UseCases
    # :close and Ctrl-W c: closes window number n of the current tab page,
    # or the current window when n is 0, giving its space to a neighbour
    # and closing its tab page when it was the last one there; the last
    # window of the last tab page stays (E444). The file buffer the
    # window showed stays listed, hidden when no other window shows it.
    # In a floating window it closes the float, never a layout window.
    class CloseWindow
      E444 = "E444: Cannot close last window"
      private_constant :E444

      attr_reader :buffers #: Domain::BufferList
      attr_reader :tabs #: Domain::TabList

      #: (buffers: Domain::BufferList, tabs: Domain::TabList) -> void
      def initialize(buffers:, tabs:)
        @buffers = buffers
        @tabs = tabs
      end

      #: (Domain::EditorState, Integer) -> Outcome
      def call(state, n)
        return Outcome.none if n == 0 && state.tab.floats.close_focused
        return Outcome.failure(E444) if @tabs.total_windows <= 1
        tab = state.tab
        id = n > 0 ? tab.layout.leaf_number(n) : tab.current
        @buffers.close_window(@tabs.tab_index, id)
        Outcome.success("")
      end
    end
  end
end
