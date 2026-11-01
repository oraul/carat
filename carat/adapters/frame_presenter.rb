require_relative "../domain/editor_state"
require_relative "../domain/frame"
require_relative "../domain/highlight"
require_relative "../domain/display_width"
require_relative "../domain/layout"
require_relative "../domain/selection"
require_relative "../domain/input_state"
require_relative "../domain/plugin_ui"
require_relative "../domain/command_grammar"

module Carat
  module Adapters
    # A pure function from editor state to a Frame: the tab line when there
    # is more than one tab page, every window of the current tab page in
    # the rectangle the layout gives it (sign column, line number gutter,
    # text with tabs expanded, tilde rows, a status line under it with the
    # plugins' segments on the current window's), a separator column
    # between windows side by side, and the message or command line row
    # (a plugin's prompt in place of the colon) with the keys of a pending
    # command at its right edge. In a visual mode the current window draws
    # its selection with the Visual highlight, leaving the cell under the
    # cursor in its own highlight so the cursor shows on top. It arranges
    # the layout and scrolls every window first so the state and the frame
    # agree, and places the cursor in the current window. The pending keys
    # come from the input state and the segments and the prompt from the
    # plugin UI state.
    class FramePresenter
      SHOWCMD_WIDTH = 10
      SEPARATOR = "│"
      FAR = 1 << 30

      attr_reader :input #: Domain::InputState
      attr_reader :plugin_ui #: Domain::PluginUi

      # @rbs @frame: Domain::Frame?

      #: (input: Domain::InputState, plugin_ui: Domain::PluginUi) -> void
      def initialize(input:, plugin_ui:)
        @input = input
        @plugin_ui = plugin_ui
        @frame = nil
      end

      #: (Domain::EditorState, Integer, Integer) -> Domain::Frame
      def call(state, rows, cols)
        frame = reuse(rows, cols)
        return frame if rows <= 0 || cols <= 0
        options = state.options
        tabstop = options.tabstop > 0 ? options.tabstop : 8
        tabline = state.tabs.tab_count > 1 ? 1 : 0
        area = rows - 1 - tabline
        area = 1 if area < 1
        tab = state.tab
        layout = tab.layout
        layout.arrange(tabline, 0, area, cols)

        paint_tabline(frame, state, cols) if tabline == 1
        visual = Domain::Mode.visual?(state.mode)
        none = Domain::Selection.none
        ids = layout.leaves
        i = 0
        while i < ids.length
          id = ids[i]
          current = id == tab.current
          selection = current && visual ? state.selection : none
          paint_window(frame, layout.window_at(id), current, options, tabstop, @plugin_ui.segments, selection)
          i += 1
        end
        paint_separators(frame, layout, layout.root)
        paint_message(frame, rows - 1, cols, state)

        window = state.window
        cursor = window.cursor
        if state.mode == Domain::Mode::CMDLINE
          frame.cursor_row = rows - 1
          frame.cursor_col = clamp(display_width(command_prefix(state), tabstop) + display_width(state.cmdline, tabstop), cols - 1)
        else
          gutter = window.gutter_width(options)
          cursor_dcol = display_col(window.buffer.line(cursor.row), cursor.col, tabstop)
          frame.cursor_row = clamp(window.row + cursor.row - window.top, rows - 1)
          frame.cursor_col = clamp(window.col + gutter + cursor_dcol - window.left, cols - 1)
          under = frame.cell(frame.cursor_row, frame.cursor_col)
          under.hl = Domain::Highlight::NORMAL if visual && under.hl == Domain::Highlight::VISUAL
        end
        frame.cursor_shape = state.mode == Domain::Mode::INSERT ? :bar : :block
        frame
      end

      # Reuses one frame across renders, reallocating only when the size
      # changes, so a steady stream of renders does not churn the heap with
      # thousands of cell objects each frame.
      #: (Integer, Integer) -> Domain::Frame
      def reuse(rows, cols)
        frame = @frame
        if frame.nil? || frame.rows != rows || frame.cols != cols
          frame = Domain::Frame.new(rows > 0 ? rows : 1, cols > 0 ? cols : 1)
          @frame = frame
        else
          frame.clear
        end
        frame
      end

      # The display column where code-point column col of line starts.
      #: (String, Integer, Integer) -> Integer
      def display_col(line, col, tabstop)
        Domain::DisplayWidth.column(line, col, tabstop)
      end

      #: (String, Integer) -> Integer
      def display_width(text, tabstop)
        display_col(text, text.length, tabstop)
      end

      private

      # Tabs reach the next tabstop, C0 controls take two cells as ^X, and
      # delete and the C1 controls take four as <xx>, matching shown_text.
      #: (String, Integer, Integer) -> Integer
      def char_width(ch, dcol, tabstop)
        Domain::DisplayWidth.cell(ch, dcol, tabstop)
      end

      #: (Integer, Integer) -> Integer
      def clamp(value, max)
        return 0 if value < 0
        value > max ? max : value
      end

      # One window: scrolled to its own cursor, then its gutter, text with
      # the selection when it has one, tilde rows, and status line inside
      # its rectangle.
      #: (Domain::Frame, Domain::Window, bool, Domain::Options, Integer, Hash[String, String], Domain::Selection) -> void
      def paint_window(frame, window, current, options, tabstop, segments, selection)
        buffer = window.buffer
        cursor = window.cursor
        gutter = window.gutter_width(options)
        text_width = window.width - gutter
        text_width = 1 if text_width < 1
        height = window.height
        window.scroll_to_row(cursor.row, buffer.line_count, height, options.scrolloff)
        cursor_dcol = display_col(buffer.line(cursor.row), cursor.col, tabstop)
        window.scroll_to_col(cursor_dcol, text_width)
        block = selection.kind == :blockwise ? selection.block(buffer, tabstop) : Domain::Block.new(0, -1, 1, 0, false)
        i = 0
        while i < height
          frame_row = window.row + i
          row = window.top + i
          if row < buffer.line_count
            line = buffer.line(row)
            paint_gutter(frame, frame_row, window.col, window.width, row, gutter, cursor.row, options, buffer)
            paint_line(frame, frame_row, window.col + gutter, line, text_width, window.left, tabstop)
            paint_selection(frame, frame_row, window.col + gutter, line, text_width, window.left, tabstop, selection.span(buffer, row, tabstop), block)
          else
            frame.put(frame_row, window.col, "~", Domain::Highlight::NON_TEXT)
          end
          i += 1
        end
        paint_status(frame, window.row + height, window.col, window.width, window, current, segments)
      end

      # The sign column, when the buffer has signs, then the number.
      #: (Domain::Frame, Integer, Integer, Integer, Integer, Integer, Integer, Domain::Options, Domain::Buffer) -> void
      def paint_gutter(frame, frame_row, col, width, row, gutter, cursor_row, options, buffer)
        return if gutter == 0
        numbers = gutter
        start = col
        if buffer.signs?
          numbers = gutter - Domain::Window::SIGN_WIDTH
          sign = buffer.sign_at(row)
          sign = sign[0, Domain::Window::SIGN_WIDTH] if sign.length > Domain::Window::SIGN_WIDTH
          frame.fill(frame_row, col, col + Domain::Window::SIGN_WIDTH, Domain::Highlight::LINE_NUMBER)
          frame.put(frame_row, col, sign, Domain::Highlight::LINE_NUMBER)
          start = col + Domain::Window::SIGN_WIDTH
        end
        return if numbers <= 0
        number = row + 1
        if options.relativenumber && row != cursor_row
          number = row > cursor_row ? row - cursor_row : cursor_row - row
        elsif options.relativenumber && !options.number
          number = 0
        end
        text = number.to_s.rjust(numbers - 1) + " "
        text = text[0, width] if text.length > width
        frame.put(frame_row, start, text, Domain::Highlight::LINE_NUMBER)
      end

      # Paints the visible part of a line from frame column col: characters
      # whose display columns fall inside [left, left + width), tabs as
      # blanks, C0 controls as ^X, delete and C1 controls as <xx>.
      #: (Domain::Frame, Integer, Integer, String, Integer, Integer, Integer) -> void
      def paint_line(frame, frame_row, col, line, width, left, tabstop)
        dcol = 0
        i = 0
        while i < line.length
          ch = line[i, 1]
          w = char_width(ch, dcol, tabstop)
          break if dcol >= left + width
          if dcol >= left && dcol + w <= left + width
            shown = shown_text(ch, w)
            frame.put(frame_row, col + dcol - left, shown, Domain::Highlight::NORMAL)
          end
          dcol += w
          i += 1
        end
      end

      # Paints the Visual highlight over the selected part of a line that
      # paint_line drew: the display columns of span, or of the block on a
      # block's row, cell by cell so a tab is covered only where selected,
      # and the cell after the last character when the line break is
      # selected.
      #: (Domain::Frame, Integer, Integer, String, Integer, Integer, Integer, Domain::Span, Domain::Block) -> void
      def paint_selection(frame, frame_row, col, line, width, left, tabstop, span, block)
        return if span.empty?
        line_width = display_col(line, line.length, tabstop)
        from = display_col(line, span.from, tabstop)
        to = display_col(line, span.to, tabstop) - 1
        if block.top <= block.bottom
          return if line_width < block.left
          from = block.left
          to = block.to_end ? FAR : block.right
          to = line_width - 1 if to > line_width - 1
        end
        to = line_width if span.eol
        dcol = from > left ? from : left
        while dcol <= to && dcol < left + width
          frame.cell(frame_row, col + dcol - left).hl = Domain::Highlight::VISUAL
          dcol += 1
        end
        return unless span.eol && line_width >= left && line_width < left + width
        frame.put(frame_row, col + line_width - left, " ", Domain::Highlight::VISUAL)
      end

      #: (String, Integer) -> String
      def shown_text(ch, width)
        return " " * width if ch == "\t"
        code = ch.ord
        return "^" + Domain::Key.char(code + 64) if code < 32
        return "<" + code.to_s(16) + ">" if Domain::DisplayWidth.control?(code)
        ch
      end

      # The status line of a window across its width: the path, or the
      # scratch title, and the modified marker at the left, the plugins'
      # segments after them on the current window, the cursor and the
      # position at the right when they fit, in the status highlight for
      # the current window and the inactive one otherwise.
      #: (Domain::Frame, Integer, Integer, Integer, Domain::Window, bool, Hash[String, String]) -> void
      def paint_status(frame, frame_row, col, width, window, current, segments)
        hl = current ? Domain::Highlight::STATUS : Domain::Highlight::STATUS_NC
        buffer = window.buffer
        name = buffer.display_name
        left = name.nil? ? "[No Name]" : name
        left = left + " [+]" if buffer.modified?
        left = left + "  " + segments.values.join(" ") if current && !segments.empty?
        left = left[0, width] if left.length > width
        cursor = window.cursor
        right = "#{cursor.row + 1},#{cursor.col + 1} #{position_text(window)}"
        frame.fill(frame_row, col, col + width, hl)
        frame.put(frame_row, col, left, hl)
        start = width - right.length
        frame.put(frame_row, col + start, right, hl) if start >= left.length + 1
      end

      #: (Domain::Window) -> String
      def position_text(window)
        count = window.buffer.line_count
        top = window.top
        height = window.height
        return "All" if count <= height
        return "Top" if top == 0
        return "Bot" if top + height >= count
        "#{top * 100 / (count - height)}%"
      end

      # A separator column after every child of a row but the last, over
      # the row's whole height, then the same inside nested splits.
      #: (Domain::Frame, Domain::Layout, Integer) -> void
      def paint_separators(frame, layout, id)
        current = layout.node(id)
        return if current.leaf?
        children = current.children
        i = 0
        while i < children.length
          child = layout.node(children[i])
          if current.kind == :row && i < children.length - 1
            sep = child.col + child.width
            r = current.row
            while r < current.row + current.height
              frame.put(r, sep, SEPARATOR, Domain::Highlight::STATUS)
              r += 1
            end
          end
          paint_separators(frame, layout, children[i])
          i += 1
        end
      end

      # The tab line: one label per tab page with its number, the file name
      # of its current window's buffer, and the modified marker, the current
      # one in the selected highlight, the rest of the row in the fill.
      #: (Domain::Frame, Domain::EditorState, Integer) -> void
      def paint_tabline(frame, state, cols)
        frame.fill(0, 0, cols, Domain::Highlight::TAB_LINE_FILL)
        col = 0
        tabs = state.tabs
        t = 0
        while t < tabs.tab_count
          buffer = tabs.tab_at(t).window.buffer
          label = " #{t + 1} #{file_name(buffer)}#{buffer.modified? ? " [+]" : ""} "
          hl = t == tabs.tab_index ? Domain::Highlight::TAB_LINE_SELECTED : Domain::Highlight::TAB_LINE
          col = frame.put(0, col, label, hl)
          break if col >= cols
          t += 1
        end
      end

      # The last path segment, or [No Name].
      #: (Domain::Buffer) -> String
      def file_name(buffer)
        path = buffer.path
        return "[No Name]" if path.nil?
        slash = path.rindex("/")
        slash.nil? ? path : path[slash + 1, path.length - slash - 1]
      end

      # ":" for an ex command line, a plugin's prompt text while one is open.
      #: (Domain::EditorState) -> String
      def command_prefix(state)
        ui = @plugin_ui
        ui.prompting? ? ui.prompt : ":"
      end

      # The keys of the command being typed, for the pending-keys display:
      # what the grammar has taken plus what the keymap is still waiting on.
      #: () -> String
      def showcmd_text
        input = @input
        text = input.grammar.typed
        keys = input.pending_keys
        i = 0
        while i < keys.length
          text = text + Domain::CommandGrammar.display(keys[i])
          i += 1
        end
        text
      end

      #: (Domain::Frame, Integer, Integer, Domain::EditorState) -> void
      def paint_message(frame, frame_row, cols, state)
        if state.mode == Domain::Mode::CMDLINE
          frame.put(frame_row, 0, command_prefix(state) + state.cmdline, Domain::Highlight::NORMAL)
          return
        end
        if !state.message.empty?
          hl = state.message_error ? Domain::Highlight::MESSAGE_ERROR : Domain::Highlight::NORMAL
          frame.put(frame_row, 0, state.message, hl)
        elsif state.mode == Domain::Mode::INSERT
          frame.put(frame_row, 0, "-- INSERT --", Domain::Highlight::NORMAL)
        elsif state.mode == Domain::Mode::VISUAL
          frame.put(frame_row, 0, "-- VISUAL --", Domain::Highlight::NORMAL)
        elsif state.mode == Domain::Mode::VISUAL_LINE
          frame.put(frame_row, 0, "-- VISUAL LINE --", Domain::Highlight::NORMAL)
        elsif state.mode == Domain::Mode::VISUAL_BLOCK
          frame.put(frame_row, 0, "-- VISUAL BLOCK --", Domain::Highlight::NORMAL)
        end
        showcmd = showcmd_text
        return if showcmd.empty?
        showcmd = showcmd[showcmd.length - SHOWCMD_WIDTH, SHOWCMD_WIDTH] if showcmd.length > SHOWCMD_WIDTH
        start = cols - showcmd.length
        frame.put(frame_row, start, showcmd, Domain::Highlight::NORMAL) if start >= 0
      end
    end
  end
end
