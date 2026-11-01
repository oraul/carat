require_relative "decoded_line"
require_relative "identity_table"

module Carat
  module Domain
    # The decoded lines of the rows the windows show, keyed by the identity
    # of each line string. Lines are never changed in place, so a line
    # that is the same object decodes the same; an edited row holds a new
    # string and is decoded again. Two generations bound it to what is on
    # the screen: fetch looks in the current table, then in the previous
    # one, moving a hit forward, and decodes a miss into the current one;
    # turn, once per frame, drops the previous table and starts a new
    # current one, so a line no frame fetched since the last turn is gone
    # after the next. A line asked for with another tabstop is decoded
    # again. A Struct record built once and shared by ArrangeView and the
    # frame presenter.
    class LineCache < Struct.new(:current, :previous)
      CAPACITY = 256

      # @rbs @current: IdentityTable
      # @rbs @previous: IdentityTable

      #: () -> void
      def initialize
        super(IdentityTable.new(CAPACITY), IdentityTable.new(CAPACITY))
      end

      #: (String, Integer) -> DecodedLine
      def fetch(text, tabstop)
        entry = current.find(text)
        return entry if !entry.nil? && entry.tabstop == tabstop
        entry = previous.find(text)
        entry = DecodedLine.decode(text, tabstop) if entry.nil? || entry.tabstop != tabstop
        current.store(entry)
        entry
      end

      # Starts a new generation: the lines fetched since the last turn stay
      # one more generation, the older ones are dropped.
      #: () -> void
      def turn
        older = previous
        self.previous = current
        older.clear
        self.current = older
      end

      # The number of lines the current generation holds.
      #: () -> Integer
      def size
        current.size
      end

      # Whether the line object is held in either generation.
      #: (String) -> bool
      def holds?(text)
        !current.find(text).nil? || !previous.find(text).nil?
      end
    end
  end
end
