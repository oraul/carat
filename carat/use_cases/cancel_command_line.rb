require_relative "../domain/editor_state"
require_relative "../domain/mode"
require_relative "../domain/plugin_ui"
require_relative "plugins/plugin_host"
require_relative "outcome"

module Carat
  module UseCases
    # Escape on the command line: back to normal mode with the line
    # dropped; while a plugin's prompt holds the command line, the plugin
    # hears the cancel.
    class CancelCommandLine
      attr_reader :plugins #: PluginHost
      attr_reader :plugin_ui #: Domain::PluginUi

      #: (plugins: PluginHost, plugin_ui: Domain::PluginUi) -> void
      def initialize(plugins:, plugin_ui:)
        @plugins = plugins
        @plugin_ui = plugin_ui
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        state.cmdline = ""
        state.mode = Domain::Mode::NORMAL
        @plugins.answer("", true) if @plugin_ui.prompting?
        Outcome.none
      end
    end
  end
end
