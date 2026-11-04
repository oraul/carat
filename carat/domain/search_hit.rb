module Carat
  module Domain
    # Where a search landed: the row and the columns of the match, from
    # col up to end_col, whether it passed an end of the buffer, the
    # status, :found, :missing (no match), :stopped (its budget ran out
    # or the engine failed), or :refused (no search could start), and the
    # message to show for it. A Struct record: mutable, with a reader and
    # a writer per member, filled in place as a search steps.
    class SearchHit < Struct.new(:row, :col, :end_col, :wrapped, :status, :message, keyword_init: true)
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @end_col: Integer
      # @rbs @wrapped: bool
      # @rbs @status: Symbol
      # @rbs @message: String

      #: (row: Integer, col: Integer) -> void
      def initialize(row:, col:)
        super(row: row, col: col, end_col: col, wrapped: false, status: :missing, message: "")
      end

      #: () -> bool
      def found?
        status == :found
      end

      # A search that could not start, with the reason.
      #: (Integer, Integer, String) -> SearchHit
      def self.refused(row, col, message)
        hit = SearchHit.new(row: row, col: col)
        hit.status = :refused
        hit.message = message
        hit
      end

      #: (Integer, Integer, Integer) -> void
      def land(row, col, end_col)
        self.row = row
        self.col = col
        self.end_col = end_col
        self.status = :found
      end
    end
  end
end
