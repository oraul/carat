module Carat
  module Domain
    # A viewport over the buffer: the first visible row and the first visible
    # display column. One window exists until the windows change.
    class Window
      attr_accessor :top #: Integer
      attr_accessor :left #: Integer

      #: () -> void
      def initialize
        @top = 0
        @left = 0
      end

      # Scrolls so that row is visible with scrolloff rows of context where
      # the buffer allows, in a window of height rows.
      #: (Integer, Integer, Integer, Integer) -> void
      def scroll_to_row(row, line_count, height, scrolloff)
        return if height <= 0
        off = scrolloff
        half = (height - 1) / 2
        off = half if off > half
        @top = row - off if row - off < @top
        @top = row + off - height + 1 if row + off >= @top + height
        max_top = line_count - height
        max_top = 0 if max_top < 0
        @top = max_top if @top > max_top
        @top = 0 if @top < 0
      end

      # Scrolls horizontally so that display column col is visible in a text
      # area of width columns.
      #: (Integer, Integer) -> void
      def scroll_to_col(col, width)
        return if width <= 0
        @left = col if col < @left
        @left = col - width + 1 if col >= @left + width
        @left = 0 if @left < 0
      end
    end
  end
end
