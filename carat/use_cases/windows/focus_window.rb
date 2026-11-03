require_relative "../../domain/editor_state"
require_relative "../outcome"
require_relative "focus_request"

module Carat
  module UseCases
    # Changes the current window of the tab page as the request says: to
    # a neighbour in a direction, stopping at the edge of the layout; to
    # the next or previous window in layout order, wrapping, or to a
    # numbered one, the last when the number is larger; or back to the
    # previously used window, if it still exists.
    class FocusWindow
      #: (Domain::EditorState, FocusRequest) -> Outcome
      def call(state, request)
        tab = state.tab
        case request.target
        when :next then cycle(state, true, request.count)
        when :previous then cycle(state, false, request.count)
        when :last_accessed then tab.focus(tab.previous) if tab.previous?
        else direction(state, request.target, request.steps)
        end
        Outcome.none
      end

      private

      #: (Domain::EditorState, Symbol, Integer) -> void
      def direction(state, where, steps)
        tab = state.tab
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
    end
  end
end
