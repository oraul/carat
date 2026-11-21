require_relative "position"
require_relative "range"
require_relative "buffer"

module Carat
  module Domain
    # Line comments as Neovim's built-in commenting makes them: the marker
    # of a buffer's filetype, whether a line is commented, the toggle of a
    # row range, and the block of adjacent commented rows the gc text
    # object selects. A line is commented when its first non-blank
    # characters are the marker. The toggle uncomments when every
    # non-blank line of the range is commented, removing the marker and
    # one space after it, and otherwise comments every non-blank line with
    # the marker and one space at the smallest indent of the range; blank
    # lines are left as they are.
    module Comments
      # The comment marker of each filetype; a later filetype is one row.
      MARKERS = { "ruby" => "#" }

      # The marker of a filetype with no row in MARKERS, or of none.
      DEFAULT_MARKER = "#"

      #: (String) -> String
      def self.marker_for(filetype)
        found = MARKERS[filetype]
        found.nil? ? DEFAULT_MARKER : found
      end

      # Whether the line holds only spaces and tabs, or nothing.
      #: (Buffer, Integer) -> bool
      def self.blank?(buffer, row)
        buffer.indent_of(row).length == buffer.line(row).length
      end

      # Whether the row's first non-blank characters are the marker.
      #: (Buffer, Integer, String) -> bool
      def self.commented?(buffer, row, marker)
        indent = buffer.indent_of(row).length
        buffer.line(row)[indent, marker.length] == marker
      end

      # Toggles the comment of rows from to to (inclusive) with one
      # set_lines, or none when no line changes, so the toggle is one undo
      # step of the transaction around it.
      #: (Buffer, Integer, Integer, String) -> void
      def self.toggle(buffer, from, to, marker)
        uncomment = true
        indent = -1
        row = from
        while row <= to
          unless blank?(buffer, row)
            uncomment = false unless commented?(buffer, row, marker)
            width = buffer.indent_of(row).length
            indent = width if indent < 0 || width < indent
          end
          row += 1
        end
        return if indent < 0
        lines = []
        row = from
        while row <= to
          line = buffer.line(row)
          if blank?(buffer, row)
            lines << line
          elsif uncomment
            lines << uncommented(line, buffer.indent_of(row).length, marker)
          else
            lines << line[0, indent].to_s + marker + " " + line[indent, line.length - indent].to_s
          end
          row += 1
        end
        buffer.set_lines(from, to + 1, lines)
      end

      # The line without its marker and the one space after it; a line
      # left holding only blanks becomes empty.
      #: (String, Integer, String) -> String
      def self.uncommented(line, indent, marker)
        rest = indent + marker.length
        rest += 1 if line[rest, 1] == " "
        tail = line[rest, line.length - rest].to_s
        return "" if tail.strip.empty?
        line[0, indent].to_s + tail
      end

      # The linewise range of the adjacent commented rows around row, or
      # nil when row is not commented; a blank row ends the block.
      #: (Buffer, Integer, String) -> Range?
      def self.block(buffer, row, marker)
        return nil if blank?(buffer, row) || !commented?(buffer, row, marker)
        from = row
        from -= 1 while from > 0 && !blank?(buffer, from - 1) && commented?(buffer, from - 1, marker)
        last = buffer.line_count - 1
        to = row
        to += 1 while to < last && !blank?(buffer, to + 1) && commented?(buffer, to + 1, marker)
        Range.new(from: Position.new(row: from, col: 0), to: Position.new(row: to, col: 0), kind: :linewise, inclusive: true)
      end
    end
  end
end
