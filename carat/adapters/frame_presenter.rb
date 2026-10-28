require_relative "../domain/editor_state"
require_relative "../domain/frame"
require_relative "../domain/highlight"
require_relative "../domain/display_width"

module Carat
  module Adapters
    # A pure function from editor state to a Frame for one window: line
    # number gutter, text with tabs expanded, tilde rows, the status line,
    # and the message or command line row with the keys of a pending
    # command at its right edge. It records the window height and scrolls
    # the window first so the state and the frame agree.
    class FramePresenter
      SHOWCMD_WIDTH = 10

      # @rbs @frame: Domain::Frame?

      #: () -> void
      def initialize
        @frame = nil
      end

      #: (Domain::EditorState, Integer, Integer) -> Domain::Frame
      def call(state, rows, cols)
        frame = reuse(rows, cols)
        return frame if rows <= 0 || cols <= 0
        height = rows >= 3 ? rows - 2 : 1
        buffer = state.buffer
        options = state.options
        cursor = state.cursor
        window = state.window
        gutter = gutter_width(state)
        text_width = cols - gutter
        text_width = 1 if text_width < 1
        tabstop = options.tabstop > 0 ? options.tabstop : 8

        window.height = height
        window.scroll_to_row(cursor.row, buffer.line_count, height, options.scrolloff)
        cursor_dcol = display_col(buffer.line(cursor.row), cursor.col, tabstop)
        window.scroll_to_col(cursor_dcol, text_width)

        i = 0
        while i < height
          row = window.top + i
          if row < buffer.line_count
            paint_gutter(frame, i, row, gutter, state)
            paint_line(frame, i, buffer.line(row), gutter, text_width, window.left, tabstop)
          else
            frame.put(i, 0, "~", Domain::Highlight::NON_TEXT)
          end
          i += 1
        end

        paint_status(frame, rows - 2, cols, state, height) if rows >= 2
        paint_message(frame, rows - 1, cols, state)

        if state.mode == Domain::Mode::CMDLINE
          frame.cursor_row = rows - 1
          frame.cursor_col = clamp(1 + display_width(state.cmdline, tabstop), cols - 1)
        else
          frame.cursor_row = clamp(cursor.row - window.top, height - 1)
          frame.cursor_col = clamp(gutter + cursor_dcol - window.left, cols - 1)
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

      # The gutter is max(3, digits of the line count) plus one space when
      # numbers are shown, and absent otherwise.
      #: (Domain::EditorState) -> Integer
      def gutter_width(state)
        options = state.options
        return 0 unless options.number || options.relativenumber
        digits = state.buffer.line_count.to_s.length
        digits = 3 if digits < 3
        digits + 1
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

      #: (String, Integer, Integer) -> Integer
      def char_width(ch, dcol, tabstop)
        return tabstop - (dcol % tabstop) if ch == "\t"
        return 2 if ch.ord < 32
        Domain::DisplayWidth.of_char(ch)
      end

      #: (Integer, Integer) -> Integer
      def clamp(value, max)
        return 0 if value < 0
        value > max ? max : value
      end

      #: (Domain::Frame, Integer, Integer, Integer, Domain::EditorState) -> void
      def paint_gutter(frame, frame_row, row, gutter, state)
        return if gutter == 0
        options = state.options
        cursor_row = state.cursor.row
        number = row + 1
        if options.relativenumber && row != cursor_row
          number = row > cursor_row ? row - cursor_row : cursor_row - row
        elsif options.relativenumber && !options.number
          number = 0
        end
        text = number.to_s.rjust(gutter - 1) + " "
        frame.put(frame_row, 0, text, Domain::Highlight::LINE_NUMBER)
      end

      # Paints the visible part of a line: characters whose display columns
      # fall inside [left, left + width), tabs as blanks, controls as ^X.
      #: (Domain::Frame, Integer, String, Integer, Integer, Integer, Integer) -> void
      def paint_line(frame, frame_row, line, gutter, width, left, tabstop)
        dcol = 0
        i = 0
        while i < line.length
          ch = line[i, 1]
          w = char_width(ch, dcol, tabstop)
          break if dcol >= left + width
          if dcol >= left && dcol + w <= left + width
            shown = shown_text(ch, w)
            frame.put(frame_row, gutter + dcol - left, shown, Domain::Highlight::NORMAL)
          end
          dcol += w
          i += 1
        end
      end

      #: (String, Integer) -> String
      def shown_text(ch, width)
        return " " * width if ch == "\t"
        return "^" + Domain::Key.char(ch.ord + 64) if ch.ord < 32
        ch
      end

      #: (Domain::Frame, Integer, Integer, Domain::EditorState, Integer) -> void
      def paint_status(frame, frame_row, cols, state, height)
        buffer = state.buffer
        path = buffer.path
        left = path.nil? ? "[No Name]" : path
        left = left + " [+]" if buffer.modified
        right = "#{state.cursor.row + 1},#{state.cursor.col + 1} #{position_text(state, height)}"
        frame.fill(frame_row, 0, cols, Domain::Highlight::STATUS)
        frame.put(frame_row, 0, left, Domain::Highlight::STATUS)
        start = cols - right.length
        frame.put(frame_row, start, right, Domain::Highlight::STATUS) if start >= left.length + 1
      end

      #: (Domain::EditorState, Integer) -> String
      def position_text(state, height)
        count = state.buffer.line_count
        top = state.window.top
        return "All" if count <= height
        return "Top" if top == 0
        return "Bot" if top + height >= count
        "#{top * 100 / (count - height)}%"
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
