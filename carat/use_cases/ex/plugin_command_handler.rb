require_relative "../../domain/editor_state"
require_relative "../plugins/plugin_host"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # The ex commands plugins declare: registered last, with no name of
    # its own, it matches a typed name an enabled plugin declares, from
    # the command's abbreviation to its full name, and runs it in the
    # first such plugin.
    class PluginCommandHandler < ExHandler
      # @rbs @plugins: PluginHost

      #: (plugins: PluginHost) -> void
      def initialize(plugins:)
        super(spec: "")
        @plugins = plugins
      end

      # @rbs typed: String
      def matches?(typed)
        @plugins.command?(typed)
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        @plugins.command(command)
      end

      #: (ExTable, plugins: PluginHost) -> void
      def self.register(table, plugins:)
        table.register(PluginCommandHandler.new(plugins: plugins))
      end
    end
  end
end
