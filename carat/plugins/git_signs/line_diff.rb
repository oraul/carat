require_relative "../../plugin_api"

module Carat
  module Plugins
    module GitSigns
      # The lines of a buffer that differ from the file's text at HEAD, as
      # one mark per buffer line: NONE, ADDED, CHANGED, or DELETED. The
      # common head and tail are trimmed, then Myers' greedy search finds
      # the fewest insertions and removals for the middle, keeping one copy
      # of the diagonal frontier per edit step, the slice -d..d only, all
      # in one flat list where step d's copy starts at (d-1)**2; past
      # MAX_EDITS steps the whole middle reads as one changed run. Between
      # two kept lines, a run of removals and insertions is CHANGED on its
      # inserted lines, insertions alone are ADDED, and removals alone mark
      # the line above DELETED, the first line when they were at the top.
      # A buffer of one empty line counts as no lines, as an empty file
      # does.
      module LineDiff
        NONE = 0
        ADDED = 1
        CHANGED = 2
        DELETED = 3
        MAX_EDITS = 300

        # One mark per line of new_lines for its difference from old_lines.
        #: (Array[String], Array[String]) -> Array[Integer]
        def self.marks(old_lines, new_lines)
          marks = Array.new(new_lines.length, NONE)
          old_size = old_lines.length
          new_size = counted(new_lines)
          head = 0
          head += 1 while head < old_size && head < new_size && old_lines[head] == new_lines[head]
          tail = 0
          tail += 1 while tail < old_size - head && tail < new_size - head && old_lines[old_size - 1 - tail] == new_lines[new_size - 1 - tail]
          old_count = old_size - head - tail
          new_count = new_size - head - tail
          return marks if old_count == 0 && new_count == 0
          kept = Array.new(new_count, false)
          removed = Array.new(new_count + 1, 0)
          removed[new_count] = old_count unless align(old_lines, new_lines, head, old_count, new_count, kept, removed)
          place(marks, head, kept, removed)
          marks
        end

        # The number of lines that count: none for one empty line.
        #: (Array[String]) -> Integer
        def self.counted(lines)
          lines.length == 1 && lines[0].empty? ? 0 : lines.length
        end

        # Marks in kept each middle line of new_lines that stays and counts
        # in removed the lines removed before each, true when the search
        # ended within MAX_EDITS steps; false leaves both untouched.
        #: (Array[String], Array[String], Integer, Integer, Integer, Array[bool], Array[Integer]) -> bool
        def self.align(old_lines, new_lines, head, old_count, new_count, kept, removed)
          limit = old_count + new_count
          limit = MAX_EDITS if limit > MAX_EDITS
          offset = limit + 1
          frontier = Array.new(2 * limit + 3, 0)
          trace = [0]
          trace.clear
          edits = -1
          d = 0
          while d <= limit && edits < 0
            save(trace, frontier, offset, d)
            k = -d
            while k <= d
              down = k == -d || (k != d && frontier[offset + k - 1] < frontier[offset + k + 1])
              x = down ? frontier[offset + k + 1] : frontier[offset + k - 1] + 1
              y = x - k
              while x < old_count && y < new_count && old_lines[head + x] == new_lines[head + y]
                x += 1
                y += 1
              end
              frontier[offset + k] = x
              if x >= old_count && y >= new_count
                edits = d
                break
              end
              k += 2
            end
            d += 1
          end
          return false if edits < 0
          backtrack(trace, edits, old_count, new_count, kept, removed)
          true
        end

        # Appends the frontier as step d starts, the diagonals
        # -(d-1)..(d-1), to the trace.
        #: (Array[Integer], Array[Integer], Integer, Integer) -> void
        def self.save(trace, frontier, offset, d)
          k = 1 - d
          while k <= d - 1
            trace << frontier[offset + k]
            k += 1
          end
        end

        # Walks the saved frontiers back from the end, step by step.
        #: (Array[Integer], Integer, Integer, Integer, Array[bool], Array[Integer]) -> void
        def self.backtrack(trace, edits, old_count, new_count, kept, removed)
          x = old_count
          y = new_count
          d = edits
          while d > 0
            base = (d - 1) * (d - 1) + d - 1
            k = x - y
            down = k == -d || (k != d && trace[base + k - 1] < trace[base + k + 1])
            before = down ? k + 1 : k - 1
            from_x = trace[base + before]
            from_y = from_x - before
            while x > from_x && y > from_y
              x -= 1
              y -= 1
              kept[y] = true if y < new_count
            end
            removed[from_y] += 1 if !down && from_y >= 0 && from_y <= new_count
            x = from_x
            y = from_y
            d -= 1
          end
          while x > 0 && y > 0
            x -= 1
            y -= 1
            kept[y] = true if y < new_count
          end
        end

        # Turns each gap between kept lines into its marks.
        #: (Array[Integer], Integer, Array[bool], Array[Integer]) -> void
        def self.place(marks, head, kept, removed)
          count = kept.length
          last = -1
          j = 0
          while j <= count
            if j == count || kept[j]
              gone = 0
              i = last + 1
              while i <= j
                gone += removed[i]
                i += 1
              end
              if j > last + 1
                kind = gone > 0 ? CHANGED : ADDED
                i = last + 1
                while i < j
                  mark(marks, head + i, kind)
                  i += 1
                end
              elsif gone > 0
                mark(marks, deleted_row(head, last), DELETED)
              end
              last = j
            end
            j += 1
          end
        end

        # The row a removal-only run marks: the kept line above it, else
        # the line above the middle, else the first line.
        #: (Integer, Integer) -> Integer
        def self.deleted_row(head, last)
          return head + last if last >= 0
          head > 0 ? head - 1 : 0
        end

        #: (Array[Integer], Integer, Integer) -> void
        def self.mark(marks, row, kind)
          marks[row] = kind if row >= 0 && row < marks.length
        end
      end
    end
  end
end
