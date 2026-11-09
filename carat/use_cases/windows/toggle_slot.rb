require_relative "../../domain/editor_state"
require_relative "../../domain/slot"
require_relative "../../domain/buffer_list"
require_relative "../../domain/messages"
require_relative "../outcome"

module Carat
  module UseCases
    # layout.toggle_sidebar, layout.toggle_right_sidebar, and
    # layout.toggle_panel: hides the current tab page's slot at side
    # (:left, :right, or :bottom) when it is shown, its window leaving the
    # layout with its view and cursor kept in the slot and another window
    # current if it was; shows a hidden one again at its edge with the
    # size it had, the focus staying where it is. A slot with no view, or
    # whose kept view's buffer left the list, answers "No view in" the
    # slot; hiding the tab page's only window answers E444, and a layout
    # with no room for the slot E36.
    class ToggleSlot
      E444 = "E444: Cannot close last window"
      private_constant :E444

      attr_reader :buffers #: Domain::BufferList

      #: (buffers: Domain::BufferList) -> void
      def initialize(buffers:)
        @buffers = buffers
      end

      #: (Domain::EditorState, Symbol) -> Outcome
      def call(state, side)
        tab = state.tab
        slot = tab.slot(side)
        layout = tab.layout
        if slot.shown?(layout)
          return Outcome.failure(E444) if layout.leaf_count <= 1
          leaf = layout.leaf_holding(slot.view_window)
          slot.hide(layout.node(leaf).size)
          taker = layout.close(leaf)
          tab.current = layout.first_leaf(taker) if leaf == tab.current
          tab.previous = -1 if tab.previous == leaf
          return Outcome.none
        end
        unless slot.kept? && @buffers.index_of(slot.view_window.buffer) >= 0
          slot.clear
          return Outcome.failure("No view in #{name_of(side)}")
        end
        current = tab.layout_window
        return Outcome.failure(Domain::Messages::E36) if layout.place_slot(slot.view_window, slot.size, side) < 0
        slot.hidden = false
        tab.current = layout.leaf_holding(current)
        Outcome.none
      end

      private

      #: (Symbol) -> String
      def name_of(side)
        return "the left sidebar" if side == :left
        return "the right sidebar" if side == :right
        "the panel"
      end
    end
  end
end
