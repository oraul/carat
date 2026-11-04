require_relative "../domain/editor_state"
require_relative "../domain/history"
require_relative "../domain/search_prompt"
require_relative "../domain/plugin_ui"
require_relative "search/preview_search"
require_relative "outcome"

module Carat
  module UseCases
    # <Up> and <Down> on the command line: the text becomes the next older
    # or newer entry of the history of the prompt (the search history at
    # "/" and "?", the command history at ":") that starts with what was
    # typed before the first recall, and a search prompt previews it.
    # A plugin's prompt has no history.
    class RecallHistory
      attr_reader :search_prompt #: Domain::SearchPrompt
      attr_reader :command_history #: Domain::History
      attr_reader :search_history #: Domain::History
      attr_reader :plugin_ui #: Domain::PluginUi
      attr_reader :preview_search #: PreviewSearch

      #: (search_prompt: Domain::SearchPrompt, command_history: Domain::History, search_history: Domain::History, plugin_ui: Domain::PluginUi, preview_search: PreviewSearch) -> void
      def initialize(search_prompt:, command_history:, search_history:, plugin_ui:, preview_search:)
        @search_prompt = search_prompt
        @command_history = command_history
        @search_history = search_history
        @plugin_ui = plugin_ui
        @preview_search = preview_search
      end

      # older is true for <Up>.
      #: (Domain::EditorState, bool) -> Outcome
      def call(state, older)
        return Outcome.none if @plugin_ui.prompting?
        history = @search_prompt.active ? @search_history : @command_history
        if older
          history.older(state.cmdline)
        else
          history.newer(state.cmdline)
        end
        return Outcome.none unless history.moved
        state.cmdline = history.recalled
        @preview_search.call(state)
      end
    end
  end
end
