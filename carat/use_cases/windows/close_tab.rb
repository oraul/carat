require_relative "../../domain/editor_state"
require_relative "../../domain/tab_list"
require_relative "../../domain/buffer_list"
require_relative "../outcome"

module Carat
  module UseCases
    # :tabclose: closes the current tab page, or tab page number (1-based)
    # when it is not 0, which the caller checked; the last one stays
    # (E784). A modified buffer shown only in the closed tab page stays
    # listed, hidden.
    class CloseTab
      E784 = "E784: Cannot close last tab page"
      private_constant :E784

      attr_reader :buffers #: Domain::BufferList
      attr_reader :tabs #: Domain::TabList

      #: (buffers: Domain::BufferList, tabs: Domain::TabList) -> void
      def initialize(buffers:, tabs:)
        @buffers = buffers
        @tabs = tabs
      end

      #: (Domain::EditorState, Integer) -> Outcome
      def call(state, number)
        return Outcome.failure(E784) if @tabs.tab_count <= 1
        @buffers.close_tab(number > 0 ? number - 1 : @tabs.tab_index)
        Outcome.success("")
      end
    end
  end
end
