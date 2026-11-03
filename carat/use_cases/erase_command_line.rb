require_relative "../domain/editor_state"
require_relative "cancel_command_line"
require_relative "outcome"

module Carat
  module UseCases
    # Backspace on the command line: the last character goes; on an empty
    # line it cancels the command line, as Vim does.
    class EraseCommandLine
      attr_reader :cancel_command_line #: CancelCommandLine

      #: (cancel_command_line: CancelCommandLine) -> void
      def initialize(cancel_command_line:)
        @cancel_command_line = cancel_command_line
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        text = state.cmdline
        return @cancel_command_line.call(state) if text.empty?
        state.cmdline = text[0, text.length - 1]
        Outcome.none
      end
    end
  end
end
