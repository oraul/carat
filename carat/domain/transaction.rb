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
    # declares their type. A Struct record.
    class Transaction < Struct.new(:buffer_id, :before, :after, :records)
      # @rbs @buffer_id: Integer
      # @rbs @before: Position
      # @rbs @after: Position
      # @rbs @records: Array[untyped]

      # The empty list is stored through the writer, not passed to super,
      # so its element type is the pinned one.
      #: (Integer, Position) -> void
      def initialize(buffer_id, before)
        super()
        self.buffer_id = buffer_id
        self.before = before
        self.after = before
        self.records = []
      end

      #: (ChangeRecord) -> void
      def add(record)
        records << record
        nil
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
