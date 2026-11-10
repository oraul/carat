require_relative "window"
require_relative "float_spec"

module Carat
  module Domain
    # A window drawn over the layout of its tab page, with the spec that
    # places it. The window's rectangle is the float's text area, set by
    # place at every arrange; PAD columns of padding stand on its left
    # and its right, and the border, when the spec asks for one and the
    # border style draws an edge, takes edge cells around that. A float
    # that is a menu (the completion popup) has its selected row in
    # selected, drawn in PmenuSel and its other rows in Pmenu; any other
    # float has -1 there. A float may mark the display columns mark_from
    # up to mark_to of its buffer's first row (the active parameter of a
    # signature), drawn in Visual; -1 for none. A Struct record: mutable,
    # with a reader and a writer per member.
    class FloatWindow < Struct.new(:window, :spec, :selected, :mark_from, :mark_to, :edge, keyword_init: true)
      # The columns of padding on each side of the text area.
      PAD = 1

      # @rbs @window: Window
      # @rbs @spec: FloatSpec
      # @rbs @selected: Integer
      # @rbs @mark_from: Integer
      # @rbs @mark_to: Integer
      # @rbs @edge: Integer

      #: (window: Window, spec: FloatSpec) -> void
      def initialize(window:, spec:)
        super(window: window, spec: spec, selected: -1, mark_from: -1, mark_to: -1, edge: spec.edge)
      end

      # Whether the float marks columns of its first row.
      #: () -> bool
      def marked?
        mark_from >= 0 && mark_to > mark_from
      end

      # Whether the float is a menu with a selected row.
      #: () -> bool
      def menu?
        selected >= 0
      end

      #: () -> Integer
      def id
        window.id
      end

      # Places the box with its corner at the spec's offset from the
      # anchor cell (top, left) inside rows by cols cells, with an edge
      # when the spec asks for a border and edged (the border style draws
      # one): its size is cut to fit first, then its corner moved in, so
      # the whole box shows whenever the area holds a one-cell text area,
      # its padding, and its border.
      #: (Integer, Integer, Integer, Integer, bool) -> void
      def place(top, left, rows, cols, edged)
        edge = edged ? spec.edge : 0
        self.edge = edge
        side = edge + PAD
        height = fit(spec.height, rows - 2 * edge)
        width = fit(spec.width, cols - 2 * side)
        box_row = shift(top + spec.row, height + 2 * edge, rows)
        box_col = shift(left + spec.col, width + 2 * side, cols)
        window.row = box_row + edge
        window.col = box_col + side
        window.height = height
        window.width = width
      end

      # Whether the box has a border drawn around it.
      #: () -> bool
      def edged?
        edge > 0
      end

      # The first screen row of the box, border included.
      #: () -> Integer
      def box_top
        window.row - edge
      end

      # The screen row after the box.
      #: () -> Integer
      def box_bottom
        window.row + window.height + edge
      end

      # The first screen column of the box, border and padding included.
      #: () -> Integer
      def box_left
        window.col - edge - PAD
      end

      # The screen column after the box.
      #: () -> Integer
      def box_right
        window.col + window.width + edge + PAD
      end

      private

      #: (Integer, Integer) -> Integer
      def fit(size, room)
        return 1 if room < 1
        size > room ? room : size
      end

      #: (Integer, Integer, Integer) -> Integer
      def shift(at, size, room)
        at = room - size if at + size > room
        at < 0 ? 0 : at
      end
    end
  end
end
