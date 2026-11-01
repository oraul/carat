require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/tab_list"
require_relative "../../domain/tab_page"
require_relative "../outcome"
require_relative "../files/open_file"

module Carat
  module UseCases
    # Opens a tab page after the current one with one window showing a
    # fresh unnamed buffer, or the given file opened as :e does, and makes
    # it current.
    class OpenTab
      attr_reader :open_file #: OpenFile
      attr_reader :buffers #: Domain::BufferList
      attr_reader :tabs #: Domain::TabList

      #: (open_file: OpenFile, buffers: Domain::BufferList, tabs: Domain::TabList) -> void
      def initialize(open_file:, buffers:, tabs:)
        @open_file = open_file
        @buffers = buffers
        @tabs = tabs
      end

      #: (Domain::EditorState, String) -> Outcome
      def call(state, path)
        buffer = Domain::Buffer.from_text("", nil)
        @buffers.add(buffer)
        @tabs.add_tab(Domain::TabPage.new(Domain::Window.new(buffer)))
        return Outcome.success("") if path.empty?
        @open_file.call(state, path)
      end
    end
  end
end
