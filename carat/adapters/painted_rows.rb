module Carat
  module Adapters
    # What each window row segment of one frame shows, kept beside the
    # frame by the frame presenter so it can tell which segments to paint
    # and which rows changed. A segment is the part of a frame row inside
    # one window, indexed row * slots + the window's place in the layout
    # order, slots being at least the number of windows. For each
    # it keeps every input of its cells: the line string it drew (compared
    # by identity, since lines are never changed in place; TILDE for a row
    # past the end of the buffer, UNSET for nothing painted), the window's
    # horizontal scroll, width, and gutter width, the line number and the
    # sign shown, the selected display columns and the line end cell, and
    # the cursor's column on the cursor row; and, to recognize a scroll,
    # the window id and its first visible row.
    class PaintedRows
      UNSET = String.new("unset")
      TILDE = String.new("tilde")

      attr_reader :size #: Integer
      attr_reader :slots #: Integer

      # @rbs @lines: Array[String]
      # @rbs @lefts: Array[Integer]
      # @rbs @widths: Array[Integer]
      # @rbs @gutters: Array[Integer]
      # @rbs @numbers: Array[Integer]
      # @rbs @signs: Array[String]
      # @rbs @sel_froms: Array[Integer]
      # @rbs @sel_tos: Array[Integer]
      # @rbs @sel_ends: Array[Integer]
      # @rbs @cursors: Array[Integer]
      # @rbs @owners: Array[Integer]
      # @rbs @tops: Array[Integer]

      #: (rows: Integer, slots: Integer) -> void
      def initialize(rows:, slots:)
        size = rows * slots
        @size = size
        @slots = slots
        @lines = Array.new(size, UNSET)
        @lefts = Array.new(size, 0)
        @widths = Array.new(size, 0)
        @gutters = Array.new(size, 0)
        @numbers = Array.new(size, 0)
        @signs = Array.new(size, "")
        @sel_froms = Array.new(size, 0)
        @sel_tos = Array.new(size, 0)
        @sel_ends = Array.new(size, 0)
        @cursors = Array.new(size, 0)
        @owners = Array.new(size, 0)
        @tops = Array.new(size, 0)
      end

      # The segment of a frame row in the window at a place of the layout
      # order.
      #: (Integer, Integer) -> Integer
      def index(row, slot)
        row * @slots + slot
      end

      # Forgets every segment, as after the geometry changed.
      #: () -> void
      def invalidate
        i = 0
        while i < @size
          @lines[i] = UNSET
          i += 1
        end
      end

      # Whether segment i shows exactly this.
      #: (Integer, String, Integer, Integer, Integer, Integer, String, Integer, Integer, Integer, Integer) -> bool
      def same?(i, line, left, width, gutter, number, sign, sel_from, sel_to, sel_end, cursor)
        @lines[i].equal?(line) && @lefts[i] == left && @widths[i] == width && @gutters[i] == gutter &&
          @numbers[i] == number && @sel_froms[i] == sel_from && @sel_tos[i] == sel_to && @sel_ends[i] == sel_end &&
          @cursors[i] == cursor && @signs[i] == sign
      end

      # Records what segment i shows.
      #: (Integer, String, Integer, Integer, Integer, Integer, String, Integer, Integer, Integer, Integer) -> void
      def store(i, line, left, width, gutter, number, sign, sel_from, sel_to, sel_end, cursor)
        @lines[i] = line
        @lefts[i] = left
        @widths[i] = width
        @gutters[i] = gutter
        @numbers[i] = number
        @signs[i] = sign
        @sel_froms[i] = sel_from
        @sel_tos[i] = sel_to
        @sel_ends[i] = sel_end
        @cursors[i] = cursor
      end

      # Records which window painted segment i and its first visible row.
      #: (Integer, Integer, Integer) -> void
      def place(i, owner, top)
        @owners[i] = owner
        @tops[i] = top
      end

      #: (Integer) -> bool
      def painted?(i)
        !@lines[i].equal?(UNSET)
      end

      #: (Integer) -> Integer
      def owner(i)
        @owners[i]
      end

      #: (Integer) -> Integer
      def top(i)
        @tops[i]
      end
    end
  end
end
