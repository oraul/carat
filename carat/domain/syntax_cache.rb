require_relative "line_splice"
require_relative "syntax_line"
require_relative "syntax_table"

module Carat
  module Domain
    # What a buffer's tokenizer has said so far, so a frame tokenizes only
    # what changed. ends holds the state at the end of every row reached
    # so far, its length the frontier, UNKNOWN for a row whose text changed
    # since; the rows [0, valid) have end states known to be right; and
    # dirty_to is the row after the last row changed since valid last
    # passed it. The tokens of the visible lines are SyntaxLine values in
    # two generations of tables keyed by the identity of the line string,
    # which is sound because lines are never changed in place: a row whose
    # line object and start state are the same has the same tokens. The
    # generations turn once per frame, so a line no window showed in the
    # last two frames is dropped. owner and name are the plugin and the
    # syntax the contents came from; another pair resets the cache, and
    # an empty owner means the buffer is drawn plain.
    #
    # Every splice of the buffer calls shift, which moves ends with the
    # rows, marks the changed rows UNKNOWN, and lowers valid to the first
    # changed row. advance records the new end state of the row at valid
    # and, when it equals the state stored before for a row at or after
    # the last change, moves valid to the frontier: every row up to it was
    # computed from its own unchanged text and the state before it, which
    # is the same again. A Struct record.
    class SyntaxCache < Struct.new(:ends, :valid, :dirty_to, :current, :previous, :owner, :name, :serial, keyword_init: true)
      UNKNOWN = -1
      CAPACITY = 128

      # @rbs @ends: Array[Integer]
      # @rbs @valid: Integer
      # @rbs @dirty_to: Integer
      # @rbs @current: SyntaxTable
      # @rbs @previous: SyntaxTable
      # @rbs @owner: String
      # @rbs @name: String
      # @rbs @serial: Integer

      #: () -> void
      def initialize
        super()
        self.ends = []
        self.valid = 0
        self.dirty_to = 0
        self.current = SyntaxTable.new(capacity: CAPACITY)
        self.previous = SyntaxTable.new(capacity: CAPACITY)
        self.owner = ""
        self.name = ""
        self.serial = 0
      end

      # Whether the cache holds a tokenizer's results, so the buffer is
      # drawn highlighted.
      #: () -> bool
      def active?
        !owner.empty?
      end

      # Readies the cache for a frame drawn with the owner plugin's
      # tokenizer for the syntax name: a new pair resets it, and the
      # generations turn once per frame serial.
      #: (String, String, Integer) -> void
      def prepare(plugin, syntax, frame_serial)
        reset(plugin, syntax) unless owner == plugin && name == syntax
        return if serial == frame_serial
        self.serial = frame_serial
        older = previous
        self.previous = current
        older.clear
        self.current = older
      end

      # Forgets everything; the buffer is drawn plain until prepared again.
      #: () -> void
      def drop
        reset("", "") if active? || !ends.empty?
      end

      # The state at the start of a row at or above valid.
      #: (Integer) -> Integer
      def start_of(row)
        row == 0 ? 0 : ends[row - 1]
      end

      # The tokens of the line object for that start state, moved into the
      # current generation, or nil.
      #: (String, Integer) -> SyntaxLine?
      def find(text, start)
        entry = current.find(text)
        return entry if !entry.nil? && entry.start == start
        entry = previous.find(text)
        return nil if entry.nil? || entry.start != start
        current.store(entry)
        entry
      end

      # Keeps the tokens of the line object for a start state.
      #: (String, Integer, Array[Integer], Integer) -> void
      def store(text, start, tokens, end_state)
        current.store(SyntaxLine.new(text, start, tokens, end_state))
      end

      # Records the end state of the row at valid and moves valid past it,
      # to the frontier when the state settled.
      #: (Integer, Integer) -> void
      def advance(row, end_state)
        old = UNKNOWN
        if row < ends.length
          old = ends[row]
          ends[row] = end_state
        else
          ends << end_state
        end
        if old == end_state && old != UNKNOWN && row + 1 >= dirty_to
          self.valid = ends.length
          self.dirty_to = 0
        else
          self.valid = row + 1
          self.dirty_to = 0 if valid >= dirty_to
        end
      end

      # Follows an edit at row that replaced removed rows with inserted
      # ones: the end states move with the rows, the inserted rows are
      # unknown, and an edit that reaches the frontier cuts it there.
      #: (Integer, Integer, Integer) -> void
      def shift(row, removed, inserted)
        known = ends.length
        return if row >= known
        if row + removed >= known
          ends.pop while ends.length > row
        else
          LineSplice.shift_marks(ends, row, removed, inserted)
          i = 0
          while i < inserted
            ends[row + i] = UNKNOWN
            i += 1
          end
        end
        last = dirty_to > valid ? dirty_to : 0
        self.valid = row if valid > row
        stop = row + inserted
        if last > row + removed
          last = last + inserted - removed
        elsif last > row
          last = stop
        end
        self.dirty_to = last > stop ? last : stop
      end

      # The tokens a visible row is painted with: its line's entry for the
      # row's start state, or NONE when the cache is inactive, the row is
      # past valid, or the line was not tokenized for this frame.
      #: (Integer, String) -> SyntaxLine
      def lookup(row, text)
        return SyntaxLine::NONE if owner.empty? || row > valid
        start = row == 0 ? 0 : ends[row - 1]
        entry = current.find(text)
        return SyntaxLine::NONE if entry.nil? || entry.start != start
        entry
      end

      private

      #: (String, String) -> void
      def reset(plugin, syntax)
        ends.clear
        self.valid = 0
        self.dirty_to = 0
        current.clear
        previous.clear
        self.owner = plugin
        self.name = syntax
      end
    end
  end
end
