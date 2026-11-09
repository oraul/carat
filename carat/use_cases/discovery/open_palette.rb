require_relative "../../domain/editor_state"
require_relative "../../domain/mode"
require_relative "../../domain/keymap"
require_relative "../../domain/keymap_node"
require_relative "../../domain/key_notation"
require_relative "../../domain/palette"
require_relative "../../domain/plugin_ui"
require_relative "../../domain/search_prompt"
require_relative "../outcome"
require_relative "../actions/action_table"
require_relative "../ex/ex_table"
require_relative "../plugins/plugin_host"

module Carat
  module UseCases
    # <leader>p and <F1>: opens the command palette. Its entries are built
    # once per opening: every core action in registration order, every
    # action of an enabled plugin, then every ex command as ":" and its
    # full name, each with its first normal-mode key in Vim notation (the
    # trie walked in the configuration's order) and its description. The
    # command line opens empty under the palette's prompt; a plugin's or
    # a search prompt that was open is closed. FollowPalette shows the
    # list after the key.
    class OpenPalette
      attr_reader :actions #: ActionTable
      attr_reader :commands #: ExTable
      attr_reader :keymap #: Domain::Keymap
      attr_reader :plugins #: PluginHost
      attr_reader :palette #: Domain::Palette
      attr_reader :plugin_ui #: Domain::PluginUi
      attr_reader :search_prompt #: Domain::SearchPrompt

      #: (actions: ActionTable, commands: ExTable, keymap: Domain::Keymap, plugins: PluginHost, palette: Domain::Palette, plugin_ui: Domain::PluginUi, search_prompt: Domain::SearchPrompt) -> void
      def initialize(actions:, commands:, keymap:, plugins:, palette:, plugin_ui:, search_prompt:)
        @actions = actions
        @commands = commands
        @keymap = keymap
        @plugins = plugins
        @palette = palette
        @plugin_ui = plugin_ui
        @search_prompt = search_prompt
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        palette = @palette
        palette.start
        keys = bound_keys
        names = @actions.names
        i = 0
        while i < names.length
          name = names[i]
          palette.add(name, key_of(keys, name), @actions.describe(name))
          i += 1
        end
        add_plugin_actions(keys)
        full = @commands.full_names
        i = 0
        while i < full.length
          palette.add(":#{full[i]}", "", @commands.describe(full[i]))
          i += 1
        end
        @plugin_ui.close_prompt
        @search_prompt.close
        state.mode = Domain::Mode::CMDLINE
        state.cmdline = ""
        Outcome.none
      end

      private

      # The actions of the enabled plugins, described by their manifests.
      #: (Hash[String, String]) -> void
      def add_plugin_actions(keys)
        names = @plugins.action_names
        i = 0
        while i < names.length
          name = names[i]
          palette_add_plugin(name, keys) if @plugins.enabled?(plugin_of(name))
          i += 1
        end
      end

      #: (String, Hash[String, String]) -> void
      def palette_add_plugin(name, keys)
        @palette.add(name, key_of(keys, name), @plugins.describe(name))
      end

      # The plugin segment of plugin.<name>.<action>, "" for another name.
      #: (String) -> String
      def plugin_of(action)
        parts = action.split(".")
        return "" unless parts.length >= 3 && parts[0] == "plugin"
        parts[1].to_s
      end

      #: (Hash[String, String], String) -> String
      def key_of(keys, name)
        key = keys[name]
        key.nil? ? "" : key
      end

      # The first normal-mode keys of every bound action, by name.
      #: () -> Hash[String, String]
      def bound_keys
        keys = { "" => "" }
        keys.clear
        walk(@keymap.node_at(Domain::Mode::NORMAL, []), "", keys)
      end

      # Records the keys of the node's value and walks its children in
      # the order they were bound; returns the table, which the caller
      # assigns.
      #: (Domain::KeymapNode, String, Hash[String, String]) -> Hash[String, String]
      def walk(node, path, keys)
        value = node.value
        keys[value] = path if !value.nil? && !keys.key?(value)
        children = node.child_keys
        i = 0
        while i < children.length
          child = children[i]
          keys = walk(node.child_named(child), path + Domain::KeyNotation.format(child.to_i), keys)
          i += 1
        end
        keys
      end
    end
  end
end
