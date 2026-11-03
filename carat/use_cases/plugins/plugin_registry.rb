require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/tab_list"
require_relative "../../domain/plugin_ui"
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

      attr_reader :state #: Domain::EditorState
      attr_reader :buffers #: Domain::BufferList
      attr_reader :tabs #: Domain::TabList
      attr_reader :plugin_ui #: Domain::PluginUi
      attr_reader :keymap #: Domain::Keymap
      attr_reader :close_window #: CloseWindow

      # @rbs @leader: String
      # @rbs @entries: PluginEntries
      # @rbs @errors: Array[String]
      # @rbs @causes: Array[String]

      #: (state: Domain::EditorState, buffers: Domain::BufferList, tabs: Domain::TabList, plugin_ui: Domain::PluginUi, keymap: Domain::Keymap, leader: String, close_window: CloseWindow) -> void
      def initialize(state:, buffers:, tabs:, plugin_ui:, keymap:, leader:, close_window:)
        @state = state
        @buffers = buffers
        @tabs = tabs
        @plugin_ui = plugin_ui
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

      # Every action name the registered plugins declare, enabled or not,
      # in registration order.
      #: () -> Array[String]
      def action_names
        names = []
        i = 0
        while i < count
          actions = entry(i).manifest.actions
          if actions.is_a?(Hash)
            actions.each_key { |key| names << key.to_s }
          end
          i += 1
        end
        names
      end

      # The enabled plugin that declared the ex command, by its name, its
      # abbreviation, or a spelling between them; the first registered wins.
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
        @buffers.feed.cause = name
      end

      #: () -> void
      def leave
        @causes.pop
        @buffers.feed.cause = @causes.empty? ? "" : @causes[@causes.length - 1]
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
        e = PluginEntry.new(plugin: plugin, manifest: PluginApi::Manifest.new(name: placeholder, version: "", api_version: "", actions: no_strings, commands: no_strings, bindings: [], events: [], options: [], option_types: no_strings, filetypes: []), name: placeholder, priority: position)
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
      # below the configuration's, and calls activate with its host. The
      # configuration's plugin lines are checked on the way: one naming no
      # registered plugin, a setting that is not plugin.<name>.<setting>,
      # an option the plugin does not declare, or a value of the wrong
      # kind is noted on the configuration.
      #: (Domain::Config) -> void
      def activate_all(config)
        check_plugin_names(config)
        i = 0
        while i < count
          e = entry(i)
          if e.enabled
            if enabled_in?(config, e)
              e.options = resolve_options(config, e)
              merge_bindings(e)
              link = e.link
              guarded(e) { e.plugin.activate(link) } unless link.nil?
            else
              e.enabled = false
              e.reason = "disabled in the configuration"
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
        @keymap.add_lines(e.manifest.bindings, @leader, e.name)
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
        buffers = @buffers
        if @plugin_ui.prompt_owner == name
          state.cmdline = ""
          state.mode = Domain::Mode::NORMAL if state.mode == Domain::Mode::CMDLINE
        end
        @plugin_ui.drop(name)
        i = 0
        while i < buffers.count
          buffers.buffer_at(i).clear_signs(name)
          i += 1
        end
        close_scratch_windows(name)
        i = buffers.count - 1
        while i >= 0
          b = buffers.buffer_at(i)
          buffers.remove(b) if b.owner == name
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
        tabs = @tabs
        t = tabs.tab_count - 1
        while t >= 0
          layout = tabs.tab_at(t).layout
          ids = layout.leaves
          k = ids.length - 1
          while k >= 0
            window = layout.window_at(ids[k])
            if window.buffer.owner == name
              if tabs.total_windows > 1
                @close_window.remove_in(state, t, ids[k])
              else
                fresh = Domain::Buffer.from_text("", nil)
                @buffers.add(fresh)
                window.show(fresh)
                window.fixed_width = false
              end
            end
            k -= 1
          end
          t -= 1
          t = tabs.tab_count - 1 if t > tabs.tab_count - 1
        end
      end

      # Notes every plugin line whose key is not plugin.<name>.<setting>
      # or whose plugin is not registered, unless the shipped defaults,
      # which name every compiled plugin, hold it.
      #: (Domain::Config) -> void
      def check_plugin_names(config)
        i = 0
        n = config.count
        while i < n
          line = config.line_at(i)
          if line.scope == "plugin"
            name = line.name
            dot = name.index(".")
            if dot.nil? || !name.index(".", dot + 1).nil?
              config.note(line, "unknown setting #{line.key}")
            else
              plugin = name[0, dot].to_s
              config.note(line, "unknown plugin #{plugin}") if find(plugin).nil? && !config.shipped?(line)
            end
          end
          i += 1
        end
      end

      # The setting a configuration line makes for the plugin, the part
      # after "plugin.<name>.", or "" when the line is not the plugin's.
      #: (Domain::RcLine, String) -> String
      def setting_of(line, name)
        return "" unless line.scope == "plugin"
        rest = line.name
        prefix = "#{name}."
        return "" unless rest.start_with?(prefix)
        setting = rest[prefix.length, rest.length - prefix.length].to_s
        setting.include?(".") ? "" : setting
      end

      # Whether the plugin's last good enabled line leaves it enabled, true
      # when no line names it; a line that is not true or false is noted.
      #: (Domain::Config, PluginEntry) -> bool
      def enabled_in?(config, e)
        enabled = true
        i = 0
        n = config.count
        while i < n
          line = config.line_at(i)
          if setting_of(line, e.name) == "enabled"
            if Domain::RcValue.valid?(line.words, "bool")
              enabled = line.words[0] == "true"
            else
              config.note(line, "#{line.key} #{Domain::RcValue.expectation("bool")}")
            end
          end
          i += 1
        end
        enabled
      end

      # The manifest's default option lines, then the configuration's
      # option lines for the plugin in order, as the text the plugin
      # reads; a line naming an option the plugin does not declare or of
      # the wrong kind is noted and keeps the value before it.
      #: (Domain::Config, PluginEntry) -> Hash[String, String]
      def resolve_options(config, e)
        result = no_strings
        types = e.option_types
        defaults = e.manifest.options
        if defaults.is_a?(Array)
          defaults.each do |item|
            parsed = Domain::RcParser.parse(item.to_s)
            next unless parsed.ok? && !parsed.blank?
            setting = setting_of(Domain::RcLine.from_parse("", 0, 0, parsed), e.name)
            kind = types[setting]
            result[setting] = Domain::RcValue.text(parsed.words, kind.to_s) unless kind.nil?
          end
        end
        i = 0
        n = config.count
        while i < n
          line = config.line_at(i)
          setting = setting_of(line, e.name)
          if !setting.empty? && setting != "enabled"
            kind = types[setting]
            if kind.nil?
              config.note(line, "plugin #{e.name} has no option #{setting}")
            elsif Domain::RcValue.valid?(line.words, kind.to_s)
              result[setting] = Domain::RcValue.text(line.words, kind.to_s)
            else
              config.note(line, "#{line.key} #{Domain::RcValue.expectation(kind.to_s)}")
            end
          end
          i += 1
        end
        result
      end
    end
  end
end
