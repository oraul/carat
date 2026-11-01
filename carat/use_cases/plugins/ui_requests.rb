require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../../domain/input_state"
require_relative "../../domain/plugin_ui"
require_relative "../../domain/icons"
require_relative "../../domain/mode"
require_relative "../files/file_ops"
require_relative "../ex/command_runner"
require_relative "plugin_registry"

module Carat
  module UseCases
    # The requests of the plugin API about the editor around the text: a
    # message, the plugin's status segment, a prompt, an icon, the
    # plugin's options, the working directory, and running an ex command
    # line, which is refused with E169 when plugin calls are already
    # nested MAX_DEPTH deep. The command runner is given at construction,
    # already built; the plugin link has checked that the plugin is
    # enabled. The segments and the prompt live in the plugin UI state.
    class UiRequests
      MAX_DEPTH = 4
      E169 = "E169: Command too recursive"

      attr_reader :state #: Domain::EditorState
      attr_reader :registry #: PluginRegistry
      attr_reader :file_ops #: FileOps
      attr_reader :plugin_ui #: Domain::PluginUi
      attr_reader :input #: Domain::InputState
      attr_reader :runner #: CommandRunner

      #: (state: Domain::EditorState, registry: PluginRegistry, file_ops: FileOps, plugin_ui: Domain::PluginUi, input: Domain::InputState, runner: CommandRunner) -> void
      def initialize(state:, registry:, file_ops:, plugin_ui:, input:, runner:)
        @state = state
        @registry = registry
        @file_ops = file_ops
        @plugin_ui = plugin_ui
        @input = input
        @runner = runner
      end

      #: (String, String, bool) -> PluginApi::Response
      def message(name, text, error)
        @state.show(text.dup, error)
        PluginApi::Response.success("", 0)
      end

      #: (String, String) -> PluginApi::Response
      def set_status(name, text)
        @plugin_ui.segment(name, text.dup)
        PluginApi::Response.success("", 0)
      end

      # Opens a prompt in the command-line row for the plugin.
      #: (String, String, String, String) -> PluginApi::Response
      def prompt(name, id, text, initial)
        state = @state
        return PluginApi::Response.failure("A prompt is already open") if @plugin_ui.prompting?
        @plugin_ui.open_prompt(name, id.dup, text.dup)
        state.cmdline = initial.dup
        @input.pending_keys = []
        state.mode = Domain::Mode::CMDLINE
        PluginApi::Response.success("", 0)
      end

      #: (String, String) -> PluginApi::TextResponse
      def icon(name, icon_name)
        glyph = Domain::Icons.glyph(icon_name, @state.options.icons)
        return PluginApi::TextResponse.failure("No icon named #{icon_name}") if glyph.empty?
        PluginApi::TextResponse.success(glyph)
      end

      #: (String, String) -> PluginApi::TextResponse
      def option(name, key)
        e = @registry.find(name)
        value = e.nil? ? nil : e.options[key]
        return PluginApi::TextResponse.failure("No option named #{key}") if value.nil?
        PluginApi::TextResponse.success(value.dup)
      end

      #: (String) -> PluginApi::TextResponse
      def working_directory(name)
        PluginApi::TextResponse.success(@file_ops.cwd.dup)
      end

      #: (String, String) -> PluginApi::Response
      def run_ex(name, text)
        return PluginApi::Response.failure(E169) if @registry.depth >= MAX_DEPTH
        outcome = @runner.call(@state, text)
        PluginApi::Response.new(outcome.ok, outcome.message, 0, [])
      end
    end
  end
end
