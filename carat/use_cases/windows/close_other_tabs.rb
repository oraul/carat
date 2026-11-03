require_relative "../../domain/editor_state"
require_relative "../../domain/tab_list"
require_relative "../../domain/buffer_list"
require_relative "../outcome"

module Carat
  module UseCases
    # :tabonly: closes every other tab page. A modified buffer shown only
    # in a closed tab page stays listed, hidden.
    class CloseOtherTabs
      ONLY_ONE = "Already only one tab page"
      private_constant :ONLY_ONE

      attr_reader :buffers #: Domain::BufferList
      attr_reader :tabs #: Domain::TabList

      #: (buffers: Domain::BufferList, tabs: Domain::TabList) -> void
      def initialize(buffers:, tabs:)
        @buffers = buffers
        @tabs = tabs
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        return Outcome.success(ONLY_ONE) if @tabs.tab_count <= 1
        @buffers.close_tab(@tabs.tab_index == 0 ? 1 : 0) while @tabs.tab_count > 1
        Outcome.success("")
      end
    end
  end
end
