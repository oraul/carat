module Carat
  module Domain
    # One tab page: a window layout, the id of its current window, the
    # id of the window that was current before it, for Ctrl-W p (-1 when
    # none), and the floating windows drawn over the layout. The current
    # window is the focused float when one is, else the layout's current
    # leaf. A Struct record: mutable, with a reader and a writer per
    # member.
    class TabPage < Struct.new(:layout, :current, :previous, :floats, keyword_init: true)
      # @rbs @layout: Layout
      # @rbs @current: Integer
      # @rbs @previous: Integer
      # @rbs @floats: FloatLayer

      #: (window: Window) -> void
      def initialize(window:)
        super(layout: Layout.new(window: window), current: 0, previous: -1, floats: FloatLayer.new)
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
