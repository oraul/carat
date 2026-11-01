require_relative "../ports/terminal_port"
require_relative "../domain/frame"
require_relative "../domain/highlight"

module Carat
  module Adapters
    # Keeps the last frame and writes only changed rows as ANSI bytes, with
    # the cursor shape per mode and the alternate screen on enter and leave.
    # One write per frame.
    class ScreenPresenter
      ENTER = "\e[?1049h\e[H\e[2J"
      LEAVE = "\e[0m\e[2 q\e[?25h\e[?1049l"

      attr_reader :terminal #: Ports::TerminalPort

      # @rbs @shadow: Domain::Frame?
      # @rbs @shape: Symbol

      #: (terminal: Ports::TerminalPort) -> void
      def initialize(terminal:)
        @terminal = terminal
        @shadow = nil
        @shape = :none
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

      # Writes the frame to the terminal in one write, drawing only the rows
      # that changed since the last frame. The last frame is kept in a shadow
      # of the presenter's own, so the caller may reuse the frame it passes.
      #: (Domain::Frame) -> void
      def present(frame)
        out = +"\e[?25l"
        shadow = @shadow
        full = shadow.nil? || shadow.rows != frame.rows || shadow.cols != frame.cols
        out << "\e[2J" if full
        row = 0
        while row < frame.rows
          if full || shadow.nil? || !frame.row_same?(shadow, row)
            out << "\e[#{row + 1};1H"
            render_row(frame, row, out)
          end
          row += 1
        end
        out << "\e[#{frame.cursor_row + 1};#{frame.cursor_col + 1}H"
        if frame.cursor_shape != @shape
          out << (frame.cursor_shape == :bar ? "\e[6 q" : "\e[2 q")
          @shape = frame.cursor_shape
        end
        out << "\e[?25h"
        @terminal.write(out)
        if full
          shadow = Domain::Frame.new(frame.rows, frame.cols)
          @shadow = shadow
        end
        shadow.sync_from(frame)
      end

      private

      # Emits one row: runs of cells that share a highlight are packed from
      # their code points in one call, so the row costs a few allocations
      # rather than one per cell.
      #: (Domain::Frame, Integer, String) -> void
      def render_row(frame, row, out)
        hl = -1
        codes = []
        i = 0
        while i < frame.cols
          cell = frame.cell(row, i)
          if cell.width > 0
            if cell.hl != hl
              out << codes.pack("U*") unless codes.empty?
              codes = []
              out << sgr(cell.hl)
              hl = cell.hl
            end
            codes << cell.code
          end
          i += 1
        end
        out << codes.pack("U*") unless codes.empty?
        out << "\e[0m"
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
