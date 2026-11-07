require_relative "window"
require_relative "float_spec"

module Carat
  module Domain
    # A window drawn over the layout of its tab page, with the spec that
    # places it. The window's rectangle is the float's text area, set by
    # place at every arrange; the border, when the spec asks for one,
    # takes one cell around it. A float that is a menu (the completion
    # popup) has its selected row in selected, drawn in PmenuSel and its
    # other rows in Pmenu; any other float has -1 there. A float may mark
    # the display columns mark_from up to mark_to of its buffer's first
    # row (the active parameter of a signature), drawn in Visual; -1 for
    # none. A Struct record: mutable, with a reader and a writer per
    # member.
    class FloatWindow < Struct.new(:window, :spec, :selected, :mark_from, :mark_to, keyword_init: true)
      # @rbs @window: Window
      # @rbs @spec: FloatSpec
      # @rbs @selected: Integer
      # @rbs @mark_from: Integer
      # @rbs @mark_to: Integer

      #: (window: Window, spec: FloatSpec) -> void
      def initialize(window:, spec:)
        super(window: window, spec: spec, selected: -1, mark_from: -1, mark_to: -1)
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
      # anchor cell (top, left) inside rows by cols cells: its size is cut
      # to fit first, then its corner moved in, so the whole box shows
      # whenever the area holds a one-cell text area and its border.
      #: (Integer, Integer, Integer, Integer) -> void
      def place(top, left, rows, cols)
        edge = spec.edge
        height = fit(spec.height, rows - 2 * edge)
        width = fit(spec.width, cols - 2 * edge)
        box_row = shift(top + spec.row, height + 2 * edge, rows)
        box_col = shift(left + spec.col, width + 2 * edge, cols)
        window.row = box_row + edge
        window.col = box_col + edge
        window.height = height
        window.width = width
      end

      # The first screen row of the box, border included.
      #: () -> Integer
      def box_top
        window.row - spec.edge
      end

      # The screen row after the box.
      #: () -> Integer
      def box_bottom
        window.row + window.height + spec.edge
      end

      #: () -> Integer
      def box_left
        window.col - spec.edge
      end

      # The screen column after the box.
      #: () -> Integer
      def box_right
        window.col + window.width + spec.edge
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
