require_relative "../domain/editor_state"
require_relative "../domain/mode"
require_relative "../domain/plugin_ui"
require_relative "../domain/search_prompt"
require_relative "../domain/last_search"
require_relative "plugins/plugin_host"
require_relative "outcome"

module Carat
  module UseCases
    # Escape on the command line: back to normal mode with the line
    # dropped; while a plugin's prompt holds the command line, the plugin
    # hears the cancel. A search prompt puts the cursor and view back
    # where it opened, ends its preview, and returns to the mode it came
    # from; HandleKey then drops the search command.
    class CancelCommandLine
      attr_reader :plugins #: PluginHost
      attr_reader :plugin_ui #: Domain::PluginUi
      attr_reader :search_prompt #: Domain::SearchPrompt
      attr_reader :last_search #: Domain::LastSearch

      #: (plugins: PluginHost, plugin_ui: Domain::PluginUi, search_prompt: Domain::SearchPrompt, last_search: Domain::LastSearch) -> void
      def initialize(plugins:, plugin_ui:, search_prompt:, last_search:)
        @plugins = plugins
        @plugin_ui = plugin_ui
        @search_prompt = search_prompt
        @last_search = last_search
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        state.cmdline = ""
        state.mode = Domain::Mode::NORMAL
        prompt = @search_prompt
        if prompt.active
          prompt.restore(state.window)
          prompt.close
          @last_search.end_preview
          state.mode = prompt.return_mode
        end
        @plugins.answer("", true) if @plugin_ui.prompting?
        Outcome.none
      end
    end
  end
end
