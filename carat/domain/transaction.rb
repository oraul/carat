require_relative "position"
require_relative "change_record"

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
    # with another cause joining makes the transaction the editor's. A
    # Struct record.
    class Transaction < Struct.new(:buffer_id, :before, :after, :records, :cause)
      # @rbs @buffer_id: Integer
      # @rbs @before: Position
      # @rbs @after: Position
      # @rbs @records: Array[untyped]
      # @rbs @cause: String

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
        records << record
        nil
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
    end
  end
end
