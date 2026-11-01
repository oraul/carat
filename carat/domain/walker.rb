require_relative "position"
require_relative "buffer"
require_relative "utf8"

module Carat
  module Domain
    # Steps through a buffer one character at a time, the way Vim's inc()
    # and dec() do: the column may rest on the end of a line (the NUL), an
    # empty line is its own position, and each step reports whether it
    # stayed on the line (0), crossed to another line (1), landed on the
    # end of the line (2), or could not move (-1). A Struct record used
    # only while a word motion runs. It keeps the code points of the last
    # line it classified, decoded once, so a word motion over a long UTF-8
    # line slices no one-character strings.
    class Walker < Struct.new(:buffer, :row, :col, :codes, :codes_line)
      # @rbs @buffer: Buffer
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @codes: Array[Integer]
      # @rbs @codes_line: String

      #: (Buffer, Integer, Integer) -> void
      def initialize(buffer, row, col)
        super(buffer, row, col, [], "")
      end

      #: () -> Integer
      def step_forward
        len = buffer.line(row).length
        if col < len
          self.col = col + 1
          return col < len ? 0 : 2
        end
        return -1 if row >= buffer.line_count - 1
        self.row = row + 1
        self.col = 0
        1
      end

      #: () -> Integer
      def step_backward
        if col > 0
          self.col = col - 1
          return 0
        end
        return -1 if row == 0
        self.row = row - 1
        self.col = buffer.line(row).length
        1
      end

      # The class of the character under the walker: 0 for a blank or the
      # end of the line, 1 for other characters, 2 for keyword characters;
      # for WORDs every non-blank is 1.
      #: (bool) -> Integer
      def char_class(big)
        line = buffer.line(row)
        return 0 if col >= line.length
        unless codes_line.equal?(line)
          self.codes = Utf8.codes(line)
          self.codes_line = line
        end
        Motions.code_class(codes[col], big)
      end

      #: () -> bool
      def empty_line?
        buffer.line(row).empty?
      end

      #: () -> Position
      def position
        Position.new(row, col)
      end
    end
  end
end
