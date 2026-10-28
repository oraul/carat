require_relative "../domain/editor_state"
require_relative "files/execute_ex"

module Carat
  module UseCases
    # Command-line mode: entering it, editing the text, cancelling, and
    # executing through ExecuteEx.
    class EditCommandLine
      # @rbs @execute_ex: ExecuteEx

      #: (ExecuteEx) -> void
      def initialize(execute_ex)
        @execute_ex = execute_ex
      end

      #: (Domain::EditorState) -> void
      def start(state)
        state.mode = Domain::Mode::CMDLINE
        state.cmdline = ""
      end

      #: (Domain::EditorState, String) -> void
      def append(state, text)
        state.cmdline = state.cmdline + text
      end

      #: (Domain::EditorState) -> void
      def backspace(state)
        text = state.cmdline
        if text.empty?
          cancel(state)
        else
          state.cmdline = text[0, text.length - 1]
        end
      end

      #: (Domain::EditorState) -> void
      def cancel(state)
        state.cmdline = ""
        state.mode = Domain::Mode::NORMAL
      end

      #: (Domain::EditorState) -> void
      def execute(state)
        text = state.cmdline
        state.cmdline = ""
        state.mode = Domain::Mode::NORMAL
        return if text.strip.empty?
        outcome = @execute_ex.call(state, text)
        state.show(outcome.message, !outcome.ok) unless outcome.message.empty?
      end
    end
  end
end
