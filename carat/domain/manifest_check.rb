require_relative "../plugin_api"
require_relative "keymap"
require_relative "rc_parser"
require_relative "rc_value"

module Carat
  module Domain
    # The rules a plugin manifest must obey before the host registers it.
    # check returns every rule broken, in a fixed order, as one line each
    # without the plugin name, so the host can prefix it; an empty list
    # means the manifest is accepted. The rules that involve other plugins,
    # unique names and ex commands, are the host's.
    module ManifestCheck
      NAME = /\A[a-z][a-z0-9_]*\z/
      ACTION = /\A[a-z0-9_]+\z/
      COMMAND = /\A[A-Z][A-Za-z0-9]*\z/
      API = /\A[0-9]+\.[0-9]+\z/

      # Every member is checked for its type before it is used, so a
      # manifest of the wrong shape is reported rather than raising.
      #: (PluginApi::Manifest) -> Array[String]
      def self.check(manifest)
        problems = []
        name = manifest.name
        unless name.is_a?(String) && manifest.api_version.is_a?(String)
          problems << "name and api_version must be strings"
          return problems
        end
        problems << "name #{name.inspect} is not lowercase letters, digits, and underscores starting with a letter" unless name.match?(NAME)
        problems.concat(check_api(manifest.api_version))
        problems.concat(check_shapes(manifest))
        return problems unless shapes_ok?(manifest)
        problems.concat(check_actions(name, manifest.actions))
        problems.concat(check_commands(manifest.commands))
        problems.concat(check_events(manifest.events))
        problems.concat(check_bindings(manifest.actions, manifest.bindings))
        problems.concat(check_options(name, manifest.options, manifest.option_types))
        problems.concat(check_filetypes(manifest.filetypes))
        problems
      end

      # The members that are not of the type the rules read.
      #: (PluginApi::Manifest) -> Array[String]
      def self.check_shapes(manifest)
        problems = []
        problems << "actions is not an object of action names" unless string_hash?(manifest.actions)
        problems << "commands is not an object of command names" unless string_hash?(manifest.commands)
        problems << "events is not a list of event names" unless manifest.events.is_a?(Array)
        problems << "bindings is not a list of keymap lines" unless string_list?(manifest.bindings)
        problems << "options is not a list of option lines" unless string_list?(manifest.options)
        problems << "option_types is not an object of option types" unless manifest.option_types.is_a?(Hash)
        problems << "filetypes is not a list of filetype names" unless manifest.filetypes.is_a?(Array)
        problems
      end

      # Each filetype is lowercase letters, digits, and underscores
      # starting with a letter, as a plugin name.
      #: (untyped) -> Array[String]
      def self.check_filetypes(filetypes)
        problems = []
        filetypes.each do |type|
          problems << "filetype #{type.inspect} is not lowercase letters, digits, and underscores starting with a letter" unless type.is_a?(String) && type.match?(NAME)
        end
        problems
      end

      #: (PluginApi::Manifest) -> bool
      def self.shapes_ok?(manifest)
        check_shapes(manifest).empty?
      end

      # Whether the value is a list of strings.
      #: (untyped) -> bool
      def self.string_list?(value)
        return false unless value.is_a?(Array)
        value.each { |item| return false unless item.is_a?(String) }
        true
      end

      # Whether the value is a hash from strings to strings.
      #: (untyped) -> bool
      def self.string_hash?(value)
        return false unless value.is_a?(Hash)
        value.each do |key, item|
          return false unless key.is_a?(String) && item.is_a?(String)
        end
        true
      end

      # The refusal of the version, or "" when it is accepted or malformed
      # (malformed is reported by check): a different major, or the host's
      # major with a newer minor, is refused.
      #: (String) -> String
      def self.refusal(api_version)
        return "" unless api_version.match?(API)
        parts = api_version.split(".")
        major = parts[0].to_i
        minor = parts[1].to_i
        return "" if major == PluginApi::MAJOR && minor <= PluginApi::MINOR
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

      #: (String, untyped) -> Array[String]
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

      #: (untyped) -> Array[String]
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

      # Event names are strings; a symbol, as API 1.1 spelled them, is
      # read as its name.
      #: (untyped) -> Array[String]
      def self.check_events(events)
        problems = []
        return problems unless events.is_a?(Array)
        events.each do |event|
          known = (event.is_a?(String) || event.is_a?(Symbol)) && PluginApi::EVENTS.include?(event.to_s)
          problems << "event #{event} is unknown" unless known
        end
        problems
      end

      # The bindings, keymap lines, must bind without errors, and a value
      # that is an action name must be one of the plugin's own actions; a
      # key sequence to replay is accepted as it is.
      #: (untyped, untyped) -> Array[String]
      def self.check_bindings(actions, bindings)
        problems = []
        keymap = Keymap.from_lines(bindings, " ")
        errors = keymap.errors
        i = 0
        while i < errors.length
          problems << "binding #{errors[i]}"
          i += 1
        end
        bindings.each do |item|
          parsed = RcParser.parse(item.to_s)
          next unless parsed.ok? && parsed.key.start_with?("keymap.") && parsed.words.length == 2
          action = parsed.words[1].to_s
          next unless Keymap.action_name?(action)
          problems << "binding #{item.to_s.inspect} names #{action.inspect}, not one of the plugin's actions" unless actions.key?(action)
        end
        problems
      end

      # The options are lines "plugin.<name>.<option> <value>", one per
      # option, each option having a type among OPTION_TYPES, a string or,
      # as API 1.1 spelled it, a symbol, and a default of that type; a line
      # that does not read, one for another plugin, a typed option with no
      # line, and a line with no type are all reported.
      #: (String, untyped, untyped) -> Array[String]
      def self.check_options(name, options, option_types)
        problems = []
        prefix = "plugin.#{name}."
        seen = Keymap.no_actions
        options.each do |item|
          text = item.to_s
          parsed = RcParser.parse(text)
          unless parsed.ok? && !parsed.blank?
            problems << "option line #{text.inspect} does not read: #{parsed.ok? ? "it is empty" : parsed.error}"
            next
          end
          key = parsed.key
          option = key.start_with?(prefix) ? key[prefix.length, key.length - prefix.length].to_s : ""
          if option.empty? || option.include?(".")
            problems << "option line #{text.inspect} is not plugin.#{name}.<option>"
            next
          end
          seen[option] = true
          raw = option_types[option]
          type = raw.nil? ? "" : raw.to_s
          if raw.nil?
            problems << "option #{option.inspect} has no type"
          elsif !PluginApi::OPTION_TYPES.include?(type)
            problems << "option #{option.inspect} has the unknown type #{type}"
          elsif !RcValue.valid?(parsed.words, type)
            problems << "option #{option.inspect} default #{parsed.words.join(" ").inspect} is not a #{type}"
          end
        end
        option_types.each_key do |option|
          problems << "option #{option.to_s.inspect} has a type but no default" unless seen.key?(option.to_s)
        end
        problems
      end
    end
  end
end
