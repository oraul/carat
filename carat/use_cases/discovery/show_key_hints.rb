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
require_relative "hide_key_hints"

module Carat
  module UseCases
    # Shows the key hints once a waiting prefix has waited keyhints.delay:
    # in a mode the grammar reads (Mode.grammar?), when the pending keys
    # lead to a node of the mode's keymap with children, a bordered float
    # titled with the keys and the prefix's group name lists each child's
    # key and what it does (the action's description, its plugin's for a
    # plugin action, the keys a remap replays, or the name of a prefix:
    # its group name, else the first segment every action under it
    # shares, else "group"), in columns when taller than the room, as a
    # panel centered at the bottom of the editor. A hints float already
    # shown is closed first through HideKeyHints, which also closes it on
    # the next key.
    class ShowKeyHints
      Z = 950
      GAP = 2
      UNNAMED = "group"
      private_constant :Z, :GAP, :UNNAMED

      attr_reader :keymap #: Domain::Keymap
      attr_reader :input #: Domain::InputState
      attr_reader :actions #: ActionTable
      attr_reader :plugins #: PluginHost
      attr_reader :hints #: Domain::KeyHints
      attr_reader :open_float #: OpenFloat
      attr_reader :hide_key_hints #: HideKeyHints

      #: (keymap: Domain::Keymap, input: Domain::InputState, actions: ActionTable, plugins: PluginHost, hints: Domain::KeyHints, open_float: OpenFloat, hide_key_hints: HideKeyHints) -> void
      def initialize(keymap:, input:, actions:, plugins:, hints:, open_float:, hide_key_hints:)
        @keymap = keymap
        @input = input
        @actions = actions
        @plugins = plugins
        @hints = hints
        @open_float = open_float
        @hide_key_hints = hide_key_hints
      end

      #: (Domain::EditorState) -> void
      def call(state)
        @hide_key_hints.call(state)
        mode = state.mode
        return unless Domain::Mode.grammar?(mode)
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

      # What a child means: its group name, the segment its actions share,
      # or UNNAMED when it is a prefix, else its action's description or
      # its keys.
      #: (Domain::KeymapNode, String) -> String
      def meaning(child, group)
        unless child.leaf?
          return group unless group.empty?
          shared = segment(child)
          return shared.empty? ? UNNAMED : shared
        end
        value = child.value
        return "" if value.nil?
        return value unless Domain::Keymap.action_name?(value)
        text = @actions.describe(value)
        text = @plugins.describe(value) if text.empty?
        text.empty? ? value : text
      end

      # The first dotted segment every action bound under node shares, ""
      # when they share none or a key sequence is bound under it.
      #: (Domain::KeymapNode) -> String
      def segment(node)
        heads = []
        collect_heads(node, heads)
        return "" if heads.empty?
        first = heads[0].to_s
        i = 1
        while i < heads.length
          return "" unless heads[i] == first
          i += 1
        end
        first
      end

      # Adds to heads the first segment of the action bound at node and
      # under it, "" for a key sequence.
      #: (Domain::KeymapNode, Array[String]) -> void
      def collect_heads(node, heads)
        value = node.value
        unless value.nil?
          dot = value.index(".")
          heads << (Domain::Keymap.action_name?(value) && !dot.nil? ? value[0, dot].to_s : "")
        end
        keys = node.child_keys
        i = 0
        while i < keys.length
          collect_heads(node.child_named(keys[i]), heads)
          i += 1
        end
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
      # message row, less the float margin and the border, needs, leaving
      # out those that do not fit, and opens the float as a panel centered
      # at the bottom of the editor (FloatWindow#centered, so it stays
      # centered after a resize); a screen with no text column left opens none.
      #: (Domain::EditorState, String, Array[String]) -> void
      def open(state, title, rows)
        room = state.screen_rows - 3 - 2 * Domain::FloatWindow::MARGIN
        return if room < 1 || state.screen_cols < 6
        width = 1
        i = 0
        while i < rows.length
          w = Domain::DisplayWidth.text_width(rows[i], 0)
          width = w if w > width
          i += 1
        end
        limit = Domain::FloatWindow.text_room(state.screen_cols, state.options.winborder)
        return if limit < 1
        width = limit if width > limit
        height = rows.length < room ? rows.length : room
        columns = (rows.length + height - 1) / height
        fit = (limit + GAP) / (width + GAP)
        columns = fit if columns > fit
        columns = 1 if columns < 1
        lines = layout(rows, height, columns, width)
        total = columns * width + (columns - 1) * GAP
        spec = Domain::FloatSpec.new(anchor: "editor", row: state.screen_rows, col: 0, height: height, width: total, border: true, title: title, z: Z)
        buffer = Domain::Buffer.new(lines: lines, path: nil, line_ending: "\n")
        buffer.owner = Domain::KeyHints::OWNER
        float = Domain::FloatWindow.new(window: Domain::Window.new(buffer: buffer), spec: spec)
        float.centered = true
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
