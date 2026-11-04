require_relative "../domain/editor_state"
require_relative "cancel_command_line"
require_relative "search/preview_search"
require_relative "outcome"

module Carat
  module UseCases
    # Backspace on the command line: the last character goes, and a
    # search prompt previews what is left; on an empty line it cancels
    # the command line, as Vim does.
    class EraseCommandLine
      attr_reader :cancel_command_line #: CancelCommandLine
      attr_reader :preview_search #: PreviewSearch

      #: (cancel_command_line: CancelCommandLine, preview_search: PreviewSearch) -> void
      def initialize(cancel_command_line:, preview_search:)
        @cancel_command_line = cancel_command_line
        @preview_search = preview_search
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        text = state.cmdline
        return @cancel_command_line.call(state) if text.empty?
        state.cmdline = text[0, text.length - 1].to_s
        @preview_search.call(state)
      end
    end
  end
end
