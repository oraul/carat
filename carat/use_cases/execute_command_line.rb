require_relative "../domain/editor_state"
require_relative "../domain/mode"
require_relative "../domain/plugin_ui"
require_relative "../domain/registers"
require_relative "../domain/history"
require_relative "../domain/search_prompt"
require_relative "../domain/last_search"
require_relative "ex/command_runner"
require_relative "plugins/plugin_host"
require_relative "outcome"

module Carat
  module UseCases
    # Enter on the command line: back to normal mode and the line run
    # through the command runner, whose outcome is returned. While a
    # plugin's prompt holds the command line, the text goes to that plugin
    # instead. An executed line becomes the ":" register after it ran, so
    # :registers does not list itself, and the newest entry of the
    # command history. At a search prompt the text joins the search
    # history, the cursor and view go back where the prompt opened, the
    # mode returns to the one it came from, and the prompt keeps the text,
    # which HandleKey hands to the search command as its pattern.
    class ExecuteCommandLine
      attr_reader :runner #: CommandRunner
      attr_reader :plugins #: PluginHost
      attr_reader :plugin_ui #: Domain::PluginUi
      attr_reader :registers #: Domain::Registers
      attr_reader :search_prompt #: Domain::SearchPrompt
      attr_reader :last_search #: Domain::LastSearch
      attr_reader :command_history #: Domain::History
      attr_reader :search_history #: Domain::History

      #: (runner: CommandRunner, plugins: PluginHost, plugin_ui: Domain::PluginUi, registers: Domain::Registers, search_prompt: Domain::SearchPrompt, last_search: Domain::LastSearch, command_history: Domain::History, search_history: Domain::History) -> void
      def initialize(runner:, plugins:, plugin_ui:, registers:, search_prompt:, last_search:, command_history:, search_history:)
        @runner = runner
        @plugins = plugins
        @plugin_ui = plugin_ui
        @registers = registers
        @search_prompt = search_prompt
        @last_search = last_search
        @command_history = command_history
        @search_history = search_history
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        text = state.cmdline
        state.cmdline = ""
        state.mode = Domain::Mode::NORMAL
        prompt = @search_prompt
        if @plugin_ui.prompting?
          prompt.close
          @last_search.end_preview
          @plugins.answer(text, false)
          return Outcome.none
        end
        if prompt.active
          prompt.restore(state.window)
          @last_search.end_preview
          @search_history.add(text)
          state.mode = prompt.return_mode
          prompt.enter(text)
          return Outcome.none
        end
        return Outcome.none if text.strip.empty?
        outcome = @runner.call(state, text)
        @registers.command_line = text
        @command_history.add(text)
        outcome
      end
    end
  end
end
