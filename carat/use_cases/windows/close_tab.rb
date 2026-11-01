require_relative "../../domain/editor_state"
require_relative "../../domain/tab_list"
require_relative "../../domain/buffer_list"
require_relative "../outcome"

module Carat
  module UseCases
    # Closes the current tab page, or every other one. A modified buffer
    # shown only in a closed tab page stays listed, hidden.
    class CloseTab
      E784 = "E784: Cannot close last tab page"
      ONLY_ONE = "Already only one tab page"

      attr_reader :buffers #: Domain::BufferList
      attr_reader :tabs #: Domain::TabList

      #: (buffers: Domain::BufferList, tabs: Domain::TabList) -> void
      def initialize(buffers:, tabs:)
        @buffers = buffers
        @tabs = tabs
      end

      #: (Domain::EditorState) -> Outcome
      def close(state)
        return Outcome.failure(E784) if @tabs.tab_count <= 1
        remove(state, @tabs.tab_index)
        Outcome.success("")
      end

      #: (Domain::EditorState) -> Outcome
      def only(state)
        return Outcome.success(ONLY_ONE) if @tabs.tab_count <= 1
        remove(state, @tabs.tab_index == 0 ? 1 : 0) while @tabs.tab_count > 1
        Outcome.success("")
      end

      private

      # Removes one tab page and releases the buffers its windows showed.
      #: (Domain::EditorState, Integer) -> void
      def remove(state, index)
        layout = @tabs.tab_at(index).layout
        ids = layout.leaves
        held = []
        i = 0
        while i < ids.length
          held << layout.window_at(ids[i]).buffer
          i += 1
        end
        @tabs.remove_tab(index)
        i = 0
        while i < held.length
          @buffers.release(held[i])
          i += 1
        end
      end
    end
  end
end
