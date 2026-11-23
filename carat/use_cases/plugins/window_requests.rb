require_relative "../../plugin_api"
require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/tab_list"
require_relative "../../domain/buffer"
require_relative "../../domain/keymap"
require_relative "../../domain/position"
require_relative "../../domain/float_spec"
require_relative "../../domain/float_window"
require_relative "../../domain/border_style"
require_relative "../../domain/window"
require_relative "../../domain/messages"
require_relative "../../domain/highlight"
require_relative "../../domain/syntax_line"
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
    # closes only when it opened them, and the frame those floats take.
    # Windows
    # are addressed by id, 0 for the current one, in any tab page. The
    # rules are the core use cases': side windows go through
    # OpenSideWindow, files through OpenFile, SplitWindow, and OpenTab. The plugin link has checked that
    # the plugin is enabled.
    class WindowRequests
      # The longest span a float row keeps: more than any line holds.
      LONGEST_SPAN = 1 << 30
      private_constant :LONGEST_SPAN

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

      # Opens the plugin's scratch buffer with that title in the tab page's
      # slot its side names (OpenSideWindow), or refreshes and focuses the
      # one already shown there; one shown only in another tab page, or
      # kept by a hidden slot, is shown in the slot here too. A new buffer takes the syntax named after
      # the plugin when the plugin tokenizes that filetype.
      #: (String, String, String, Integer, Array[String], untyped) -> PluginApi::WindowResponse
      def open_scratch(name, title, side, width, lines, bindings)
        return PluginApi::WindowResponse.failure("No side #{side}: left, right, or bottom") unless PluginApi::SIDES.include?(side)
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
        if @tabs.total_windows <= 1
          refused = open_file_window(leaf)
          return PluginApi::Response.failure(refused) unless refused.empty?
        end
        @buffers.close_window(@tabs.tab_index, leaf)
        PluginApi::Response.success("", 0)
      end

      # Makes the window current, switching to its tab page first; a
      # float's window is entered when the plugin opened it, and any
      # other float, another plugin's or the completion popup, answers as
      # an unknown id does. Id 0 answers the current window, entering
      # nothing.
      #: (String, Integer) -> PluginApi::WindowResponse
      def focus_window(name, id)
        target = window_or_current(id)
        tab_index = @tabs.window_tab(target)
        if tab_index < 0
          tab_index = id == 0 ? @tabs.float_tab(target) : own_float_tab(name, id)
          return PluginApi::WindowResponse.failure("No window #{id}") if tab_index < 0
          @tabs.tab_index = tab_index
          @tabs.tab.floats.enter(target)
          return PluginApi::WindowResponse.success("", target)
        end
        focus_at(tab_index, target)
        PluginApi::WindowResponse.success("", target)
      end

      # Opens the file in the window as :e would there, then focuses the
      # window: a failed open leaves the focus where it was. The file
      # buffer the window showed stays listed, hidden; the file the
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

      # Opens the file as the tab the top row shows: under option.gt
      # buffers in the editing window as open_file does, a buffer tab;
      # under option.gt tabpages, or with no file window, a tab page.
      #: (String, String) -> PluginApi::WindowResponse
      def open_as_tab(name, path)
        return open_in_tab(name, path) unless @state.options.gt_follows_buffers?
        target = editing_window(name).window
        return open_in_tab(name, path) if target == 0
        open_file(name, target, path)
      end

      # The previously used window when it shows a file buffer, otherwise
      # the first window in layout order that does, 0 when none does.
      #: (String) -> PluginApi::WindowResponse
      def editing_window(name)
        tab = @state.tab
        leaf = tab.editing_leaf
        PluginApi::WindowResponse.success("", leaf < 0 ? 0 : tab.layout.window_at(leaf).id)
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
        why = Domain::FloatSpec.refusal(options.anchor.to_s, options.row.to_i, options.col.to_i, options.height.to_i, options.width.to_i, options.z.to_i)
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

      # Moves the plugin's float to another offset, refused out of range.
      #: (String, Integer, Integer, Integer) -> PluginApi::Response
      def move_float(name, id, row, col)
        why = Domain::FloatSpec.offset_refusal(row, col)
        return PluginApi::Response.failure(why) unless why.empty?
        index = own_float_tab(name, id)
        return PluginApi::Response.failure("No float #{id}") if index < 0
        @tabs.tab_at(index).floats.move(window_or_current(id), row, col)
        PluginApi::Response.success("", 0)
      end

      # Replaces the lines and the title of the plugin's float in place,
      # its cursor, selection anchor, and scroll back at the start, as a
      # reopened float has them; the window id, box, z order, and focus
      # stay. A float switched to a buffer of the list, such as one of
      # the plugin's scratch buffers, is refused: only the unlisted buffer
      # the float was opened with is refilled. The refill drops the
      # float's style, its rows new strings.
      #: (String, Integer, Array[String], String) -> PluginApi::Response
      def set_float_lines(name, id, lines, title)
        index = unlisted_float_tab(name, id)
        return PluginApi::Response.failure("No float #{id}") if index < 0
        float = float_in(index, id)
        window = float.window
        buffer = window.buffer
        replace_lines(buffer, lines)
        shown = String.new(title)
        buffer.title = shown
        float.spec = float.spec.titled(shown)
        window.cursor = Domain::Cursor.new(row: 0, col: 0)
        window.anchor = Domain::Position.new(row: 0, col: 0)
        window.top = 0
        window.left = 0
        float.selected = -1
        buffer.styles = Array.new(0, nil) if buffer.styled?
        PluginApi::Response.success("", 0)
      end

      # Replaces the style of the plugin's float: its selected row, in
      # PmenuSel with the other rows in Pmenu, or -1, and its spans, flat
      # (row, column, length, group) quadruples kept as each row's tokens
      # for that row's string, PmenuMatch on the selected row given as
      # PmenuMatchSel. Everything is checked before anything changes, so a
      # refused request leaves the previous style; the same float as
      # set_float_lines is refused.
      #: (String, Integer, Integer, Array[Integer]) -> PluginApi::Response
      def style_float(name, id, selected, spans)
        index = unlisted_float_tab(name, id)
        return PluginApi::Response.failure("No float #{id}") if index < 0
        float = float_in(index, id)
        buffer = float.window.buffer
        why = style_refusal(buffer.line_count, selected, spans)
        return PluginApi::Response.failure(why) unless why.empty?
        float.selected = selected
        float.style_count += 1
        buffer.styles = spans.empty? ? Array.new(0, nil) : row_styles(buffer, selected, spans)
        PluginApi::Response.success("", 0)
      end

      # Gives the plugin's float a border style of its own, a copy of one
      # of BorderStyle::STYLES, or "" for option.winborder, and a border
      # whatever it opened with; the float is any of the plugin's, as
      # move_float's, since the border belongs to the window. Raising the
      # style count repaints a restyle that keeps the box.
      #: (String, Integer, String) -> PluginApi::Response
      def set_float_border(name, id, style)
        index = own_float_tab(name, id)
        return PluginApi::Response.failure("No float #{id}") if index < 0
        return PluginApi::Response.failure("No border style #{style}: none, single, double, rounded, or solid") unless style.empty? || Domain::BorderStyle.style?(style)
        float = float_in(index, id)
        float.border_style = String.new(style)
        float.spec = float.spec.bordered
        float.style_count += 1
        PluginApi::Response.success("", 0)
      end

      # The frame a float of the plugin would have, bordered or not, under
      # the current border style: its edge, padding, and margin cells.
      #: (String, bool) -> PluginApi::FloatFrame
      def float_frame(name, border)
        edge = border && Domain::BorderStyle.edged?(@state.options.winborder) ? 1 : 0
        PluginApi::FloatFrame.success(edge, Domain::FloatWindow::PAD, Domain::FloatWindow::MARGIN)
      end

      #: (String, Integer) -> PluginApi::Response
      def close_float(name, id)
        return PluginApi::Response.failure("No float #{id}") if own_float_tab(name, id) < 0
        outcome = @close_float.call(@state, window_or_current(id))
        return PluginApi::Response.failure(outcome.message) unless outcome.ok
        PluginApi::Response.success("", 0)
      end

      # Whether the id is a float the plugin opened, never 0 for the
      # current window.
      #: (String, Integer) -> bool
      def holds_float?(name, id)
        id != 0 && own_float_tab(name, id) >= 0
      end

      private

      # Opens a file window beside the scratch window leaf, the editor's
      # last, so closing the scratch window leaves it: it shows the first
      # listed file buffer, or a new empty one, and takes the focus. E36
      # when there is no room for it, "" otherwise.
      #: (Integer) -> String
      def open_file_window(leaf)
        tab = @state.tab
        tab.floats.leave
        id = tab.layout.split(leaf, true, 0, 1)
        return Domain::Messages::E36 if id < 0
        @tabs.adopt(tab.layout.window_at(id))
        tab.layout.window_at(id).unfix_size
        tab.focus(id)
        shown = @buffers.file_at(1)
        @buffers.load(shown.nil? ? Domain::Buffer.from_text("", nil) : shown)
        ""
      end

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

      # The index of the tab page holding the plugin's float with the id,
      # 0 for the current window, when it shows the unlisted buffer the
      # float was opened with; -1 for another plugin's float, a missing
      # one, or one switched to a buffer of the list.
      #: (String, Integer) -> Integer
      def unlisted_float_tab(name, id)
        index = own_float_tab(name, id)
        return -1 if index < 0
        @buffers.index_of(float_in(index, id).window.buffer) >= 0 ? -1 : index
      end

      # The float with the id, 0 for the current window, in the tab page
      # at index, which holds it.
      #: (Integer, Integer) -> Domain::FloatWindow
      def float_in(index, id)
        floats = @tabs.tab_at(index).floats
        floats.at(floats.index_of(window_or_current(id)))
      end

      # Why a style of the selected row and the spans cannot go on a float
      # of count lines, "" when it can.
      #: (Integer, Integer, Array[Integer]) -> String
      def style_refusal(count, selected, spans)
        return "No row #{selected}" if selected < -1 || selected >= count
        return "Spans are row, column, length, and group" if spans.length % 4 != 0
        i = 0
        while i < spans.length
          row = spans[i]
          from = spans[i + 1]
          length = spans[i + 2]
          group = spans[i + 3]
          return "No row #{row}" if row < 0 || row >= count
          return "No span at column #{from} length #{length}" if from < 0 || length < 1
          return "No float group #{group}" unless Domain::Highlight.float_style?(group)
          i += 4
        end
        ""
      end

      # A SyntaxLine per row of the buffer: for a row with spans, one made
      # for the row's own string holding them as (column, length, group)
      # triples in their order, a length cut to LONGEST_SPAN so the
      # painter's column plus length stays small; SyntaxLine::NONE for any
      # other row. The spans are chained per row first, so the work is one
      # pass over the rows and one over the spans.
      #: (Domain::Buffer, Integer, Array[Integer]) -> Array[untyped]
      def row_styles(buffer, selected, spans)
        count = buffer.line_count
        first = Array.new(count, -1)
        after = Array.new(spans.length / 4, -1)
        i = spans.length - 4
        while i >= 0
          row = spans[i]
          after[i / 4] = first[row]
          first[row] = i
          i -= 4
        end
        out = Array.new(0, nil)
        row = 0
        while row < count
          at = first[row]
          if at < 0
            out << Domain::SyntaxLine::NONE
          else
            tokens = Array.new(0, 0)
            while at >= 0
              group = spans[at + 3]
              group = Domain::Highlight::POPUP_MENU_MATCH_SELECTED if row == selected && group == Domain::Highlight::POPUP_MENU_MATCH
              length = spans[at + 2]
              tokens << spans[at + 1]
              tokens << (length > LONGEST_SPAN ? LONGEST_SPAN : length)
              tokens << group
              at = after[at / 4]
            end
            out << Domain::SyntaxLine.new(text: buffer.line(row), start: 0, tokens: tokens, end_state: 0)
          end
          row += 1
        end
        out
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

      # Shows the buffer in the slot the side names through
      # OpenSideWindow: left, right, or bottom.
      #: (Domain::Buffer, String, Integer) -> PluginApi::WindowResponse
      def place_side(buffer, side, width)
        slot = side == "left" ? :left : (side == "right" ? :right : :bottom)
        outcome = @open_side_window.call(@state, buffer, width, slot)
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
