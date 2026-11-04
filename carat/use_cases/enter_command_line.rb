require_relative "../domain/editor_state"
require_relative "../domain/mode"
require_relative "../domain/plugin_ui"
require_relative "../domain/history"
require_relative "../domain/search_prompt"
require_relative "outcome"

module Carat
  module UseCases
    # ":": command-line mode with an empty line; a plugin's prompt or a
    # search prompt that was open is closed, and a recall of the command
    # history starts again.
    class EnterCommandLine
      attr_reader :plugin_ui #: Domain::PluginUi
      attr_reader :search_prompt #: Domain::SearchPrompt
      attr_reader :command_history #: Domain::History

      #: (plugin_ui: Domain::PluginUi, search_prompt: Domain::SearchPrompt, command_history: Domain::History) -> void
      def initialize(plugin_ui:, search_prompt:, command_history:)
        @plugin_ui = plugin_ui
        @search_prompt = search_prompt
        @command_history = command_history
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        state.mode = Domain::Mode::CMDLINE
        state.cmdline = ""
        @plugin_ui.close_prompt
        @search_prompt.close
        @command_history.restart
        Outcome.none
      end
    end
  end
end
