module Carat
  module Domain
    # One node of a window layout tree: a leaf holding a window, a column
    # whose children are stacked (made by :split), a row whose children sit
    # side by side (made by :vsplit), or a free slot a closed node left for
    # the next allocation. parent and children are node ids into the
    # layout's table, size is the node's extent along its parent's axis
    # (rows including the status line under a column, columns without the
    # separator under a row), and row, col, height, and width are the
    # rectangle the last arrange gave it. A Struct record: mutable, with a
    # reader and a writer per member.
    class LayoutNode < Struct.new(:kind, :parent, :children, :window, :size, :row, :col, :height, :width)
      # @rbs @kind: Symbol
      # @rbs @parent: Integer
      # @rbs @children: Array[Integer]
      # @rbs @window: Window?
      # @rbs @size: Integer
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @height: Integer
      # @rbs @width: Integer

      #: (Symbol, Integer, Window?) -> void
      def initialize(kind, parent, window)
        super(kind, parent, [], window, 0, 0, 0, 0, 0)
      end

      #: () -> bool
      def leaf?
        kind == :leaf
      end
    end
  end
end
