require_relative "position"
require_relative "change_record"
require_relative "line_splice"

module Carat
  module Domain
    # The edits of one command grouped together: the buffer's id, the
    # cursor before the command and after it, and the change records in
    # the order the primitives made them. A transaction is opened and
    # closed through its buffer (Buffer#begin_transaction and
    # Buffer#commit_transaction); the undo change consumes the closed
    # ones. The records are kept as Array[untyped], because Spinel pins
    # arrays only of builtin types, and read through record_at, which
    # declares their type. cause is the plugin whose request made the
    # records, taken from the first record, or "" for the editor: a record
    # with another cause joining makes the transaction the editor's.
    #
    # A record whose removed rows lie inside the inserted rows of the
    # record before it is merged into that record, so typing on one line
    # keeps one record holding the line before and the line after, as Vim
    # saves a line once per undo state; the records before sealed (the
    # mark the plugin host takes to revert to) are never merged into.
    # history marks the transaction of an undo or a redo, which observers
    # see like any other but which is not kept as an undo state, and whose
    # records are never merged. A Struct record.
    class Transaction < Struct.new(:buffer_id, :before, :after, :records, :cause, :history, :sealed)
      # @rbs @buffer_id: Integer
      # @rbs @before: Position
      # @rbs @after: Position
      # @rbs @records: Array[untyped]
      # @rbs @cause: String
      # @rbs @history: bool
      # @rbs @sealed: Integer

      # The empty list is stored through the writer, not passed to super,
      # so its element type is the pinned one.
      #: (Integer, Position) -> void
      def initialize(buffer_id, before)
        super()
        self.buffer_id = buffer_id
        self.before = before
        self.after = before
        self.records = []
        self.cause = ""
        self.history = false
        self.sealed = 0
      end

      # Adds a record made while the plugin named by cause ("" for none)
      # was running.
      #: (ChangeRecord, String) -> void
      def add(record, cause)
        if records.empty?
          self.cause = cause
        elsif cause != self.cause
          self.cause = ""
        end
        return if merged?(record)
        records << record
        nil
      end

      # Seals the records made so far against merging and returns their
      # count, the mark Buffer#revert_to returns to.
      #: () -> Integer
      def seal
        self.sealed = records.length
        sealed
      end

      # Drops the records after the first count, which Buffer#revert_to
      # has undone.
      #: (Integer) -> void
      def truncate(count)
        records.pop while records.length > count
        nil
      end

      # The rows the transaction changed as one span over the text before
      # it: [first row, rows removed, rows inserted in their place]. Each
      # record widens the span to cover it; rows between two records that
      # did not change are inside the span.
      #: () -> Array[Integer]
      def span
        return [0, 0, 0] if records.empty?
        first = record_at(0)
        start = first.row
        removed = first.removed.length
        inserted = first.inserted.length
        i = 1
        while i < records.length
          r = record_at(i)
          a = r.row
          gone = r.removed.length
          added = r.inserted.length
          delta = inserted - removed
          s = a < start ? a : start
          e = start + inserted
          e = a + gone if a + gone > e
          removed = e - delta - s
          inserted = e + added - gone - s
          start = s
          i += 1
        end
        [start, removed, inserted]
      end

      #: (Integer) -> ChangeRecord
      def record_at(i)
        records[i]
      end

      #: () -> Integer
      def size
        records.length
      end

      #: () -> bool
      def empty?
        records.empty?
      end

      private

      # Merges the record into the last one when its removed rows lie
      # inside the rows the last one inserted: those rows of the last
      # record's inserted list are replaced in place by the record's
      # inserted lines. The inserted list belongs to the record alone,
      # built by the primitive for its call.
      #: (ChangeRecord) -> bool
      def merged?(record)
        n = records.length
        return false if history || n == 0 || n <= sealed
        previous = record_at(n - 1)
        offset = record.row - previous.row
        gone = record.removed.length
        rows = previous.inserted
        return false if offset < 0 || offset + gone > rows.length
        LineSplice.apply(rows, offset, offset + gone, record.inserted)
        true
      end
    end
  end
end
