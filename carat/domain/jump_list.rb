module Carat
  module Domain
    # The jump list: the positions gd left, oldest first, as parallel
    # buffer ids, rows, and columns, at most LIMIT; index is the current
    # entry, equal to the length when none is (after a jump). A new entry
    # replaces one of the same buffer and row. Ctrl-O from the newest end
    # first records where it starts, so Ctrl-I comes back there. A Struct
    # record built with no arguments.
    class JumpList < Struct.new(:buffer_ids, :rows, :cols, :index, keyword_init: true)
      # @rbs @buffer_ids: Array[Integer]
      # @rbs @rows: Array[Integer]
      # @rbs @cols: Array[Integer]
      # @rbs @index: Integer

      LIMIT = 100

      #: () -> void
      def initialize
        super()
        self.buffer_ids = []
        self.rows = []
        self.cols = []
        self.index = 0
      end

      #: () -> Integer
      def count
        buffer_ids.length
      end

      # Appends a position, dropping an entry of the same buffer and row
      # and the oldest past LIMIT; no entry is current afterwards.
      #: (Integer, Integer, Integer) -> void
      def push(buffer_id, row, col)
        i = 0
        while i < buffer_ids.length
          if buffer_ids[i] == buffer_id && rows[i] == row
            remove_at(i)
          else
            i += 1
          end
        end
        buffer_ids << buffer_id
        rows << row
        cols << col
        remove_at(0) while buffer_ids.length > LIMIT
        self.index = buffer_ids.length
      end

      # Moves by entries, older for a negative by, from the position given
      # (recorded first when going older from the newest end); answers the
      # entry reached, or -1 past either end with nothing moved.
      #: (Integer, Integer, Integer, Integer) -> Integer
      def step(by, buffer_id, row, col)
        if by < 0 && index >= buffer_ids.length
          push(buffer_id, row, col)
          self.index = buffer_ids.length - 1
        end
        target = index + by
        return -1 if target < 0 || target >= buffer_ids.length
        self.index = target
        target
      end

      # Removes the entry at i, keeping index on the same entry.
      #: (Integer) -> void
      def remove_at(i)
        return if i < 0 || i >= buffer_ids.length
        buffer_ids.delete_at(i)
        rows.delete_at(i)
        cols.delete_at(i)
        self.index = index - 1 if index > i
      end
    end
  end
end
