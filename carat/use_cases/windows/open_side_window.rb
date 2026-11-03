require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/window"
require_relative "../../domain/tab_list"
require_relative "../../domain/buffer_list"
require_relative "../../domain/messages"
require_relative "../outcome"

module Carat
  module UseCases
    # Adds a fixed-width window showing the buffer at the left or right
    # edge of the current tab page, width columns wide, lists the buffer,
    # and makes the window current; E36 when the layout cannot hold it.
    # This is how a plugin's side window opens; the new window gets its id
    # from the tab list.
    class OpenSideWindow
      attr_reader :buffers #: Domain::BufferList
      attr_reader :tabs #: Domain::TabList

      #: (buffers: Domain::BufferList, tabs: Domain::TabList) -> void
      def initialize(buffers:, tabs:)
        @buffers = buffers
        @tabs = tabs
      end

      #: (Domain::EditorState, Domain::Buffer, Integer, bool) -> Outcome
      def call(state, buffer, width, left)
        tab = state.tab
        window = Domain::Window.new(buffer: buffer)
        window.fixed_width = true
        id = tab.layout.split_edge(window, width, left)
        return Outcome.failure(Domain::Messages::E36) if id < 0
        @tabs.adopt(window)
        @buffers.add(buffer)
        tab.focus(id)
        Outcome.success("")
      end
    end
  end
end
