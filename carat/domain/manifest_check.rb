require_relative "../plugin_api"
require_relative "keymap"

module Carat
  module Domain
    # The rules a plugin manifest must obey before the host registers it.
    # check returns every rule broken, in a fixed order, as one line each
    # without the plugin name, so the host can prefix it; an empty list
    # means the manifest is accepted.
    module ManifestCheck
      NAME = /\A[a-z][a-z0-9_]*\z/
      ACTION = /\A[a-z0-9_]+\z/
      COMMAND = /\A[A-Z][A-Za-z0-9]*\z/
      API = /\A[0-9]+\.[0-9]+\z/

      #: (PluginApi::Manifest) -> Array[String]
      def self.check(manifest)
        problems = []
        name = manifest.name
        problems << "name #{name.inspect} is not lowercase letters, digits, and underscores starting with a letter" unless name.match?(NAME)
        problems.concat(check_api(manifest.api_version))
        problems.concat(check_actions(name, manifest.actions))
        problems.concat(check_commands(manifest.commands))
        problems.concat(check_events(manifest.events))
        problems.concat(check_bindings(manifest.actions, manifest.bindings))
        problems.concat(check_options(manifest.options, manifest.option_types))
        problems
      end

      # The refusal of a newer major version, or "" when the version is
      # accepted or malformed (malformed is reported by check).
      #: (String) -> String
      def self.refusal(api_version)
        return "" unless api_version.match?(API)
        major = api_version.split(".")[0].to_i
        return "" if major <= PluginApi::MAJOR
        "needs API #{api_version}, the host has #{PluginApi::VERSION}"
      end

      #: (String) -> Array[String]
      def self.check_api(api_version)
        problems = []
        if api_version.match?(API)
          refused = refusal(api_version)
          problems << refused unless refused.empty?
        else
          problems << "api_version #{api_version.inspect} is not major.minor"
        end
        problems
      end

      #: (String, Hash[String, String]) -> Array[String]
      def self.check_actions(name, actions)
        problems = []
        prefix = "plugin.#{name}."
        actions.each do |action, description|
          rest = action.start_with?(prefix) ? action[prefix.length, action.length - prefix.length] : ""
          problems << "action #{action.inspect} is not plugin.#{name}.<action>" unless action.start_with?(prefix) && rest.match?(ACTION)
          problems << "action #{action.inspect} has no description" if description.empty?
        end
        problems
      end

      #: (Hash[String, String]) -> Array[String]
      def self.check_commands(commands)
        problems = []
        commands.each do |command, abbreviation|
          problems << "command #{command.inspect} does not start with an uppercase letter" unless command.match?(COMMAND)
          unless abbreviation.empty?
            proper = abbreviation.length < command.length && command.start_with?(abbreviation)
            problems << "abbreviation #{abbreviation.inspect} is not a proper prefix of #{command.inspect}" unless proper
          end
        end
        problems
      end

      # The list is untyped because a signature naming Array[Symbol] is
      # not applied by the compiler.
      #: (untyped) -> Array[String]
      def self.check_events(events)
        problems = []
        return problems unless events.is_a?(Array)
        events.each do |event|
          problems << "event #{event} is unknown" unless PluginApi::EVENTS.include?(event)
        end
        problems
      end

      # The bindings must build without errors, and a value that is an
      # action name must be one of the plugin's own actions; a key sequence
      # to replay is accepted as it is.
      #: (Hash[String, String], untyped) -> Array[String]
      def self.check_bindings(actions, bindings)
        problems = []
        return problems if bindings.nil?
        unless bindings.is_a?(Hash)
          problems << "bindings is not an object of modes"
          return problems
        end
        keymap = Keymap.build(bindings, " ")
        errors = keymap.errors
        i = 0
        while i < errors.length
          problems << "binding #{errors[i]}"
          i += 1
        end
        bindings.each do |mode, map|
          next unless map.is_a?(Hash)
          map.each do |key, value|
            next unless value.is_a?(String)
            next unless action_name?(value)
            problems << "binding #{mode}.#{key} names #{value.inspect}, not one of the plugin's actions" unless actions.key?(value)
          end
        end
        problems
      end

      #: (String) -> bool
      def self.action_name?(value)
        value.match?(/\A[a-z0-9_]+(\.[a-z0-9_]+)+\z/)
      end

      # Every option has a type among OPTION_TYPES and a default of that
      # type; a typed option with no default and a default with no type are
      # both reported.
      #: (Hash[String, String], Hash[String, Symbol]) -> Array[String]
      def self.check_options(options, option_types)
        problems = []
        options.each do |name, default|
          type = option_types[name]
          if type.nil?
            problems << "option #{name.inspect} has no type"
          elsif !PluginApi::OPTION_TYPES.include?(type)
            problems << "option #{name.inspect} has the unknown type #{type}"
          elsif !text_of_type?(default, type)
            problems << "option #{name.inspect} default #{default.inspect} is not a #{type}"
          end
        end
        option_types.each_key do |name|
          problems << "option #{name.inspect} has a type but no default" unless options.key?(name)
        end
        problems
      end

      # Whether a text value is a valid representation of the type.
      #: (String, Symbol) -> bool
      def self.text_of_type?(text, type)
        case type
        when :bool then text == "true" || text == "false"
        when :integer then text.match?(/\A-?[0-9]+\z/)
        else true
        end
      end
    end
  end
end
