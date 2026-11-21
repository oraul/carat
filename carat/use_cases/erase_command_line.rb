require_relative "../domain/editor_state"
require_relative "cancel_command_line"
require_relative "search/preview_search"
require_relative "outcome"

module Carat
  module UseCases
    # Backspace on the command line: the character before the cursor goes,
    # and a search prompt previews what is left; at the start of a line
    # with text nothing happens, and on an empty line it cancels the
    # command line, as Vim does.
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
        cursor = state.cmdline_position
        return Outcome.none if cursor == 0
        if cursor == text.length
          state.cmdline = text[0, cursor - 1].to_s
          state.cmdline_after = 0
        else
          state.cmdline = text[0, cursor - 1].to_s + text[cursor, text.length - cursor].to_s
          state.cmdline_position = cursor - 1
        end
        @preview_search.call(state)
      end
    end
  end
end
