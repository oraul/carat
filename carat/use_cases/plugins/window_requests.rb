require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/tab_list"
require_relative "../../domain/buffer"
require_relative "../../domain/keymap"
require_relative "../../domain/position"
require_relative "../../domain/float_spec"
require_relative "../../domain/float_window"
require_relative "../../domain/window"
require_relative "../files/open_file"
require_relative "../../ports/file_port"
require_relative "../windows/split_window"
require_relative "../windows/open_tab"
require_relative "../windows/open_side_window"
require_relative "../windows/open_float"
require_relative "../windows/close_float"
require_relative "boundary"
require_relative "plugin_registry"

module Carat
  module UseCases
    # The window requests of the plugin API: scratch buffers in side
    # windows, focusing a window, opening a file in a window, in a split,
    # or in a tab page, the windows a plugin opens files in, and floats
    # over the layout (OpenFloat, CloseFloat), which a plugin moves and
    # closes only when it opened them. Windows
    # are addressed by id, 0 for the current one, in any tab page. The
    # rules are the core use cases': side windows go through
    # OpenSideWindow, files through OpenFile, SplitWindow, and OpenTab. The plugin link has checked that
    # the plugin is enabled.
    class WindowRequests
      E444 = "E444: Cannot close last window"
      private_constant :E444

      attr_reader :state #: Domain::EditorState
      attr_reader :buffers #: Domain::BufferList
      attr_reader :tabs #: Domain::TabList
      attr_reader :registry #: PluginRegistry
      attr_reader :split_window #: SplitWindow
      attr_reader :open_tab #: OpenTab
      attr_reader :open_side_window #: OpenSideWindow
      attr_reader :files #: Ports::FilePort

      # open_file, open_float, and close_float are also the names of
      # requests, so they have no reader.
      # @rbs @open_file: OpenFile
      # @rbs @open_float: OpenFloat
      # @rbs @close_float: CloseFloat

      #: (state: Domain::EditorState, buffers: Domain::BufferList, tabs: Domain::TabList, registry: PluginRegistry, open_file: OpenFile, split_window: SplitWindow, open_tab: OpenTab, open_side_window: OpenSideWindow, open_float: OpenFloat, close_float: CloseFloat, files: Ports::FilePort) -> void
      def initialize(state:, buffers:, tabs:, registry:, open_file:, split_window:, open_tab:, open_side_window:, open_float:, close_float:, files:)
        @state = state
        @buffers = buffers
        @tabs = tabs
        @registry = registry
        @open_file = open_file
        @split_window = split_window
        @open_tab = open_tab
        @open_side_window = open_side_window
        @open_float = open_float
        @close_float = close_float
        @files = files
      end

      # Opens the plugin's scratch buffer with that title in a fixed-width
      # window at the edge of the tab page, or refreshes and focuses the
      # one already shown there; one shown only in another tab page gets a
      # side window here too. A new buffer takes the syntax named after
      # the plugin when the plugin tokenizes that filetype.
      #: (String, String, String, Integer, Array[String], untyped) -> PluginApi::WindowResponse
      def open_scratch(name, title, side, width, lines, bindings)
        return PluginApi::WindowResponse.failure("No side #{side}: left or right") unless PluginApi::SIDES.include?(side)
        state = @state
        layout = state.tab.layout
        existing = @buffers.scratch_for(name, title)
        unless existing.nil?
          leaf = layout.leaf_showing(existing)
          if leaf >= 0
            replace_lines(existing, lines)
            state.tab.focus(leaf)
            return PluginApi::WindowResponse.success("", layout.window_at(leaf).id)
          end
          if @tabs.shown?(existing)
            replace_lines(existing, lines)
            return place_side(existing, side, width)
          end
          @buffers.remove(existing)
        end
        buffer = Domain::Buffer.new(lines: Boundary.copied_lines(lines), path: nil, line_ending: "\n")
        buffer.owner = name
        buffer.title = title
        entry = @registry.find(name)
        buffer.syntax = name if !entry.nil? && entry.tokenizes?(name)
        keymap = Domain::Keymap.from_lines(bindings, @registry.leader)
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
        buffer = @buffers.scratch_for(name, title)
        return PluginApi::Response.failure("No scratch buffer #{title}") if buffer.nil?
        replace_lines(buffer, lines)
        PluginApi::Response.success("", 0)
      end

      #: (String, String) -> PluginApi::Response
      def close_scratch(name, title)
        state = @state
        buffer = @buffers.scratch_for(name, title)
        leaf = buffer.nil? ? -1 : state.tab.layout.leaf_showing(buffer)
        return PluginApi::Response.failure("No window shows #{title}") if leaf < 0
        return PluginApi::Response.failure(E444) if @tabs.total_windows <= 1
        @buffers.close_window(@tabs.tab_index, leaf)
        PluginApi::Response.success("", 0)
      end

      # Makes the window current, switching to its tab page first; a
      # float's window is entered.
      #: (String, Integer) -> PluginApi::WindowResponse
      def focus_window(name, id)
        target = window_or_current(id)
        tab_index = @tabs.window_tab(target)
        if tab_index < 0
          tab_index = @tabs.float_tab(target)
          return PluginApi::WindowResponse.failure("No window #{id}") if tab_index < 0
          @tabs.tab_index = tab_index
          @tabs.tab.floats.enter(target)
          return PluginApi::WindowResponse.success("", target)
        end
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
        tab_index = @tabs.window_tab(target)
        return PluginApi::WindowResponse.failure("No window #{id}") if tab_index < 0
        tab = @tabs.tab_at(tab_index)
        leaf = tab.layout.leaf_of(target)
        window = tab.layout.window_at(leaf)
        old = window.buffer
        own = old.path
        if !own.nil? && !old.scratch? && same_path?(own, path)
          focus_at(tab_index, target)
          return PluginApi::WindowResponse.success("", target)
        end
        outcome = in_window(tab_index, leaf) { @open_file.call(state, path) }
        return PluginApi::WindowResponse.failure(outcome.message) unless outcome.ok
        window.unfix_size if old.scratch? && !window.buffer.equal?(old)
        @buffers.add(old) if old.modified? && !old.scratch? && @buffers.index_of(old) < 0
        focus_at(tab_index, target)
        PluginApi::WindowResponse.success(outcome.message, target)
      end

      # Splits the window and shows the file, taken as it is, in the new
      # window, which becomes current; with no room the focus stays.
      #: (String, Integer, String, bool) -> PluginApi::WindowResponse
      def open_in_split(name, id, path, vertical)
        state = @state
        target = window_or_current(id)
        tab_index = @tabs.window_tab(target)
        return PluginApi::WindowResponse.failure("No window #{id}") if tab_index < 0
        tab = @tabs.tab_at(tab_index)
        saved_tab = @tabs.tab_index
        saved_current = tab.current
        @tabs.tab_index = tab_index
        tab.current = tab.layout.leaf_of(target)
        outcome = @split_window.call(state, vertical, 0, path, false)
        if tab.current == tab.layout.leaf_of(target)
          tab.current = saved_current
          @tabs.tab_index = saved_tab
        end
        return PluginApi::WindowResponse.failure(outcome.message) unless outcome.ok
        PluginApi::WindowResponse.success(outcome.message, state.window.id)
      end

      # Opens a tab page after the current one showing the file, taken as
      # it is.
      #: (String, String) -> PluginApi::WindowResponse
      def open_in_tab(name, path)
        outcome = @open_tab.call(@state, path)
        return PluginApi::WindowResponse.failure(outcome.message) unless outcome.ok
        PluginApi::WindowResponse.success(outcome.message, @state.window.id)
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
        buffer = @buffers.scratch_for(name, title)
        layout = state.tab.layout
        leaf = buffer.nil? ? -1 : layout.leaf_showing(buffer)
        PluginApi::WindowResponse.success("", leaf < 0 ? 0 : layout.window_at(leaf).id)
      end

      # Opens a float over the current tab page showing a copy of the
      # lines in a scratch buffer the plugin owns, outside the buffer list.
      #: (String, PluginApi::FloatOptions, Array[String]) -> PluginApi::WindowResponse
      def open_float(name, options, lines)
        why = Domain::FloatSpec.refusal(options.anchor.to_s, options.height.to_i, options.width.to_i, options.z.to_i)
        return PluginApi::WindowResponse.failure(why) unless why.empty?
        buffer = Domain::Buffer.new(lines: Boundary.copied_lines(lines), path: nil, line_ending: "\n")
        buffer.owner = name
        title = String.new(options.title.to_s)
        buffer.title = title
        spec = Domain::FloatSpec.new(anchor: String.new(options.anchor.to_s), row: options.row.to_i, col: options.col.to_i, height: options.height.to_i, width: options.width.to_i, border: options.border == true, title: title, z: options.z.to_i)
        float = Domain::FloatWindow.new(window: Domain::Window.new(buffer: buffer), spec: spec)
        outcome = @open_float.call(@state, float, options.enter == true)
        return PluginApi::WindowResponse.failure(outcome.message) unless outcome.ok
        PluginApi::WindowResponse.success("", float.id)
      end

      #: (String, Integer, Integer, Integer) -> PluginApi::Response
      def move_float(name, id, row, col)
        index = own_float_tab(name, id)
        return PluginApi::Response.failure("No float #{id}") if index < 0
        @tabs.tab_at(index).floats.move(window_or_current(id), row, col)
        PluginApi::Response.success("", 0)
      end

      #: (String, Integer) -> PluginApi::Response
      def close_float(name, id)
        return PluginApi::Response.failure("No float #{id}") if own_float_tab(name, id) < 0
        outcome = @close_float.call(@state, window_or_current(id))
        return PluginApi::Response.failure(outcome.message) unless outcome.ok
        PluginApi::Response.success("", 0)
      end

      private

      # The index of the tab page holding the float with the id, 0 for the
      # current window, when the plugin opened it; -1 otherwise.
      #: (String, Integer) -> Integer
      def own_float_tab(name, id)
        target = window_or_current(id)
        index = @tabs.float_tab(target)
        return -1 if index < 0
        floats = @tabs.tab_at(index).floats
        floats.at(floats.index_of(target)).window.buffer.owner == name ? index : -1
      end

      #: (Integer) -> Integer
      def window_or_current(id)
        id == 0 ? @state.window.id : id
      end

      # Makes the window with the id, in the tab page at the index, current.
      #: (Integer, Integer) -> void
      def focus_at(tab_index, id)
        @tabs.tab_index = tab_index
        tab = @state.tab
        tab.focus(tab.layout.leaf_of(id))
      end

      # Runs the block with the leaf of that tab page standing as the
      # current window, a focused float left for it, then puts the
      # current tab page, window, and float focus back.
      # @rbs skip
      def in_window(tab_index, leaf)
        state = @state
        tab = @tabs.tab_at(tab_index)
        floats = tab.floats
        saved_tab = @tabs.tab_index
        saved_current = tab.current
        saved_float = floats.focused? ? floats.focused.id : -1
        @tabs.tab_index = tab_index
        floats.leave
        tab.current = leaf
        result = yield
        tab.current = saved_current
        floats.enter(saved_float) if saved_float >= 0
        @tabs.tab_index = saved_tab
        result
      end

      # Whether two paths name the same file once resolved against the
      # working directory.
      #: (String, String) -> bool
      def same_path?(a, b)
        here = @files.cwd
        PluginApi::Paths.absolute(here, a) == PluginApi::Paths.absolute(here, b)
      end

      # Adds the side window through OpenSideWindow.
      #: (Domain::Buffer, String, Integer) -> PluginApi::WindowResponse
      def place_side(buffer, side, width)
        outcome = @open_side_window.call(@state, buffer, width, side == "left")
        return PluginApi::WindowResponse.failure(outcome.message) unless outcome.ok
        PluginApi::WindowResponse.success("", @state.window.id)
      end

      # Replaces a scratch buffer's lines through Buffer#reload, one
      # change that leaves it unmodified, inside one transaction, whose
      # close keeps the cursors on the buffer inside the new lines.
      #: (Domain::Buffer, Array[String]) -> void
      def replace_lines(buffer, lines)
        state = @state
        before = buffer.equal?(state.buffer) ? state.cursor.position : Domain::Position.new(row: 0, col: 0)
        opened = buffer.begin_transaction(before)
        buffer.reload(Boundary.copied_lines(lines))
        after = buffer.equal?(state.buffer) ? state.cursor.position : Domain::Position.new(row: 0, col: 0)
        buffer.commit_transaction(after) if opened
      end
    end
  end
end
