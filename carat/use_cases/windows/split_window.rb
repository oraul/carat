require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/tab_list"
require_relative "../outcome"
require_relative "../files/open_file"

module Carat
  module UseCases
    # Splits the current window horizontally or vertically. The new window
    # goes above or to the left, becomes current, and shows the same view,
    # a file opened as :e does, or a fresh unnamed buffer. A split that
    # cannot give both windows their minimum size reports E36. Every new
    # window gets its id from the tab list.
    class SplitWindow
      E36 = "E36: Not enough room"

      attr_reader :open_file #: OpenFile
      attr_reader :buffers #: Domain::BufferList
      attr_reader :tabs #: Domain::TabList

      #: (open_file: OpenFile, buffers: Domain::BufferList, tabs: Domain::TabList) -> void
      def initialize(open_file:, buffers:, tabs:)
        @open_file = open_file
        @buffers = buffers
        @tabs = tabs
      end

      # size is the new window's text rows or columns, 0 for half; path is
      # the file to show, "" for none; fresh asks for a new empty buffer.
      #: (Domain::EditorState, bool, Integer, String, bool) -> Outcome
      def call(state, vertical, size, path, fresh)
        tab = state.tab
        min_width = state.window.gutter_width(state.options) + 1
        id = tab.layout.split(tab.current, vertical, size, min_width)
        return Outcome.failure(E36) if id < 0
        @tabs.adopt(tab.layout.window_at(id))
        tab.focus(id)
        if fresh
          @buffers.load(Domain::Buffer.from_text("", nil))
          return Outcome.success("")
        end
        return Outcome.success("") if path.empty?
        @open_file.call(state, path)
      end

      # Adds a fixed-width window showing the buffer at the left or right
      # edge of the current tab page, width columns wide, lists the buffer,
      # and makes the window current; E36 when the layout cannot hold it.
      # This is how a plugin's side window opens.
      #: (Domain::EditorState, Domain::Buffer, Integer, bool) -> Outcome
      def side(state, buffer, width, left)
        tab = state.tab
        window = Domain::Window.new(buffer)
        window.fixed_width = true
        id = tab.layout.split_edge(window, width, left)
        return Outcome.failure(E36) if id < 0
        @tabs.adopt(window)
        @buffers.add(buffer)
        tab.focus(id)
        Outcome.success("")
      end
    end
  end
end
