require_relative "../domain/editor_state"
require_relative "../domain/frame"
require_relative "../domain/text_lines"
require_relative "../domain/highlight"
require_relative "../domain/display_width"
require_relative "../domain/decoded_line"
require_relative "../domain/line_cache"
require_relative "../domain/syntax_line"
require_relative "../domain/layout"
require_relative "../domain/selection"
require_relative "../domain/input_state"
require_relative "../domain/plugin_ui"
require_relative "../domain/command_grammar"
require_relative "../domain/last_search"
require_relative "../domain/search_prompt"
require_relative "../domain/palette"
require_relative "../domain/search"
require_relative "../domain/search_budget"
require_relative "../domain/search_pattern"
require_relative "../domain/start_screen"
require_relative "painted_rows"
require_relative "status_bar"
require_relative "tab_bar"

module Carat
  module Adapters
    # Draws the editor state into a Frame, reading the state and changing
    # nothing in it: ArrangeView has already laid out the windows and
    # scrolled them for the screen size the state holds. The frame shows
    # the buffer tabs on the top row when two file buffers are listed or
    # two tab pages exist (TabBar), every window of the current tab page
    # in its rectangle (sign column, line number gutter, text with tabs
    # expanded and unprintable code points as markers, tilde rows), a
    # separator row under each window above another and a separator
    # column between windows side by side, both in WinSeparator, the one
    # status bar of the current window on the row above the last
    # (StatusBar), and the message or command line row (a
    # plugin's prompt in place of the colon) with the keys of a pending
    # command at its right edge. In a visual mode the current window draws
    # its selection with the Visual highlight, leaving the cell under the
    # cursor in its own highlight (its token's group or the normal one)
    # so the cursor shows on top. With hlsearch the matches of the last
    # search, or of the pattern a search prompt previews, are drawn in the
    # Search group after the tokens and the previewed match in IncSearch;
    # a frame's matching runs under its own budget and stops highlighting
    # rows when it is spent, and a row records the last search's stamp, 0
    # when nothing is highlighted, so a frame without search does no
    # other work. With cursorline the cursor's row of the current window
    # is lifted onto the cursor-line layer of groups from the end of its
    # gutter to its right edge, its number in CursorLineNr, the layer
    # being an input of the row like its cursor column. The cursor is
    # placed in the current window, a bar in insert mode, an underline in
    # replace mode, and a block otherwise.
    #
    # Two frames are kept and painted in turn, so the one the screen shows
    # stays intact while the other is drawn; they are reallocated only when
    # the size changes. Each keeps a PaintedRows record of what its window
    # rows show, one segment per row and window, so a row is painted only when what it shows differs from
    # what that frame already holds, and is marked dirty when it differs
    # from the frame drawn before. A full-width window whose first visible
    # row moved by less than its height records a scroll, its rows sourced
    # from where they were. The separator rows, the status bar, the tab
    # row, and the message row are painted every time and compared cell
    # by cell. Lines are drawn
    # from the shared line cache, which turns once per frame.
    #
    # A message of several lines is painted over the rows above the
    # message row, its last lines when it is taller than the screen, with
    # the hit-enter line in the message row and the cursor after it; those
    # rows are compared cell by cell like the rest of the chrome, and the
    # frame forgets its layout key and painted rows, so the next frames
    # repaint every window row and are compared in full.
    #
    # The floating windows of the tab page are painted last, by z, over
    # the windows, the status bar, and the start screen: their text in
    # NormalFloat (a menu's in Pmenu, its selected row in PmenuSel), a
    # rounded border in FloatBorder with the title in
    # Title. A frame keeps the boxes it was painted with; when they
    # differ from the ones to paint, the frame forgets the window rows the
    # old boxes covered, so those are repainted, and every row a box
    # covers in this frame or in the frame shown is compared cell by cell.
    # A window under any of those boxes records no scroll. With no float
    # in the tab page or either frame none of this runs.
    #
    # While the start screen shows, its frame is painted over the current
    # window's text rows after the windows, and the frame forgets its
    # layout key and painted rows the same way, so the start frames are
    # compared in full and the first frame after them repaints the window.
    class FramePresenter
      SHOWCMD_WIDTH = 10
      HIT_ENTER = "Press ENTER or type command to continue"
      SEPARATOR = "│"
      PALETTE_PROMPT = ">"
      ROW_SEPARATOR = "─"
      FAR = 1 << 30
      FLOAT_STRIDE = 10

      attr_reader :input #: Domain::InputState
      attr_reader :plugin_ui #: Domain::PluginUi
      attr_reader :cache #: Domain::LineCache
      attr_reader :last_search #: Domain::LastSearch
      attr_reader :search_prompt #: Domain::SearchPrompt
      attr_reader :palette #: Domain::Palette
      attr_reader :start_screen #: Domain::StartScreen
      attr_reader :status_bar #: StatusBar
      attr_reader :tab_bar #: TabBar

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
      # @rbs @budget: Domain::SearchBudget
      # @rbs @pattern: Domain::SearchPattern
      # @rbs @drawn: Integer
      # @rbs @row_of: Integer
      # @rbs @current: bool
      # @rbs @number_hl: Integer
      # @rbs @float_key: Array[Integer]
      # @rbs @floating: bool
      # @rbs @repainted: Array[Integer]

      #: (input: Domain::InputState, plugin_ui: Domain::PluginUi, cache: Domain::LineCache, last_search: Domain::LastSearch, search_prompt: Domain::SearchPrompt, palette: Domain::Palette, start_screen: Domain::StartScreen, status_bar: StatusBar, tab_bar: TabBar) -> void
      def initialize(input:, plugin_ui:, cache:, last_search:, search_prompt:, palette:, start_screen:, status_bar:, tab_bar:)
        @palette = palette
        @input = input
        @plugin_ui = plugin_ui
        @cache = cache
        @last_search = last_search
        @search_prompt = search_prompt
        @start_screen = start_screen
        @status_bar = status_bar
        @tab_bar = tab_bar
        @budget = Domain::SearchBudget.new(left: Domain::SearchBudget::FRAME)
        @pattern = Domain::SearchPattern.none
        @drawn = 0
        @row_of = -1
        @current = false
        @number_hl = Domain::Highlight::LINE_NUMBER
        @float_key = []
        @floating = false
        @repainted = [1]
        @front = Domain::Frame.new(rows: 1, cols: 1)
        @back = Domain::Frame.new(rows: 1, cols: 1)
        @front_rows = PaintedRows.new(rows: 1, slots: 1)
        @back_rows = PaintedRows.new(rows: 1, slots: 1)
        @serial = 0
        @key = []
        @chrome = []
        @sel_from = -1
        @sel_to = -2
        @sel_end = -1
        @none = Domain::Selection.none
        @no_block = Domain::Block.new(top: 0, bottom: -1, left: 1, right: 0, to_end: false)
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
        tabline = @tab_bar.buffers.tab_row?(state.tabs.tab_count) ? 1 : 0
        tab = state.tab
        layout = tab.layout
        ids = layout.leaves
        ensure_slots(rows, ids.length)
        build_key(rows, cols, tabline, tabstop, layout, ids)
        unless same_ints?(@key, back.layout)
          @back_rows.invalidate
          copy_ints(@key, back.layout)
        end
        base_same = based && same_ints?(@key, base.layout)
        floats = tab.floats
        in_float = floats.focused?
        @floating = floats.count > 0 || back.floats.length > 0 || base.floats.length > 0
        full_floats = false
        if @floating
          build_float_key(floats)
          full_floats = !same_ints?(@float_key, back.floats) || ids.length > 1 || in_float
          unless same_ints?(@float_key, back.floats)
            forget_rows(back.floats, rows)
            copy_ints(@float_key, back.floats)
          end
          clear_repainted(rows)
        end
        back.reset_rows
        @chrome.clear

        if tabline == 1
          @tab_bar.paint(back, state, cols)
          @chrome << 0
          @repainted[0] = 1 if @floating
        end
        visual = Domain::Mode.visual?(state.mode)
        selection = visual ? state.selection : @none
        @drawn = @last_search.drawn(options)
        if @drawn > 0
          @pattern = @last_search.highlighted(options)
          @budget.reset(Domain::SearchBudget::FRAME)
        end
        bar = rows - 2
        i = 0
        while i < ids.length
          id = ids[i]
          current = id == tab.current && !in_float
          paint_window(back, layout.window_at(id), i, current, options, tabstop, bar, current ? selection : @none, cols, base_same)
          i += 1
        end
        paint_separators(back, layout, layout.root)
        paint_headers(back, tab)
        if bar >= tabline
          @status_bar.paint(back, bar, cols, state)
          @chrome << bar
          @repainted[bar] = 1 if @floating
        end
        start = @start_screen.showing
        if start
          window = state.window
          @start_screen.paint(back, window.row, window.col, window.height, window.width)
        end
        if @floating
          paint_floats(back, floats, tabstop, rows, cols, full_floats || start)
          unless based && same_ints?(@float_key, base.floats)
            compare_boxes(back, base, @float_key)
            compare_boxes(back, base, base.floats)
          end
        end
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
        if start
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
        @front = Domain::Frame.new(rows: rows, cols: cols)
        @back = Domain::Frame.new(rows: rows, cols: cols)
        @repainted = Array.new(rows, 1)
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

      #: (Array[Integer], Array[Integer]) -> bool
      def same_ints?(key, other)
        return false unless other.length == key.length
        i = 0
        while i < key.length
          return false unless other[i] == key[i]
          i += 1
        end
        true
      end

      #: (Array[Integer], Array[Integer]) -> void
      def copy_ints(key, target)
        target.clear
        i = 0
        while i < key.length
          target << key[i]
          i += 1
        end
      end

      # What the floats to paint show, FLOAT_STRIDE integers each: the box
      # (top, the row after it, left, the column after it), the first
      # row and column the float shows, its buffer's change counters, its
      # window id, so a float reopened at the same box repaints, and its
      # selected menu row.
      #: (Domain::FloatLayer) -> void
      def build_float_key(floats)
        key = @float_key
        key.clear
        i = 0
        while i < floats.count
          float = floats.at(i)
          window = float.window
          buffer = window.buffer
          key << float.box_top
          key << float.box_bottom
          key << float.box_left
          key << float.box_right
          key << window.top
          key << window.left
          key << buffer.closed_count
          key << buffer.changes
          key << window.id
          key << float.selected
          i += 1
        end
      end

      # Forgets the window rows the boxes of a key cover.
      #: (Array[Integer], Integer) -> void
      def forget_rows(key, rows)
        i = 0
        while i < key.length
          r = key[i] < 0 ? 0 : key[i]
          last = key[i + 1] > rows ? rows : key[i + 1]
          while r < last
            @back_rows.forget(r)
            r += 1
          end
          i += FLOAT_STRIDE
        end
      end

      # Marks dirty each row of a key's boxes whose cells, from the one
      # before the box to the one after it, differ from the base's.
      #: (Domain::Frame, Domain::Frame, Array[Integer]) -> void
      def compare_boxes(frame, base, key)
        i = 0
        while i < key.length
          r = key[i] < 0 ? 0 : key[i]
          last = key[i + 1] > frame.rows ? frame.rows : key[i + 1]
          while r < last
            frame.dirty[r] = 1 unless frame.same_cells?(r, key[i + 2] - 1, key[i + 3] + 1, base)
            r += 1
          end
          i += FLOAT_STRIDE
        end
      end

      # Whether a float box to paint or one of the frame shown meets the
      # rows from top to the row before bottom.
      #: (Integer, Integer) -> bool
      def under_float?(top, bottom)
        covers?(@float_key, top, bottom) || covers?(@front.floats, top, bottom)
      end

      #: (Array[Integer], Integer, Integer) -> bool
      def covers?(key, top, bottom)
        i = 0
        while i < key.length
          return true if key[i] < bottom && key[i + 1] > top
          i += FLOAT_STRIDE
        end
        false
      end

      #: (Integer) -> void
      def clear_repainted(rows)
        r = 0
        while r < rows
          @repainted[r] = 0
          r += 1
        end
      end

      # Each float in drawing order, one whose box leaves the screen above
      # the message row skipped: every row of it when full, else only the
      # rows painted again under it in this frame.
      #: (Domain::Frame, Domain::FloatLayer, Integer, Integer, Integer, bool) -> void
      def paint_floats(frame, floats, tabstop, rows, cols, full)
        i = 0
        while i < floats.count
          float = floats.at(i)
          if float.box_top >= 0 && float.box_left >= 0 && float.box_bottom < rows && float.box_right <= cols
            r = float.box_top
            while r < float.box_bottom
              paint_float_row(frame, float, r, tabstop, cols) if full || @repainted[r] == 1
              r += 1
            end
          end
          i += 1
        end
      end

      # One row of a float's box: its text in NormalFloat, then its border
      # and, on the top edge, its title.
      #: (Domain::Frame, Domain::FloatWindow, Integer, Integer, Integer) -> void
      def paint_float_row(frame, float, r, tabstop, cols)
        mend_edges(frame, r, float.box_left, float.box_right, cols)
        window = float.window
        if r >= window.row && r < window.row + window.height
          x = window.col
          width = window.width
          buffer = window.buffer
          row = window.top + r - window.row
          if row < buffer.line_count
            paint_text(frame, r, x, @cache.fetch(buffer.line(row), tabstop), width, window.left)
          else
            frame.blank(r, x, x + width)
          end
          frame.fill(r, x, x + width, float_group(float, row))
          paint_mark(frame, float, r, x, width) if row == 0 && float.marked?
        end
        paint_border_row(frame, float, r) if float.spec.border
      end

      # The marked columns of a float's first row in Visual, within its
      # text area of width cells from x.
      #: (Domain::Frame, Domain::FloatWindow, Integer, Integer, Integer) -> void
      def paint_mark(frame, float, r, x, width)
        left = float.window.left
        from = x + float.mark_from - left
        to = x + float.mark_to - left
        from = x if from < x
        to = x + width if to > x + width
        frame.fill(r, from, to, Domain::Highlight::VISUAL) if to > from
      end

      # The group of a float's text row: NormalFloat, or for a menu Pmenu
      # and PmenuSel on its selected row.
      #: (Domain::FloatWindow, Integer) -> Integer
      def float_group(float, row)
        return Domain::Highlight::NORMAL_FLOAT unless float.menu?
        row == float.selected ? Domain::Highlight::POPUP_MENU_SELECTED : Domain::Highlight::POPUP_MENU
      end

      # Blanks the halves of wide characters a box cuts at its edges, so
      # no cell is left holding half of one.
      #: (Domain::Frame, Integer, Integer, Integer, Integer) -> void
      def mend_edges(frame, row, left, right, cols)
        frame.blank(row, left - 1, left) if left > 0 && frame.width_at(row, left - 1) == 2
        frame.blank(row, right, right + 1) if right < cols && frame.width_at(row, right) == 0
      end

      # The border cells of one row of a box, rounded corners.
      #: (Domain::Frame, Domain::FloatWindow, Integer) -> void
      def paint_border_row(frame, float, r)
        left = float.box_left
        right = float.box_right - 1
        hl = Domain::Highlight::FLOAT_BORDER
        top = r == float.box_top
        if top || r == float.box_bottom - 1
          frame.put_code(r, left, top ? 0x256D : 0x2570, 1, hl)
          frame.put_code(r, right, top ? 0x256E : 0x256F, 1, hl)
          c = left + 1
          while c < right
            frame.put_code(r, c, 0x2500, 1, hl)
            c += 1
          end
          title = float.spec.title
          frame.put_within(r, left + 1, title, Domain::Highlight::TITLE, right) if top && !title.empty?
        else
          frame.put_code(r, left, 0x2502, 1, hl)
          frame.put_code(r, right, 0x2502, 1, hl)
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
          hl = frame.hl_at(row, col)
          if visual && Domain::Highlight.base(hl) == Domain::Highlight::VISUAL
            line = window.buffer.line(cursor.row)
            frame.set_hl(row, col, token_group(window.buffer.syntax_cache.lookup(cursor.row, line).tokens, cursor.col) + hl - Domain::Highlight::VISUAL)
          end
        end
        frame.cursor_shape = shape_of(state.mode)
      end

      # The cursor shape of a mode: a bar in insert mode, an underline in
      # replace mode, a block in every other.
      #: (Symbol) -> Symbol
      def shape_of(mode)
        return :bar if mode == Domain::Mode::INSERT
        return :underline if mode == Domain::Mode::REPLACE
        :block
      end

      # The group of the token covering a code point column, the normal
      # group for none.
      #: (Array[Integer], Integer) -> Integer
      def token_group(tokens, col)
        i = 0
        while i + 2 < tokens.length
          from = tokens[i]
          return tokens[i + 2] if col >= from && col < from + tokens[i + 1]
          i += 3
        end
        Domain::Highlight::NORMAL
      end

      # One window: each text row painted when what it shows changed and
      # marked dirty when it differs from the base frame's, a scroll
      # recorded for a full-width window, then the separator row under it
      # unless that row is the status bar's, bar.
      #: (Domain::Frame, Domain::Window, Integer, bool, Domain::Options, Integer, Integer, Domain::Selection, Integer, bool) -> void
      def paint_window(frame, window, slot, current, options, tabstop, bar, selection, cols, base_same)
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
        if base_same && x == 0 && width == cols && height > 1 && !(@floating && under_float?(wrow, wrow + height))
          first = @front_rows.index(wrow, slot)
          if @front_rows.painted?(first) && @front_rows.owner(first) == window.id
            moved = top - @front_rows.top(first)
            delta = moved if moved != 0 && moved > -height && moved < height
          end
        end
        frame.add_scroll(wrow, wrow + height - 1, delta) if delta != 0
        signs = buffer.signs?
        highlights = buffer.syntax_cache
        search = @drawn
        @current = current
        lit = current && options.cursorline ? Domain::Highlight::CURSOR_LINE_LAYER : 0
        count = buffer.line_count
        i = 0
        while i < height
          frame_row = wrow + i
          row = top + i
          seg = @back_rows.index(frame_row, slot)
          line = PaintedRows::TILDE
          syntax = Domain::SyntaxLine::NONE
          number = -1
          sign = ""
          cur = -1
          layer = 0
          @sel_from = -1
          @sel_to = -2
          @sel_end = -1
          if row < count
            line = buffer.line(row)
            syntax = highlights.lookup(row, line)
            number = number_shown(row, cursor.row, options, gutter, signs)
            sign = buffer.sign_at(row) if signs
            if row == cursor.row
              cur = cursor.col
              layer = lit
            end
            select_columns(selection, buffer, row, line, tabstop, block) if selecting
          end
          unless @back_rows.same?(seg, line, left, width, gutter, number, sign, @sel_from, @sel_to, @sel_end, cur, layer, syntax, search)
            @row_of = row
            @number_hl = layer > 0 ? Domain::Highlight::CURSOR_LINE_NUMBER : Domain::Highlight::LINE_NUMBER
            paint_row(frame, frame_row, x, width, gutter, line, number, sign, signs, text_width, left, tabstop, syntax)
            @repainted[frame_row] = 1 if @floating
            frame.lift(frame_row, x + gutter, x + width, layer) if layer > 0
            @back_rows.store(seg, line, left, width, gutter, number, sign, @sel_from, @sel_to, @sel_end, cur, layer, syntax, search)
          end
          @back_rows.place(seg, window.id, top)
          if base_same
            source = frame_row
            if delta != 0
              j = i + delta
              source = j >= 0 && j < height ? wrow + j : -1
              frame.sources[frame_row] = source
            end
            frame.dirty[frame_row] = 1 if source < 0 || !@front_rows.same?(@front_rows.index(source, slot), line, left, width, gutter, number, sign, @sel_from, @sel_to, @sel_end, cur, layer, syntax, search)
          end
          i += 1
        end
        below = wrow + height
        return if below == bar
        frame.blank(below, x, x + width)
        @repainted[below] = 1 if @floating
        c = x
        while c < x + width
          frame.put(below, c, ROW_SEPARATOR, Domain::Highlight::WINDOW_SEPARATOR)
          c += 1
        end
        @chrome << below
      end

      # The header row above each shown slot window that ArrangeView gave
      # one: the titles of the slot's views, each between spaces, the
      # shown one in TabLineSel and the others in TabLine, the rest of the
      # row in TabLineFill. The titles are the strings the slot holds, so
      # nothing is allocated.
      #: (Domain::Frame, Domain::TabPage) -> void
      def paint_headers(frame, tab)
        layout = tab.layout
        i = 0
        while i < Domain::TabPage::SLOT_COUNT
          slot = tab.slot_at(i)
          if slot.shown?(layout)
            window = slot.view_window
            row = window.row - 1
            paint_header(frame, slot, window, row) if layout.node(layout.leaf_holding(window)).row == row
          end
          i += 1
        end
      end

      #: (Domain::Frame, Domain::Slot, Domain::Window, Integer) -> void
      def paint_header(frame, slot, window, row)
        x = window.col
        limit = x + window.width
        frame.blank(row, x, limit)
        frame.fill(row, x, limit, Domain::Highlight::TAB_LINE_FILL)
        shown = window.buffer.title
        views = slot.views
        c = x
        k = 0
        while k < views.length && c < limit
          hl = views[k] == shown ? Domain::Highlight::TAB_LINE_SELECTED : Domain::Highlight::TAB_LINE
          c = frame.put_within(row, c, " ", hl, limit)
          c = frame.put_within(row, c, views[k], hl, limit)
          c = frame.put_within(row, c, " ", hl, limit)
          k += 1
        end
        @repainted[row] = 1 if @floating
        @chrome << row
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
      # and blanks between and after, then the token groups, then the
      # selection.
      #: (Domain::Frame, Integer, Integer, Integer, Integer, String, Integer, String, bool, Integer, Integer, Integer, Domain::SyntaxLine) -> void
      def paint_row(frame, frame_row, x, width, gutter, line, number, sign, signs, text_width, left, tabstop, syntax)
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
            frame.fill(frame_row, x, x + Domain::Window::SIGN_WIDTH, Domain::Highlight::SIGN_COLUMN)
            shown = sign.length > Domain::Window::SIGN_WIDTH ? sign[0, Domain::Window::SIGN_WIDTH] : sign
            frame.put(frame_row, x, shown, Domain::Highlight::SIGN_COLUMN)
            start = x + Domain::Window::SIGN_WIDTH
            numbers = gutter - Domain::Window::SIGN_WIDTH
          end
          if number >= 0
            visible = numbers > width ? width : numbers
            frame.put_number(frame_row, start, numbers - 1, number, visible, @number_hl)
          end
        end
        decoded = @cache.fetch(line, tabstop)
        paint_text(frame, frame_row, x + gutter, decoded, text_width, left)
        paint_tokens(frame, frame_row, x + gutter, decoded, text_width, left, syntax.tokens) unless syntax.tokens.empty?
        paint_matches(frame, frame_row, x + gutter, decoded, text_width, left, line) if @drawn > 0
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

      # Gives the cells of each token the token's group: the display
      # columns of its code points inside [left, left + width), a token
      # past the end of the line cut there.
      #: (Domain::Frame, Integer, Integer, Domain::DecodedLine, Integer, Integer, Array[Integer]) -> void
      def paint_tokens(frame, frame_row, col, decoded, width, left, tokens)
        size = decoded.size
        limit = left + width
        i = 0
        while i + 2 < tokens.length
          from = tokens[i]
          if from < size
            to = from + tokens[i + 1]
            to = size if to > size
            first = decoded.col(from)
            last = decoded.col(to)
            first = left if first < left
            last = limit if last > limit
            frame.fill(frame_row, col + first - left, col + last - left, tokens[i + 2]) if first < last
          end
          i += 3
        end
      end

      # Gives the matches of the highlighted pattern on the row being
      # painted the Search group, up to the right edge of the window and
      # while the frame's budget lasts, and the match a search prompt
      # previews on it, in the current window, IncSearch. An empty match
      # is not drawn.
      #: (Domain::Frame, Integer, Integer, Domain::DecodedLine, Integer, Integer, String) -> void
      def paint_matches(frame, frame_row, col, decoded, width, left, line)
        pattern = @pattern
        size = decoded.size
        limit = left + width
        if pattern.ok?
          text = Domain::Search.searchable(line)
          length = text.length
          budget = @budget
          from = 0
          while from <= size
            found = Domain::Search.match_at(pattern, text, length, from, budget)
            break if found.nil?
            first = found.begin(0)
            last = found.end(0)
            break if first >= size || decoded.col(first) >= limit
            if last > first
              fill_columns(frame, frame_row, col, decoded, left, limit, first, last, Domain::Highlight::SEARCH)
              from = last
            else
              from = first + 1
            end
          end
        end
        search = @last_search
        return unless @current && search.preview_row == @row_of && search.preview_end > search.preview_col
        fill_columns(frame, frame_row, col, decoded, left, limit, search.preview_col, search.preview_end, Domain::Highlight::INC_SEARCH)
      end

      # Gives the code points from first up to last of a decoded line the
      # group, over the display columns inside [left, limit).
      #: (Domain::Frame, Integer, Integer, Domain::DecodedLine, Integer, Integer, Integer, Integer, Integer) -> void
      def fill_columns(frame, frame_row, col, decoded, left, limit, first, last, group)
        size = decoded.size
        last = size if last > size
        return if first >= last
        from = decoded.col(first)
        to = decoded.col(last)
        from = left if from < left
        to = limit if to > limit
        frame.fill(frame_row, col + from - left, col + to - left, group) if from < to
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
              frame.put(r, sep, SEPARATOR, Domain::Highlight::WINDOW_SEPARATOR)
              r += 1
            end
          end
          paint_separators(frame, layout, children[i])
          i += 1
        end
      end

      # ":" for an ex command line, "/" or "?" for a search prompt, a
      # plugin's prompt text while one is open, ">" while the command
      # palette is.
      #: (Domain::EditorState) -> String
      def command_prefix(state)
        ui = @plugin_ui
        return ui.prompt if ui.prompting?
        return PALETTE_PROMPT if @palette.active
        @search_prompt.active ? @search_prompt.prefix : ":"
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
        lines = Domain::TextLines.split(state.message, false)
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

      # The message of the diagnostic shown on the cursor's line of the
      # window, in its severity's group; nothing for none.
      #: (Domain::Frame, Integer, Domain::Window) -> void
      def paint_diagnostic(frame, frame_row, window)
        diagnostic = window.buffer.diagnostic_at(window.cursor.row)
        return if diagnostic.nil?
        frame.put(frame_row, 0, diagnostic.message, FramePresenter.diagnostic_group(diagnostic.severity))
      end

      # The highlight group of a diagnostic severity.
      #: (Integer) -> Integer
      def self.diagnostic_group(severity)
        return Domain::Highlight::DIAGNOSTIC_ERROR if severity == 1
        return Domain::Highlight::DIAGNOSTIC_WARN if severity == 2
        return Domain::Highlight::DIAGNOSTIC_INFO if severity == 3
        Domain::Highlight::DIAGNOSTIC_HINT
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
        elsif state.mode == Domain::Mode::NORMAL
          paint_diagnostic(frame, frame_row, state.window)
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
