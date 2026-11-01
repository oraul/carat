require_relative "../domain/editor_state"
require_relative "ex/execute_ex"
require_relative "plugins/plugin_host"
require_relative "outcome"

module Carat
  module UseCases
    # Command-line mode: entering it, editing the text, cancelling, and
    # executing through ExecuteEx. While a plugin's prompt holds the
    # command line, Enter delivers the text to that plugin instead of
    # running it, and cancelling delivers a cancel. Every entry point but
    # append returns the Outcome to report; executing returns the ex
    # command's.
    class EditCommandLine
      # @rbs @execute_ex: ExecuteEx
      # @rbs @plugins: PluginHost

      #: (execute_ex: ExecuteEx, plugins: PluginHost) -> void
      def initialize(execute_ex:, plugins:)
        @execute_ex = execute_ex
        @plugins = plugins
      end

      #: (Domain::EditorState) -> Outcome
      def start(state)
        state.mode = Domain::Mode::CMDLINE
        state.cmdline = ""
        state.prompt = ""
        state.prompt_owner = ""
        state.prompt_id = ""
        Outcome.none
      end

      #: (Domain::EditorState, String) -> void
      def append(state, text)
        state.cmdline = state.cmdline + text
      end

      #: (Domain::EditorState) -> Outcome
      def backspace(state)
        text = state.cmdline
        return cancel(state) if text.empty?
        state.cmdline = text[0, text.length - 1]
        Outcome.none
      end

      #: (Domain::EditorState) -> Outcome
      def cancel(state)
        state.cmdline = ""
        state.mode = Domain::Mode::NORMAL
        @plugins.answer("", true) if state.prompting?
        Outcome.none
      end

      #: (Domain::EditorState) -> Outcome
      def execute(state)
        text = state.cmdline
        state.cmdline = ""
        state.mode = Domain::Mode::NORMAL
        if state.prompting?
          @plugins.answer(text, false)
          return Outcome.none
        end
        return Outcome.none if text.strip.empty?
        @execute_ex.call(state, text)
      end
    end
  end
end
