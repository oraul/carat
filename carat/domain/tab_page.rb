module Carat
  module Domain
    # One tab page: a window layout, the id of its current window, and the
    # id of the window that was current before it, for Ctrl-W p (-1 when
    # none). A Struct record: mutable, with a reader and a writer per
    # member.
    class TabPage < Struct.new(:layout, :current, :previous)
      # @rbs @layout: Layout
      # @rbs @current: Integer
      # @rbs @previous: Integer

      #: (Window) -> void
      def initialize(window)
        super(Layout.new(window), 0, -1)
      end

      #: () -> Window
      def window
        layout.window_at(current)
      end

      #: () -> Integer
      def window_count
        layout.leaf_count
      end

      # Makes the leaf id current, remembering the one it replaces.
      #: (Integer) -> void
      def focus(id)
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
