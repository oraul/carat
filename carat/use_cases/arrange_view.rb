require_relative "../domain/editor_state"
require_relative "../domain/window"
require_relative "../domain/options"
require_relative "../domain/line_cache"

module Carat
  module UseCases
    # Lays out the current tab page for the screen size the state holds
    # and scrolls each of its windows to its cursor, so the geometry the
    # use cases read (split sizes, neighbours, H, M, and L) is the one the
    # next frame will show. The top row is the tab line when there are
    # several tab pages and the last row the message row; the layout gets
    # the rows between. Each window scrolls vertically to keep its cursor
    # row visible with scrolloff and horizontally to keep the display
    # column of its cursor visible, read from the shared line cache. It
    # does nothing before the size is known. Run after every key, after a
    # file is opened, and before every render.
    class ArrangeView
      attr_reader :cache #: Domain::LineCache

      #: (cache: Domain::LineCache) -> void
      def initialize(cache:)
        @cache = cache
      end

      #: (Domain::EditorState) -> void
      def call(state)
        rows = state.screen_rows
        cols = state.screen_cols
        return if rows <= 0 || cols <= 0
        options = state.options
        tabstop = options.tabstop > 0 ? options.tabstop : 8
        tabline = state.tabs.tab_count > 1 ? 1 : 0
        area = rows - 1 - tabline
        area = 1 if area < 1
        layout = state.tab.layout
        layout.arrange(tabline, 0, area, cols)
        id = 0
        while id < layout.node_count
          scroll(layout.window_at(id), options, tabstop) if layout.node(id).leaf?
          id += 1
        end
      end

      private

      #: (Domain::Window, Domain::Options, Integer) -> void
      def scroll(window, options, tabstop)
        buffer = window.buffer
        cursor = window.cursor
        text_width = window.width - window.gutter_width(options)
        text_width = 1 if text_width < 1
        window.scroll_to_row(cursor.row, buffer.line_count, window.height, options.scrolloff)
        dcol = @cache.fetch(buffer.line(cursor.row), tabstop).col(cursor.col)
        window.scroll_to_col(dcol, text_width)
      end
    end
  end
end
