require_relative "../domain/editor_state"
require_relative "../domain/mode"
require_relative "../domain/plugin_ui"
require_relative "../domain/registers"
require_relative "ex/command_runner"
require_relative "plugins/plugin_host"
require_relative "outcome"

module Carat
  module UseCases
    # Enter on the command line: back to normal mode and the line run
    # through the command runner, whose outcome is returned. While a
    # plugin's prompt holds the command line, the text goes to that plugin
    # instead. An executed line becomes the ":" register after it ran, so
    # :registers does not list itself.
    class ExecuteCommandLine
      attr_reader :runner #: CommandRunner
      attr_reader :plugins #: PluginHost
      attr_reader :plugin_ui #: Domain::PluginUi
      attr_reader :registers #: Domain::Registers

      #: (runner: CommandRunner, plugins: PluginHost, plugin_ui: Domain::PluginUi, registers: Domain::Registers) -> void
      def initialize(runner:, plugins:, plugin_ui:, registers:)
        @runner = runner
        @plugins = plugins
        @plugin_ui = plugin_ui
        @registers = registers
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        text = state.cmdline
        state.cmdline = ""
        state.mode = Domain::Mode::NORMAL
        if @plugin_ui.prompting?
          @plugins.answer(text, false)
          return Outcome.none
        end
        return Outcome.none if text.strip.empty?
        outcome = @runner.call(state, text)
        @registers.command_line = text
        outcome
      end
    end
  end
end
