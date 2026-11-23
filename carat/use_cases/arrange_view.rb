require_relative "../domain/editor_state"
require_relative "../domain/mode"
require_relative "../domain/window"
require_relative "../domain/options"
require_relative "../domain/border_style"
require_relative "../domain/line_cache"
require_relative "../domain/buffer_list"

module Carat
  module UseCases
    # Lays out the current tab page for the screen size the state holds
    # and scrolls each of its windows to its cursor, so the geometry the
    # use cases read (split sizes, neighbours, H, M, and L) is the one the
    # next frame will show. The top row holds the buffer tabs when two
    # file buffers are listed or two tab pages exist, the row above the
    # last the status bar, and the last row the message row; the layout gets
    # the rows between, each shown slot window gives its first row to the
    # slot's header (Slot#headed?), and, when the breadcrumbs mode shows winbars
    # (TabPage#winbar?), each file window gives its first row to its
    # winbar. Each window scrolls vertically to keep its cursor
    # row visible with scrolloff and horizontally to keep the display
    # column of its cursor visible, read from the shared line cache. The
    # floats of the tab page are then placed over the rows above the
    # message row, from the editor's top-left cell or the cursor cell of
    # the layout's current window, and scroll like windows. Outside insert
    # and replace modes a cursor inside a closed fold first moves to the
    # fold's first line, where the fold is drawn, as Neovim's
    # foldAdjustCursor does after every command; in those modes the
    # current window's closed folds holding the cursor open instead, as
    # foldOpenCursor does when an insert session starts (RepeatLast does
    # the same for a replayed insert, which leaves no key between). It does
    # nothing before the size is known. Run after every key, after a file
    # is opened, and before every render.
    class ArrangeView
      attr_reader :cache #: Domain::LineCache
      attr_reader :buffers #: Domain::BufferList

      #: (cache: Domain::LineCache, buffers: Domain::BufferList) -> void
      def initialize(cache:, buffers:)
        @cache = cache
        @buffers = buffers
      end

      #: (Domain::EditorState) -> void
      def call(state)
        rows = state.screen_rows
        cols = state.screen_cols
        return if rows <= 0 || cols <= 0
        options = state.options
        tabstop = options.tabstop > 0 ? options.tabstop : 8
        tabline = @buffers.tab_row?(state.tabs.tab_count, options.showtabline) ? 1 : 0
        area = rows - 1 - tabline
        area = 1 if area < 1
        layout = state.tab.layout
        layout.arrange(tabline, 0, area, cols)
        reserve_headers(state.tab, tabline == 1)
        reserve_winbars(layout, state.tab.winbar?(options.breadcrumbs))
        id = 0
        typing = state.mode == Domain::Mode::INSERT || state.mode == Domain::Mode::REPLACE
        while id < layout.node_count
          if layout.node(id).leaf?
            window = layout.window_at(id)
            if typing
              window.open_cursor_folds if id == state.tab.current
            else
              to_fold_start(window, Domain::Mode.visual?(state.mode))
            end
            scroll(window, options, tabstop)
          end
          id += 1
        end
        floats = state.tab.floats
        place_floats(state, floats, rows - 1, cols, options, tabstop) if floats.count > 0
      end

      private

      # Gives each shown slot window's first row to its header, as
      # Slot#headed? decides with tab_row, whether the tab row shows: the
      # window starts a row lower, a row shorter, when it has two rows or
      # more.
      #: (Domain::TabPage, bool) -> void
      def reserve_headers(tab, tab_row)
        layout = tab.layout
        i = 0
        while i < Domain::TabPage::SLOT_COUNT
          slot = tab.slot_at(i)
          if slot.shown?(layout) && slot.headed?(tab_row)
            window = slot.view_window
            if window.height > 1
              window.row = window.row + 1
              window.height = window.height - 1
            end
          end
          i += 1
        end
      end

      # Decides which windows show a winbar, the one place that does: when
      # shown is true, each file window of two rows or more gives its
      # first row to its winbar the same way and is marked (Window#winbar)
      # for the presenter; slot and plugin windows hold scratch buffers and
      # keep theirs. Every other leaf is unmarked.
      #: (Domain::Layout, bool) -> void
      def reserve_winbars(layout, shown)
        id = 0
        while id < layout.node_count
          if layout.node(id).leaf?
            window = layout.window_at(id)
            marked = shown && !window.buffer.scratch? && window.height > 1
            if marked
              window.row = window.row + 1
              window.height = window.height - 1
            end
            window.winbar = marked
          end
          id += 1
        end
      end

      #: (Domain::EditorState, Domain::FloatLayer, Integer, Integer, Domain::Options, Integer) -> void
      def place_floats(state, floats, rows, cols, options, tabstop)
        window = state.tab.layout_window
        cursor = window.cursor
        dcol = @cache.fetch(window.buffer.line(cursor.row), tabstop).col(cursor.col)
        cursor_row = window.row + window.row_offset(cursor.row)
        cursor_col = window.col + window.gutter_width(options) + dcol - window.left
        winborder = options.winborder
        i = 0
        while i < floats.count
          float = floats.at(i)
          edged = Domain::BorderStyle.edged?(float.style_under(winborder))
          if float.spec.cursor_anchored?
            float.place(cursor_row, cursor_col, rows, cols, edged)
          else
            float.place(0, 0, rows, cols, edged)
          end
          scroll(float.window, options, tabstop)
          i += 1
        end
      end

      # Moves the cursor of window from inside a closed fold to the fold's
      # first line, its column kept on that line: past the last character
      # only in the visual modes, where it selects the line break.
      #: (Domain::Window, bool) -> void
      def to_fold_start(window, visual)
        folds = window.folds
        return unless folds.folded?
        cursor = window.cursor
        first = folds.first_row(cursor.row)
        return if first == cursor.row
        len = window.buffer.line(first).length
        max = visual || len == 0 ? len : len - 1
        cursor.row = first
        cursor.col = max if cursor.col > max
      end

      #: (Domain::Window, Domain::Options, Integer) -> void
      def scroll(window, options, tabstop)
        buffer = window.buffer
        cursor = window.cursor
        text_width = window.width - window.gutter_width(options)
        text_width = 1 if text_width < 1
        window.scroll_to_row(cursor.row, buffer.line_count, options.scrolloff)
        dcol = @cache.fetch(buffer.line(cursor.row), tabstop).col(cursor.col)
        window.scroll_to_col(dcol, text_width)
      end
    end
  end
end
