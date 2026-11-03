require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../outcome"

module Carat
  module UseCases
    # :only and Ctrl-W o: closes every other window of the current tab
    # page. The buffer a closed window showed stays listed while it is
    # modified, hidden, and leaves the list otherwise.
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
    end
  end
end
