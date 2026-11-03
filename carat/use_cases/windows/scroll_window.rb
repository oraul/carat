require_relative "../../domain/editor_state"
require_relative "../../domain/window"
require_relative "../../domain/motions"
require_relative "../outcome"
require_relative "scroll_request"

module Carat
  module UseCases
    # Scrolls the current window as Neovim's <C-f> <C-b> <C-d> <C-u> <C-e>
    # <C-y> zt zz zb do: by pages of the text rows minus two, by the scroll
    # option (half the window when 0) moving the cursor as far, by lines,
    # or so the cursor line sits at the top, middle, or bottom with
    # scrolloff. The first shown line stays between the first line and
    # the one that fills the window to the last, as ArrangeView clamps it,
    # and the cursor then moves onto the nearest line the window shows
    # with scrolloff, keeping its wanted column, so the arrangement after
    # the key keeps the view. <C-f> with the last line shown goes to the
    # last line. Before the first render, when the window has no height,
    # nothing scrolls.
    class ScrollWindow
      #: (Domain::EditorState, ScrollRequest) -> Outcome
      def call(state, request)
        window = state.window
        return Outcome.none if window.height <= 0
        case request.target
        when :page_down then page(state, window, request.steps)
        when :page_up then page(state, window, -request.steps)
        when :half_down then half(state, window, request.count, 1)
        when :half_up then half(state, window, request.count, -1)
        when :line_down then line(state, window, request.steps)
        when :line_up then line(state, window, -request.steps)
        else place(state, window, request.target, request.count)
        end
        Outcome.none
      end

      private

      #: (Domain::EditorState, Domain::Window, Integer) -> void
      def page(state, window, pages)
        if pages > 0 && window.top >= max_top(state, window)
          move_row(state, state.buffer.line_count - 1)
          return
        end
        size = window.height - 2
        size = 1 if size < 1
        scroll_to(state, window, window.top + pages * size)
        keep_in_view(state, window)
      end

      #: (Domain::EditorState, Domain::Window, Integer, Integer) -> void
      def half(state, window, count, direction)
        options = state.options
        options.scroll = count if count > 0
        amount = options.scroll > 0 ? options.scroll : window.height / 2
        amount = 1 if amount < 1
        scroll_to(state, window, window.top + direction * amount)
        move_row(state, state.cursor.row + direction * amount)
        keep_in_view(state, window)
      end

      #: (Domain::EditorState, Domain::Window, Integer) -> void
      def line(state, window, lines)
        scroll_to(state, window, window.top + lines)
        keep_in_view(state, window)
      end

      #: (Domain::EditorState, Domain::Window, Symbol, Integer) -> void
      def place(state, window, where, count)
        move_row(state, count - 1) if count > 0
        row = state.cursor.row
        height = window.height
        off = margin(state, window)
        top = row - height + 1 + off
        top = row - off if where == :cursor_top
        top = row - (height - 1) / 2 if where == :cursor_middle
        scroll_to(state, window, top)
        keep_in_view(state, window)
      end

      # The last first-shown line: the one that fills the window to the
      # last line of the buffer.
      #: (Domain::EditorState, Domain::Window) -> Integer
      def max_top(state, window)
        last = state.buffer.line_count - window.height
        last < 0 ? 0 : last
      end

      # scrolloff, capped at half the window as Neovim caps it.
      #: (Domain::EditorState, Domain::Window) -> Integer
      def margin(state, window)
        off = state.options.scrolloff
        half = (window.height - 1) / 2
        off > half ? half : off
      end

      #: (Domain::EditorState, Domain::Window, Integer) -> void
      def scroll_to(state, window, top)
        last = max_top(state, window)
        top = last if top > last
        top = 0 if top < 0
        window.top = top
      end

      # Moves the cursor onto the rows the window shows, scrolloff rows in
      # from an edge that is not the start or the end of the buffer.
      #: (Domain::EditorState, Domain::Window) -> void
      def keep_in_view(state, window)
        top = window.top
        off = margin(state, window)
        low = top == 0 ? 0 : top + off
        high = top >= max_top(state, window) ? state.buffer.line_count - 1 : top + window.height - 1 - off
        row = state.cursor.row
        move_row(state, low) if row < low
        move_row(state, high) if row > high
      end

      # Puts the cursor on row, clamped to the buffer, in the column its
      # wanted column gives there, which it keeps.
      #: (Domain::EditorState, Integer) -> void
      def move_row(state, row)
        last = state.buffer.line_count - 1
        row = last if row > last
        row = 0 if row < 0
        cursor = state.cursor
        col = Domain::Motions.wanted_col(state, row)
        cursor.row = row
        cursor.col = col
      end
    end
  end
end
