require_relative "buffer"
require_relative "buffer_list"
require_relative "fuzzy_match"

module Carat
  module Domain
    # The words of the listed buffers that complete a prefix, in the order
    # Neovim's keyword completion (Ctrl-N, Ctrl-P) finds them: the current
    # buffer from the word being completed, forward (the rest of its row,
    # the rows below, the rows above from the top, the start of its row)
    # or backward (the exact reverse), then every other listed buffer that
    # is not a scratch buffer, in list order after the current one, top to
    # bottom forward or bottom to top backward. A word is a run of word
    # bytes (FuzzyMatch.word_byte?); a match starts with the prefix's
    # bytes, is longer, and is kept once, where it is first found. The
    # scan stops at LIMIT words and after SCAN_BYTES bytes read, charged
    # per line slice before it is read, a slice longer than what is left
    # cut. A Struct record: mutable, with a reader and a writer per member.
    class BufferWords < Struct.new(:prefix, :words, :budget, keyword_init: true)
      # @rbs @prefix: String
      # @rbs @words: Array[String]
      # @rbs @budget: Integer

      LIMIT = 200
      SCAN_BYTES = 1_000_000

      #: (prefix: String) -> void
      def initialize(prefix:)
        super()
        self.prefix = prefix
        self.words = []
        self.budget = SCAN_BYTES
      end

      # Collects the matches for the word starting at byte start of row in
      # the current buffer, forward or backward.
      #: (BufferList, Buffer, Integer, Integer, bool) -> void
      def collect(buffers, current, row, start, forward)
        scan_current(current, row, start, forward)
        n = buffers.count
        at = buffers.index_of(current)
        i = 1
        while i <= n && !done?
          other = buffers.buffer_at((at + i) % n)
          scan_rows(other, 0, other.line_count, forward) unless other.scratch? || other.equal?(current)
          i += 1
        end
      end

      # Whether the scan stops: the words are full or the bytes spent.
      #: () -> bool
      def done?
        words.length >= LIMIT || budget <= 0
      end

      private

      # The current buffer around the word being completed.
      #: (Buffer, Integer, Integer, bool) -> void
      def scan_current(buffer, row, start, forward)
        line = buffer.line(row)
        count = buffer.line_count
        if forward
          scan_line(line, start + 1, line.bytesize, true)
          scan_rows(buffer, row + 1, count, true)
          scan_rows(buffer, 0, row, true)
          scan_line(line, 0, start, true)
        else
          scan_line(line, 0, start, false)
          scan_rows(buffer, 0, row, false)
          scan_rows(buffer, row + 1, count, false)
          scan_line(line, start + 1, line.bytesize, false)
        end
      end

      # The whole rows from first up to before last, in the direction.
      #: (Buffer, Integer, Integer, bool) -> void
      def scan_rows(buffer, first, last, forward)
        r = forward ? first : last - 1
        while r >= first && r < last && !done?
          line = buffer.line(r)
          scan_line(line, 0, line.bytesize, forward)
          r += forward ? 1 : -1
        end
      end

      # The words of the line starting at a byte from from up to before
      # to, in the direction; a word may run on past to.
      #: (String, Integer, Integer, bool) -> void
      def scan_line(line, from, to, forward)
        len = line.bytesize
        to = len if to > len
        return if from >= to || done?
        left = budget
        if to - from > left
          if forward
            to = from + left
          else
            from = to - left
          end
        end
        self.budget = left - (to - from)
        s = forward ? from : to - 1
        while s >= from && s < to && words.length < LIMIT
          take(line, s, len) if start_at?(line, s)
          s += forward ? 1 : -1
        end
      end

      # Whether a word starts at byte s of the line.
      #: (String, Integer) -> bool
      def start_at?(line, s)
        return false unless FuzzyMatch.word_byte?(line.getbyte(s).to_i)
        s == 0 || !FuzzyMatch.word_byte?(line.getbyte(s - 1).to_i)
      end

      # Keeps the word starting at byte s when it completes the prefix and
      # was not found before.
      #: (String, Integer, Integer) -> void
      def take(line, s, len)
        wanted = prefix
        n = wanted.bytesize
        return if s + n >= len
        i = 0
        while i < n
          return unless line.getbyte(s + i).to_i == wanted.getbyte(i).to_i
          i += 1
        end
        e = s + n
        e += 1 while e < len && FuzzyMatch.word_byte?(line.getbyte(e).to_i)
        return if e == s + n
        word = line.byteslice(s, e - s).to_s
        words << word unless words.include?(word)
      end
    end
  end
end
