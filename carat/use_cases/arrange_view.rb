require_relative "../domain/editor_state"
require_relative "../domain/window"
require_relative "../domain/options"
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
    # slot's header, and, when the breadcrumbs mode shows winbars
    # (TabPage#winbar?), each file window gives its first row to its
    # winbar. Each window scrolls vertically to keep its cursor
    # row visible with scrolloff and horizontally to keep the display
    # column of its cursor visible, read from the shared line cache. The
    # floats of the tab page are then placed over the rows above the
    # message row, from the editor's top-left cell or the cursor cell of
    # the layout's current window, and scroll like windows. It
    # does nothing before the size is known. Run after every key, after a
    # file is opened, and before every render.
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
        tabline = @buffers.tab_row?(state.tabs.tab_count) ? 1 : 0
        area = rows - 1 - tabline
        area = 1 if area < 1
        layout = state.tab.layout
        layout.arrange(tabline, 0, area, cols)
        reserve_headers(state.tab)
        reserve_winbars(layout) if state.tab.winbar?(options.breadcrumbs)
        id = 0
        while id < layout.node_count
          scroll(layout.window_at(id), options, tabstop) if layout.node(id).leaf?
          id += 1
        end
        floats = state.tab.floats
        place_floats(state, floats, rows - 1, cols, options, tabstop) if floats.count > 0
      end

      private

      # Gives each shown slot window's first row to its header: the window
      # starts a row lower, a row shorter, when it has two rows or more.
      #: (Domain::TabPage) -> void
      def reserve_headers(tab)
        layout = tab.layout
        i = 0
        while i < Domain::TabPage::SLOT_COUNT
          slot = tab.slot_at(i)
          if slot.shown?(layout)
            window = slot.view_window
            if window.height > 1
              window.row = window.row + 1
              window.height = window.height - 1
            end
          end
          i += 1
        end
      end

      # Gives each file window's first row to its winbar the same way;
      # slot and plugin windows hold scratch buffers and keep theirs.
      #: (Domain::Layout) -> void
      def reserve_winbars(layout)
        id = 0
        while id < layout.node_count
          if layout.node(id).leaf?
            window = layout.window_at(id)
            if !window.buffer.scratch? && window.height > 1
              window.row = window.row + 1
              window.height = window.height - 1
            end
          end
          id += 1
        end
      end

      #: (Domain::EditorState, Domain::FloatLayer, Integer, Integer, Domain::Options, Integer) -> void
      def place_floats(state, floats, rows, cols, options, tabstop)
        window = state.tab.layout_window
        cursor = window.cursor
        dcol = @cache.fetch(window.buffer.line(cursor.row), tabstop).col(cursor.col)
        cursor_row = window.row + cursor.row - window.top
        cursor_col = window.col + window.gutter_width(options) + dcol - window.left
        i = 0
        while i < floats.count
          float = floats.at(i)
          if float.spec.cursor_anchored?
            float.place(cursor_row, cursor_col, rows, cols)
          else
            float.place(0, 0, rows, cols)
          end
          scroll(float.window, options, tabstop)
          i += 1
        end
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
