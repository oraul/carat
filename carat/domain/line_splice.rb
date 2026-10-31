module Carat
  module Domain
    # Replaces a span of a line array in place without copying the rest of
    # it. The rows both sides have in common are overwritten; the
    # difference is made with one insert or delete_at per line when it is
    # at most SMALL lines, and with one pass that moves the tail when it is
    # larger, measured on Spinel to be the faster choice above eight lines
    # (each insert or delete_at moves the whole tail natively; the pass
    # moves it once, element by element). A slice assignment that changes
    # the length copies the tail into a new array, which is what this
    # avoids. Over Array[String] only: a later per-line array of another
    # element type gets a sibling function of the same shape, because
    # Spinel types a method's parameters once for the whole program.
    module LineSplice
      SMALL = 8

      # Replaces lines[from...to] with new_lines; from and to are inside
      # the array, from <= to.
      #: (Array[String], Integer, Integer, Array[String]) -> void
      def self.apply(lines, from, to, new_lines)
        removed = to - from
        added = new_lines.length
        common = removed < added ? removed : added
        i = 0
        while i < common
          lines[from + i] = new_lines[i]
          i += 1
        end
        at = from + common
        if added > removed
          grow(lines, at, new_lines, common)
        elsif removed > added
          shrink(lines, at, removed - added)
        end
        nil
      end

      # Inserts source[start..] at row at.
      #: (Array[String], Integer, Array[String], Integer) -> void
      def self.grow(lines, at, source, start)
        extra = source.length - start
        if extra <= SMALL
          k = 0
          while k < extra
            lines.insert(at + k, source[start + k])
            k += 1
          end
        else
          spread(lines, at, source, start, extra)
        end
        nil
      end

      # Opens a gap of extra rows at row at by moving the tail once, then
      # fills it from source[start..].
      #: (Array[String], Integer, Array[String], Integer, Integer) -> void
      def self.spread(lines, at, source, start, extra)
        old = lines.length
        k = 0
        while k < extra
          lines << ""
          k += 1
        end
        j = old - 1
        while j >= at
          lines[j + extra] = lines[j]
          j -= 1
        end
        k = 0
        while k < extra
          lines[at + k] = source[start + k]
          k += 1
        end
        nil
      end

      # Removes count rows starting at row at.
      #: (Array[String], Integer, Integer) -> void
      def self.shrink(lines, at, count)
        if count <= SMALL
          k = 0
          while k < count
            lines.delete_at(at)
            k += 1
          end
        else
          close_gap(lines, at, count)
        end
        nil
      end

      # Moves the tail back over count rows at row at once, then drops the
      # last count slots.
      #: (Array[String], Integer, Integer) -> void
      def self.close_gap(lines, at, count)
        last = lines.length - count
        j = at
        while j < last
          lines[j] = lines[j + count]
          j += 1
        end
        k = 0
        while k < count
          lines.pop
          k += 1
        end
        nil
      end
    end
  end
end
