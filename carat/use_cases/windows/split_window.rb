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

      # size is the new window's text rows (a winbar's row added when the
      # windows will show winbars) or columns, 0 for half; path is
      # the file to show, "" for none; fresh asks for a new empty buffer.
      #: (Domain::EditorState, bool, Integer, String, bool) -> Outcome
      def call(state, vertical, size, path, fresh)
        tab = state.tab
        tab.floats.leave
        min_width = state.window.gutter_width(state.options) + 1
        rows = !vertical && size > 0 && winbar_after?(state, path, fresh) ? size + 1 : size
        id = tab.layout.split(tab.current, vertical, rows, min_width)
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

      private

      # Whether the windows show winbars once the split is made, so that a
      # count of text rows gets one row more for the new window's winbar:
      # the new window is a file window unless it shows the current
      # window's scratch buffer.
      #: (Domain::EditorState, String, bool) -> bool
      def winbar_after?(state, path, fresh)
        mode = state.options.breadcrumbs
        return false if mode == "never"
        return true if mode == "always"
        added = state.window.buffer.scratch? && path.empty? && !fresh ? 0 : 1
        state.tab.file_window_count + added > 1
      end
    end
  end
end
