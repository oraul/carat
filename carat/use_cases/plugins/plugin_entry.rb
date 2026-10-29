require_relative "../../plugin_api"
require_relative "plugin_link"

module Carat
  module UseCases
    # One registered plugin: the plugin object, its manifest, its name,
    # whether it is enabled, why it is not ("" while it is), the link the
    # host hands it, and its resolved options as text. A Struct record:
    # mutable, with a reader and a writer per member.
    class PluginEntry < Struct.new(:plugin, :manifest, :name, :enabled, :reason, :link, :options)
      # @rbs @plugin: PluginApi::Plugin
      # @rbs @manifest: PluginApi::Manifest
      # @rbs @name: String
      # @rbs @enabled: bool
      # @rbs @reason: String
      # @rbs @link: PluginLink
      # @rbs @options: Hash[String, String]

      # The options are stored through the writer after super, so the
      # empty literal takes the pinned type.
      #: (PluginApi::Plugin, PluginApi::Manifest, String, PluginLink) -> void
      def initialize(plugin, manifest, name, link)
        super(plugin, manifest, name, true, "", link)
        self.options = {}
      end

      # Whether the plugin subscribed to the event.
      #: (Symbol) -> bool
      def subscribed?(event)
        manifest.events.include?(event)
      end

      # Whether the plugin declared the ex command, by name or
      # abbreviation.
      #: (String) -> bool
      def command?(name)
        full_command(name) != ""
      end

      # The declared name of the ex command typed as name or abbreviation,
      # or "".
      #: (String) -> String
      def full_command(name)
        manifest.commands.each do |command, abbreviation|
          return command if command == name
          return command if !abbreviation.empty? && abbreviation == name
        end
        ""
      end
    end
  end
end
