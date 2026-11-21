require_relative "../domain/editor_state"
require_relative "../domain/command_line_text"
require_relative "outcome"

module Carat
  module UseCases
    # The cursor keys of the command line, the search prompts, and the
    # other prompts, which share it: one character back (:left) or forward
    # (:right), to the start (:home) or the end (:end), and one
    # blank-separated word back (:word_left) or forward (:word_right). The
    # cursor never leaves the text.
    class MoveCommandLineCursor
      #: (Domain::EditorState, Symbol) -> Outcome
      def call(state, motion)
        text = state.cmdline
        cursor = state.cmdline_position
        case motion
        when :left then cursor = cursor > 0 ? cursor - 1 : 0
        when :right then cursor = cursor < text.length ? cursor + 1 : text.length
        when :home then cursor = 0
        when :end then cursor = text.length
        when :word_left then cursor = Domain::CommandLineText.word_back(text, cursor)
        else cursor = Domain::CommandLineText.word_forward(text, cursor)
        end
        state.cmdline_position = cursor
        Outcome.none
      end
    end
  end
end
