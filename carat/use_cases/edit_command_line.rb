require_relative "../domain/editor_state"
require_relative "files/execute_ex"
require_relative "plugins/plugin_host"

module Carat
  module UseCases
    # Command-line mode: entering it, editing the text, cancelling, and
    # executing through ExecuteEx. While a plugin's prompt holds the
    # command line, Enter delivers the text to that plugin instead of
    # running it, and cancelling delivers a cancel.
    class EditCommandLine
      # @rbs @execute_ex: ExecuteEx
      # @rbs @plugins: PluginHost

      #: (ExecuteEx, PluginHost) -> void
      def initialize(execute_ex, plugins)
        @execute_ex = execute_ex
        @plugins = plugins
      end

      #: (Domain::EditorState) -> void
      def start(state)
        state.mode = Domain::Mode::CMDLINE
        state.cmdline = ""
        state.prompt = ""
        state.prompt_owner = ""
        state.prompt_id = ""
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
        @plugins.answer("", true) if state.prompting?
      end

      #: (Domain::EditorState) -> void
      def execute(state)
        text = state.cmdline
        state.cmdline = ""
        state.mode = Domain::Mode::NORMAL
        if state.prompting?
          @plugins.answer(text, false)
          return
        end
        return if text.strip.empty?
        outcome = @execute_ex.call(state, text)
        state.show(outcome.message, !outcome.ok) unless outcome.message.empty?
      end
    end
  end
end
