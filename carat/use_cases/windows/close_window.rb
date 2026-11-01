require_relative "../../domain/editor_state"
require_relative "../../domain/tab_list"
require_relative "../../domain/buffer_list"
require_relative "../outcome"

module Carat
  module UseCases
    # Closes windows: one window, giving its space to a neighbour and
    # closing its tab page when it was the last one there, or every window
    # but the current one. The buffer a closed window showed stays listed
    # while it is modified, hidden, and leaves the list otherwise.
    class CloseWindow
      E444 = "E444: Cannot close last window"
      ONLY_ONE = "Already only one window"

      attr_reader :buffers #: Domain::BufferList
      attr_reader :tabs #: Domain::TabList

      #: (buffers: Domain::BufferList, tabs: Domain::TabList) -> void
      def initialize(buffers:, tabs:)
        @buffers = buffers
        @tabs = tabs
      end

      # Closes window number n of the current tab page, or the current
      # window when n is 0; the last window of the last tab page stays.
      #: (Domain::EditorState, Integer) -> Outcome
      def close(state, n)
        return Outcome.failure(E444) if @tabs.total_windows <= 1
        tab = state.tab
        id = n > 0 ? tab.layout.leaf_number(n) : tab.current
        remove(state, id)
        Outcome.success("")
      end

      # Closes every other window of the current tab page.
      #: (Domain::EditorState) -> Outcome
      def only(state)
        tab = state.tab
        return Outcome.success(ONLY_ONE) if tab.window_count <= 1
        layout = tab.layout
        ids = layout.leaves
        i = 0
        while i < ids.length
          id = ids[i]
          unless id == tab.current
            buffer = layout.window_at(id).buffer
            layout.close(id)
            @buffers.release(buffer)
          end
          i += 1
        end
        tab.previous = -1
        Outcome.success("")
      end

      # Removes leaf id from the current tab page, closing the tab page when
      # it was the last window there, and releases its buffer. The caller
      # has checked that another window exists somewhere.
      #: (Domain::EditorState, Integer) -> void
      def remove(state, id)
        remove_in(state, @tabs.tab_index, id)
      end

      # Removes leaf id from the tab page at index, as remove does for the
      # current one.
      #: (Domain::EditorState, Integer, Integer) -> void
      def remove_in(state, index, id)
        tab = @tabs.tab_at(index)
        layout = tab.layout
        buffer = layout.window_at(id).buffer
        if layout.leaf_count <= 1
          @tabs.remove_tab(index)
        else
          taker = layout.close(id)
          tab.current = layout.first_leaf(taker) if id == tab.current
          tab.previous = -1 if tab.previous == id
        end
        @buffers.release(buffer)
      end
    end
  end
end
