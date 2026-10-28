module Carat
  module Domain
    # The text of one file as an array of line strings without newlines, plus
    # path, modified, and line_ending. All edits go through the four
    # primitives insert, delete, replace, and set_lines; a later change hooks
    # transactions into them without changing their signatures. Lines are
    # never mutated in place: every primitive stores new strings. A Struct
    # record: mutable, with a reader and a writer per member.
    class Buffer < Struct.new(:lines, :path, :line_ending, :modified)
      # @rbs @lines: Array[String]
      # @rbs @path: String?
      # @rbs @line_ending: String
      # @rbs @modified: bool

      #: (Array[String], String?, String) -> void
      def initialize(lines, path, line_ending)
        lines << "" if lines.empty?
        super(lines, path, line_ending, false)
      end

      # Splits file text into lines. The line ending is "\r\n" when the first
      # terminator is one, "\n" otherwise; a trailing terminator does not
      # produce an extra empty line.
      #: (String, String?) -> Buffer
      def self.from_text(text, path)
        first = text.index("\n")
        ending = "\n"
        ending = "\r\n" if !first.nil? && first > 0 && text[first - 1, 1] == "\r"
        body = ending == "\r\n" ? text.gsub("\r\n", "\n") : text
        lines = body.split("\n", -1)
        lines.pop if lines.length > 1 && lines.last == ""
        lines = [""] if lines.empty?
        new(lines, path, ending)
      end

      # The file text: every line followed by the line ending.
      #: () -> String
      def to_text
        lines.join(line_ending) + line_ending
      end

      #: () -> Integer
      def line_count
        lines.length
      end

      # The line at row, or an empty string outside the buffer.
      #: (Integer) -> String
      def line(row)
        l = lines[row]
        l.nil? ? "" : l
      end

      #: () -> Integer
      def byte_count
        to_text.bytesize
      end

      # Inserts text at pos; newlines in text split the line.
      #: (Position, String) -> void
      def insert(pos, text)
        return if text.empty?
        current = line(pos.row)
        col = clamp_col(current, pos.col)
        head = current[0, col]
        tail = tail_of(current, col)
        parts = text.split("\n", -1)
        if parts.length == 1
          set_lines(pos.row, pos.row + 1, [head + text + tail])
        else
          middle = parts[1, parts.length - 2]
          new_lines = [head + parts[0]]
          new_lines.concat(middle)
          new_lines << parts[parts.length - 1] + tail
          set_lines(pos.row, pos.row + 1, new_lines)
        end
      end

      # Deletes a charwise range; a range spanning lines joins the remaining
      # head of the first line to the remaining tail of the last.
      #: (Range) -> void
      def delete(range)
        r = range.normalized
        from = r.from
        to = r.to
        if from.row == to.row
          current = line(from.row)
          a = clamp_col(current, from.col)
          b = clamp_col(current, to.col)
          set_lines(from.row, from.row + 1, [current[0, a] + tail_of(current, b)])
        else
          first = line(from.row)
          last = line(to.row)
          head = first[0, clamp_col(first, from.col)]
          tail = tail_of(last, clamp_col(last, to.col))
          set_lines(from.row, to.row + 1, [head + tail])
        end
      end

      # Replaces a charwise range with text in one step.
      #: (Range, String) -> void
      def replace(range, text)
        r = range.normalized
        delete(r)
        insert(r.from, text)
      end

      # Replaces the rows from..to (exclusive) with new_lines, keeping at
      # least one line in the buffer.
      #: (Integer, Integer, Array[String]) -> void
      def set_lines(from, to, new_lines)
        lines[from...to] = new_lines
        lines << "" if lines.empty?
        self.modified = true
      end

      private

      #: (String, Integer) -> Integer
      def clamp_col(text, col)
        return 0 if col < 0
        col > text.length ? text.length : col
      end

      #: (String, Integer) -> String
      def tail_of(text, col)
        col >= text.length ? "" : text[col, text.length - col]
      end
    end
  end
end
