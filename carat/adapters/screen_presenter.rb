require_relative "../ports/terminal_port"
require_relative "../domain/frame"
require_relative "../domain/highlight"

module Carat
  module Adapters
    # Writes frames to the terminal as ANSI bytes, one write per frame,
    # sending only the runs of cells that changed, with the cursor shape
    # per mode and the alternate screen on enter and leave.
    #
    # It keeps the last frame it presented and the serial that frame had
    # then. A frame drawn after that one (its base serial is that serial)
    # is trusted: its scrolls are sent as scroll regions (DECSTBM, scroll
    # up or down, reset), and only its dirty rows are compared, each with
    # the row of the last frame the terminal shows there after the
    # scrolls, or with a blank row for a row that came into view. The same
    # frame presented again unchanged writes only the cursor. Any other
    # frame is compared row by row with the last one when that one still
    # holds what it showed, and drawn in full otherwise, as is the first
    # frame and every frame after a size change.
    class ScreenPresenter
      ENTER = "\e[?1049h\e[H\e[2J"
      LEAVE = "\e[0m\e[2 q\e[?25h\e[?1049l"
      # Unchanged cells fewer than this between two changed runs of a row
      # are written again to join the runs, which costs no more than the
      # cursor position between them.
      JOIN = 8

      attr_reader :terminal #: Ports::TerminalPort

      # @rbs @shadow: Domain::Frame?
      # @rbs @shadow_serial: Integer
      # @rbs @shape: Symbol
      # @rbs @hl: Integer

      #: (terminal: Ports::TerminalPort) -> void
      def initialize(terminal:)
        @terminal = terminal
        @shadow = nil
        @shadow_serial = 0
        @shape = :none
        @hl = -1
      end

      #: () -> void
      def enter
        @terminal.enter
        @terminal.write(ENTER)
        @shadow = nil
        @shape = :none
      end

      #: () -> void
      def leave
        @terminal.write(LEAVE)
        @terminal.leave
      end

      # Writes the frame to the terminal in one write. The caller may
      # repaint the frame afterwards; the presenter notices from its
      # serial.
      #: (Domain::Frame) -> void
      def present(frame)
        out = +"\e[?25l"
        @hl = -1
        shadow = @shadow
        if shadow.nil? || shadow.rows != frame.rows || shadow.cols != frame.cols
          full(frame, out)
        elsif shadow.equal?(frame)
          full(frame, out) unless frame.serial == @shadow_serial
        elsif frame.base_serial == @shadow_serial && shadow.serial == @shadow_serial
          incremental(frame, shadow, out)
        elsif shadow.serial == @shadow_serial
          compare_all(frame, shadow, out)
        else
          full(frame, out)
        end
        out << "\e[0m" if @hl >= 0
        position(out, frame.cursor_row, frame.cursor_col)
        if frame.cursor_shape != @shape
          out << (frame.cursor_shape == :bar ? "\e[6 q" : "\e[2 q")
          @shape = frame.cursor_shape
        end
        out << "\e[?25h"
        @terminal.write(out)
        @shadow = frame
        @shadow_serial = frame.serial
      end

      private

      # Clears the screen and writes every row.
      #: (Domain::Frame, String) -> void
      def full(frame, out)
        out << "\e[2J"
        row = 0
        while row < frame.rows
          write_row(frame, row, nil, -1, out)
          row += 1
        end
      end

      # Sends the frame's scrolls, then compares its dirty rows with the
      # rows they came from.
      #: (Domain::Frame, Domain::Frame, String) -> void
      def incremental(frame, shadow, out)
        scrolls = frame.scrolls
        i = 0
        while i + 2 < scrolls.length
          first = scrolls[i]
          last = scrolls[i + 1]
          delta = scrolls[i + 2]
          out << "\e[0m" if @hl != 0
          @hl = 0
          out << "\e["
          number(out, first + 1)
          out << ";"
          number(out, last + 1)
          out << "r\e["
          number(out, delta > 0 ? delta : -delta)
          out << (delta > 0 ? "S" : "T")
          out << "\e[r"
          i += 3
        end
        sources = frame.sources
        row = 0
        while row < frame.rows
          write_row(frame, row, shadow, sources[row], out) if frame.dirty?(row)
          row += 1
        end
      end

      # Compares every row with the same row of the last frame.
      #: (Domain::Frame, Domain::Frame, String) -> void
      def compare_all(frame, shadow, out)
        row = 0
        while row < frame.rows
          write_row(frame, row, shadow, row, out)
          row += 1
        end
      end

      # Writes the runs of cells of a row that differ from row source of
      # the old frame, or from a blank row when source is -1 or there is
      # no old frame. A run that starts on the second cell of a wide
      # character, in either frame, starts one cell earlier, and runs
      # closer than JOIN cells are joined.
      #: (Domain::Frame, Integer, Domain::Frame?, Integer, String) -> void
      def write_row(frame, row, old, source, out)
        cols = frame.cols
        codes = frame.codes
        widths = frame.widths
        hls = frame.hls
        base = row * cols
        old_codes = codes
        old_widths = widths
        old_hls = hls
        old_base = -1
        unless old.nil? || source < 0
          old_codes = old.codes
          old_widths = old.widths
          old_hls = old.hls
          old_base = source * cols
        end
        c = 0
        while c < cols
          if old_base < 0
            c += 1 while c < cols && codes[base + c] == Domain::Frame::SPACE && widths[base + c] == 1 && hls[base + c] == Domain::Highlight::NORMAL
          else
            c += 1 while c < cols && codes[base + c] == old_codes[old_base + c] && widths[base + c] == old_widths[old_base + c] && hls[base + c] == old_hls[old_base + c]
          end
          break if c >= cols
          start = c
          start -= 1 if start > 0 && (widths[base + start] == 0 || (old_base >= 0 && old_widths[old_base + start] == 0))
          stop = c + 1
          gap = 0
          while stop < cols && gap < JOIN
            if same_cell?(codes, widths, hls, base + stop, old_codes, old_widths, old_hls, old_base, stop)
              gap += 1
            else
              gap = 0
            end
            stop += 1
          end
          stop -= gap
          stop += 1 if stop < cols && widths[base + stop] == 0
          write_run(frame, row, start, stop, out)
          c = stop
        end
      end

      # Whether cell i of the frame equals cell col of the old row at
      # old_base, or is a blank when old_base is -1.
      #: (Array[Integer], Array[Integer], Array[Integer], Integer, Array[Integer], Array[Integer], Array[Integer], Integer, Integer) -> bool
      def same_cell?(codes, widths, hls, i, old_codes, old_widths, old_hls, old_base, col)
        if old_base < 0
          return codes[i] == Domain::Frame::SPACE && widths[i] == 1 && hls[i] == Domain::Highlight::NORMAL
        end
        j = old_base + col
        codes[i] == old_codes[j] && widths[i] == old_widths[j] && hls[i] == old_hls[j]
      end

      # Positions the cursor and writes cells [from, to) of a row, the
      # highlight escape whenever the group changes, the continuation
      # cells of wide characters skipped.
      #: (Domain::Frame, Integer, Integer, Integer, String) -> void
      def write_run(frame, row, from, to, out)
        position(out, row, from)
        cols = frame.cols
        codes = frame.codes
        widths = frame.widths
        hls = frame.hls
        i = row * cols + from
        last = row * cols + to
        while i < last
          if widths[i] > 0
            hl = hls[i]
            if hl != @hl
              out << sgr(hl)
              @hl = hl
            end
            out << codes[i]
          end
          i += 1
        end
      end

      # Appends the cursor position sequence for a 0-based row and column.
      #: (String, Integer, Integer) -> void
      def position(out, row, col)
        out << "\e["
        number(out, row + 1)
        out << ";"
        number(out, col + 1)
        out << "H"
      end

      # Appends the decimal digits of a number of zero or more, up to five
      # digits, a code point at a time, so no string is built for it.
      #: (String, Integer) -> void
      def number(out, value)
        out << 48 + value / 10_000 % 10 if value >= 10_000
        out << 48 + value / 1000 % 10 if value >= 1000
        out << 48 + value / 100 % 10 if value >= 100
        out << 48 + value / 10 % 10 if value >= 10
        out << 48 + value % 10
      end

      #: (Integer) -> String
      def sgr(hl)
        case hl
        when Domain::Highlight::LINE_NUMBER then "\e[0;33m"
        when Domain::Highlight::STATUS then "\e[0;7m"
        when Domain::Highlight::MESSAGE_ERROR then "\e[0;37;41m"
        when Domain::Highlight::NON_TEXT then "\e[0;34m"
        when Domain::Highlight::STATUS_NC then "\e[0;2;7m"
        when Domain::Highlight::TAB_LINE then "\e[0;7m"
        when Domain::Highlight::TAB_LINE_SELECTED then "\e[0;1m"
        when Domain::Highlight::TAB_LINE_FILL then "\e[0;7m"
        when Domain::Highlight::VISUAL then "\e[0;7m"
        else "\e[0m"
        end
      end
    end
  end
end
