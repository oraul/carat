require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/tab_list"
require_relative "../../domain/messages"
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
        return Outcome.failure(Domain::Messages::E36) if id < 0
        @tabs.adopt(tab.layout.window_at(id))
        tab.focus(id)
        if fresh
          @buffers.load(Domain::Buffer.from_text("", nil))
          return Outcome.success("")
        end
        return Outcome.success("") if path.empty?
        @open_file.call(state, path)
      end
    end
  end
end
