require_relative "window"
require_relative "float_window"

module Carat
  module Domain
    # The floating windows of one tab page, in drawing order: ascending z,
    # a float added after the floats of its z, so the last one is the
    # topmost. focus is the index of the float that is the current
    # window, -1 when the layout's window is. At most LIMIT floats.
    class FloatLayer
      LIMIT = 16

      # @rbs @floats: Array[untyped]
      # @rbs @focus: Integer

      #: () -> void
      def initialize
        @floats = []
        @focus = -1
      end

      #: () -> Integer
      def count
        @floats.length
      end

      #: () -> bool
      def full?
        @floats.length >= LIMIT
      end

      #: (Integer) -> FloatWindow
      def at(i)
        @floats[i]
      end

      #: () -> bool
      def focused?
        @focus >= 0
      end

      # The window of the focused float; call only when focused? is true.
      #: () -> Window
      def focused
        at(@focus).window
      end

      # The index of the float whose window has the id, or -1.
      #: (Integer) -> Integer
      def index_of(id)
        i = 0
        while i < @floats.length
          return i if at(i).id == id
          i += 1
        end
        -1
      end

      # Adds the float above every float of its z or lower, focusing it
      # when enter is true; false, adding nothing, when the layer is full.
      #: (FloatWindow, bool) -> bool
      def add(float, enter)
        return false if full?
        z = float.spec.z
        i = @floats.length
        i -= 1 while i > 0 && at(i - 1).spec.z > z
        @floats.insert(i, float)
        @focus += 1 if @focus >= i
        @focus = i if enter
        true
      end

      # Removes the float with the id; a focused one gives the focus back
      # to the layout. False when no float has the id.
      #: (Integer) -> bool
      def close(id)
        i = index_of(id)
        return false if i < 0
        @floats.delete_at(i)
        if @focus == i
          @focus = -1
        elsif @focus > i
          @focus -= 1
        end
        true
      end

      # Closes the topmost float; false when none is open.
      #: () -> bool
      def close_top
        return false if @floats.empty?
        close(at(@floats.length - 1).id)
      end

      # Closes the focused float; false when none is focused.
      #: () -> bool
      def close_focused
        return false unless focused?
        close(at(@focus).id)
      end

      # Makes the float with the id the current window; false for none.
      #: (Integer) -> bool
      def enter(id)
        i = index_of(id)
        return false if i < 0
        @focus = i
        true
      end

      # Gives the focus back to the layout's window.
      #: () -> void
      def leave
        @focus = -1
      end

      # Moves the float with the id to another offset; false for none.
      #: (Integer, Integer, Integer) -> bool
      def move(id, row, col)
        i = index_of(id)
        return false if i < 0
        float = at(i)
        float.spec = float.spec.moved(row, col)
        true
      end
    end
  end
end
