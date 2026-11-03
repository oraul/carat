require_relative "../../domain/ex_name"
require_relative "../../plugin_api"

module Carat
  module UseCases
    # One registered plugin: the plugin object, its manifest, its name,
    # whether it is enabled, why it is not ("" while it is), the host it
    # receives at activation, its resolved options as text, the events it
    # subscribed to and its option types, both as names (a manifest may
    # spell them as symbols), and its priority, the registration position
    # from 0, which orders its signs, and the filetypes it tokenizes. A
    # Struct record: mutable, with a reader and a writer per member.
    class PluginEntry < Struct.new(:plugin, :manifest, :name, :enabled, :reason, :link, :options, :events, :option_types, :priority, :filetypes, keyword_init: true)
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
      # @rbs @filetypes: Array[String]

      # Every member is stored through its writer after super(), so the
      # empty literals take the pinned types. The link is nil until the
      # plugin host gives the entry its own.
      #: (plugin: PluginApi::Plugin, manifest: PluginApi::Manifest, name: String, priority: Integer) -> void
      def initialize(plugin:, manifest:, name:, priority:)
        super()
        self.plugin = plugin
        self.manifest = manifest
        self.name = name
        self.enabled = true
        self.reason = ""
        self.link = nil
        self.options = {}
        self.events = []
        self.option_types = {}
        self.priority = priority
        self.filetypes = []
      end

      # Whether the plugin tokenizes the filetype.
      #: (String) -> bool
      def tokenizes?(filetype)
        filetypes.include?(filetype)
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
          return full if Domain::ExName.new(short: short, full: full).match?(name)
        end
        ""
      end

      # Reads the manifest's events and option types as names, so a 1.1
      # manifest's symbols and a 1.2 manifest's strings mean the same, and
      # its filetypes.
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
        types_list = []
        declared_types = manifest.filetypes
        if declared_types.is_a?(Array)
          declared_types.each { |type| types_list << type.to_s }
        end
        self.filetypes = types_list
      end
    end
  end
end
