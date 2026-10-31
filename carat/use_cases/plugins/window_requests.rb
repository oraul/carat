require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/keymap"
require_relative "../../domain/position"
require_relative "../files/open_file"
require_relative "../files/file_ops"
require_relative "../windows/split_window"
require_relative "../windows/open_tab"
require_relative "../windows/close_window"
require_relative "boundary"
require_relative "plugin_registry"

module Carat
  module UseCases
    # The window requests of the plugin API: scratch buffers in side
    # windows, focusing a window, opening a file in a window, in a split,
    # or in a tab page, and the windows a plugin opens files in. Windows
    # are addressed by id, 0 for the current one, in any tab page. The
    # rules are the core use cases': side windows go through SplitWindow,
    # files through OpenFile and OpenTab. The plugin link has checked that
    # the plugin is enabled.
    class WindowRequests
      E444 = "E444: Cannot close last window"

      # @rbs @state: Domain::EditorState
      # @rbs @registry: PluginRegistry
      # @rbs @open_file: OpenFile
      # @rbs @split_window: SplitWindow
      # @rbs @open_tab: OpenTab
      # @rbs @close_window: CloseWindow
      # @rbs @file_ops: FileOps

      #: (Domain::EditorState, PluginRegistry, OpenFile, SplitWindow, OpenTab, CloseWindow, FileOps) -> void
      def initialize(state, registry, open_file, split_window, open_tab, close_window, file_ops)
        @state = state
        @registry = registry
        @open_file = open_file
        @split_window = split_window
        @open_tab = open_tab
        @close_window = close_window
        @file_ops = file_ops
      end

      # Opens the plugin's scratch buffer with that title in a fixed-width
      # window at the edge of the tab page, or refreshes and focuses the
      # one already shown there; one shown only in another tab page gets a
      # side window here too.
      #: (String, String, String, Integer, Array[String], untyped) -> PluginApi::WindowResponse
      def open_scratch(name, title, side, width, lines, bindings)
        return PluginApi::WindowResponse.failure("No side #{side}: left or right") unless PluginApi::SIDES.include?(side)
        state = @state
        layout = state.tab.layout
        existing = state.scratch_for(name, title)
        unless existing.nil?
          leaf = layout.leaf_showing(existing)
          if leaf >= 0
            replace_lines(existing, lines)
            state.tab.focus(leaf)
            return PluginApi::WindowResponse.success("", layout.window_at(leaf).id)
          end
          if state.shown?(existing)
            replace_lines(existing, lines)
            return place_side(existing, side, width)
          end
          state.drop_buffer(existing)
        end
        buffer = Domain::Buffer.new(Boundary.copied_lines(lines), nil, "\n")
        buffer.owner = name
        buffer.title = title
        keymap = Domain::Keymap.build(bindings, @registry.leader)
        errors = keymap.errors
        i = 0
        while i < errors.length
          @registry.record("plugin #{name}: binding #{errors[i]}")
          i += 1
        end
        buffer.keymap = keymap
        place_side(buffer, side, width)
      end

      #: (String, String, Array[String]) -> PluginApi::Response
      def set_scratch_lines(name, title, lines)
        buffer = @state.scratch_for(name, title)
        return PluginApi::Response.failure("No scratch buffer #{title}") if buffer.nil?
        replace_lines(buffer, lines)
        PluginApi::Response.success("", 0)
      end

      #: (String, String) -> PluginApi::Response
      def close_scratch(name, title)
        state = @state
        buffer = state.scratch_for(name, title)
        leaf = buffer.nil? ? -1 : state.tab.layout.leaf_showing(buffer)
        return PluginApi::Response.failure("No window shows #{title}") if leaf < 0
        return PluginApi::Response.failure(E444) if state.total_windows <= 1
        @close_window.remove(state, leaf)
        PluginApi::Response.success("", 0)
      end

      # Makes the window current, switching to its tab page first.
      #: (String, Integer) -> PluginApi::WindowResponse
      def focus_window(name, id)
        target = window_or_current(id)
        tab_index = @state.window_tab(target)
        return PluginApi::WindowResponse.failure("No window #{id}") if tab_index < 0
        focus_at(tab_index, target)
        PluginApi::WindowResponse.success("", target)
      end

      # Opens the file in the window as :e would there, then focuses the
      # window: a failed open leaves the focus where it was. A modified
      # file buffer the window showed stays listed, hidden; the file the
      # window already shows is left as it is; a side window that takes a
      # file loses its fixed width.
      #: (String, Integer, String) -> PluginApi::WindowResponse
      def open_file(name, id, path)
        state = @state
        target = window_or_current(id)
        tab_index = state.window_tab(target)
        return PluginApi::WindowResponse.failure("No window #{id}") if tab_index < 0
        tab = state.tab_at(tab_index)
        leaf = tab.layout.leaf_of(target)
        window = tab.layout.window_at(leaf)
        old = window.buffer
        own = old.path
        if !own.nil? && !old.scratch? && @file_ops.same_path?(own, path)
          focus_at(tab_index, target)
          return PluginApi::WindowResponse.success("", target)
        end
        outcome = in_window(tab_index, leaf) { @open_file.call(state, path) }
        return PluginApi::WindowResponse.failure(outcome.message) unless outcome.ok
        window.fixed_width = false if old.scratch? && !window.buffer.equal?(old)
        state.add_buffer(old) if old.modified && !old.scratch? && state.buffer_index(old) < 0
        focus_at(tab_index, target)
        PluginApi::WindowResponse.success(outcome.message, target)
      end

      # Splits the window and shows the file, taken as it is, in the new
      # window, which becomes current; with no room the focus stays.
      #: (String, Integer, String, bool) -> PluginApi::WindowResponse
      def open_in_split(name, id, path, vertical)
        state = @state
        target = window_or_current(id)
        tab_index = state.window_tab(target)
        return PluginApi::WindowResponse.failure("No window #{id}") if tab_index < 0
        tab = state.tab_at(tab_index)
        saved_tab = state.tab_index
        saved_current = tab.current
        state.tab_index = tab_index
        tab.current = tab.layout.leaf_of(target)
        outcome = @split_window.call(state, vertical, 0, path, false)
        if tab.current == tab.layout.leaf_of(target)
          tab.current = saved_current
          state.tab_index = saved_tab
        end
        return PluginApi::WindowResponse.failure(outcome.message) unless outcome.ok
        PluginApi::WindowResponse.success(outcome.message, state.window_id)
      end

      # Opens a tab page after the current one showing the file, taken as
      # it is.
      #: (String, String) -> PluginApi::WindowResponse
      def open_in_tab(name, path)
        outcome = @open_tab.call(@state, path)
        return PluginApi::WindowResponse.failure(outcome.message) unless outcome.ok
        PluginApi::WindowResponse.success(outcome.message, @state.window_id)
      end

      # The previously used window when it shows a file buffer, otherwise
      # the first window in layout order that does, 0 when none does.
      #: (String) -> PluginApi::WindowResponse
      def editing_window(name)
        tab = @state.tab
        layout = tab.layout
        if tab.previous? && !layout.window_at(tab.previous).buffer.scratch?
          return PluginApi::WindowResponse.success("", layout.window_at(tab.previous).id)
        end
        ids = layout.leaves
        i = 0
        while i < ids.length
          window = layout.window_at(ids[i])
          return PluginApi::WindowResponse.success("", window.id) unless window.buffer.scratch?
          i += 1
        end
        PluginApi::WindowResponse.success("", 0)
      end

      #: (String, String) -> PluginApi::WindowResponse
      def scratch_window(name, title)
        state = @state
        buffer = state.scratch_for(name, title)
        layout = state.tab.layout
        leaf = buffer.nil? ? -1 : layout.leaf_showing(buffer)
        PluginApi::WindowResponse.success("", leaf < 0 ? 0 : layout.window_at(leaf).id)
      end

      private

      #: (Integer) -> Integer
      def window_or_current(id)
        id == 0 ? @state.window_id : id
      end

      # Makes the window with the id, in the tab page at the index, current.
      #: (Integer, Integer) -> void
      def focus_at(tab_index, id)
        @state.tab_index = tab_index
        tab = @state.tab
        tab.focus(tab.layout.leaf_of(id))
      end

      # Runs the block with the leaf of that tab page standing as the
      # current window, then puts the current tab page and window back.
      # @rbs skip
      def in_window(tab_index, leaf)
        state = @state
        tab = state.tab_at(tab_index)
        saved_tab = state.tab_index
        saved_current = tab.current
        state.tab_index = tab_index
        tab.current = leaf
        result = yield
        tab.current = saved_current
        state.tab_index = saved_tab
        result
      end

      # Adds the side window through SplitWindow.
      #: (Domain::Buffer, String, Integer) -> PluginApi::WindowResponse
      def place_side(buffer, side, width)
        outcome = @split_window.side(@state, buffer, width, side == "left")
        return PluginApi::WindowResponse.failure(outcome.message) unless outcome.ok
        PluginApi::WindowResponse.success("", @state.window_id)
      end

      # Replaces a scratch buffer's lines through Buffer#reload, one
      # change that leaves it unmodified, inside one transaction.
      #: (Domain::Buffer, Array[String]) -> void
      def replace_lines(buffer, lines)
        state = @state
        before = buffer.equal?(state.buffer) ? state.cursor.position : Domain::Position.new(0, 0)
        opened = buffer.begin_transaction(before)
        buffer.reload(Boundary.copied_lines(lines))
        state.clamp_cursors(buffer)
        after = buffer.equal?(state.buffer) ? state.cursor.position : Domain::Position.new(0, 0)
        buffer.commit_transaction(after) if opened
      end
    end
  end
end
