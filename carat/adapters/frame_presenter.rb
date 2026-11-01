require_relative "../domain/editor_state"
require_relative "../domain/frame"
require_relative "../domain/highlight"
require_relative "../domain/display_width"
require_relative "../domain/decoded_line"
require_relative "../domain/line_cache"
require_relative "../domain/layout"
require_relative "../domain/selection"
require_relative "../domain/input_state"
require_relative "../domain/plugin_ui"
require_relative "../domain/command_grammar"
require_relative "painted_rows"

module Carat
  module Adapters
    # Draws the editor state into a Frame, reading the state and changing
    # nothing in it: ArrangeView has already laid out the windows and
    # scrolled them for the screen size the state holds. The frame shows
    # the tab line when there is more than one tab page, every window of
    # the current tab page in its rectangle (sign column, line number
    # gutter, text with tabs expanded and unprintable code points as
    # markers, tilde rows, a status line under it with the plugins'
    # segments on the current window's), a separator column between
    # windows side by side, and the message or command line row (a
    # plugin's prompt in place of the colon) with the keys of a pending
    # command at its right edge. In a visual mode the current window draws
    # its selection with the Visual highlight, leaving the cell under the
    # cursor in its own highlight so the cursor shows on top. The cursor is
    # placed in the current window.
    #
    # Two frames are kept and painted in turn, so the one the screen shows
    # stays intact while the other is drawn; they are reallocated only when
    # the size changes. Each keeps a PaintedRows record of what its window
    # rows show, one segment per row and window, so a row is painted only when what it shows differs from
    # what that frame already holds, and is marked dirty when it differs
    # from the frame drawn before. A full-width window whose first visible
    # row moved by less than its height records a scroll, its rows sourced
    # from where they were. The status lines, the tab line, and the message
    # row are painted every time and compared cell by cell. Lines are drawn
    # from the shared line cache, which turns once per frame.
    #
    # A message of several lines is painted over the rows above the
    # message row, its last lines when it is taller than the screen, with
    # the hit-enter line in the message row and the cursor after it; those
    # rows are compared cell by cell like the rest of the chrome, and the
    # frame forgets its layout key and painted rows, so the next frames
    # repaint every window row and are compared in full.
    class FramePresenter
      SHOWCMD_WIDTH = 10
      HIT_ENTER = "Press ENTER or type command to continue"
      SEPARATOR = "│"
      FAR = 1 << 30

      attr_reader :input #: Domain::InputState
      attr_reader :plugin_ui #: Domain::PluginUi
      attr_reader :cache #: Domain::LineCache

      # @rbs @front: Domain::Frame
      # @rbs @back: Domain::Frame
      # @rbs @front_rows: PaintedRows
      # @rbs @back_rows: PaintedRows
      # @rbs @serial: Integer
      # @rbs @key: Array[Integer]
      # @rbs @chrome: Array[Integer]
      # @rbs @sel_from: Integer
      # @rbs @sel_to: Integer
      # @rbs @sel_end: Integer
      # @rbs @none: Domain::Selection
      # @rbs @no_block: Domain::Block

      #: (input: Domain::InputState, plugin_ui: Domain::PluginUi, cache: Domain::LineCache) -> void
      def initialize(input:, plugin_ui:, cache:)
        @input = input
        @plugin_ui = plugin_ui
        @cache = cache
        @front = Domain::Frame.new(1, 1)
        @back = Domain::Frame.new(1, 1)
        @front_rows = PaintedRows.new(rows: 1, slots: 1)
        @back_rows = PaintedRows.new(rows: 1, slots: 1)
        @serial = 0
        @key = []
        @chrome = []
        @sel_from = -1
        @sel_to = -2
        @sel_end = -1
        @none = Domain::Selection.none
        @no_block = Domain::Block.new(0, -1, 1, 0, false)
      end

      #: (Domain::EditorState) -> Domain::Frame
      def call(state)
        rows = state.screen_rows
        cols = state.screen_cols
        ensure_size(rows > 0 ? rows : 1, cols > 0 ? cols : 1)
        return @back if rows <= 0 || cols <= 0
        @cache.turn
        back = @back
        base = @front
        @serial += 1
        back.serial = @serial
        based = base.serial > 0
        back.base_serial = based ? base.serial : -1
        options = state.options
        tabstop = options.tabstop > 0 ? options.tabstop : 8
        tabline = state.tabs.tab_count > 1 ? 1 : 0
        tab = state.tab
        layout = tab.layout
        ids = layout.leaves
        ensure_slots(rows, ids.length)
        build_key(rows, cols, tabline, tabstop, layout, ids)
        unless same_key?(back.layout)
          @back_rows.invalidate
          copy_key(back.layout)
        end
        base_same = based && same_key?(base.layout)
        back.reset_rows
        @chrome.clear

        if tabline == 1
          back.blank(0, 0, cols)
          paint_tabline(back, state, cols)
          @chrome << 0
        end
        visual = Domain::Mode.visual?(state.mode)
        selection = visual ? state.selection : @none
        i = 0
        while i < ids.length
          id = ids[i]
          current = id == tab.current
          paint_window(back, layout.window_at(id), i, current, options, tabstop, @plugin_ui.segments, current ? selection : @none, cols, base_same)
          i += 1
        end
        paint_separators(back, layout, layout.root)
        back.blank(rows - 1, 0, cols)
        paint_message(back, rows - 1, cols, state)
        @chrome << rows - 1
        listed = state.mode != Domain::Mode::CMDLINE && state.list_message?
        paint_list(back, state, rows, cols) if listed
        if base_same
          i = 0
          while i < @chrome.length
            row = @chrome[i]
            back.dirty[row] = 1 unless back.same_row?(row, base, row)
            i += 1
          end
        else
          back.mark_all_dirty
        end
        place_cursor(back, state, options, tabstop, visual, rows, cols)
        if listed
          back.cursor_row = rows - 1
          back.cursor_col = clamp(HIT_ENTER.length, cols - 1)
          back.layout.clear
          @back_rows.invalidate
        end
        swap
        back
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

      # Keeps two frames of the size, allocating both anew when it changes;
      # the new ones have no base.
      #: (Integer, Integer) -> void
      def ensure_size(rows, cols)
        return if @back.rows == rows && @back.cols == cols && @front.rows == rows && @front.cols == cols
        @front = Domain::Frame.new(rows, cols)
        @back = Domain::Frame.new(rows, cols)
        slots = @back_rows.slots
        @front_rows = PaintedRows.new(rows: rows, slots: slots)
        @back_rows = PaintedRows.new(rows: rows, slots: slots)
      end

      # Keeps room for a segment per window on every row, allocating the
      # records anew when there are more windows than slots; the frames'
      # layout keys are dropped so neither counts as painted.
      #: (Integer, Integer) -> void
      def ensure_slots(rows, windows)
        return if windows <= @back_rows.slots
        slots = @back_rows.slots * 2
        slots = windows if slots < windows
        @front_rows = PaintedRows.new(rows: rows, slots: slots)
        @back_rows = PaintedRows.new(rows: rows, slots: slots)
        @front.layout.clear
        @back.layout.clear
      end

      #: () -> void
      def swap
        painted = @back
        @back = @front
        @front = painted
        rows = @back_rows
        @back_rows = @front_rows
        @front_rows = rows
      end

      # The geometry a frame is painted with: the size, the tab line, the
      # tabstop, and every window's rectangle.
      #: (Integer, Integer, Integer, Integer, Domain::Layout, Array[Integer]) -> void
      def build_key(rows, cols, tabline, tabstop, layout, ids)
        key = @key
        key.clear
        key << rows
        key << cols
        key << tabline
        key << tabstop
        i = 0
        while i < ids.length
          window = layout.window_at(ids[i])
          key << window.row
          key << window.col
          key << window.height
          key << window.width
          i += 1
        end
      end

      #: (Array[Integer]) -> bool
      def same_key?(other)
        key = @key
        return false unless other.length == key.length
        i = 0
        while i < key.length
          return false unless other[i] == key[i]
          i += 1
        end
        true
      end

      #: (Array[Integer]) -> void
      def copy_key(target)
        target.clear
        key = @key
        i = 0
        while i < key.length
          target << key[i]
          i += 1
        end
      end

      #: (Integer, Integer) -> Integer
      def clamp(value, max)
        return 0 if value < 0
        value > max ? max : value
      end

      #: (Domain::Frame, Domain::EditorState, Domain::Options, Integer, bool, Integer, Integer) -> void
      def place_cursor(frame, state, options, tabstop, visual, rows, cols)
        if state.mode == Domain::Mode::CMDLINE
          frame.cursor_row = rows - 1
          frame.cursor_col = clamp(display_width(command_prefix(state), tabstop) + display_width(state.cmdline, tabstop), cols - 1)
        else
          window = state.window
          cursor = window.cursor
          gutter = window.gutter_width(options)
          cursor_dcol = @cache.fetch(window.buffer.line(cursor.row), tabstop).col(cursor.col)
          row = clamp(window.row + cursor.row - window.top, rows - 1)
          col = clamp(window.col + gutter + cursor_dcol - window.left, cols - 1)
          frame.cursor_row = row
          frame.cursor_col = col
          frame.set_hl(row, col, Domain::Highlight::NORMAL) if visual && frame.hl_at(row, col) == Domain::Highlight::VISUAL
        end
        frame.cursor_shape = state.mode == Domain::Mode::INSERT ? :bar : :block
      end

      # One window: each text row painted when what it shows changed and
      # marked dirty when it differs from the base frame's, a scroll
      # recorded for a full-width window, then the status line.
      #: (Domain::Frame, Domain::Window, Integer, bool, Domain::Options, Integer, Hash[String, String], Domain::Selection, Integer, bool) -> void
      def paint_window(frame, window, slot, current, options, tabstop, segments, selection, cols, base_same)
        buffer = window.buffer
        cursor = window.cursor
        gutter = window.gutter_width(options)
        width = window.width
        text_width = width - gutter
        text_width = 1 if text_width < 1
        height = window.height
        top = window.top
        left = window.left
        x = window.col
        wrow = window.row
        selecting = selection.kind != :none
        block = selection.kind == :blockwise ? selection.block(buffer, tabstop) : @no_block
        delta = 0
        if base_same && x == 0 && width == cols && height > 1
          first = @front_rows.index(wrow, slot)
          if @front_rows.painted?(first) && @front_rows.owner(first) == window.id
            moved = top - @front_rows.top(first)
            delta = moved if moved != 0 && moved > -height && moved < height
          end
        end
        frame.add_scroll(wrow, wrow + height - 1, delta) if delta != 0
        signs = buffer.signs?
        count = buffer.line_count
        i = 0
        while i < height
          frame_row = wrow + i
          row = top + i
          seg = @back_rows.index(frame_row, slot)
          line = PaintedRows::TILDE
          number = -1
          sign = ""
          cur = -1
          @sel_from = -1
          @sel_to = -2
          @sel_end = -1
          if row < count
            line = buffer.line(row)
            number = number_shown(row, cursor.row, options, gutter, signs)
            sign = buffer.sign_at(row) if signs
            cur = cursor.col if row == cursor.row
            select_columns(selection, buffer, row, line, tabstop, block) if selecting
          end
          unless @back_rows.same?(seg, line, left, width, gutter, number, sign, @sel_from, @sel_to, @sel_end, cur)
            paint_row(frame, frame_row, x, width, gutter, line, number, sign, signs, text_width, left, tabstop)
            @back_rows.store(seg, line, left, width, gutter, number, sign, @sel_from, @sel_to, @sel_end, cur)
          end
          @back_rows.place(seg, window.id, top)
          if base_same
            source = frame_row
            if delta != 0
              j = i + delta
              source = j >= 0 && j < height ? wrow + j : -1
              frame.sources[frame_row] = source
            end
            frame.dirty[frame_row] = 1 if source < 0 || !@front_rows.same?(@front_rows.index(source, slot), line, left, width, gutter, number, sign, @sel_from, @sel_to, @sel_end, cur)
          end
          i += 1
        end
        status_row = wrow + height
        frame.blank(status_row, x, x + width)
        paint_status(frame, status_row, x, width, window, current, segments)
        @chrome << status_row
      end

      # The line number a row shows, -1 when the window has no number
      # column.
      #: (Integer, Integer, Domain::Options, Integer, bool) -> Integer
      def number_shown(row, cursor_row, options, gutter, signs)
        numbers = signs ? gutter - Domain::Window::SIGN_WIDTH : gutter
        return -1 if numbers <= 0
        if options.relativenumber && row != cursor_row
          return row > cursor_row ? row - cursor_row : cursor_row - row
        end
        return 0 if options.relativenumber && !options.number
        row + 1
      end

      # Sets @sel_from and @sel_to, the selected display columns of the
      # row, and @sel_end, the display column of the selected line end or
      # -1: a span's columns, or the block's on a block's row, cut to the
      # line, with the cell after the last character when the line break
      # is selected.
      #: (Domain::Selection, Domain::Buffer, Integer, String, Integer, Domain::Block) -> void
      def select_columns(selection, buffer, row, line, tabstop, block)
        span = selection.span(buffer, row, tabstop)
        return if span.empty?
        decoded = @cache.fetch(line, tabstop)
        line_width = decoded.width
        from = decoded.col(span.from)
        to = decoded.col(span.to) - 1
        if block.top <= block.bottom
          return if line_width < block.left
          from = block.left
          to = block.to_end ? FAR : block.right
          to = line_width - 1 if to > line_width - 1
        end
        to = line_width if span.eol
        @sel_from = from
        @sel_to = to
        @sel_end = span.eol ? line_width : -1
      end

      # One text row of a window, every cell written once: the tilde past
      # the end of the buffer, or the sign column, the number, the text,
      # and blanks between and after, then the selection.
      #: (Domain::Frame, Integer, Integer, Integer, Integer, String, Integer, String, bool, Integer, Integer, Integer) -> void
      def paint_row(frame, frame_row, x, width, gutter, line, number, sign, signs, text_width, left, tabstop)
        if line.equal?(PaintedRows::TILDE)
          frame.blank(frame_row, x, x + width)
          frame.put(frame_row, x, "~", Domain::Highlight::NON_TEXT)
          return
        end
        if gutter > 0
          frame.blank(frame_row, x, x + gutter)
          start = x
          numbers = gutter
          if signs
            frame.fill(frame_row, x, x + Domain::Window::SIGN_WIDTH, Domain::Highlight::LINE_NUMBER)
            shown = sign.length > Domain::Window::SIGN_WIDTH ? sign[0, Domain::Window::SIGN_WIDTH] : sign
            frame.put(frame_row, x, shown, Domain::Highlight::LINE_NUMBER)
            start = x + Domain::Window::SIGN_WIDTH
            numbers = gutter - Domain::Window::SIGN_WIDTH
          end
          if number >= 0
            visible = numbers > width ? width : numbers
            frame.put_number(frame_row, start, numbers - 1, number, visible, Domain::Highlight::LINE_NUMBER)
          end
        end
        decoded = @cache.fetch(line, tabstop)
        paint_text(frame, frame_row, x + gutter, decoded, text_width, left)
        paint_selection(frame, frame_row, x + gutter, text_width, left) if @sel_from <= @sel_to || @sel_end >= 0
      end

      # Paints the visible part of a decoded line from frame column col
      # over width cells: characters whose display columns fall inside
      # [left, left + width), C0 controls as ^X, delete and C1 controls as
      # <xx>, and blanks everywhere else, tabs included.
      #: (Domain::Frame, Integer, Integer, Domain::DecodedLine, Integer, Integer) -> void
      def paint_text(frame, frame_row, col, decoded, width, left)
        if decoded.plain
          paint_plain(frame, frame_row, col, decoded.text, width, left)
          return
        end
        codes = decoded.codes
        cols = decoded.cols
        n = codes.length
        limit = left + width
        filled = col
        k = left > 0 ? decoded.index_at(left) : 0
        while k < n
          dcol = cols[k]
          break if dcol >= limit
          w = cols[k + 1] - dcol
          code = codes[k]
          if dcol >= left && dcol + w <= limit && w > 0 && code != 9
            at = col + dcol - left
            frame.blank(frame_row, filled, at) if at > filled
            if code < 32
              frame.put_code(frame_row, at, 94, 1, Domain::Highlight::NORMAL)
              frame.put_code(frame_row, at + 1, code + 64, 1, Domain::Highlight::NORMAL)
            elsif w == 4 && Domain::DisplayWidth.control?(code)
              frame.put_code(frame_row, at, 60, 1, Domain::Highlight::NORMAL)
              frame.put_code(frame_row, at + 1, hex_digit(code >> 4), 1, Domain::Highlight::NORMAL)
              frame.put_code(frame_row, at + 2, hex_digit(code & 15), 1, Domain::Highlight::NORMAL)
              frame.put_code(frame_row, at + 3, 62, 1, Domain::Highlight::NORMAL)
            else
              frame.put_code(frame_row, at, code, w, Domain::Highlight::NORMAL)
            end
            filled = at + w
          end
          k += 1
        end
        frame.blank(frame_row, filled, col + width) if filled < col + width
      end

      # paint_text for a line of printable ASCII: one cell per byte.
      #: (Domain::Frame, Integer, Integer, String, Integer, Integer) -> void
      def paint_plain(frame, frame_row, col, text, width, left)
        n = text.bytesize
        k = left
        stop = left + width
        stop = n if stop > n
        at = col
        while k < stop
          frame.put_code(frame_row, at, text.getbyte(k).to_i, 1, Domain::Highlight::NORMAL)
          k += 1
          at += 1
        end
        frame.blank(frame_row, at, col + width) if at < col + width
      end

      # The code point of a lowercase hexadecimal digit.
      #: (Integer) -> Integer
      def hex_digit(value)
        value < 10 ? 48 + value : 87 + value
      end

      # Paints the Visual highlight over the selected display columns of a
      # row that paint_text drew, cell by cell so a tab is covered only
      # where selected, and the cell after the last character when the line
      # break is selected.
      #: (Domain::Frame, Integer, Integer, Integer, Integer) -> void
      def paint_selection(frame, frame_row, col, width, left)
        to = @sel_to
        dcol = @sel_from > left ? @sel_from : left
        while dcol <= to && dcol < left + width
          frame.set_hl(frame_row, col + dcol - left, Domain::Highlight::VISUAL)
          dcol += 1
        end
        eol = @sel_end
        return unless eol >= 0 && eol >= left && eol < left + width
        frame.put(frame_row, col + eol - left, " ", Domain::Highlight::VISUAL)
      end

      # The status line of a window across its width: the path, or the
      # scratch title, and the modified marker at the left, the plugins'
      # segments after them on the current window, the cursor and the
      # position at the right when they fit, in the status highlight for
      # the current window and the inactive one otherwise. The pieces are
      # written one after the other and the numbers digit by digit, so a
      # status line costs no string unless plugins have segments.
      #: (Domain::Frame, Integer, Integer, Integer, Domain::Window, bool, Hash[String, String]) -> void
      def paint_status(frame, frame_row, col, width, window, current, segments)
        hl = current ? Domain::Highlight::STATUS : Domain::Highlight::STATUS_NC
        buffer = window.buffer
        name = buffer.display_name
        limit = col + width
        frame.fill(frame_row, col, limit, hl)
        shown = name.nil? ? "[No Name]" : name
        left = shown.length
        at = frame.put_within(frame_row, col, shown, hl, limit)
        if buffer.modified?
          at = frame.put_within(frame_row, at, " [+]", hl, limit)
          left += 4
        end
        if current && !segments.empty?
          joined = segments.values.join(" ")
          at = frame.put_within(frame_row, at, "  ", hl, limit)
          frame.put_within(frame_row, at, joined, hl, limit)
          left += 2 + joined.length
        end
        left = width if left > width
        paint_ruler(frame, frame_row, col, width, window, left, hl)
      end

      # The cursor as row,col and the position, All, Top, Bot, or a
      # percentage, at the right of a status line when they leave a blank
      # after the left part.
      #: (Domain::Frame, Integer, Integer, Integer, Domain::Window, Integer, Integer) -> void
      def paint_ruler(frame, frame_row, col, width, window, left, hl)
        cursor = window.cursor
        row = cursor.row + 1
        column = cursor.col + 1
        count = window.buffer.line_count
        top = window.top
        height = window.height
        word = ""
        percent = -1
        if count <= height
          word = "All"
        elsif top == 0
          word = "Top"
        elsif top + height >= count
          word = "Bot"
        else
          percent = top * 100 / (count - height)
        end
        length = Domain::Frame.digits(row) + Domain::Frame.digits(column) + 2 + (percent >= 0 ? Domain::Frame.digits(percent) + 1 : word.length)
        start = width - length
        return unless start >= left + 1
        at = frame.put_digits(frame_row, col + start, row, hl)
        at = frame.put(frame_row, at, ",", hl)
        at = frame.put_digits(frame_row, at, column, hl)
        at = frame.put(frame_row, at, " ", hl)
        if percent >= 0
          at = frame.put_digits(frame_row, at, percent, hl)
          frame.put(frame_row, at, "%", hl)
        else
          frame.put(frame_row, at, word, hl)
        end
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

      # The lines of a message of several lines over the rows above the
      # message row, the last ones when they do not all fit.
      #: (Domain::Frame, Domain::EditorState, Integer, Integer) -> void
      def paint_list(frame, state, rows, cols)
        lines = state.message.split("\n", -1)
        room = rows - 1
        first = lines.length > room ? lines.length - room : 0
        row = rows - 1 - (lines.length - first)
        hl = state.message_error ? Domain::Highlight::MESSAGE_ERROR : Domain::Highlight::NORMAL
        i = first
        while i < lines.length
          frame.blank(row, 0, cols)
          frame.put(row, 0, lines[i], hl)
          @chrome << row
          row += 1
          i += 1
        end
      end

      #: (Domain::Frame, Integer, Integer, Domain::EditorState) -> void
      def paint_message(frame, frame_row, cols, state)
        if state.mode == Domain::Mode::CMDLINE
          col = frame.put(frame_row, 0, command_prefix(state), Domain::Highlight::NORMAL)
          frame.put(frame_row, col, state.cmdline, Domain::Highlight::NORMAL)
          return
        end
        if state.list_message?
          frame.put(frame_row, 0, HIT_ENTER, Domain::Highlight::NORMAL)
        elsif !state.message.empty?
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
