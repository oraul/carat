module Carat
  module Domain
    # One tab page: a window layout, the id of its current window, the
    # id of the window that was current before it, for Ctrl-W p (-1 when
    # none), the floating windows drawn over the layout, and its three
    # slots: the left and right sidebars and the bottom panel. The current
    # window is the focused float when one is, else the layout's current
    # leaf. A Struct record: mutable, with a reader and a writer per
    # member.
    class TabPage < Struct.new(:layout, :current, :previous, :floats, :left_slot, :right_slot, :panel_slot, keyword_init: true)
      # @rbs @layout: Layout
      # @rbs @current: Integer
      # @rbs @previous: Integer
      # @rbs @floats: FloatLayer
      # @rbs @left_slot: Slot
      # @rbs @right_slot: Slot
      # @rbs @panel_slot: Slot

      SLOT_COUNT = 3

      #: (window: Window) -> void
      def initialize(window:)
        super(layout: Layout.new(window: window), current: 0, previous: -1, floats: FloatLayer.new, left_slot: Slot.new(side: :left), right_slot: Slot.new(side: :right), panel_slot: Slot.new(side: :bottom))
      end

      #: () -> Window
      def window
        return floats.focused if floats.focused?
        layout.window_at(current)
      end

      # The layout's current window, under a focused float.
      #: () -> Window
      def layout_window
        layout.window_at(current)
      end

      #: () -> Integer
      def window_count
        layout.leaf_count
      end

      # The layout's windows showing a buffer that is not a scratch
      # buffer, slot and plugin windows left out; walks the node table, so
      # nothing is allocated.
      #: () -> Integer
      def file_window_count
        count = 0
        id = 0
        while id < layout.node_count
          count += 1 if layout.node(id).leaf? && !layout.window_at(id).buffer.scratch?
          id += 1
        end
        count
      end

      # Whether the file windows show a winbar under the breadcrumbs mode
      # (Options::BREADCRUMBS): never, always, or with two or more file
      # windows.
      #: (String) -> bool
      def winbar?(mode)
        return false if mode == "never"
        return true if mode == "always"
        file_window_count > 1
      end

      # The slot at a side: :left, :right, or :bottom.
      #: (Symbol) -> Slot
      def slot(side)
        return left_slot if side == :left
        return right_slot if side == :right
        panel_slot
      end

      # The slot at index 0 (left), 1 (right), or 2 (the panel), for walks
      # over the SLOT_COUNT slots.
      #: (Integer) -> Slot
      def slot_at(index)
        return left_slot if index == 0
        return right_slot if index == 1
        panel_slot
      end

      # Whether a hidden slot keeps a window over the buffer.
      #: (Buffer) -> bool
      def keeps?(target)
        left_slot.keeps?(target) || right_slot.keeps?(target) || panel_slot.keeps?(target)
      end

      # Makes the leaf id current, remembering the one it replaces, and
      # leaves a focused float.
      #: (Integer) -> void
      def focus(id)
        floats.leave
        return if id == current
        self.previous = current
        self.current = id
      end

      # Whether the previously used window still exists.
      #: () -> bool
      def previous?
        previous >= 0 && previous < layout.nodes.length && layout.node(previous).leaf?
      end
    end
  end
end
