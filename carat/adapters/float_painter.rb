require_relative "../domain/frame"
require_relative "../domain/highlight"
require_relative "../domain/display_width"
require_relative "../domain/border_style"
require_relative "../domain/line_cache"
require_relative "../domain/options"
require_relative "../domain/float_layer"
require_relative "../domain/float_window"
require_relative "../domain/message_history"
require_relative "../domain/notices"
require_relative "line_painter"

module Carat
  module Adapters
    # Paints the floating windows of the tab page and the notification
    # boxes, the frame presenter calling it after the windows, the bars,
    # and the start screen. The floats are drawn by z: their text in
    # NormalFloat (a menu's in Pmenu, its selected row in PmenuSel) with
    # a column of padding in the same colors on each side, a
    # documentation row's styles on the float layer (under plain only
    # a selected row's bar and label, PmenuMarkSel and PmenuLabelSel), the
    # border of option.winborder or the float's own style in FloatBorder
    # (none under none, ASCII when plain or under option.icons ascii),
    # and the title centered on the top edge with a blank on each side in
    # FloatTitle. The notifications follow at the top right in the same
    # border, their severity centered as a title is, all in Normal and
    # ASCII when plain (NO_COLOR). It keeps the boxes of a frame as its
    # key, STRIDE integers a box, which the presenter compares with the
    # frames' to know the rows to repaint and compare; painting a box
    # allocates nothing.
    class FloatPainter
      # The integers of a box in the key.
      STRIDE = 11
      # The title of a notification box by its level.
      NOTICE_TITLES = ["Info", "Warning", "Error"]
      # The rows of a notification box and its narrowest width.
      NOTICE_HEIGHT = 3
      NOTICE_MIN_WIDTH = 20
      # The narrowest screen that draws notification boxes.
      NOTICE_NARROWEST = 8

      attr_reader :cache #: Domain::LineCache
      attr_reader :notices #: Domain::Notices
      attr_reader :key #: Array[Integer]
      attr_reader :plain #: bool

      # @rbs @lines: LinePainter
      # @rbs @notice_from: Integer
      # @rbs @border: Array[Integer]
      # @rbs @ascii: bool

      #: (cache: Domain::LineCache, notices: Domain::Notices) -> void
      def initialize(cache:, notices:)
        @cache = cache
        @notices = notices
        @lines = LinePainter.new
        @key = []
        @notice_from = 0
        @plain = false
        @border = Domain::BorderStyle::ROUNDED
        @ascii = false
      end

      # Draws the boxes with ASCII glyphs and no color when plain, as
      # NO_COLOR asks.
      #: (bool) -> void
      def plain=(value)
        @plain = value
      end

      # Takes the border glyphs of option.winborder for the frame, ASCII
      # when plain or under option.icons ascii.
      #: (Domain::Options) -> void
      def configure(options)
        @ascii = @plain || options.icons == "ascii"
        @border = Domain::BorderStyle.glyphs(options.winborder, @ascii)
      end

      # Whether a float of the tab page or a notification is there to
      # paint.
      #: (Domain::FloatLayer) -> bool
      def boxes?(floats)
        floats.count > 0 || @notices.count > 0
      end

      # Fills the key with the boxes to paint: the floats', then the
      # notifications' below the tab row.
      #: (Domain::FloatLayer, Integer, Integer, Integer) -> void
      def build_key(floats, rows, cols, tabline)
        build_float_key(floats)
        add_notice_boxes(rows, cols, tabline)
      end

      # Paints the floats, then the notifications: every row of a box when
      # full, else only the rows painted again under it in this frame, 1
      # in repainted.
      #: (Domain::Frame, Domain::FloatLayer, Array[Integer], Integer, Integer, Integer, bool) -> void
      def paint(frame, floats, repainted, tabstop, rows, cols, full)
        paint_floats(frame, floats, repainted, tabstop, rows, cols, full)
        paint_notices(frame, repainted, cols, full)
      end

      private

      # What the floats to paint show, STRIDE integers each: the box
      # (top, the row after it, left, the column after it), the first
      # row and column the float shows, its buffer's change counters, its
      # window id, so a float reopened at the same box repaints, its
      # selected menu row, and its style count, so a restyle repaints.
      #: (Domain::FloatLayer) -> void
      def build_float_key(floats)
        key = @key
        key.clear
        i = 0
        while i < floats.count
          float = floats.at(i)
          window = float.window
          buffer = window.buffer
          key << float.box_top
          key << float.box_bottom
          key << float.box_left
          key << float.box_right
          key << window.top
          key << window.left
          key << buffer.closed_count
          key << buffer.changes
          key << window.id
          key << float.selected
          key << float.style_count
          i += 1
        end
      end

      # Appends to the float key a box per notification, oldest first from
      # the row under the buffer tabs down, its right edge one column from
      # the screen's, as wide as its text and its border, at least
      # NOTICE_MIN_WIDTH so the title fits, within half the screen; a box
      # reaching the status bar and those after it are left out, and every
      # box on a screen narrower than NOTICE_NARROWEST. Its serial and
      # level follow the box, so a new notification repaints.
      #: (Integer, Integer, Integer) -> void
      def add_notice_boxes(rows, cols, tabline)
        key = @key
        @notice_from = key.length
        notices = @notices
        widest = cols / 2
        widest = NOTICE_MIN_WIDTH if widest < NOTICE_MIN_WIDTH
        right = cols - 1
        return if cols < NOTICE_NARROWEST
        i = 0
        while i < notices.count
          top = tabline + i * NOTICE_HEIGHT
          return if top + NOTICE_HEIGHT > rows - 2
          width = Domain::DisplayWidth.text_width(notices.text_at(i), 0) + 4
          width = NOTICE_MIN_WIDTH if width < NOTICE_MIN_WIDTH
          width = widest if width > widest
          left = right - width
          left = 0 if left < 0
          key << top
          key << top + NOTICE_HEIGHT
          key << left
          key << right
          key << notices.serial_at(i)
          key << notices.level_at(i)
          key << 0
          key << 0
          key << 0
          key << -1
          key << 0
          i += 1
        end
      end

      # Each notification box of the float key: every row when full, else
      # only the rows painted again under it in this frame.
      #: (Domain::Frame, Array[Integer], Integer, bool) -> void
      def paint_notices(frame, repainted, cols, full)
        key = @key
        i = @notice_from
        n = 0
        while i < key.length
          r = key[i]
          while r < key[i + 1]
            paint_notice_row(frame, n, r, key[i], key[i + 2], key[i + 3], cols) if full || repainted[r] == 1
            r += 1
          end
          i += STRIDE
          n += 1
        end
      end

      # One row of notification n's box from left to the column before
      # right: the border with its level's title on top, or its text.
      #: (Domain::Frame, Integer, Integer, Integer, Integer, Integer, Integer) -> void
      def paint_notice_row(frame, n, r, top, left, right, cols)
        mend_edges(frame, r, left, right, cols)
        plain = @plain
        last = right - 1
        bottom = top + NOTICE_HEIGHT - 1
        border = plain ? Domain::Highlight::NORMAL : Domain::Highlight::FLOAT_BORDER
        paint_edge(frame, r, left, last, top, bottom, border, @border)
        if r == top
          level = @notices.level_at(n)
          paint_title(frame, r, left, last, NOTICE_TITLES[level], plain ? Domain::Highlight::NORMAL : notice_group(level))
        elsif r != bottom
          text = plain ? Domain::Highlight::NORMAL : Domain::Highlight::NORMAL_FLOAT
          frame.blank(r, left + 1, last)
          frame.fill(r, left + 1, last, text)
          frame.put_within(r, left + 2, @notices.text_at(n), text, last - 1)
        end
      end

      # One row of a box's border from left to last in hl, in the border
      # glyphs given: on its top or bottom row the corners and the edge
      # between them, on any other row its two sides.
      #: (Domain::Frame, Integer, Integer, Integer, Integer, Integer, Integer, Array[Integer]) -> void
      def paint_edge(frame, r, left, last, top, bottom, hl, glyphs)
        if r == top || r == bottom
          frame.put_code(r, left, glyphs[r == top ? Domain::BorderStyle::TOP_LEFT : Domain::BorderStyle::BOTTOM_LEFT], 1, hl)
          frame.put_code(r, last, glyphs[r == top ? Domain::BorderStyle::TOP_RIGHT : Domain::BorderStyle::BOTTOM_RIGHT], 1, hl)
          code = glyphs[Domain::BorderStyle::HORIZONTAL]
          c = left + 1
          while c < last
            frame.put_code(r, c, code, 1, hl)
            c += 1
          end
        else
          code = glyphs[Domain::BorderStyle::VERTICAL]
          frame.put_code(r, left, code, 1, hl)
          frame.put_code(r, last, code, 1, hl)
        end
      end

      # The diagnostic group of a notification level's title.
      #: (Integer) -> Integer
      def notice_group(level)
        return Domain::Highlight::DIAGNOSTIC_ERROR if level == Domain::MessageHistory::ERROR
        return Domain::Highlight::DIAGNOSTIC_WARN if level == Domain::MessageHistory::WARNING
        Domain::Highlight::DIAGNOSTIC_INFO
      end

      # Each float in drawing order, one whose box leaves the screen above
      # the message row skipped: every row of it when full, else only the
      # rows painted again under it in this frame.
      #: (Domain::Frame, Domain::FloatLayer, Array[Integer], Integer, Integer, Integer, bool) -> void
      def paint_floats(frame, floats, repainted, tabstop, rows, cols, full)
        i = 0
        while i < floats.count
          float = floats.at(i)
          if float.box_top >= 0 && float.box_left >= 0 && float.box_bottom < rows && float.box_right <= cols
            r = float.box_top
            while r < float.box_bottom
              paint_float_row(frame, float, r, tabstop, cols) if full || repainted[r] == 1
              r += 1
            end
          end
          i += 1
        end
      end

      # One row of a float's box: its text, its padding, and the fill of
      # its group across both, a documentation row's styles on the float
      # layer (only a selected row's bar and label when plain, NO_COLOR), then its
      # border and, on the top edge, its title.
      #: (Domain::Frame, Domain::FloatWindow, Integer, Integer, Integer) -> void
      def paint_float_row(frame, float, r, tabstop, cols)
        mend_edges(frame, r, float.box_left, float.box_right, cols)
        window = float.window
        if r >= window.row && r < window.row + window.height
          x = window.col
          width = window.width
          inner_left = x - Domain::FloatWindow::PAD
          inner_right = x + width + Domain::FloatWindow::PAD
          buffer = window.buffer
          row = window.top + r - window.row
          text = row < buffer.line_count
          if text
            @lines.paint_text(frame, r, x, @cache.fetch(buffer.line(row), tabstop), width, window.left)
          else
            frame.blank(r, x, x + width)
          end
          frame.blank(r, inner_left, x)
          frame.blank(r, x + width, inner_right)
          frame.fill(r, inner_left, inner_right, float_group(float, row))
          if text && buffer.styled?
            line = buffer.line(row)
            @lines.paint_tokens(frame, r, x, @cache.fetch(line, tabstop), width, window.left, buffer.style_at(row, line).tokens, Domain::Highlight::FLOAT_LAYER, @plain)
          end
          paint_mark(frame, float, r, x, width) if row == 0 && float.marked?
        end
        paint_border_row(frame, float, r) if float.edged?
      end

      # The marked columns of a float's first row in Visual, within its
      # text area of width cells from x.
      #: (Domain::Frame, Domain::FloatWindow, Integer, Integer, Integer) -> void
      def paint_mark(frame, float, r, x, width)
        left = float.window.left
        from = x + float.mark_from - left
        to = x + float.mark_to - left
        from = x if from < x
        to = x + width if to > x + width
        frame.fill(r, from, to, Domain::Highlight::VISUAL) if to > from
      end

      # The group of a float's text row: NormalFloat, or for a menu Pmenu
      # and PmenuSel on its selected row.
      #: (Domain::FloatWindow, Integer) -> Integer
      def float_group(float, row)
        return Domain::Highlight::NORMAL_FLOAT unless float.menu?
        row == float.selected ? Domain::Highlight::POPUP_MENU_SELECTED : Domain::Highlight::POPUP_MENU
      end

      # Blanks the halves of wide characters a box cuts at its edges, so
      # no cell is left holding half of one.
      #: (Domain::Frame, Integer, Integer, Integer, Integer) -> void
      def mend_edges(frame, row, left, right, cols)
        frame.blank(row, left - 1, left) if left > 0 && frame.width_at(row, left - 1) == 2
        frame.blank(row, right, right + 1) if right < cols && frame.width_at(row, right) == 0
      end

      # The border cells of one row of a float's box in FloatBorder, in
      # the float's own border style or the frame's, and, on its top
      # edge, its title centered between the corners.
      #: (Domain::Frame, Domain::FloatWindow, Integer) -> void
      def paint_border_row(frame, float, r)
        left = float.box_left
        last = float.box_right - 1
        top = float.box_top
        style = float.border_style
        glyphs = style.empty? ? @border : Domain::BorderStyle.glyphs(style, @ascii)
        paint_edge(frame, r, left, last, top, float.box_bottom - 1, Domain::Highlight::FLOAT_BORDER, glyphs)
        title = float.spec.title
        paint_title(frame, r, left, last, title, Domain::Highlight::FLOAT_TITLE) if r == top && !title.empty?
      end

      # A title between the corners at left and last, with a blank on each
      # side, centered and cut to the cells between them, in hl: FloatTitle
      # for a float, the severity's group for a notification.
      #: (Domain::Frame, Integer, Integer, Integer, String, Integer) -> void
      def paint_title(frame, r, left, last, title, hl)
        room = last - left - 1
        return if room < 3
        width = Domain::DisplayWidth.text_width(title, 0) + 2
        width = room if width > room
        from = left + 1 + (room - width) / 2
        frame.put_code(r, from, 0x20, 1, hl)
        stop = frame.put_within(r, from + 1, title, hl, from + width - 1)
        frame.put_code(r, stop, 0x20, 1, hl)
      end
    end
  end
end
