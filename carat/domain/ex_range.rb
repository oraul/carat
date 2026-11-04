require_relative "selection"

module Carat
  module Domain
    # The lines a command line's range names, as rows from first to last,
    # whether a range was typed, and the error that refused it ("" when
    # none). resolve reads the range as ExGrammar kept it: "%" for every
    # line, or one address or two joined by ",", each ".", "$", a line
    # number, "'<" or "'>" (the window's last visual selection), or empty
    # for the cursor line. Line 0 is line 1, as for every command Carat
    # has. A Data value.
    class ExRange < Data.define(:first, :last, :given, :error)
      # @rbs @first: Integer
      # @rbs @last: Integer
      # @rbs @given: bool
      # @rbs @error: String

      INVALID = "E16: Invalid range"
      BACKWARDS = "E493: Backwards range given"
      NO_MARK = "E20: Mark not set"
      # A line number is read up to this, which no buffer reaches.
      MAX_NUMBER = 1_000_000_000

      #: () -> bool
      def ok?
        error.empty?
      end

      #: (String) -> ExRange
      def self.refused(message)
        ExRange.new(first: 0, last: 0, given: true, error: message)
      end

      # The range of text on a buffer of line_count lines with the cursor
      # on row, selection being the window's last visual selection.
      #: (String, Integer, Integer, Selection) -> ExRange
      def self.resolve(text, row, line_count, selection)
        return ExRange.new(first: row, last: row, given: false, error: "") if text.empty?
        return ExRange.new(first: 0, last: line_count - 1, given: true, error: "") if text == "%"
        numbers = Array.new(0, 0)
        start = 0
        size = text.bytesize
        while start <= size
          comma = text.byteindex(",", start)
          stop = comma.nil? ? size : comma
          number = address(text.byteslice(start, stop - start).to_s.strip, row, line_count, selection)
          return refused(NO_MARK) if number == -2
          return refused("Not implemented: range #{text}") if number < 0
          return refused(INVALID) if number > line_count
          numbers << number
          start = stop + 1
        end
        low = numbers.length > 1 ? numbers[numbers.length - 2].to_i : numbers[0].to_i
        high = numbers[numbers.length - 1].to_i
        return refused(BACKWARDS) if low > high
        ExRange.new(first: low > 0 ? low - 1 : 0, last: high > 0 ? high - 1 : 0, given: true, error: "")
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
        number(text)
      end

      # The decimal number text holds, -1 when it holds anything else.
      #: (String) -> Integer
      def self.number(text)
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
