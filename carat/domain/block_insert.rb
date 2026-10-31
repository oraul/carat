module Carat
  module Domain
    # The repetition a blockwise "I", "A", or "c" owes when insert mode is
    # left: the row typed on, the column and the line length when insert
    # mode started, the line count then, the other rows of the block to
    # repeat on, the display column to insert at, how (:insert and :change
    # at that column, :append padding a short row up to it, :append_end at
    # every row's end), and the column the cursor goes to afterwards (-1
    # for the usual one column left). A Struct record held by the editor
    # state; active is false when nothing is owed.
    class BlockInsert < Struct.new(:active, :kind, :row, :col, :length, :line_count, :rows, :vcol, :home)
      # @rbs @active: bool
      # @rbs @kind: Symbol
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @length: Integer
      # @rbs @line_count: Integer
      # @rbs @rows: Array[Integer]
      # @rbs @vcol: Integer
      # @rbs @home: Integer

      #: () -> void
      def initialize
        super(false, :none, 0, 0, 0, 0, [], 0, -1)
      end

      #: (Symbol, Integer, Integer, Integer, Integer, Array[Integer], Integer, Integer) -> void
      def start(kind, row, col, length, line_count, rows, vcol, home)
        self.active = true
        self.kind = kind
        self.row = row
        self.col = col
        self.length = length
        self.line_count = line_count
        self.rows = rows
        self.vcol = vcol
        self.home = home
      end

      # Row i of the rows to repeat on, read through a return signature
      # because an indexed element is nullable to the compiler.
      #: (Integer) -> Integer
      def row_at(i)
        rows[i]
      end

      #: () -> void
      def clear
        self.active = false
        self.kind = :none
        self.rows = []
        self.home = -1
      end
    end
  end
end
