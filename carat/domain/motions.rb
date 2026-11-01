require_relative "position"
require_relative "buffer"
require_relative "editor_state"
require_relative "command"
require_relative "walker"
require_relative "sentence_starts"
require_relative "motion"

module Carat
  module Domain
    # Every motion as a pure function from the editor state and a count to
    # a Motion, or nil when the motion cannot move. The same functions
    # serve cursor movement (pending false) and operator ranges (pending
    # true); the flag lets "l" step past the last character and "w" stop at
    # the end of the line only under an operator.
    module Motions
      CLOSERS = ")]\"'"
      TERMINATORS = ".!?"

      # The motions that read one more key, the character to find; the
      # action table registers them with the kind :find.
      FIND_NAMES = ["motion.find_forward", "motion.find_backward", "motion.till_forward", "motion.till_backward"]

      # Every other motion this module implements, in the order of the
      # case statements below; the action table registers them with the
      # kind :motion.
      NAMES = [
        "motion.repeat_find", "motion.repeat_find_reverse",
        "cursor.left", "cursor.right", "cursor.up", "cursor.down", "cursor.line_start", "cursor.first_nonblank",
        "cursor.line_end", "cursor.buffer_start", "cursor.buffer_end",
        "motion.line_down", "motion.line_up", "motion.line",
        "motion.word_forward", "motion.big_word_forward", "motion.word_backward", "motion.big_word_backward",
        "motion.word_end", "motion.big_word_end", "motion.word_end_backward", "motion.big_word_end_backward",
        "motion.sentence_forward", "motion.sentence_backward", "motion.paragraph_forward", "motion.paragraph_backward",
        "motion.screen_top", "motion.screen_middle", "motion.screen_bottom"
      ]

      # The motion a command asks for. This is the one entry point with a
      # side effect: f, F, t, and T record themselves in state.last_find
      # so that ";" and "," can repeat them.
      #: (EditorState, Command, bool) -> Motion?
      def self.for_command(state, command, pending)
        action = command.action
        count = command.count
        case action
        when "motion.find_forward" then remember(state, Find.new(command.char, true, false), count, false)
        when "motion.find_backward" then remember(state, Find.new(command.char, false, false), count, false)
        when "motion.till_forward" then remember(state, Find.new(command.char, true, true), count, false)
        when "motion.till_backward" then remember(state, Find.new(command.char, false, true), count, false)
        when "motion.repeat_find"
          find = state.last_find
          find.nil? ? nil : find_char(state, find, count, true)
        when "motion.repeat_find_reverse"
          find = state.last_find
          find.nil? ? nil : find_char(state, find.reversed, count, true)
        else call(state, action, count, pending)
        end
      end

      #: (EditorState, Find, Integer, bool) -> Motion?
      def self.remember(state, find, count, repeat)
        state.last_find = find
        find_char(state, find, count, repeat)
      end

      # A motion by action name; count is 0 when none was typed.
      #: (EditorState, String, Integer, bool) -> Motion?
      def self.call(state, action, count, pending)
        n = count > 0 ? count : 1
        case action
        when "cursor.left" then left(state, n)
        when "cursor.right" then right(state, n, pending)
        when "cursor.up" then vertical(state, -n)
        when "cursor.down" then vertical(state, n)
        when "cursor.line_start" then horizontal(state, 0)
        when "cursor.first_nonblank" then horizontal(state, state.buffer.first_nonblank(state.cursor.row))
        when "cursor.line_end" then line_end(state, n)
        when "cursor.buffer_start" then to_row(state, count > 0 ? count - 1 : 0)
        when "cursor.buffer_end" then to_row(state, count > 0 ? count - 1 : state.buffer.line_count - 1)
        when "motion.line_down" then line_down(state, n)
        when "motion.line_up" then line_down(state, -n)
        when "motion.line" then line_down(state, n - 1)
        when "motion.word_forward" then word_forward(state, n, false, pending)
        when "motion.big_word_forward" then word_forward(state, n, true, pending)
        when "motion.word_backward" then word_backward(state, n, false)
        when "motion.big_word_backward" then word_backward(state, n, true)
        when "motion.word_end" then word_end(state, n, false, false, pending)
        when "motion.big_word_end" then word_end(state, n, true, false, pending)
        when "motion.word_end_backward" then word_end_backward(state, n, false)
        when "motion.big_word_end_backward" then word_end_backward(state, n, true)
        when "motion.sentence_forward" then sentence_forward(state, n, pending)
        when "motion.sentence_backward" then sentence_backward(state, n)
        when "motion.paragraph_forward" then paragraph_forward(state, n, pending)
        when "motion.paragraph_backward" then paragraph_backward(state, n)
        when "motion.screen_top" then screen(state, :top, n, pending)
        when "motion.screen_middle" then screen(state, :middle, n, pending)
        when "motion.screen_bottom" then screen(state, :bottom, n, pending)
        else nil
        end
      end

      # ------------------------------------------------------------ classes

      #: (String) -> bool
      def self.blank?(ch)
        ch == " " || ch == "\t"
      end

      # Keyword characters: ASCII letters, digits, underscore, and every
      # code point from U+00C0 upward, until iskeyword exists.
      #: (String) -> bool
      def self.keyword?(ch)
        ch.match?(/\A[A-Za-z0-9_]\z/) || ch.ord >= 0xC0
      end

      #: (String, bool) -> Integer
      def self.char_class(ch, big)
        return 0 if blank?(ch)
        return 1 if big
        keyword?(ch) ? 2 : 1
      end

      # ------------------------------------------------------- left-right

      #: (EditorState, Integer) -> Motion?
      def self.left(state, n)
        cursor = state.cursor
        return nil if cursor.col == 0
        col = cursor.col - n
        col = 0 if col < 0
        Motion.new(Position.new(cursor.row, col), false, false, :set)
      end

      #: (EditorState, Integer, bool) -> Motion?
      def self.right(state, n, pending)
        cursor = state.cursor
        max = pending ? state.buffer.line(cursor.row).length : state.max_col(cursor.row)
        return nil if cursor.col >= max
        col = cursor.col + n
        col = max if col > max
        Motion.new(Position.new(cursor.row, col), false, false, :set)
      end

      #: (EditorState, Integer) -> Motion?
      def self.horizontal(state, col)
        Motion.new(Position.new(state.cursor.row, col), false, false, :set)
      end

      #: (EditorState, Integer) -> Motion?
      def self.line_end(state, n)
        row = state.cursor.row + n - 1
        last = state.buffer.line_count - 1
        row = last if row > last
        Motion.new(Position.new(row, state.max_col(row)), false, true, :end)
      end

      # f, F, t, and T, and their repeats: the count-th occurrence of the
      # character on the cursor line. A repeated till skips a match next to
      # the cursor, as Neovim does without cpo-;.
      #: (EditorState, Find, Integer, bool) -> Motion?
      def self.find_char(state, find, count, repeat)
        n = count > 0 ? count : 1
        cursor = state.cursor
        line = state.buffer.line(cursor.row)
        ch = find.char
        col = cursor.col
        step = find.forward ? 1 : -1
        col += step if repeat && find.till && col + step >= 0 && col + step < line.length && line[col + step, 1] == ch
        while n > 0
          col += step
          return nil if col < 0 || col >= line.length
          n -= 1 if line[col, 1] == ch
        end
        col -= step if find.till
        Motion.new(Position.new(cursor.row, col), false, find.forward, :set)
      end

      # --------------------------------------------------------- up-down

      # Up (delta < 0) or down count rows, clamped to the buffer, aiming for
      # the wanted column; nil when already at the edge.
      #: (EditorState, Integer) -> Motion?
      def self.vertical(state, delta)
        cursor = state.cursor
        last = state.buffer.line_count - 1
        return nil if delta < 0 && cursor.row == 0
        return nil if delta > 0 && cursor.row == last
        row = cursor.row + delta
        row = 0 if row < 0
        row = last if row > last
        to_row(state, row)
      end

      # A linewise motion to row, clamped, keeping the wanted column.
      #: (EditorState, Integer) -> Motion?
      def self.to_row(state, row)
        last = state.buffer.line_count - 1
        row = last if row > last
        row = 0 if row < 0
        Motion.new(Position.new(row, wanted_col(state, row)), true, false, :keep)
      end

      # The column the wanted column gives on row in the current mode.
      #: (EditorState, Integer) -> Integer
      def self.wanted_col(state, row)
        max = state.max_col(row)
        want = state.cursor.want_col
        col = want < 0 ? max : want
        col > max ? max : col
      end

      # "+", "-", and "_": delta rows, to the first non-blank, linewise.
      #: (EditorState, Integer) -> Motion?
      def self.line_down(state, delta)
        cursor = state.cursor
        last = state.buffer.line_count - 1
        return nil if delta < 0 && cursor.row == 0
        return nil if delta > 0 && cursor.row == last
        row = cursor.row + delta
        row = 0 if row < 0
        row = last if row > last
        Motion.new(Position.new(row, state.buffer.first_nonblank(row)), true, false, :set)
      end

      # ------------------------------------------------------------ words

      #: (EditorState) -> Walker
      def self.walker(state)
        Walker.new(state.buffer, state.cursor.row, state.cursor.col)
      end

      # A charwise motion to where the walker stopped. A word motion may end
      # on the end of a line: the cursor is moved back onto the last
      # character, as is an inclusive operator target; an exclusive
      # operator target stays there so the range reaches the line end.
      #: (Walker, bool, bool) -> Motion
      def self.word_motion(w, inclusive, pending)
        len = w.buffer.line(w.row).length
        col = w.col
        col = len - 1 if col >= len && len > 0 && (!pending || inclusive)
        Motion.new(Position.new(w.row, col), false, inclusive, :set)
      end

      #: (EditorState, Integer, bool, bool) -> Motion?
      def self.word_forward(state, n, big, pending)
        w = walker(state)
        ok = forward_word(w, n, big, pending)
        return nil if !ok && !pending
        return nil if w.position == state.cursor.position
        word_motion(w, false, pending)
      end

      #: (EditorState, Integer, bool) -> Motion?
      def self.word_backward(state, n, big)
        w = walker(state)
        return nil unless backward_word(w, n, big)
        word_motion(w, false, false)
      end

      #: (EditorState, Integer, bool, bool, bool) -> Motion?
      def self.word_end(state, n, big, stop, pending)
        w = walker(state)
        ok = end_word(w, n, big, stop)
        return nil if !ok && !pending
        word_motion(w, true, pending)
      end

      #: (EditorState, Integer, bool) -> Motion?
      def self.word_end_backward(state, n, big)
        w = walker(state)
        return nil unless backward_word_end(w, n, big)
        word_motion(w, true, false)
      end

      # Vim's forward_word: one word forward, count times. With eol (an operator
      # is pending) the last word stops at the end of its line. Returns
      # false when the walker was already at the end of the buffer.
      #: (Walker, Integer, bool, bool) -> bool
      def self.forward_word(w, count, big, eol)
        while count > 0
          count -= 1
          sclass = w.char_class(big)
          last_line = w.row == w.buffer.line_count - 1
          i = w.step_forward
          return false if i == -1 || (i >= 1 && last_line)
          return true if i >= 1 && eol && count == 0
          if sclass != 0
            while w.char_class(big) == sclass
              i = w.step_forward
              return true if i == -1 || (i >= 1 && eol && count == 0)
            end
          end
          while w.char_class(big) == 0
            break if w.col == 0 && w.empty_line?
            i = w.step_forward
            return true if i == -1 || (i >= 1 && eol && count == 0)
          end
        end
        true
      end

      # Vim's backward_word: to the start of the current or previous word.
      #: (Walker, Integer, bool) -> bool
      def self.backward_word(w, count, big)
        while count > 0
          count -= 1
          return false if w.step_backward == -1
          finished = false
          while w.char_class(big) == 0
            if w.col == 0 && w.empty_line?
              finished = true
              break
            end
            return true if w.step_backward == -1
          end
          next if finished
          cclass = w.char_class(big)
          while w.char_class(big) == cclass
            return true if w.step_backward == -1
          end
          w.step_forward
        end
        true
      end

      # Vim's end_word: to the end of the current or next word. With stop,
      # a walker already at the end of a word stays there, which is what
      # makes "cw" change only the word under the cursor.
      #: (Walker, Integer, bool, bool) -> bool
      def self.end_word(w, count, big, stop)
        while count > 0
          count -= 1
          sclass = w.char_class(big)
          return false if w.step_forward == -1
          if w.char_class(big) == sclass && sclass != 0
            return false if skip_class(w, sclass, big)
          elsif !stop || sclass == 0
            while w.char_class(big) == 0
              return false if w.step_forward == -1
            end
            return false if skip_class(w, w.char_class(big), big)
          end
          w.step_backward
          stop = false
        end
        true
      end

      # Moves forward over characters of cclass; true when the buffer ended.
      #: (Walker, Integer, bool) -> bool
      def self.skip_class(w, cclass, big)
        while w.char_class(big) == cclass
          return true if w.step_forward == -1
        end
        false
      end

      # Vim's backward_word_end: to the end of the previous word.
      #: (Walker, Integer, bool) -> bool
      def self.backward_word_end(w, count, big)
        while count > 0
          count -= 1
          sclass = w.char_class(big)
          return false if w.step_backward == -1
          if sclass != 0
            while w.char_class(big) == sclass
              return true if w.step_backward == -1
            end
          end
          while w.char_class(big) == 0
            break if w.col == 0 && w.empty_line?
            return true if w.step_backward == -1
          end
        end
        true
      end

      # -------------------------------------------------------- sentences

      # Where sentences start, in buffer order: the buffer start, each
      # empty line that ends a paragraph, the first non-blank after an
      # empty line, and the first non-blank after a sentence terminator.
      #: (Buffer) -> SentenceStarts
      def self.sentence_starts(buffer)
        starts = SentenceStarts.new
        starts.add(0, 0)
        count = buffer.line_count
        row = 0
        while row < count
          line = buffer.line(row)
          if line.empty?
            starts.add(row, 0) if row > 0 && !buffer.line(row - 1).empty?
            following = next_nonblank(buffer, row + 1, 0)
            add_start(starts, following)
            row += 1
            next
          end
          col = 0
          while col < line.length
            if TERMINATORS.include?(line[col, 1])
              after = col + 1
              after += 1 while after < line.length && CLOSERS.include?(line[after, 1])
              if after >= line.length || blank?(line[after, 1])
                following = next_nonblank(buffer, row, after)
                add_start(starts, following)
              end
              col = after
            else
              col += 1
            end
          end
          row += 1
        end
        starts
      end

      #: (SentenceStarts, Position?) -> void
      def self.add_start(starts, pos)
        return if pos.nil?
        sure = Position.sure(pos)
        starts.add(sure.row, sure.col)
      end

      # The first non-blank character at or after (row, col), crossing
      # lines but stopping on an empty line; nil at the end of the buffer.
      #: (Buffer, Integer, Integer) -> Position?
      def self.next_nonblank(buffer, row, col)
        count = buffer.line_count
        while row < count
          line = buffer.line(row)
          return Position.new(row, 0) if line.empty? && col == 0
          while col < line.length
            return Position.new(row, col) unless blank?(line[col, 1])
            col += 1
          end
          row += 1
          col = 0
        end
        nil
      end

      # The position past the last character of the buffer.
      #: (Buffer) -> Position
      def self.buffer_end(buffer)
        row = buffer.line_count - 1
        Position.new(row, buffer.line(row).length)
      end

      #: (EditorState, Integer, bool) -> Motion?
      def self.sentence_forward(state, n, pending)
        buffer = state.buffer
        starts = sentence_starts(buffer)
        pos = state.cursor.position
        while n > 0
          n -= 1
          found = -1
          i = 0
          while i < starts.length
            if starts.after?(i, pos)
              found = i
              break
            end
            i += 1
          end
          pos = found < 0 ? buffer_end(buffer) : starts.position(found)
        end
        return nil if pos == state.cursor.position
        end_motion(buffer, pos, pending)
      end

      # A charwise exclusive motion that may land past the end of the
      # buffer's last line: in normal mode the cursor goes onto the last
      # character instead.
      #: (Buffer, Position, bool) -> Motion
      def self.end_motion(buffer, pos, pending)
        len = buffer.line(pos.row).length
        col = pos.col
        col = len - 1 if col >= len && len > 0 && !pending
        Motion.new(Position.new(pos.row, col), false, false, :set)
      end

      #: (EditorState, Integer) -> Motion?
      def self.sentence_backward(state, n)
        starts = sentence_starts(state.buffer)
        pos = state.cursor.position
        while n > 0
          n -= 1
          found = -1
          i = starts.length - 1
          while i >= 0
            if starts.before?(i, pos)
              found = i
              break
            end
            i -= 1
          end
          pos = found < 0 ? Position.new(0, 0) : starts.position(found)
        end
        return nil if pos == state.cursor.position
        Motion.new(Position.new(pos.row, pos.col), false, false, :set)
      end

      # ------------------------------------------------------- paragraphs

      # The next empty line after the cursor's paragraph, count times, or
      # the end of the buffer.
      #: (EditorState, Integer, bool) -> Motion?
      def self.paragraph_forward(state, n, pending)
        buffer = state.buffer
        last = buffer.line_count - 1
        row = state.cursor.row
        while n > 0
          n -= 1
          skipped = false
          loop do
            skipped = true unless buffer.line(row).empty?
            break if skipped && buffer.line(row).empty?
            break if row >= last
            row += 1
          end
        end
        if row >= last && !buffer.line(last).empty?
          end_motion(buffer, buffer_end(buffer), pending)
        else
          Motion.new(Position.new(row, 0), false, false, :set)
        end
      end

      #: (EditorState, Integer) -> Motion?
      def self.paragraph_backward(state, n)
        buffer = state.buffer
        row = state.cursor.row
        while n > 0
          n -= 1
          skipped = false
          loop do
            skipped = true unless buffer.line(row).empty?
            break if skipped && buffer.line(row).empty?
            break if row <= 0
            row -= 1
          end
        end
        Motion.new(Position.new(row, 0), false, false, :set)
      end

      # ----------------------------------------------------------- screen

      # H, M, and L over the rows the window showed at its last render,
      # honoring scrolloff when moving the cursor but not under an operator.
      #: (EditorState, Symbol, Integer, bool) -> Motion?
      def self.screen(state, where, n, pending)
        buffer = state.buffer
        window = state.window
        last = buffer.line_count - 1
        height = window.height > 0 ? window.height : buffer.line_count
        top = window.top
        visible = buffer.line_count - top
        visible = height if visible > height
        visible = 1 if visible < 1
        bottom = top + visible - 1
        off = state.options.scrolloff
        half = (height - 1) / 2
        off = half if off > half
        off = 0 if pending
        row = top
        case where
        when :top
          row = top + n - 1
          row = top + off if row < top + off && top > 0
        when :middle
          row = top + (visible + 1) / 2 - 1
        else
          row = bottom - n + 1
          row = bottom - off if row > bottom - off && bottom < last
        end
        row = bottom if row > bottom
        row = top if row < top
        to_row(state, row)
      end
    end
  end
end
