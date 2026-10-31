require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../../domain/icons"
require_relative "../../domain/mode"
require_relative "../files/file_ops"
require_relative "plugin_registry"

module Carat
  module UseCases
    # The requests of the plugin API about the editor around the text: a
    # message, the plugin's status segment, a prompt, an icon, the
    # plugin's options, the working directory, and running an ex command
    # line, which is refused with E169 when plugin calls are already
    # nested MAX_DEPTH deep. ExecuteEx is attached after construction
    # because it routes plugin commands to the host while this runs ex
    # command strings through it. The plugin link has checked that the
    # plugin is enabled.
    class UiRequests
      MAX_DEPTH = 4
      E169 = "E169: Command too recursive"

      # @rbs @state: Domain::EditorState
      # @rbs @registry: PluginRegistry
      # @rbs @file_ops: FileOps
      # @rbs @execute_ex: ExecuteEx?

      #: (Domain::EditorState, PluginRegistry, FileOps) -> void
      def initialize(state, registry, file_ops)
        @state = state
        @registry = registry
        @file_ops = file_ops
        @execute_ex = nil
      end

      #: (ExecuteEx) -> void
      def attach(execute_ex)
        @execute_ex = execute_ex
      end

      #: (String, String, bool) -> PluginApi::Response
      def message(name, text, error)
        @state.show(text.dup, error)
        PluginApi::Response.success("", 0)
      end

      #: (String, String) -> PluginApi::Response
      def set_status(name, text)
        if text.empty?
          @state.segments.delete(name)
        else
          @state.segments[name] = text.dup
        end
        PluginApi::Response.success("", 0)
      end

      # Opens a prompt in the command-line row for the plugin.
      #: (String, String, String, String) -> PluginApi::Response
      def prompt(name, id, text, initial)
        state = @state
        return PluginApi::Response.failure("A prompt is already open") if state.prompting?
        state.prompt = text.dup
        state.prompt_owner = name
        state.prompt_id = id.dup
        state.cmdline = initial.dup
        state.pending_keys = []
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
        runner = @execute_ex
        return PluginApi::Response.failure("No ex command runner") if runner.nil?
        outcome = runner.call(@state, text)
        PluginApi::Response.new(outcome.ok, outcome.message, 0, [])
      end
    end
  end
end
