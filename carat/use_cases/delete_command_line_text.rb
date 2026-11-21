require_relative "../domain/editor_state"
require_relative "../domain/command_line_text"
require_relative "erase_command_line"
require_relative "search/preview_search"
require_relative "outcome"

module Carat
  module UseCases
    # The deleting keys of the command line besides Backspace: the character
    # under the cursor (:under, which at the end of the line is Backspace,
    # leaving an empty line), the word before the cursor (:word, as
    # <C-w>), and everything before it (:line, as <C-u>). The last two do
    # nothing on an empty line. A search prompt previews what is left.
    class DeleteCommandLineText
      attr_reader :erase_command_line #: EraseCommandLine
      attr_reader :preview_search #: PreviewSearch

      #: (erase_command_line: EraseCommandLine, preview_search: PreviewSearch) -> void
      def initialize(erase_command_line:, preview_search:)
        @erase_command_line = erase_command_line
        @preview_search = preview_search
      end

      #: (Domain::EditorState, Symbol) -> Outcome
      def call(state, unit)
        text = state.cmdline
        cursor = state.cmdline_position
        return @erase_command_line.call(state) if unit == :under && cursor >= text.length
        from = cursor
        to = cursor
        case unit
        when :under then to = cursor + 1
        when :word then from = Domain::CommandLineText.removal_start(text, cursor)
        else from = 0
        end
        return Outcome.none if from == to
        state.cmdline = text[0, from].to_s + text[to, text.length - to].to_s
        state.cmdline_position = from
        @preview_search.call(state)
      end
    end
  end
end
