require_relative "position"
require_relative "range"
require_relative "buffer"
require_relative "registers"

module Carat
  module Domain
    # The buffer work behind the operators, each a function from a Range,
    # or a row, to the buffer primitives. A linewise range covers the rows
    # from its from row to its to row inclusive; a charwise range is used
    # normalized. Cursor and mode placement belong to the Operate use case.
    module Operators
      # The text a range covers, with its kind.
      #: (Buffer, Range) -> RegisterEntry
      def self.extract(buffer, range)
        if range.kind == :linewise
          RegisterEntry.lines(buffer.lines_of(range.from.row, range.to.row))
        else
          RegisterEntry.charwise(buffer.text_of(range))
        end
      end

      #: (Buffer, Range) -> void
      def self.delete(buffer, range)
        if range.kind == :linewise
          buffer.set_lines(range.from.row, range.to.row + 1, [])
        else
          buffer.delete(range)
        end
      end

      # Puts entry count times after (or before) pos and returns where the
      # cursor goes: the last inserted character of one-line charwise text,
      # the first inserted character of multi-line charwise text, or the
      # first non-blank of the first new line of linewise text.
      #: (Buffer, Position, RegisterEntry, Integer, bool) -> Position
      def self.put(buffer, pos, entry, count, after)
        if entry.linewise
          row = after ? pos.row + 1 : pos.row
          lines = []
          i = 0
          while i < count
            lines.concat(entry.lines)
            i += 1
          end
          buffer.set_lines(row, row, lines)
          return Position.new(row, buffer.first_nonblank(row))
        end
        text = +""
        i = 0
        while i < count
          text << entry.text
          i += 1
        end
        len = buffer.line(pos.row).length
        col = after ? pos.col + 1 : pos.col
        col = len if col > len
        buffer.insert(Position.new(pos.row, col), text)
        return Position.new(pos.row, col) if text.include?("\n")
        Position.new(pos.row, col + text.length - 1)
      end

      # Joins count lines (at least two) starting at row and returns the
      # column of the last join: leading blanks of each joined line are
      # dropped and one space inserted unless the text so far ends in a
      # blank or the joined line is empty or starts with ")".
      #: (Buffer, Integer, Integer) -> Integer
      def self.join(buffer, row, count)
        text = buffer.line(row)
        col = 0
        i = 1
        while i < count
          next_line = buffer.line(row + i)
          j = 0
          j += 1 while j < next_line.length && (next_line[j, 1] == " " || next_line[j, 1] == "\t")
          rest = next_line[j, next_line.length - j]
          col = text.length
          if !rest.empty? && !rest.start_with?(")") && !text.empty? && !text.end_with?(" ") && !text.end_with?("\t")
            text = text + " " + rest
          else
            text = text + rest
          end
          i += 1
        end
        buffer.set_lines(row, row + count, [text])
        col
      end

      # Shifts rows from..to by amount steps of shiftwidth: right when
      # amount is positive, left otherwise, never below column 0, leaving
      # empty lines alone when shifting right.
      #: (Buffer, Integer, Integer, Integer, Integer, Integer, bool) -> void
      def self.shift(buffer, from, to, amount, shiftwidth, tabstop, expandtab)
        width = shiftwidth > 0 ? shiftwidth : (tabstop > 0 ? tabstop : 8)
        lines = []
        row = from
        while row <= to
          line = buffer.line(row)
          if line.empty? && amount > 0
            lines << line
          else
            indent = buffer.indent_of(row)
            columns = indent_width(indent, tabstop) + amount * width
            columns = 0 if columns < 0
            lines << make_indent(columns, tabstop, expandtab) + line[indent.length, line.length - indent.length]
          end
          row += 1
        end
        buffer.set_lines(from, to + 1, lines)
      end

      # The display width of leading blanks.
      #: (String, Integer) -> Integer
      def self.indent_width(indent, tabstop)
        ts = tabstop > 0 ? tabstop : 8
        width = 0
        i = 0
        while i < indent.length
          width = indent[i, 1] == "\t" ? width + ts - (width % ts) : width + 1
          i += 1
        end
        width
      end

      # Blanks of the given display width: spaces, or tabs then spaces.
      #: (Integer, Integer, bool) -> String
      def self.make_indent(columns, tabstop, expandtab)
        return " " * columns if expandtab || tabstop <= 0
        ("\t" * (columns / tabstop)) + (" " * (columns % tabstop))
      end
    end
  end
end
