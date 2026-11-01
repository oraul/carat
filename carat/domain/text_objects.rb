require_relative "position"
require_relative "range"
require_relative "buffer"
require_relative "editor_state"
require_relative "motions"
require_relative "runs"

module Carat
  module Domain
    # Text objects as pure functions from the editor state and a count to
    # the Range an operator works on, or nil when there is no such object
    # around the cursor. Word and sentence objects are charwise, paragraph
    # objects linewise, bracket objects charwise unless the inner form
    # stands between brackets that end their lines.
    module TextObjects
      # Every text object this module implements, in the order of the case
      # statement below; the action table registers them with the kind
      # :text_object.
      NAMES = [
        "textobject.inner_word", "textobject.a_word", "textobject.inner_big_word", "textobject.a_big_word",
        "textobject.inner_sentence", "textobject.a_sentence", "textobject.inner_paragraph", "textobject.a_paragraph",
        "textobject.inner_paren", "textobject.a_paren", "textobject.inner_bracket", "textobject.a_bracket",
        "textobject.inner_brace", "textobject.a_brace", "textobject.inner_angle", "textobject.a_angle",
        "textobject.inner_double_quote", "textobject.a_double_quote", "textobject.inner_single_quote",
        "textobject.a_single_quote", "textobject.inner_backtick", "textobject.a_backtick"
      ]

      # Whether the action names a text object.
      #: (String) -> bool
      def self.object?(action)
        NAMES.include?(action)
      end

      #: (EditorState, String, Integer) -> Range?
      def self.call(state, action, count)
        n = count > 0 ? count : 1
        case action
        when "textobject.inner_word" then word(state, n, false, false)
        when "textobject.a_word" then word(state, n, false, true)
        when "textobject.inner_big_word" then word(state, n, true, false)
        when "textobject.a_big_word" then word(state, n, true, true)
        when "textobject.inner_sentence" then sentence(state, n, false)
        when "textobject.a_sentence" then sentence(state, n, true)
        when "textobject.inner_paragraph" then paragraph(state, n, false)
        when "textobject.a_paragraph" then paragraph(state, n, true)
        when "textobject.inner_paren" then pair(state, n, "(", ")", false)
        when "textobject.a_paren" then pair(state, n, "(", ")", true)
        when "textobject.inner_bracket" then pair(state, n, "[", "]", false)
        when "textobject.a_bracket" then pair(state, n, "[", "]", true)
        when "textobject.inner_brace" then pair(state, n, "{", "}", false)
        when "textobject.a_brace" then pair(state, n, "{", "}", true)
        when "textobject.inner_angle" then pair(state, n, "<", ">", false)
        when "textobject.a_angle" then pair(state, n, "<", ">", true)
        when "textobject.inner_double_quote" then quote(state, "\"", false)
        when "textobject.a_double_quote" then quote(state, "\"", true)
        when "textobject.inner_single_quote" then quote(state, "'", false)
        when "textobject.a_single_quote" then quote(state, "'", true)
        when "textobject.inner_backtick" then quote(state, "`", false)
        when "textobject.a_backtick" then quote(state, "`", true)
        else nil
        end
      end

      # ------------------------------------------------------------ words

      # The runs of one line: blanks (0), other characters (1), keyword
      # characters (2), or blank and non-blank for WORDs.
      #: (String, bool) -> Runs
      def self.runs(line, big)
        result = Runs.new
        i = 0
        while i < line.length
          cls = Motions.char_class(line[i, 1], big)
          j = i + 1
          j += 1 while j < line.length && Motions.char_class(line[j, 1], big) == cls
          result.add(i, j, cls)
          i = j
        end
        result
      end

      # iw, aw, iW, aW on the cursor line. "a" adds the blanks after the
      # word, or the blanks before it when none follow; a count takes that
      # many more runs (inner) or words with their blanks (a).
      #: (EditorState, Integer, bool, bool) -> Range?
      def self.word(state, n, big, around)
        row = state.cursor.row
        line = state.buffer.line(row)
        return nil if line.empty?
        runs = runs(line, big)
        i = runs.index_of(state.cursor.col)
        from = runs.from(i)
        to = runs.to(i)
        last = i
        if around
          if runs.class_at(i) != 0
            if i + 1 < runs.length
              last = i + 1
              to = runs.to(last)
            elsif i > 0 && runs.class_at(i - 1) == 0
              from = runs.from(i - 1)
            end
          elsif i + 1 < runs.length
            last = i + 1
            to = runs.to(last)
          end
          n -= 1
          while n > 0 && last + 1 < runs.length
            last += 1
            to = runs.to(last)
            if runs.class_at(last) != 0 && last + 1 < runs.length && runs.class_at(last + 1) == 0
              last += 1
              to = runs.to(last)
            end
            n -= 1
          end
        else
          n -= 1
          while n > 0 && last + 1 < runs.length
            last += 1
            to = runs.to(last)
            n -= 1
          end
        end
        Range.new(Position.new(row, from), Position.new(row, to), :charwise, false)
      end

      # -------------------------------------------------------- sentences

      # is and as over the sentence starts the motions compute: the inner
      # form stops before the trailing blanks and line breaks, the "a" form
      # runs to the next sentence start, or takes the blanks before the
      # sentence when none follow it.
      #: (EditorState, Integer, bool) -> Range?
      def self.sentence(state, n, around)
        buffer = state.buffer
        starts = Motions.sentence_starts(buffer)
        pos = state.cursor.position
        i = starts.index_at(pos)
        from = starts.position(i)
        j = i + n
        to = j < starts.length ? starts.position(j) : Motions.buffer_end(buffer)
        inner = trim_back(buffer, from, to)
        if around
          if inner == to
            col = from.col
            line = buffer.line(from.row)
            col -= 1 while col > 0 && Motions.blank?(line[col - 1, 1])
            from = Position.new(from.row, col)
          end
        else
          to = inner
        end
        return nil if to == from
        Range.new(from, to, :charwise, false)
      end

      # The position after the last non-blank character before to, not
      # going back past from.
      #: (Buffer, Position, Position) -> Position
      def self.trim_back(buffer, from, to)
        row = to.row
        col = to.col
        while true
          if col == 0
            break if row <= from.row
            row -= 1
            col = buffer.line(row).length
          elsif Motions.blank?(buffer.line(row)[col - 1, 1])
            col -= 1
          else
            break
          end
        end
        Position.new(row, col)
      end

      # ------------------------------------------------------- paragraphs

      # ip and ap: the run of lines of the cursor line's kind, empty or
      # not; "a" adds the empty lines after a paragraph, or the ones before
      # it when none follow, and a count takes that many more runs.
      #: (EditorState, Integer, bool) -> Range?
      def self.paragraph(state, n, around)
        buffer = state.buffer
        last = buffer.line_count - 1
        row = state.cursor.row
        empty = buffer.line(row).empty?
        from = row
        from -= 1 while from > 0 && buffer.line(from - 1).empty? == empty
        to = row
        to += 1 while to < last && buffer.line(to + 1).empty? == empty
        if around
          if to < last
            to = run_end(buffer, to + 1)
          elsif !empty && from > 0
            from -= 1
            from -= 1 while from > 0 && buffer.line(from - 1).empty?
          end
          n -= 1
          while n > 0 && to < last
            to = run_end(buffer, to + 1)
            to = run_end(buffer, to + 1) if to < last
            n -= 1
          end
        else
          n -= 1
          while n > 0 && to < last
            to = run_end(buffer, to + 1)
            n -= 1
          end
        end
        col = state.cursor.col
        Range.new(Position.new(from, col), Position.new(to, col), :linewise, true)
      end

      # The last row of the run of lines of row's kind that starts at row.
      #: (Buffer, Integer) -> Integer
      def self.run_end(buffer, row)
        last = buffer.line_count - 1
        empty = buffer.line(row).empty?
        row += 1 while row < last && buffer.line(row + 1).empty? == empty
        row
      end

      # ----------------------------------------------------------- pairs

      # The character at pos, or "" on the end of a line.
      #: (Buffer, Position) -> String
      def self.char_at(buffer, pos)
        line = buffer.line(pos.row)
        pos.col < line.length ? line[pos.col, 1] : ""
      end

      # The unmatched opener before pos, scanning backward over the buffer
      # and counting nesting; nil when there is none.
      #: (Buffer, Position, String, String) -> Position?
      def self.find_opener(buffer, pos, open, close)
        w = Walker.new(buffer, pos.row, pos.col)
        depth = 0
        while w.step_backward != -1
          ch = char_at(buffer, w.position)
          if ch == close
            depth += 1
          elsif ch == open
            return w.position if depth == 0
            depth -= 1
          end
        end
        nil
      end

      # The closer matching the opener at pos.
      #: (Buffer, Position, String, String) -> Position?
      def self.find_closer(buffer, pos, open, close)
        w = Walker.new(buffer, pos.row, pos.col)
        depth = 0
        while w.step_forward != -1
          ch = char_at(buffer, w.position)
          if ch == open
            depth += 1
          elsif ch == close
            return w.position if depth == 0
            depth -= 1
          end
        end
        nil
      end

      # i( a( and the other bracket pairs: the count-th enclosing pair.
      #: (EditorState, Integer, String, String, bool) -> Range?
      def self.pair(state, n, open, close, around)
        buffer = state.buffer
        pos = state.cursor.position
        opener = char_at(buffer, pos) == open ? pos : find_opener(buffer, pos, open, close)
        n -= 1
        while n > 0 && !opener.nil?
          opener = find_opener(buffer, opener, open, close)
          n -= 1
        end
        return nil if opener.nil?
        found = find_closer(buffer, opener, open, close)
        return nil if found.nil?
        start = Position.sure(opener)
        stop = Position.sure(found)
        if around
          return Range.new(start, Position.new(stop.row, stop.col + 1), :charwise, false)
        end
        from = Position.new(start.row, start.col + 1)
        if stop.row > start.row && buffer.line(start.row)[from.col, buffer.line(start.row).length].strip.empty? && buffer.line(stop.row)[0, stop.col].strip.empty?
          return nil if stop.row - start.row < 2
          return Range.new(Position.new(start.row + 1, 0), Position.new(stop.row - 1, 0), :linewise, true)
        end
        return nil if from == stop
        Range.new(from, stop, :charwise, false)
      end

      # ---------------------------------------------------------- quotes

      # i" a" and the single quote and backtick forms, on the cursor line:
      # quotes pair up from the start of the line, a backslash escapes one,
      # and the string under the cursor or the first one after it is used.
      #: (EditorState, String, bool) -> Range?
      def self.quote(state, q, around)
        row = state.cursor.row
        line = state.buffer.line(row)
        col = state.cursor.col
        quotes = []
        i = 0
        while i < line.length
          ch = line[i, 1]
          if ch == "\\"
            i += 2
          else
            quotes << i if ch == q
            i += 1
          end
        end
        q1 = -1
        q2 = -1
        i = 0
        while i + 1 < quotes.length
          if (quotes[i] <= col && col <= quotes[i + 1]) || quotes[i] > col
            q1 = quotes[i]
            q2 = quotes[i + 1]
            break
          end
          i += 2
        end
        return nil if q1 < 0
        if around
          from = q1
          to = q2 + 1
          trailing = to
          trailing += 1 while trailing < line.length && Motions.blank?(line[trailing, 1])
          if trailing > to
            to = trailing
          else
            from -= 1 while from > 0 && Motions.blank?(line[from - 1, 1])
          end
          return Range.new(Position.new(row, from), Position.new(row, to), :charwise, false)
        end
        return nil if q2 == q1 + 1
        Range.new(Position.new(row, q1 + 1), Position.new(row, q2), :charwise, false)
      end
    end
  end
end
