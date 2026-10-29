require_relative "../../domain/editor_state"
require_relative "../../domain/tab_page"
require_relative "../outcome"
require_relative "../files/open_file"

module Carat
  module UseCases
    # Opens a tab page after the current one with one window showing a
    # fresh unnamed buffer, or the given file opened as :e does, and makes
    # it current.
    class OpenTab
      # @rbs @open_file: OpenFile

      #: (OpenFile) -> void
      def initialize(open_file)
        @open_file = open_file
      end

      #: (Domain::EditorState, String) -> Outcome
      def call(state, path)
        buffer = Domain::Buffer.from_text("", nil)
        state.add_buffer(buffer)
        state.add_tab(Domain::TabPage.new(Domain::Window.new(buffer)))
        return Outcome.success("") if path.empty?
        @open_file.call(state, path)
      end
    end
  end
end
