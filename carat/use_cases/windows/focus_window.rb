require_relative "../../domain/editor_state"

module Carat
  module UseCases
    # Changes the current window of the tab page: to a neighbour in a
    # direction, to the next or previous window in layout order or to a
    # numbered one, or back to the previously used window.
    class FocusWindow
      # Moves count times (at least once) in the direction, stopping at the
      # edge of the layout.
      #: (Domain::EditorState, Symbol, Integer) -> void
      def direction(state, where, count)
        tab = state.tab
        steps = count > 0 ? count : 1
        id = tab.current
        i = 0
        while i < steps
          found = tab.layout.neighbour(id, where)
          break if found < 0
          id = found
          i += 1
        end
        tab.focus(id)
      end

      # Without a count, the next or previous window, wrapping; with one,
      # window number count, or the last window when count is larger.
      #: (Domain::EditorState, bool, Integer) -> void
      def cycle(state, forward, count)
        tab = state.tab
        layout = tab.layout
        if count > 0
          tab.focus(layout.leaf_number(count))
          return
        end
        ids = layout.leaves
        pos = layout.number_of(tab.current) - 1
        pos = forward ? (pos + 1) % ids.length : (pos - 1 + ids.length) % ids.length
        tab.focus(ids[pos])
      end

      # Back to the window that was current before the last change, if it
      # still exists.
      #: (Domain::EditorState) -> void
      def previous(state)
        tab = state.tab
        tab.focus(tab.previous) if tab.previous?
      end
    end
  end
end
