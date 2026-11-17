module Carat
  module Domain
    # A window's manual folds, Neovim's foldmethod=manual: parallel first
    # rows, last rows, and closed flags, sorted by first row and, at one
    # first row, the outer fold first, so a walk meets the folds holding
    # a row from the outermost in. Folds nest by containment: a new fold
    # crossing another grows until it holds it. The closed region at a
    # row is the first closed fold holding it, which the window draws as
    # one row and j and k pass as one line. shift moves the folds with an
    # edit of the buffer, which calls it for every record it tracks.
    # labels keeps each fold's text for one width until the next change
    # of the folds or the buffer.
    # A Struct record built with no arguments.
    class Folds < Struct.new(:starts, :ends, :closed, :labels, :label_widths, keyword_init: true)
      # @rbs @starts: Array[Integer]
      # @rbs @ends: Array[Integer]
      # @rbs @closed: Array[bool]
      # @rbs @labels: Array[String]
      # @rbs @label_widths: Array[Integer]

      FILL = "·"

      #: () -> void
      def initialize
        super()
        self.starts = []
        self.ends = []
        self.closed = []
        self.labels = []
        self.label_widths = []
      end

      #: () -> Integer
      def count
        starts.length
      end

      #: () -> bool
      def empty?
        starts.empty?
      end

      # Whether any fold is closed, the one check the hot paths make.
      #: () -> bool
      def folded?
        i = 0
        while i < closed.length
          return true if closed[i]
          i += 1
        end
        false
      end

      #: (Integer) -> Integer
      def first_of(i)
        starts[i]
      end

      #: (Integer) -> Integer
      def last_of(i)
        ends[i]
      end

      #: (Integer) -> bool
      def closed?(i)
        closed[i]
      end

      # Adds a closed fold over rows from to to, grown to hold every fold
      # it crosses.
      #: (Integer, Integer) -> void
      def create(from, to)
        if to < from
          swap = from
          from = to
          to = swap
        end
        grown = true
        while grown
          grown = false
          i = 0
          while i < starts.length
            s = starts[i]
            e = ends[i]
            crosses = (s >= from && s <= to && e > to) || (s < from && e >= from && e < to)
            if crosses
              from = s if s < from
              to = e if e > to
              grown = true
            end
            i += 1
          end
        end
        at = 0
        at += 1 while at < starts.length && (starts[at] < from || (starts[at] == from && ends[at] >= to))
        starts.insert(at, from)
        ends.insert(at, to)
        closed.insert(at, true)
        labels.insert(at, "")
        label_widths.insert(at, 0)
        forget_labels
      end

      # The index of the outermost closed fold holding row, -1 for none.
      #: (Integer) -> Integer
      def closed_at(row)
        i = 0
        while i < starts.length
          return i if closed[i] && starts[i] <= row && ends[i] >= row
          i += 1
        end
        -1
      end

      # The first row of the closed region at row, or row.
      #: (Integer) -> Integer
      def first_row(row)
        i = closed_at(row)
        i < 0 ? row : starts[i]
      end

      # The last row of the closed region at row, or row.
      #: (Integer) -> Integer
      def last_row(row)
        i = closed_at(row)
        i < 0 ? row : ends[i]
      end

      # The row n shown lines below row, a closed region counted once,
      # stopping at last.
      #: (Integer, Integer, Integer) -> Integer
      def down(row, n, last)
        row = first_row(row)
        while n > 0
          after = last_row(row) + 1
          break if after > last
          row = first_row(after)
          n -= 1
        end
        row
      end

      # The row n shown lines above row, a closed region counted once,
      # stopping at the first line.
      #: (Integer, Integer) -> Integer
      def up(row, n)
        row = first_row(row)
        while n > 0 && row > 0
          row = first_row(row - 1)
          n -= 1
        end
        row
      end

      # The shown lines whose first rows are from row from up to row to,
      # to excluded: the screen rows between them.
      #: (Integer, Integer) -> Integer
      def rows_between(from, to)
        shown = 0
        row = first_row(from)
        while row < to
          shown += 1
          row = last_row(row) + 1
        end
        shown
      end

      # Opens the outermost closed fold holding row (zo); false when no
      # fold holds it.
      #: (Integer) -> bool
      def open_at(row)
        i = closed_at(row)
        if i >= 0
          closed[i] = false
          return true
        end
        holds?(row)
      end

      # Closes the innermost open fold holding row above its first closed
      # one (zc); false when no fold holds it.
      #: (Integer) -> bool
      def close_at(row)
        found = -1
        i = 0
        while i < starts.length
          if starts[i] <= row && ends[i] >= row
            break if closed[i]
            found = i
          end
          i += 1
        end
        closed[found] = true if found >= 0
        holds?(row)
      end

      # Opens the fold at row when it is closed, else closes one (za).
      #: (Integer) -> bool
      def toggle_at(row)
        closed_at(row) >= 0 ? open_at(row) : close_at(row)
      end

      # Deletes the innermost fold holding row above its first closed one,
      # or that closed one (zd), keeping the folds nested in it; false
      # when no fold holds it.
      #: (Integer) -> bool
      def delete_at(row)
        found = -1
        i = 0
        while i < starts.length
          if starts[i] <= row && ends[i] >= row
            found = i
            break if closed[i]
          end
          i += 1
        end
        return false if found < 0
        remove_at(found)
        true
      end

      # Deletes every fold (zE).
      #: () -> void
      def clear
        starts.clear
        ends.clear
        closed.clear
        labels.clear
        label_widths.clear
      end

      # Takes a copy of other's folds, as a split's new window does.
      #: (Folds) -> void
      def copy_from(other)
        self.starts = other.starts.dup
        self.ends = other.ends.dup
        self.closed = other.closed.dup
        self.labels = other.labels.dup
        self.label_widths = other.label_widths.dup
      end

      # Moves the folds by an edit at row that replaced removed rows with
      # inserted ones: the first rows of both are changed in place, then
      # the rest are deleted, shrinking the folds and dropping one whose
      # rows all go, or inserted, shifting the folds below and extending
      # one they land inside.
      #: (Integer, Integer, Integer) -> void
      def shift(row, removed, inserted)
        same = removed < inserted ? removed : inserted
        at = row + same
        gone = removed - same
        added = inserted - same
        delete_rows(at, gone) if gone > 0
        insert_rows(at, added) if added > 0
        forget_labels
      end

      # Neovim's default fold text for fold i, whose first line is text,
      # filled to width with FILL: "+--" with a dash per level, the line
      # count, and the line with its leading blanks removed and its tabs
      # made spaces. Kept until the folds or the width change.
      #: (Integer, String, Integer) -> String
      def label(i, text, width)
        kept = labels[i]
        return kept if !kept.empty? && label_widths[i] == width
        lines = (ends[i] - starts[i] + 1).to_s
        lines = " " + lines while lines.length < 3
        head = "+-" + "-" * level(i) + lines + " lines: " + text.lstrip.tr("\t", " ")
        fill = width - head.length
        made = fill > 0 ? head + FILL * fill : head
        labels[i] = made
        label_widths[i] = width
        made
      end

      private

      # The folds holding fold i, itself included: the sort puts every
      # one of them at i or before it.
      #: (Integer) -> Integer
      def level(i)
        depth = 0
        j = 0
        while j <= i
          depth += 1 if starts[j] <= starts[i] && ends[j] >= ends[i]
          j += 1
        end
        depth
      end

      #: (Integer) -> bool
      def holds?(row)
        i = 0
        while i < starts.length
          return true if starts[i] <= row && ends[i] >= row
          i += 1
        end
        false
      end

      #: (Integer, Integer) -> void
      def delete_rows(at, gone)
        stop = at + gone
        i = starts.length - 1
        while i >= 0
          s = starts[i]
          e = ends[i]
          s = s >= stop ? s - gone : at if s >= at
          e = e >= stop ? e - gone : at - 1 if e >= at
          if e < s
            remove_at(i)
          else
            starts[i] = s
            ends[i] = e
          end
          i -= 1
        end
      end

      #: (Integer, Integer) -> void
      def insert_rows(at, added)
        i = 0
        while i < starts.length
          starts[i] = starts[i] + added if starts[i] >= at
          ends[i] = ends[i] + added if ends[i] >= at
          i += 1
        end
      end

      #: (Integer) -> void
      def remove_at(i)
        starts.delete_at(i)
        ends.delete_at(i)
        closed.delete_at(i)
        labels.delete_at(i)
        label_widths.delete_at(i)
        forget_labels
      end

      # Drops every kept fold text: a fold made or deleted changes the
      # level, and so the dashes, of the folds it holds or sits in.
      #: () -> void
      def forget_labels
        i = 0
        while i < labels.length
          labels[i] = ""
          i += 1
        end
      end
    end
  end
end
