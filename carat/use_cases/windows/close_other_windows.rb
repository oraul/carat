require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../outcome"

module Carat
  module UseCases
    # :only and Ctrl-W o: closes every other window of the current tab
    # page through BufferList#close_window, so each closed window leaves
    # its cursor in its buffer, which stays listed, hidden when no other
    # window shows it.
    class CloseOtherWindows
      ONLY_ONE = "Already only one window"
      private_constant :ONLY_ONE

      attr_reader :buffers #: Domain::BufferList

      #: (buffers: Domain::BufferList) -> void
      def initialize(buffers:)
        @buffers = buffers
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        tab = state.tab
        return Outcome.success(ONLY_ONE) if tab.window_count <= 1
        index = @buffers.tabs.tab_index
        ids = tab.layout.leaves
        i = 0
        while i < ids.length
          id = ids[i]
          @buffers.close_window(index, id) unless id == tab.current
          i += 1
        end
        tab.previous = -1
        Outcome.success("")
      end
    end
  end
end
