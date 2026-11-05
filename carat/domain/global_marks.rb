require_relative "line_splice"

module Carat
  module Domain
    # The lines a running :global marked, as Vim keeps them in its line
    # store: one flag per line of the buffer (1 marked, 0 not) while a
    # global runs, none otherwise, and low, the first row that may still be
    # marked. The buffer's one splice calls shift, so a marked line keeps
    # its mark however the lines above it move, a deleted one loses it, and
    # an inserted one has none. A Struct record: mutable, with a reader and
    # a writer per member.
    class GlobalMarks < Struct.new(:flags, :low, keyword_init: true)
      # @rbs @flags: Array[Integer]
      # @rbs @low: Integer

      # No marks: what every buffer starts with.
      #: () -> void
      def initialize
        super()
        self.flags = []
        self.low = 0
      end

      #: () -> bool
      def active?
        !flags.empty?
      end

      # Marks rows, sorted, of a buffer of line_count lines.
      #: (Array[Integer], Integer) -> void
      def mark(rows, line_count)
        marked = Array.new(line_count, 0)
        i = 0
        while i < rows.length
          marked[rows[i].to_i] = 1
          i += 1
        end
        self.flags = marked
        self.low = rows.empty? ? line_count : rows[0].to_i
      end

      # The first marked row, its mark cleared, or -1 when none is left.
      #: () -> Integer
      def take
        marked = flags
        row = low
        while row < marked.length
          if marked[row] == 1
            marked[row] = 0
            self.low = row + 1
            return row
          end
          row += 1
        end
        self.low = row
        -1
      end

      # Moves the marks by an edit at row that replaced removed rows with
      # inserted ones; nothing when no global runs.
      #: (Integer, Integer, Integer) -> void
      def shift(row, removed, inserted)
        return if flags.empty?
        LineSplice.shift_marks(flags, row, removed, inserted)
        self.low = row if row < low
      end

      # Drops every mark.
      #: () -> void
      def clear
        self.flags = []
        self.low = 0
      end
    end
  end
end
