module Carat
  module Domain
    # What one buffer primitive changed: the id of the buffer, the first
    # row, the lines it removed from there, and the lines it inserted in
    # their place. The strings are the buffer's own line strings, shared
    # rather than copied, which is sound because a line is never mutated in
    # place: every primitive stores new strings. Applying the record
    # backwards (removing inserted, putting back removed at row) restores
    # the text before the edit. A Data value.
    class ChangeRecord < Data.define(:buffer_id, :row, :removed, :inserted)
      # @rbs @buffer_id: Integer
      # @rbs @row: Integer
      # @rbs @removed: Array[String]
      # @rbs @inserted: Array[String]

      # How many lines the edit added, negative when it removed lines.
      #: () -> Integer
      def delta
        inserted.length - removed.length
      end
    end
  end
end
