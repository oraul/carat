require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/keymap"
require_relative "../../domain/manifest_check"
require_relative "../../domain/mode"
require_relative "../windows/close_window"
require_relative "../concerns/guarded"
require_relative "plugin_entry"
require_relative "plugin_entries"

module Carat
  module UseCases
    # The registered plugins and what the host knows of each: registration
    # with every manifest rule, the version, and the uniqueness of names
    # and ex commands, activation from the configuration with the options
    # resolved and the default bindings merged, the refusal of a disabled
    # plugin's requests, and disabling with the cleanup of everything the
    # plugin left in the editor. It also counts the plugin calls in
    # progress and knows the plugin of the innermost one, the cause of
    # whatever happens meanwhile.
    class PluginRegistry
      include Guarded

      # @rbs @state: Domain::EditorState
      # @rbs @keymap: Domain::Keymap
      # @rbs @leader: String
      # @rbs @close_window: CloseWindow
      # @rbs @entries: PluginEntries
      # @rbs @errors: Array[String]
      # @rbs @causes: Array[String]

      #: (Domain::EditorState, Domain::Keymap, String, CloseWindow) -> void
      def initialize(state, keymap, leader, close_window)
        @state = state
        @keymap = keymap
        @leader = leader
        @close_window = close_window
        @entries = PluginEntries.new
        @errors = []
        @causes = []
      end

      #: () -> String
      def leader
        @leader
      end

      #: (Integer) -> PluginEntry
      def entry(i)
        @entries.entry(i)
      end

      #: () -> Integer
      def count
        @entries.count
      end

      #: (String) -> PluginEntry?
      def find(name)
        @entries.find(name)
      end

      # The problems recorded while registering and activating: manifest
      # rules broken, refusals, option values of the wrong type, and
      # binding conflicts.
      #: () -> Array[String]
      def errors
        @errors
      end

      #: (String) -> void
      def record(problem)
        @errors << problem
        nil
      end

      #: (String) -> bool
      def enabled?(name)
        e = find(name)
        e.nil? ? false : e.enabled
      end

      # Why a plugin is disabled, or "" when it is enabled or unknown.
      #: (String) -> String
      def reason(name)
        e = find(name)
        e.nil? ? "" : e.reason
      end

      # The reason a request from the named plugin is refused, "" for none.
      #: (String) -> String
      def refusal(name)
        e = find(name)
        return "No plugin named #{name}" if e.nil?
        e.enabled ? "" : "Plugin #{name} is disabled"
      end

      # The description of an action across the plugins, "" when none
      # declares it.
      #: (String) -> String
      def describe(action)
        i = 0
        while i < count
          actions = entry(i).manifest.actions
          if actions.is_a?(Hash)
            text = actions[action]
            return text if text.is_a?(String) && !text.empty?
          end
          i += 1
        end
        ""
      end

      # The enabled plugin that declared the ex command, by name or
      # abbreviation.
      #: (String) -> PluginEntry?
      def owner_of_command(name)
        i = 0
        while i < count
          e = entry(i)
          return e if e.enabled && e.command?(name)
          i += 1
        end
        nil
      end

      # ------------------------------------------------------------ depth

      # How many plugin calls are in progress, one inside another.
      #: () -> Integer
      def depth
        @causes.length
      end

      #: () -> bool
      def busy?
        !@causes.empty?
      end

      # A call into the named plugin begins: it is the cause of what
      # happens until it ends.
      #: (String) -> void
      def enter(name)
        @causes << name
        @state.feed.cause = name
      end

      #: () -> void
      def leave
        @causes.pop
        @state.feed.cause = @causes.empty? ? "" : @causes[@causes.length - 1]
      end

      # The plugin whose call is the innermost in progress, "" for none.
      #: () -> String
      def cause
        @causes.empty? ? "" : @causes[@causes.length - 1]
      end

      # ----------------------------------------------------- registration

      # Registers a plugin: its manifest is read and checked under the
      # guard, and a manifest that raises, breaks a rule, needs another API
      # version, or repeats a registered name or ex command registers the
      # plugin disabled with the reason. A manifest that raises leaves the
      # plugin named plugin<N>, its position in the list.
      #: (PluginApi::Plugin) -> PluginEntry
      def register(plugin)
        position = count
        placeholder = "plugin#{position + 1}"
        e = PluginEntry.new(plugin, PluginApi::Manifest.new(placeholder, "", "", no_strings, no_strings, nil, [], no_strings, no_strings), placeholder, position)
        given = e.manifest
        read = guarded(e) { given = plugin.manifest }
        if read && given.is_a?(PluginApi::Manifest)
          e.manifest = given
          e.name = given.name if given.name.is_a?(String)
          problem = ""
          checked = guarded(e) { problem = first_problem(e) }
          refuse(e, problem) if checked && !problem.empty?
          e.read_names if checked
        elsif read
          refuse(e, "manifest is not a PluginApi::Manifest")
        end
        @errors << "plugin #{e.name}: #{e.reason}" unless e.enabled
        @entries.add(e)
        e
      end

      # Activates every registered plugin the configuration leaves enabled:
      # resolves its options, merges its default bindings into the keymap
      # below the configuration's, and calls activate with its host.
      # config_plugins is the "plugins" object of the configuration, or
      # anything else for no entries.
      #: (untyped) -> void
      def activate_all(config_plugins)
        i = 0
        while i < count
          e = entry(i)
          if e.enabled
            setting = config_plugins.is_a?(Hash) ? config_plugins[e.name] : nil
            if setting.is_a?(Hash) && setting["enabled"] == false
              e.enabled = false
              e.reason = "disabled in the configuration"
            else
              e.options = resolve_options(e, setting)
              merge_bindings(e)
              link = e.link
              guarded(e) { e.plugin.activate(link) } unless link.nil?
            end
          end
          i += 1
        end
      end

      # Calls deactivate on every enabled plugin, as the editor ends.
      #: () -> void
      def deactivate_all
        i = 0
        while i < count
          e = entry(i)
          guarded(e) { e.plugin.deactivate } if e.enabled
          i += 1
        end
      end

      # ------------------------------------------------------------ disable

      # Disables a plugin that raised: the message row says so, and
      # everything it left in the editor goes, its status segment, its
      # prompt, its signs, its scratch buffers with their windows, and its
      # key bindings.
      #: (PluginEntry, String) -> void
      def disable(e, why)
        e.enabled = false
        e.reason = why
        @state.show("Plugin #{e.name} disabled: #{why}", true)
        clean_up(e.name)
      end

      private

      # The concern's reader: the registry guards its own calls.
      #: () -> PluginRegistry
      def registry
        self
      end

      # An empty table for the placeholder manifest of a plugin whose own
      # has not been read, typed as the manifests' tables are.
      # The table starts with one typed pair, so the compiler types it as
      # the manifests' tables, and is emptied.
      #: () -> Hash[String, String]
      def no_strings
        table = { "" => "" }
        table.clear
        table
      end

      # Registers the entry disabled with the problem as the reason.
      #: (PluginEntry, String) -> void
      def refuse(e, problem)
        e.enabled = false
        e.reason = problem
      end

      # The first rule the entry's manifest breaks, or "".
      #: (PluginEntry) -> String
      def first_problem(e)
        problems = Domain::ManifestCheck.check(e.manifest)
        return problems[0] unless problems.empty?
        return "a plugin named #{e.name} is already registered" if @entries.include?(e.name)
        commands = e.manifest.commands
        commands.each do |command, abbreviation|
          owner = owner_of_command(command)
          owner = owner_of_command(abbreviation) if owner.nil? && !abbreviation.empty?
          return "command #{command} is already declared by plugin #{owner.name}" unless owner.nil?
        end
        ""
      end

      # Adds the plugin's default bindings with the plugin as their owner
      # and records the keys another plugin already holds.
      #: (PluginEntry) -> void
      def merge_bindings(e)
        before = @keymap.conflicts.length
        @keymap.add_owned(e.manifest.bindings, @leader, e.name)
        conflicts = @keymap.conflicts
        i = before
        while i < conflicts.length
          @errors << "plugin #{e.name}: binding #{conflicts[i]}"
          i += 1
        end
      end

      # Removes what the named plugin left in the editor.
      #: (String) -> void
      def clean_up(name)
        state = @state
        state.segments.delete(name)
        if state.prompt_owner == name
          state.prompt = ""
          state.prompt_owner = ""
          state.prompt_id = ""
          state.cmdline = ""
          state.mode = Domain::Mode::NORMAL if state.mode == Domain::Mode::CMDLINE
        end
        i = 0
        while i < state.buffer_count
          state.buffer_at(i).clear_signs(name)
          i += 1
        end
        close_scratch_windows(name)
        i = state.buffer_count - 1
        while i >= 0
          b = state.buffer_at(i)
          state.drop_buffer(b) if b.owner == name
          i -= 1
        end
        @keymap.remove_owner(name)
      end

      # Closes every window of every tab page that shows one of the
      # plugin's scratch buffers; the last window of the editor shows a
      # new empty buffer instead.
      #: (String) -> void
      def close_scratch_windows(name)
        state = @state
        t = state.tab_count - 1
        while t >= 0
          layout = state.tab_at(t).layout
          ids = layout.leaves
          k = ids.length - 1
          while k >= 0
            window = layout.window_at(ids[k])
            if window.buffer.owner == name
              if state.total_windows > 1
                @close_window.remove_in(state, t, ids[k])
              else
                fresh = Domain::Buffer.from_text("", nil)
                state.add_buffer(fresh)
                window.show(fresh)
                window.fixed_width = false
              end
            end
            k -= 1
          end
          t -= 1
          t = state.tab_count - 1 if t > state.tab_count - 1
        end
      end

      # The manifest defaults, with the configuration entry's options of
      # the right type over them; a wrong type or an unknown option is
      # recorded and keeps the default.
      #: (PluginEntry, untyped) -> Hash[String, String]
      def resolve_options(e, setting)
        result = no_strings
        defaults = e.manifest.options
        defaults.each { |key, default| result[key.to_s] = default.to_s } if defaults.is_a?(Hash)
        return result unless setting.is_a?(Hash)
        given = setting["options"]
        return result unless given.is_a?(Hash)
        given.each do |key, value|
          type = e.option_types[key.to_s]
          if type.nil?
            @errors << "plugin #{e.name}: unknown option #{key}"
          elsif option_valid?(value, type)
            result[key.to_s] = option_text(value, type)
          else
            @errors << "plugin #{e.name}: option #{key} must be a #{type}"
          end
        end
        result
      end

      #: (untyped, String) -> bool
      def option_valid?(value, type)
        case type
        when "bool" then value == true || value == false
        when "integer" then value.is_a?(Integer)
        when "string" then value.is_a?(String)
        when "list"
          return false unless value.is_a?(Array)
          value.each { |item| return false unless item.is_a?(String) }
          true
        else false
        end
      end

      #: (untyped, String) -> String
      def option_text(value, type)
        case type
        when "bool" then value == true ? "true" : "false"
        when "integer" then value.to_s
        when "list"
          items = []
          value.each { |item| items << item.to_s }
          items.join("\n")
        else value.to_s
        end
      end
    end
  end
end
