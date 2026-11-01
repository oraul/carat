require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../../domain/ex_command"
require_relative "../outcome"
require_relative "../concerns/guarded"
require_relative "plugin_registry"

module Carat
  module UseCases
    # Routes what the user does to the plugin that owns it: a
    # plugin.<name>.<action> action with the count, register, and cursor
    # of the command, an ex command a plugin declared, and the answer to a
    # prompt a plugin opened. Every call into a plugin is guarded.
    class PluginRouter
      include Guarded

      # @rbs @state: Domain::EditorState
      # @rbs @registry: PluginRegistry

      #: (state: Domain::EditorState, registry: PluginRegistry) -> void
      def initialize(state:, registry:)
        @state = state
        @registry = registry
      end

      # Runs a plugin.<name>.<action> action, with the count and register
      # of the command, in the plugin that owns it; an action no enabled
      # plugin declares is a failure to report.
      #: (String, Domain::Command) -> Outcome
      def action(name, command)
        state = @state
        parts = name.split(".")
        plugin_name = parts.length > 1 ? parts[1] : ""
        e = @registry.find(plugin_name)
        return Outcome.failure("No plugin named #{plugin_name}") if e.nil?
        return Outcome.failure("Plugin #{plugin_name} is disabled") unless e.enabled
        actions = e.manifest.actions
        return Outcome.failure("Plugin #{plugin_name} has no action #{name}") unless actions.is_a?(Hash) && actions.key?(name)
        cursor = state.cursor
        context = PluginApi::Context.new(command.count, command.register, state.buffer.id, state.window_id, state.buffer.path_text.dup, cursor.row, cursor.col)
        guarded(e) { e.plugin.on_action(name, context) }
        Outcome.none
      end

      # Whether an enabled plugin declared the ex command, by name or
      # abbreviation.
      #: (String) -> bool
      def command?(name)
        !@registry.owner_of_command(name).nil?
      end

      # Runs the ex command in the plugin that declared it; the plugin's
      # own messages go through its requests, so the outcome is silent.
      #: (Domain::ExCommand) -> Outcome
      def command(ex_command)
        e = @registry.owner_of_command(ex_command.name)
        return Outcome.failure("E492: Not an editor command: #{ex_command.name}") if e.nil?
        call = PluginApi::Command.new(e.full_command(ex_command.name), ex_command.bang, ex_command.args.dup)
        guarded(e) { e.plugin.on_command(call) }
        Outcome.success("")
      end

      # Ends the open prompt: delivers the text, or a cancel, to the plugin
      # that opened it.
      #: (String, bool) -> void
      def answer(text, cancelled)
        state = @state
        owner = state.prompt_owner
        id = state.prompt_id
        state.prompt = ""
        state.prompt_owner = ""
        state.prompt_id = ""
        e = @registry.find(owner)
        return if e.nil? || !e.enabled
        input = PluginApi::Input.new(id, cancelled ? "" : text.dup, cancelled)
        guarded(e) { e.plugin.on_input(input) }
      end

      private

      # The concern's reader.
      #: () -> PluginRegistry
      def registry
        @registry
      end
    end
  end
end
