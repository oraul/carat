require_relative "../../domain/ex_name"
require_relative "../../plugin_api"

module Carat
  module UseCases
    # One registered plugin: the plugin object, its manifest, its name,
    # whether it is enabled, why it is not ("" while it is), the host it
    # receives at activation, its resolved options as text, the events it
    # subscribed to and its option types, both as names (a manifest may
    # spell them as symbols), and its priority, the registration position
    # from 0, which orders its signs. A Struct record: mutable, with a
    # reader and a writer per member.
    class PluginEntry < Struct.new(:plugin, :manifest, :name, :enabled, :reason, :link, :options, :events, :option_types, :priority)
      # @rbs @plugin: PluginApi::Plugin
      # @rbs @manifest: PluginApi::Manifest
      # @rbs @name: String
      # @rbs @enabled: bool
      # @rbs @reason: String
      # @rbs @link: PluginLink?
      # @rbs @options: Hash[String, String]
      # @rbs @events: Array[String]
      # @rbs @option_types: Hash[String, String]
      # @rbs @priority: Integer

      # The collections are stored through the writers after super, so the
      # empty literals take the pinned types. The link is nil until the
      # plugin host gives the entry its own.
      #: (PluginApi::Plugin, PluginApi::Manifest, String, Integer) -> void
      def initialize(plugin, manifest, name, priority)
        super(plugin, manifest, name, true, "", nil)
        self.options = {}
        self.events = []
        self.option_types = {}
        self.priority = priority
      end

      # Whether the plugin subscribed to the event.
      #: (String) -> bool
      def subscribed?(event)
        events.include?(event)
      end

      # Whether the plugin declared the ex command typed as name: its
      # abbreviation, its full name, or a spelling between them.
      #: (String) -> bool
      def command?(name)
        full_command(name) != ""
      end

      # The declared name of the ex command the typed name names, with
      # the same matcher as the core commands (Domain::ExName), the
      # abbreviation standing for the short form; "" when none does. The
      # first command in the manifest's order wins.
      #: (String) -> String
      def full_command(name)
        commands = manifest.commands
        return "" unless commands.is_a?(Hash)
        commands.each do |command, abbreviation|
          full = command.to_s
          short = abbreviation.to_s
          short = full if short.empty?
          return full if Domain::ExName.new(short, full).match?(name)
        end
        ""
      end

      # Reads the manifest's events and option types as names, so a 1.1
      # manifest's symbols and a 1.2 manifest's strings mean the same.
      #: () -> void
      def read_names
        list = []
        given = manifest.events
        if given.is_a?(Array)
          given.each { |event| list << event.to_s }
        end
        self.events = list
        types = {}
        declared = manifest.option_types
        if declared.is_a?(Hash)
          declared.each { |key, type| types[key.to_s] = type.to_s }
        end
        self.option_types = types
      end
    end
  end
end
