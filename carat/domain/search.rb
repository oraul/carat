require_relative "utf8"
require_relative "buffer"
require_relative "search_pattern"
require_relative "search_budget"
require_relative "search_hit"

module Carat
  module Domain
    # Pattern search over a buffer, line by line, as pure functions: the
    # next or previous match from a position, wrapping around the buffer,
    # and the matches of one line. Columns are code points, as
    # Regexp#match takes and gives them. Every scan is paid from a
    # SearchBudget before the engine runs (the line's length, since the
    # engine finds a code point position from the line start, plus the
    # characters it may read times the pattern's size), so no search
    # outlives its budget however many matches a line has, and an error
    # of the engine stops the budget instead of reaching the editor.
    # A line that is not valid UTF-8, on which the engine raises, is
    # matched through a copy with U+FFFD for each byte that starts no
    # character, which has exactly the line's characters.
    module Search
      REPLACEMENT = "\u{FFFD}"

      # The search prompts, which the grammar reads a pattern for, and the
      # searches that complete at once; both are motions under an
      # operator.
      PROMPT_NAMES = ["search.forward", "search.backward"]
      MOTION_NAMES = ["search.next", "search.previous", "search.word_forward", "search.word_backward", "search.partial_word_forward", "search.partial_word_backward"]
      # The short descriptions of both, in the same order, for the key hints.
      PROMPT_DESCRIPTIONS = ["Search forward", "Search backward"]
      MOTION_DESCRIPTIONS = ["Next match", "Previous match", "Word under cursor forward", "Word under cursor backward", "Partial word forward", "Partial word backward"]

      BOTTOM = "search hit BOTTOM, continuing at TOP"
      TOP = "search hit TOP, continuing at BOTTOM"
      NO_PREVIOUS = "E35: No previous regular expression"
      NO_STRING = "E348: No string under cursor"
      STOPPED = "E363: search stopped, pattern too costly here"

      # Whether an action is a search.
      #: (String) -> bool
      def self.action?(name)
        name.start_with?("search.") && (PROMPT_NAMES.include?(name) || MOTION_NAMES.include?(name))
      end

      # The count-th match after (forward) or before a position, starting
      # again at the other end of the buffer when it passes one. The hit
      # says where, whether it wrapped, or why there is none.
      #: (Buffer, SearchPattern, Integer, Integer, bool, Integer, SearchBudget) -> SearchHit
      def self.find(buffer, pattern, row, col, forward, count, budget)
        hit = SearchHit.new(row: row, col: col)
        n = count > 0 ? count : 1
        while n > 0
          from_row = hit.row
          from_col = hit.col
          if forward
            step_forward(buffer, pattern, from_row, from_col, budget, hit)
          else
            step_backward(buffer, pattern, from_row, from_col, budget, hit)
          end
          if budget.stopped
            hit.status = :stopped
            return hit
          end
          return hit unless hit.found?
          n -= 1
          hit.status = :missing if n > 0
        end
        hit.status = :found
        hit
      end

      # The text the engine matches for a line: the line itself when it
      # is valid UTF-8, else a copy with U+FFFD for each illegal byte.
      #: (String) -> String
      def self.searchable(line)
        return line if line.valid_encoding?
        out = +""
        n = line.bytesize
        i = 0
        run = 0
        while i < n
          size = Utf8.size_at(line, i, n)
          if size == 1 && line.getbyte(i).to_i >= 0x80
            out << line.byteslice(run, i - run).to_s if i > run
            out << REPLACEMENT
            run = i + 1
          end
          i += size
        end
        out << line.byteslice(run, n - run).to_s if n > run
        out.force_encoding(Encoding::UTF_8)
      end

      # The first match in text, of length code points, starting at the
      # code point from or later, nil when there is none or the budget
      # cannot pay for the scan. The length is charged on every call and
      # never refunded: finding from costs up to the line's length on text
      # that is not ASCII (docs/spinel-notes.md), whatever the scan reads.
      #: (SearchPattern, String, Integer, Integer, SearchBudget) -> MatchData?
      def self.match_at(pattern, text, length, from, budget)
        return nil if from > length
        size = pattern.size
        worst = (length - from + 1) * size
        budget.charge(length + worst)
        return nil if budget.stopped
        found = pattern.regexp.match(text, from)
        used = found.nil? ? length - from + 1 : found.end(0) - from + 1
        budget.refund(worst - used * size)
        found
      rescue RegexpError, ArgumentError
        budget.stop
        nil
      end

      # The start of the last match in text, of length code points, that
      # starts before limit, -1 when none does.
      #: (SearchPattern, String, Integer, Integer, SearchBudget) -> Integer
      def self.last_before(pattern, text, length, limit, budget)
        last = -1
        from = 0
        while from < limit
          found = match_at(pattern, text, length, from, budget)
          break if found.nil?
          start = found.begin(0)
          break if start >= limit
          last = start
          from = start + 1
        end
        last
      end

      # The end of the match that starts at col of text, of length code
      # points, col when none does.
      #: (SearchPattern, String, Integer, Integer, SearchBudget) -> Integer
      def self.end_at(pattern, text, length, col, budget)
        found = match_at(pattern, text, length, col, budget)
        return col if found.nil? || found.begin(0) != col
        found.end(0)
      end

      # The column a normal-mode cursor takes for a match starting at
      # start on a line of length characters: a match at the line end
      # stands on the last character.
      #: (Integer, Integer) -> Integer
      def self.resting_col(start, length)
        start >= length && length > 0 ? length - 1 : start
      end

      # One search forward from (row, col) into hit: the first match whose
      # start the cursor would not already stand on, then the following
      # rows, then from the top down to the starting row.
      #: (Buffer, SearchPattern, Integer, Integer, SearchBudget, SearchHit) -> void
      def self.step_forward(buffer, pattern, row, col, budget, hit)
        lines = buffer.line_count
        at = row
        from = col + 1
        wrapped = false
        while true
          text = searchable(buffer.line(at))
          length = text.length
          found = match_at(pattern, text, length, from, budget)
          while !found.nil? && !wrapped && at == row && resting_col(found.begin(0), length) <= col
            found = match_at(pattern, text, length, found.begin(0) + 1, budget)
          end
          return if budget.stopped
          unless found.nil?
            hit.wrapped = true if wrapped
            hit.land(at, found.begin(0), found.end(0))
            return
          end
          break if wrapped && at == row
          at += 1
          from = 0
          if at >= lines
            at = 0
            wrapped = true
          end
        end
        hit.status = :missing
      end

      # One search backward from (row, col) into hit: the last match on
      # the starting row that starts before col, then the rows above, then
      # from the bottom up to the starting row.
      #: (Buffer, SearchPattern, Integer, Integer, SearchBudget, SearchHit) -> void
      def self.step_backward(buffer, pattern, row, col, budget, hit)
        lines = buffer.line_count
        at = row
        wrapped = false
        while true
          text = searchable(buffer.line(at))
          length = text.length
          limit = !wrapped && at == row ? col : length + 1
          start = last_before(pattern, text, length, limit, budget)
          return if budget.stopped
          if start >= 0
            hit.wrapped = true if wrapped
            hit.land(at, start, end_at(pattern, text, length, start, budget))
            return
          end
          break if wrapped && at == row
          at -= 1
          if at < 0
            at = lines - 1
            wrapped = true
          end
        end
        hit.status = :missing
      end
    end
  end
end
