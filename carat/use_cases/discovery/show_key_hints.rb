require_relative "../../domain/editor_state"
require_relative "../../domain/input_state"
require_relative "../../domain/mode"
require_relative "../../domain/keymap"
require_relative "../../domain/keymap_node"
require_relative "../../domain/key_notation"
require_relative "../../domain/key_hints"
require_relative "../../domain/display_width"
require_relative "../../domain/buffer"
require_relative "../../domain/window"
require_relative "../../domain/float_spec"
require_relative "../../domain/float_window"
require_relative "../actions/action_table"
require_relative "../plugins/plugin_host"
require_relative "../windows/open_float"
require_relative "../windows/close_float"

module Carat
  module UseCases
    # Shows the key hints once a waiting prefix has waited keyhints.delay:
    # in normal, visual, and operator-pending mode, when the pending keys
    # lead to a node of the mode's keymap with children, a bordered float
    # titled with the keys and the prefix's group name lists each child's key and what it does (the
    # action's description, its plugin's for a plugin action, the keys a
    # remap replays, or the group name of a prefix, "+" and its count of
    # bindings when unnamed), in columns when taller than the room, at the
    # bottom right of the editor. A hints float already shown is closed
    # first. HideKeyHints closes it on the next key.
    class ShowKeyHints
      Z = 950
      GAP = 2
      private_constant :Z, :GAP

      attr_reader :keymap #: Domain::Keymap
      attr_reader :input #: Domain::InputState
      attr_reader :actions #: ActionTable
      attr_reader :plugins #: PluginHost
      attr_reader :hints #: Domain::KeyHints
      attr_reader :open_float #: OpenFloat
      attr_reader :close_float #: CloseFloat

      #: (keymap: Domain::Keymap, input: Domain::InputState, actions: ActionTable, plugins: PluginHost, hints: Domain::KeyHints, open_float: OpenFloat, close_float: CloseFloat) -> void
      def initialize(keymap:, input:, actions:, plugins:, hints:, open_float:, close_float:)
        @keymap = keymap
        @input = input
        @actions = actions
        @plugins = plugins
        @hints = hints
        @open_float = open_float
        @close_float = close_float
      end

      #: (Domain::EditorState) -> void
      def call(state)
        hints = @hints
        if hints.showing?
          @close_float.call(state, hints.float_id)
          hints.float_id = 0
        end
        mode = state.mode
        return unless mode == Domain::Mode::NORMAL || mode == Domain::Mode::OPERATOR_PENDING || Domain::Mode.visual?(mode)
        keys = @input.pending_keys
        return if keys.empty?
        node = @keymap.node_at(mode, keys)
        return if node.leaf?
        rows = entries(mode, keys, node)
        name = title(keys)
        group = @keymap.group_of(mode, keys)
        name = "#{name} #{group}" unless group.empty?
        open(state, name, rows)
      end

      private

      # One "key  meaning" text per child of the node the keys lead to, in
      # the order bound.
      #: (Symbol, Array[Integer], Domain::KeymapNode) -> Array[String]
      def entries(mode, keys, node)
        rows = []
        children = node.child_keys
        i = 0
        while i < children.length
          code = children[i].to_i
          child = node.child_named(children[i])
          rows << "#{Domain::KeyNotation.format(code)}  #{meaning(child, @keymap.group_of(mode, keys + [code]))}"
          i += 1
        end
        rows
      end

      # What a child means: its group name or the count of its bindings
      # when it is a prefix, else its action's description or its keys.
      #: (Domain::KeymapNode, String) -> String
      def meaning(child, group)
        unless child.leaf?
          return group unless group.empty?
          return "+#{child.binding_count}"
        end
        value = child.value
        return "" if value.nil?
        return value unless Domain::Keymap.action_name?(value)
        text = @actions.describe(value)
        text = @plugins.describe(value) if text.empty?
        text.empty? ? value : text
      end

      #: (Array[Integer]) -> String
      def title(keys)
        text = +""
        i = 0
        while i < keys.length
          text << Domain::KeyNotation.format(keys[i])
          i += 1
        end
        text
      end

      # Lays the entries out in as many columns as the room above the
      # message row needs, leaving out those that do not fit, and opens
      # the float at the bottom right of the editor.
      #: (Domain::EditorState, String, Array[String]) -> void
      def open(state, title, rows)
        room = state.screen_rows - 3
        return if room < 1 || state.screen_cols < 6
        width = 1
        i = 0
        while i < rows.length
          w = Domain::DisplayWidth.text_width(rows[i], 0)
          width = w if w > width
          i += 1
        end
        limit = state.screen_cols - 2
        width = limit if width > limit
        height = rows.length < room ? rows.length : room
        columns = (rows.length + height - 1) / height
        fit = (limit + GAP) / (width + GAP)
        columns = fit if columns > fit
        columns = 1 if columns < 1
        lines = layout(rows, height, columns, width)
        total = columns * width + (columns - 1) * GAP
        spec = Domain::FloatSpec.new(anchor: "editor", row: state.screen_rows, col: state.screen_cols, height: height, width: total, border: true, title: title, z: Z)
        buffer = Domain::Buffer.new(lines: lines, path: nil, line_ending: "\n")
        buffer.owner = Domain::KeyHints::OWNER
        float = Domain::FloatWindow.new(window: Domain::Window.new(buffer: buffer), spec: spec)
        @hints.float_id = float.id if @open_float.call(state, float, false).ok
      end

      # The rows of the float: entry r of each column side by side, each
      # but the last padded to the column width, an entry cut to it.
      #: (Array[String], Integer, Integer, Integer) -> Array[String]
      def layout(rows, height, columns, width)
        lines = []
        r = 0
        while r < height
          line = +""
          c = 0
          while c < columns
            at = c * height + r
            if at < rows.length
              used = Domain::DisplayWidth.text_width(line, 0)
              target = c * (width + GAP)
              line << " " * (target - used) if target > used
              line << Domain::DisplayWidth.cut(rows[at], width)
            end
            c += 1
          end
          lines << line
          r += 1
        end
        lines
      end
    end
  end
end
