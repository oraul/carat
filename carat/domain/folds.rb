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
      # it crosses: one starting inside it past its first row and ending
      # below it, or starting above it and ending inside it before its
      # last row. A fold sharing its first row holds it or is held, as
      # Neovim nests them.
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
            crosses = (s > from && s <= to && e > to) || (s < from && e >= from && e < to)
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

      # Opens every fold (zR), as Neovim's highest foldlevel does.
      #: () -> void
      def open_all
        fill_closed(false)
      end

      # Closes every fold (zM), as Neovim's foldlevel 0 does.
      #: () -> void
      def close_all
        fill_closed(true)
      end

      # The row zj (forward) or zk moves to from row: the first row of the
      # next fold or the last row of the previous one, as Neovim's
      # foldMoveTo walks the nested folds from the top: at each level the
      # fold beside row gives the row, a deeper one replacing it, and the
      # walk goes into the fold holding row unless it is closed, so a
      # closed fold counts as one. row when there is none.
      #: (Integer, bool) -> Integer
      def next_fold_row(row, forward)
        found = row
        parent = -1
        while true
          j = child_beside(parent, row, forward)
          if j >= 0
            found = forward ? starts[j] : ends[j]
          end
          at = child_holding(parent, row)
          break if at < 0 || closed[at]
          parent = at
        end
        found
      end

      # The row ]z (forward) or [z moves to from row: the last or first row
      # of the innermost open fold holding row that moves the cursor, the
      # walk stopping at a closed fold, as Neovim's foldMoveTo does; row
      # when there is none.
      #: (Integer, bool) -> Integer
      def open_fold_row(row, forward)
        found = row
        at = child_holding(-1, row)
        while at >= 0 && !closed[at]
          edge = forward ? ends[at] : starts[at]
          found = edge if forward ? edge > row : edge < row
          at = child_holding(at, row)
        end
        found
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

      #: (bool) -> void
      def fill_closed(value)
        i = 0
        while i < closed.length
          closed[i] = value
          i += 1
        end
      end

      # The innermost fold holding fold i, -1 for none: the sort puts
      # every fold holding it before it, the innermost last.
      #: (Integer) -> Integer
      def parent_of(i)
        j = i - 1
        while j >= 0
          return j if starts[j] <= starts[i] && ends[j] >= ends[i]
          j -= 1
        end
        -1
      end

      # The fold nested directly in fold parent (-1 for the top level)
      # that holds row, -1 for none, parent holding row: the sort puts
      # every fold holding a fold before it, so the first fold past parent
      # that holds row is a direct child of parent.
      #: (Integer, Integer) -> Integer
      def child_holding(parent, row)
        i = parent + 1
        while i < starts.length
          return i if starts[i] <= row && ends[i] >= row
          i += 1
        end
        -1
      end

      # The fold nested directly in fold parent nearest row past it: the
      # first starting below row (forward) or the last ending above it,
      # -1 for none. Beside the fold holding row it is that fold's next or
      # previous sibling.
      #: (Integer, Integer, bool) -> Integer
      def child_beside(parent, row, forward)
        found = -1
        i = parent + 1
        while i < starts.length
          if parent_of(i) == parent
            return i if forward && starts[i] > row
            found = i if !forward && ends[i] < row
          end
          i += 1
        end
        found
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
