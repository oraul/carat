require_relative "../domain/editor_state"
require_relative "../domain/frame"
require_relative "../domain/highlight"
require_relative "../domain/display_width"
require_relative "../domain/layout"

module Carat
  module Adapters
    # A pure function from editor state to a Frame: the tab line when there
    # is more than one tab page, every window of the current tab page in
    # the rectangle the layout gives it (line number gutter, text with tabs
    # expanded, tilde rows, a status line under it), a separator column
    # between windows side by side, and the message or command line row
    # with the keys of a pending command at its right edge. It arranges the
    # layout and scrolls every window first so the state and the frame
    # agree, and places the cursor in the current window.
    class FramePresenter
      SHOWCMD_WIDTH = 10
      SEPARATOR = "│"

      # @rbs @frame: Domain::Frame?

      #: () -> void
      def initialize
        @frame = nil
      end

      #: (Domain::EditorState, Integer, Integer) -> Domain::Frame
      def call(state, rows, cols)
        frame = reuse(rows, cols)
        return frame if rows <= 0 || cols <= 0
        options = state.options
        tabstop = options.tabstop > 0 ? options.tabstop : 8
        tabline = state.tab_count > 1 ? 1 : 0
        area = rows - 1 - tabline
        area = 1 if area < 1
        tab = state.tab
        layout = tab.layout
        layout.arrange(tabline, 0, area, cols)

        paint_tabline(frame, state, cols) if tabline == 1
        ids = layout.leaves
        i = 0
        while i < ids.length
          id = ids[i]
          paint_window(frame, layout.window_at(id), id == tab.current, options, tabstop)
          i += 1
        end
        paint_separators(frame, layout, layout.root)
        paint_message(frame, rows - 1, cols, state)

        window = state.window
        cursor = window.cursor
        if state.mode == Domain::Mode::CMDLINE
          frame.cursor_row = rows - 1
          frame.cursor_col = clamp(1 + display_width(state.cmdline, tabstop), cols - 1)
        else
          gutter = window.gutter_width(options)
          cursor_dcol = display_col(window.buffer.line(cursor.row), cursor.col, tabstop)
          frame.cursor_row = clamp(window.row + cursor.row - window.top, rows - 1)
          frame.cursor_col = clamp(window.col + gutter + cursor_dcol - window.left, cols - 1)
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
        dcol = 0
        i = 0
        while i < col && i < line.length
          dcol += char_width(line[i, 1], dcol, tabstop)
          i += 1
        end
        dcol
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
        return tabstop - (dcol % tabstop) if ch == "\t"
        code = ch.ord
        return 2 if code < 32
        return 4 if Domain::DisplayWidth.control?(code)
        Domain::DisplayWidth.of(code)
      end

      #: (Integer, Integer) -> Integer
      def clamp(value, max)
        return 0 if value < 0
        value > max ? max : value
      end

      # One window: scrolled to its own cursor, then its gutter, text, tilde
      # rows, and status line inside its rectangle.
      #: (Domain::Frame, Domain::Window, bool, Domain::Options, Integer) -> void
      def paint_window(frame, window, current, options, tabstop)
        buffer = window.buffer
        cursor = window.cursor
        gutter = window.gutter_width(options)
        text_width = window.width - gutter
        text_width = 1 if text_width < 1
        height = window.height
        window.scroll_to_row(cursor.row, buffer.line_count, height, options.scrolloff)
        cursor_dcol = display_col(buffer.line(cursor.row), cursor.col, tabstop)
        window.scroll_to_col(cursor_dcol, text_width)
        i = 0
        while i < height
          frame_row = window.row + i
          row = window.top + i
          if row < buffer.line_count
            paint_gutter(frame, frame_row, window.col, window.width, row, gutter, cursor.row, options)
            paint_line(frame, frame_row, window.col + gutter, buffer.line(row), text_width, window.left, tabstop)
          else
            frame.put(frame_row, window.col, "~", Domain::Highlight::NON_TEXT)
          end
          i += 1
        end
        paint_status(frame, window.row + height, window.col, window.width, window, current)
      end

      #: (Domain::Frame, Integer, Integer, Integer, Integer, Integer, Integer, Domain::Options) -> void
      def paint_gutter(frame, frame_row, col, width, row, gutter, cursor_row, options)
        return if gutter == 0
        number = row + 1
        if options.relativenumber && row != cursor_row
          number = row > cursor_row ? row - cursor_row : cursor_row - row
        elsif options.relativenumber && !options.number
          number = 0
        end
        text = number.to_s.rjust(gutter - 1) + " "
        text = text[0, width] if text.length > width
        frame.put(frame_row, col, text, Domain::Highlight::LINE_NUMBER)
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

      #: (String, Integer) -> String
      def shown_text(ch, width)
        return " " * width if ch == "\t"
        code = ch.ord
        return "^" + Domain::Key.char(code + 64) if code < 32
        return "<" + code.to_s(16) + ">" if Domain::DisplayWidth.control?(code)
        ch
      end

      # The status line of a window across its width: the path and the
      # modified marker at the left, the cursor and the position at the
      # right when they fit, in the status highlight for the current window
      # and the inactive one otherwise.
      #: (Domain::Frame, Integer, Integer, Integer, Domain::Window, bool) -> void
      def paint_status(frame, frame_row, col, width, window, current)
        hl = current ? Domain::Highlight::STATUS : Domain::Highlight::STATUS_NC
        buffer = window.buffer
        path = buffer.path
        left = path.nil? ? "[No Name]" : path
        left = left + " [+]" if buffer.modified
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
        t = 0
        while t < state.tab_count
          buffer = state.tab_at(t).window.buffer
          label = " #{t + 1} #{file_name(buffer)}#{buffer.modified ? " [+]" : ""} "
          hl = t == state.tab_index ? Domain::Highlight::TAB_LINE_SELECTED : Domain::Highlight::TAB_LINE
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

      #: (Domain::Frame, Integer, Integer, Domain::EditorState) -> void
      def paint_message(frame, frame_row, cols, state)
        if state.mode == Domain::Mode::CMDLINE
          frame.put(frame_row, 0, ":" + state.cmdline, Domain::Highlight::NORMAL)
          return
        end
        if !state.message.empty?
          hl = state.message_error ? Domain::Highlight::MESSAGE_ERROR : Domain::Highlight::NORMAL
          frame.put(frame_row, 0, state.message, hl)
        elsif state.mode == Domain::Mode::INSERT
          frame.put(frame_row, 0, "-- INSERT --", Domain::Highlight::NORMAL)
        end
        showcmd = state.showcmd
        return if showcmd.empty?
        showcmd = showcmd[showcmd.length - SHOWCMD_WIDTH, SHOWCMD_WIDTH] if showcmd.length > SHOWCMD_WIDTH
        start = cols - showcmd.length
        frame.put(frame_row, start, showcmd, Domain::Highlight::NORMAL) if start >= 0
      end
    end
  end
end
