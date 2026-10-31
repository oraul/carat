require_relative "position"
require_relative "range"
require_relative "buffer"
require_relative "registers"
require_relative "display_width"
require_relative "selection"

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
      # column of the last join. With spaces, as "J" does, leading blanks
      # of each joined line are dropped and one space inserted unless the
      # text so far ends in a blank or the joined line is empty or starts
      # with ")"; without, as "gJ" does, the lines are joined as they are.
      #: (Buffer, Integer, Integer, bool) -> Integer
      def self.join(buffer, row, count, spaces)
        text = buffer.line(row)
        col = 0
        i = 1
        while i < count
          next_line = buffer.line(row + i)
          col = text.length
          if spaces
            j = 0
            j += 1 while j < next_line.length && (next_line[j, 1] == " " || next_line[j, 1] == "\t")
            rest = next_line[j, next_line.length - j]
            if !rest.empty? && !rest.start_with?(")") && !text.empty? && !text.end_with?(" ") && !text.end_with?("\t")
              text = text + " " + rest
            else
              text = text + rest
            end
          else
            text = text + next_line
          end
          i += 1
        end
        buffer.set_lines(row, row + count, [text])
        col
      end

      # ------------------------------------------------------------ blocks

      # The rows of a block as a blockwise entry, each the characters the
      # block's columns meet.
      #: (Buffer, Block, Integer) -> RegisterEntry
      def self.extract_block(buffer, block, tabstop)
        rows = []
        r = block.top
        while r <= block.bottom
          line = buffer.line(r)
          span = block.span(line, tabstop)
          rows << line[span.from, span.to - span.from]
          r += 1
        end
        RegisterEntry.block(rows)
      end

      # Removes the characters of a block from every row, in one edit.
      #: (Buffer, Block, Integer) -> void
      def self.delete_block(buffer, block, tabstop)
        lines = []
        r = block.top
        while r <= block.bottom
          line = buffer.line(r)
          span = block.span(line, tabstop)
          lines << line[0, span.from] + line[span.to, line.length - span.to]
          r += 1
        end
        buffer.set_lines(block.top, block.bottom + 1, lines)
      end

      # Puts the rows of entry as a block from display column vcol of row
      # downward, each row count times: a row too short is padded with
      # spaces, rows past the end of the buffer are added, and each copy
      # is padded to the block's width unless nothing follows it. Returns
      # the position of the block's first character.
      #: (Buffer, Integer, Integer, RegisterEntry, Integer, Integer) -> Position
      def self.put_block(buffer, row, vcol, entry, count, tabstop)
        rows = entry.lines
        width = 0
        i = 0
        while i < rows.length
          w = DisplayWidth.column(rows[i], rows[i].length, tabstop)
          width = w if w > width
          i += 1
        end
        first = 0
        i = 0
        while i < rows.length
          r = row + i
          buffer.set_lines(r, r, [""]) if r >= buffer.line_count
          line = buffer.line(r)
          line_width = DisplayWidth.column(line, line.length, tabstop)
          line = line + (" " * (vcol - line_width)) if line_width < vcol
          col = DisplayWidth.col_at(line, vcol, tabstop)
          text = rows[i]
          pad = " " * (width - DisplayWidth.column(text, text.length, tabstop))
          piece = +""
          k = 0
          while k < count
            piece << text
            piece << pad if k < count - 1 || col < line.length
            k += 1
          end
          buffer.set_lines(r, r + 1, [line[0, col] + piece + line[col, line.length - col]])
          first = col if i == 0
          i += 1
        end
        Position.new(row, first)
      end

      # Shifts the text of every row that goes past the block by amount
      # steps of shiftwidth at the block's left edge: right inserts spaces
      # there, left removes up to that many columns of blanks after it.
      #: (Buffer, Block, Integer, Integer, Integer) -> void
      def self.shift_block(buffer, block, amount, shiftwidth, tabstop)
        width = shiftwidth > 0 ? shiftwidth : (tabstop > 0 ? tabstop : 8)
        total = (amount < 0 ? -amount : amount) * width
        lines = []
        r = block.top
        while r <= block.bottom
          line = buffer.line(r)
          line_width = DisplayWidth.column(line, line.length, tabstop)
          short = block.to_end ? line_width < block.left : line_width <= block.right
          if short
            lines << line
          else
            col = block.span(line, tabstop).from
            if amount > 0
              lines << line[0, col] + (" " * total) + line[col, line.length - col]
            else
              lines << line[0, col] + unindent(line, col, total, tabstop)
            end
          end
          r += 1
        end
        buffer.set_lines(block.top, block.bottom + 1, lines)
      end

      # The part of line from col with up to total columns of blanks
      # removed from its start; a tab that reaches past total leaves the
      # rest of its width as spaces.
      #: (String, Integer, Integer, Integer) -> String
      def self.unindent(line, col, total, tabstop)
        keep = ""
        removed = 0
        j = col
        while j < line.length && removed < total
          ch = line[j, 1]
          break unless ch == " " || ch == "\t"
          w = DisplayWidth.cell(ch, DisplayWidth.column(line, j, tabstop), tabstop)
          if removed + w > total
            keep = " " * (removed + w - total)
            removed = total
          else
            removed += w
          end
          j += 1
        end
        keep + line[j, line.length - j]
      end

      # -------------------------------------------------------------- case

      # text changed as the visual "~", "u", "U", and "r" change it: how is
      # :toggle, :lower, :upper, or :replace, which puts char in place of
      # every character.
      #: (String, Symbol, String) -> String
      def self.recase(text, how, char)
        case how
        when :toggle then text.swapcase
        when :lower then text.downcase
        when :upper then text.upcase
        else char * text.length
        end
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
