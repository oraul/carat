require_relative "../domain/editor_state"
require_relative "../domain/plugin_ui"
require_relative "../domain/registers"
require_relative "ex/command_runner"
require_relative "plugins/plugin_host"
require_relative "outcome"

module Carat
  module UseCases
    # Command-line mode: entering it, editing the text, cancelling, and
    # executing through the command runner. While a plugin's prompt holds the
    # command line, Enter delivers the text to that plugin instead of
    # running it, and cancelling delivers a cancel. Every entry point but
    # append returns the Outcome to report; executing returns the ex
    # command's. An executed line becomes the ":" register after it ran,
    # so :registers does not list itself.
    class EditCommandLine
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
      def start(state)
        state.mode = Domain::Mode::CMDLINE
        state.cmdline = ""
        @plugin_ui.close_prompt
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
        @plugins.answer("", true) if @plugin_ui.prompting?
        Outcome.none
      end

      #: (Domain::EditorState) -> Outcome
      def execute(state)
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
