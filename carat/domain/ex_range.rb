require_relative "selection"
require_relative "messages"
require_relative "utf8"

module Carat
  module Domain
    # The lines a command line's range names, as rows from first to last,
    # whether a range was typed, and the error that refused it ("" when
    # none). resolve reads the range as ExGrammar kept it: "%" for every
    # line, or one address or two joined by ",", each ".", "$", a line
    # number, "'<" or "'>" (the window's last visual selection), or empty
    # for the cursor line. Line 0 is line 1, as for every command Carat
    # has. addresses is how many addresses the range typed, as Neovim's
    # addr_count reads for the checks Carat has: 0 for none, 1, or 2 for
    # "%" or two or more. A Data value.
    class ExRange < Data.define(:first, :last, :given, :error, :addresses)
      # @rbs @first: Integer
      # @rbs @last: Integer
      # @rbs @given: bool
      # @rbs @error: String
      # @rbs @addresses: Integer

      INVALID = Messages::E16
      BACKWARDS = "E493: Backwards range given"
      NO_MARK = "E20: Mark not set"
      UNREAD = "Not implemented: "
      # A line number is read up to this, which no buffer reaches.
      MAX_NUMBER = 1_000_000_000

      #: () -> bool
      def ok?
        error.empty?
      end

      #: (String) -> ExRange
      def self.refused(message)
        ExRange.new(first: 0, last: 0, given: true, error: message, addresses: 0)
      end

      # The range of text on a buffer of line_count lines with the cursor
      # on row, selection being the window's last visual selection. An
      # address line_of refuses as unread answers "Not implemented: range"
      # with the whole range.
      #: (String, Integer, Integer, Selection) -> ExRange
      def self.resolve(text, row, line_count, selection)
        return ExRange.new(first: row, last: row, given: false, error: "", addresses: 0) if text.empty?
        return ExRange.new(first: 0, last: line_count - 1, given: true, error: "", addresses: 2) if text == "%"
        numbers = Array.new(0, 0)
        start = 0
        size = text.bytesize
        while start <= size
          comma = text.byteindex(",", Utf8.boundary(text, start))
          stop = comma.nil? ? size : comma
          piece = text.byteslice(start, stop - start).to_s.strip
          # "%" is a range of its own, not an address, as in Neovim.
          return refused("#{UNREAD}range #{text}") if piece.start_with?("%")
          line = line_of(piece, row, line_count, selection)
          return refused(line.error.start_with?(UNREAD) ? "#{UNREAD}range #{text}" : line.error) unless line.ok?
          numbers << line.first
          start = stop + 1
        end
        low = numbers.length > 1 ? numbers[numbers.length - 2].to_i : numbers[0].to_i
        high = numbers[numbers.length - 1].to_i
        return refused(BACKWARDS) if low > high
        ExRange.new(first: low > 0 ? low - 1 : 0, last: high > 0 ? high - 1 : 0, given: true, error: "", addresses: numbers.length > 1 ? 2 : 1)
      end

      # The target address of :m, :co, and :t as the row the lines are put
      # at, in first and last: the row below the line the address names,
      # so 0 is above the first line, the same base as resolve's rows.
      # Empty text is E16; the rest is what line_of answers.
      #: (String, Integer, Integer, Selection) -> ExRange
      def self.target(text, row, line_count, selection)
        address_text = text.strip
        return refused(INVALID) if address_text.empty?
        line_of(address_text, row, line_count, selection)
      end

      # The one reading of a single address, for resolve and target: the
      # 1-based line it names in first and last (empty text is the
      # cursor line), or its refusal: E20 for an unset visual mark, E16
      # past the last line or for text that is not an address, and "Not
      # implemented: address" for an address Carat does not read: an
      # offset, a ";", a pattern, another mark, or numbers joined by
      # blanks, which Neovim adds.
      #: (String, Integer, Integer, Selection) -> ExRange
      def self.line_of(text, row, line_count, selection)
        number = address(text, row, line_count, selection)
        return refused(NO_MARK) if number == -2
        return refused(unread?(text) ? "#{UNREAD}address #{text}" : INVALID) if number < 0
        return refused(INVALID) if number > line_count
        ExRange.new(first: number, last: number, given: true, error: "", addresses: 1)
      end

      # Whether text, which address could not read, is an address Neovim
      # reads and Carat does not.
      #: (String) -> bool
      def self.unread?(text)
        return true if text.include?("+") || text.include?("-") || text.include?(";")
        return true if text.start_with?("/") || text.start_with?("?") || text.start_with?("'")
        digits = false
        i = 0
        while i < text.bytesize
          byte = text.getbyte(i).to_i
          return false unless (byte >= 48 && byte <= 57) || byte == 32 || byte == 9
          digits = true if byte >= 48 && byte <= 57
          i += 1
        end
        digits
      end

      # The range a count after a line command names, as Neovim's: from
      # the last row, count rows, stopping at the buffer's last row.
      #: (Integer, Integer) -> ExRange
      def counted(count, line_count)
        stop = last + count - 1
        stop = line_count - 1 if stop > line_count - 1
        ExRange.new(first: last, last: stop, given: true, error: "", addresses: addresses)
      end

      # The line number one address names, -2 for a mark that is not set,
      # -1 for an address Carat does not read.
      #: (String, Integer, Integer, Selection) -> Integer
      def self.address(text, row, line_count, selection)
        return row + 1 if text.empty? || text == "."
        return line_count if text == "$"
        if text == "'<" || text == "'>"
          return -2 unless selection.active?
          mark = text == "'<" ? selection.top + 1 : selection.bottom + 1
          return mark > line_count ? line_count : mark
        end
        line_number(text)
      end

      # The decimal number text holds, -1 when it holds anything else.
      #: (String) -> Integer
      def self.line_number(text)
        value = 0
        i = 0
        n = text.bytesize
        while i < n
          byte = text.getbyte(i).to_i
          return -1 if byte < 48 || byte > 57
          value = value * 10 + (byte - 48) if value < MAX_NUMBER
          i += 1
        end
        value
      end
    end
  end
end
