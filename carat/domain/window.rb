module Carat
  module Domain
    # A viewport over the buffer: the first visible row and the first visible
    # display column. One window exists until the windows change. A Struct
    # record: mutable, with a reader and a writer per member.
    class Window < Struct.new(:top, :left)
      # @rbs @top: Integer
      # @rbs @left: Integer

      #: () -> void
      def initialize
        super(0, 0)
      end

      # Scrolls so that row is visible with scrolloff rows of context where
      # the buffer allows, in a window of height rows.
      #: (Integer, Integer, Integer, Integer) -> void
      def scroll_to_row(row, line_count, height, scrolloff)
        return if height <= 0
        off = scrolloff
        half = (height - 1) / 2
        off = half if off > half
        self.top = row - off if row - off < top
        self.top = row + off - height + 1 if row + off >= top + height
        max_top = line_count - height
        max_top = 0 if max_top < 0
        self.top = max_top if top > max_top
        self.top = 0 if top < 0
      end

      # Scrolls horizontally so that display column col is visible in a text
      # area of width columns.
      #: (Integer, Integer) -> void
      def scroll_to_col(col, width)
        return if width <= 0
        self.left = col if col < left
        self.left = col - width + 1 if col >= left + width
        self.left = 0 if left < 0
      end
    end
  end
end
