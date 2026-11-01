require_relative "../plugins/plugin_host"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # Every plugin.<name>.<action> action: registered for the "plugin."
    # namespace, it hands the action to the plugin host, which runs it in
    # the plugin that declared it or answers why it cannot.
    class PluginActionHandler < ActionHandler
      PREFIX = "plugin."

      attr_reader :plugins #: PluginHost

      #: (plugins: PluginHost) -> void
      def initialize(plugins:)
        super(kind: :action, repeat: false)
        @plugins = plugins
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        @plugins.action(command.action, command)
      end

      #: (ActionTable, plugins: PluginHost) -> void
      def self.register(table, plugins:)
        table.register_namespace(PREFIX, PluginActionHandler.new(plugins: plugins))
      end
    end
  end
end
