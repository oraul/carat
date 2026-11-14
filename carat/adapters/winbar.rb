require_relative "../domain/frame"
require_relative "../domain/highlight"
require_relative "../domain/window"
require_relative "../domain/symbol_request"

module Carat
  module Adapters
    # Paints a file window's winbar, the row above its text: one space,
    # the buffer's path (the scratch title or [No Name]), and, when the
    # shared SymbolRequest holds that buffer's symbols, SEPARATOR (or
    # ASCII_SEPARATOR under option.icons ascii) and the
    # name of each symbol spanning the window's cursor row in the order
    # held, outermost first, then a space; the current window's in
    # TabLineSel, the others' in TabLine, the rest of the row in
    # TabLineFill, cut at the window's right edge. Every string written is
    # already stored, so a winbar costs no object per frame.
    class Winbar
      NO_NAME = "[No Name]"
      SEPARATOR = " › "
      ASCII_SEPARATOR = " > "

      attr_reader :symbols #: Domain::SymbolRequest

      #: (symbols: Domain::SymbolRequest) -> void
      def initialize(symbols:)
        @symbols = symbols
      end

      # Paints the winbar of the window on the frame row, the symbols
      # joined by ASCII_SEPARATOR when ascii.
      #: (Domain::Frame, Domain::Window, Integer, bool, bool) -> void
      def paint(frame, window, row, current, ascii)
        x = window.col
        limit = x + window.width
        frame.blank(row, x, limit)
        frame.fill(row, x, limit, Domain::Highlight::TAB_LINE_FILL)
        hl = current ? Domain::Highlight::TAB_LINE_SELECTED : Domain::Highlight::TAB_LINE
        buffer = window.buffer
        name = buffer.display_name
        c = frame.put_within(row, x, " ", hl, limit)
        c = frame.put_within(row, c, name.nil? ? NO_NAME : name, hl, limit)
        ask = @symbols
        if ask.held?(buffer.id)
          cursor_row = window.cursor.row
          separator = ascii ? ASCII_SEPARATOR : SEPARATOR
          i = 0
          while i < ask.count && c < limit
            if ask.spans?(i, cursor_row)
              c = frame.put_within(row, c, separator, hl, limit)
              c = frame.put_within(row, c, ask.name_at(i), hl, limit)
            end
            i += 1
          end
        end
        frame.put_within(row, c, " ", hl, limit)
      end
    end
  end
end
