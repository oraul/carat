require_relative "../domain/decoded_line"
require_relative "../domain/frame"
require_relative "../domain/highlight"
require_relative "../domain/options"

module Carat
  module Adapters
    # The whitespace marks of file windows, Neovim's list and listchars,
    # painted by the frame presenter over a row's text cells after its
    # syntax tokens and indent guides, so a tab's mark shows over a
    # guide: the tab marks over every cell a tab takes (the first mark on
    # its first cell, the middle mark on the cells after, and the last
    # mark, when given, on its last cell), the trail mark over each space
    # after the line's last other character, and the nbsp mark over each
    # no-break space, all in Whitespace. The marks' code points are read
    # from the options once a frame, only when list is on and the
    # listchars or the icon set changed, so painting allocates nothing.
    class WhitespaceMarks
      # The no-break spaces Neovim marks: U+00A0 and U+202F.
      NBSP = 0xa0
      NARROW_NBSP = 0x202f

      # @rbs @on: bool
      # @rbs @source: String
      # @rbs @ascii: bool
      # @rbs @serial: Integer
      # @rbs @tab_first: Integer
      # @rbs @tab_middle: Integer
      # @rbs @tab_last: Integer
      # @rbs @trail: Integer
      # @rbs @nbsp: Integer

      #: () -> void
      def initialize
        @on = false
        @source = ""
        @ascii = false
        @serial = 0
        @tab_first = 0
        @tab_middle = 0
        @tab_last = 0
        @trail = 0
        @nbsp = 0
      end

      # Takes a frame's options and returns the stamp of the marks'
      # settings for the frame's geometry key: 0 with list off, else a
      # serial that changes whenever a mark does.
      #: (Domain::Options) -> Integer
      def configure(options)
        @on = options.list
        return 0 unless @on
        ascii = options.icons == "ascii"
        unless options.listchars.equal?(@source) && ascii == @ascii
          @source = options.listchars
          @ascii = ascii
          @tab_first = options.listchar_code("tab", 0)
          @tab_middle = options.listchar_code("tab", 1)
          @tab_last = options.listchar_code("tab", 2)
          @trail = options.listchar_code("trail", 0)
          @nbsp = options.listchar_code("nbsp", 0)
          @serial += 1
        end
        @serial
      end

      # Whether list is on for this frame.
      #: () -> bool
      def on?
        @on
      end

      # Paints the marks of a decoded line on a frame row whose text starts
      # at column col, width cells wide, scrolled left columns.
      #: (Domain::Frame, Integer, Integer, Domain::DecodedLine, Integer, Integer) -> void
      def paint(frame, frame_row, col, decoded, width, left)
        limit = left + width
        if decoded.plain
          paint_trail(frame, frame_row, col, decoded.text, left, limit)
          return
        end
        codes = decoded.codes
        cols = decoded.cols
        n = codes.length
        trailing = n
        trailing -= 1 while trailing > 0 && codes[trailing - 1] == 32
        k = left > 0 ? decoded.index_at(left) : 0
        while k < n
          dcol = cols[k]
          break if dcol >= limit
          code = codes[k]
          if code == 9
            paint_tab(frame, frame_row, col, dcol, cols[k + 1], left, limit) if @tab_first != 0
          elsif dcol >= left
            mark = 0
            mark = @trail if code == 32 && k >= trailing
            mark = @nbsp if code == NBSP || code == NARROW_NBSP
            frame.put_code(frame_row, col + dcol - left, mark, 1, Domain::Highlight::WHITESPACE) if mark != 0
          end
          k += 1
        end
      end

      private

      # The trail marks of a plain line, one cell per byte.
      #: (Domain::Frame, Integer, Integer, String, Integer, Integer) -> void
      def paint_trail(frame, frame_row, col, text, left, limit)
        return if @trail == 0
        n = text.bytesize
        k = n
        k -= 1 while k > 0 && text.getbyte(k - 1) == 32
        k = left if k < left
        stop = n < limit ? n : limit
        while k < stop
          frame.put_code(frame_row, col + k - left, @trail, 1, Domain::Highlight::WHITESPACE)
          k += 1
        end
      end

      # The marks of a tab over its visible cells, from display column
      # from up to to.
      #: (Domain::Frame, Integer, Integer, Integer, Integer, Integer, Integer) -> void
      def paint_tab(frame, frame_row, col, from, to, left, limit)
        c = from < left ? left : from
        stop = to < limit ? to : limit
        while c < stop
          mark = @tab_middle
          mark = @tab_first if c == from
          mark = @tab_last if c == to - 1 && @tab_last != 0
          frame.put_code(frame_row, col + c - left, mark, 1, Domain::Highlight::WHITESPACE)
          c += 1
        end
      end
    end
  end
end
