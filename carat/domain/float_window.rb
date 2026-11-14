require_relative "window"
require_relative "float_spec"
require_relative "border_style"

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
    # signature), drawn in Visual; -1 for none. A centered float (the
    # palette) has its column computed by place from its box at every
    # arrange, so it is centered at show and after a resize, the spec's
    # column unused. A Struct record: mutable, with a reader and a writer
    # per member.
    class FloatWindow < Struct.new(:window, :spec, :selected, :mark_from, :mark_to, :edge, :centered, keyword_init: true)
      # The columns of padding on each side of the text area.
      PAD = 1
      # The cells an editor-anchored box keeps from each side of the area
      # it is placed in, when the area holds the box and its margin; a
      # cursor-anchored box follows its anchor cell to the area's edge.
      MARGIN = 1

      # @rbs @window: Window
      # @rbs @spec: FloatSpec
      # @rbs @selected: Integer
      # @rbs @mark_from: Integer
      # @rbs @mark_to: Integer
      # @rbs @edge: Integer
      # @rbs @centered: bool

      #: (window: Window, spec: FloatSpec) -> void
      def initialize(window:, spec:)
        super(window: window, spec: spec, selected: -1, mark_from: -1, mark_to: -1, edge: spec.edge, centered: false)
      end

      # The columns a box's frame takes beside its text: the padding on
      # each side and, with an edge of one cell, the border on each side.
      #: (Integer) -> Integer
      def self.frame_width(edge)
        2 * (edge + PAD)
      end

      # The widest text a bordered float can show on a screen of cols
      # columns: the screen less its margin and its frame, the border
      # counted when the style draws an edge. Every float sized to the
      # screen asks this, so place never cuts a row it laid out.
      #: (Integer, String) -> Integer
      def self.text_room(cols, style)
        cols - 2 * MARGIN - frame_width(BorderStyle.edged?(style) ? 1 : 0)
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
      # anchor cell (top, left), or centered when the float is, inside
      # rows by cols cells, less MARGIN on each side for an editor-anchored
      # box, with an edge when the spec asks for a border and edged (the
      # border style draws one): its size is cut to fit first, then its
      # corner moved in, so the whole box shows whenever the area holds a
      # one-cell text area, its padding, and its border.
      #: (Integer, Integer, Integer, Integer, bool) -> void
      def place(top, left, rows, cols, edged)
        self.edge = edged ? spec.edge : 0
        margin = spec.cursor_anchored? ? 0 : MARGIN
        frame = FloatWindow.frame_width(edge)
        height = fit(spec.height, rows - 2 * margin - 2 * edge)
        width = fit(spec.width, cols - 2 * margin - frame)
        box_col = centered ? (cols - width - frame) / 2 : left + spec.col
        box_row = shift(top + spec.row, height + 2 * edge, rows, margin)
        box_col = shift(box_col, width + frame, cols, margin)
        window.row = box_row + edge
        window.col = box_col + edge + PAD
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

      # The corner at moved in so a box of size cells lies inside room
      # less margin on each side, or inside room when it cannot hold the
      # box and its margin.
      #: (Integer, Integer, Integer, Integer) -> Integer
      def shift(at, size, room, margin)
        low = size + 2 * margin > room ? 0 : margin
        high = room - low
        at = high - size if at + size > high
        at < low ? low : at
      end
    end
  end
end
