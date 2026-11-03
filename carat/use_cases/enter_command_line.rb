require_relative "../domain/editor_state"
require_relative "../domain/mode"
require_relative "../domain/plugin_ui"
require_relative "outcome"

module Carat
  module UseCases
    # ":": command-line mode with an empty line; a plugin's prompt that
    # was open is closed.
    class EnterCommandLine
      attr_reader :plugin_ui #: Domain::PluginUi

      #: (plugin_ui: Domain::PluginUi) -> void
      def initialize(plugin_ui:)
        @plugin_ui = plugin_ui
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        state.mode = Domain::Mode::CMDLINE
        state.cmdline = ""
        @plugin_ui.close_prompt
        Outcome.none
      end
    end
  end
end
