module Carat
  module Domain
    # The document symbols the editor shares with the language services,
    # for the winbar's symbol path. languages are those whose running
    # server offers document symbols. The gateway asks for the current
    # window's buffer's symbols once per text: asked_buffer,
    # asked_changes, and asked_closed are the buffer id and the change
    # counts of the text last asked (0, -1, -1 for none); sent_id is the
    # request in flight (0 for none), language its server's, and deadline
    # when it is cancelled unanswered. The answer is kept for buffer_id (0
    # for none) as parallel lists, parents before children: each symbol's
    # name (cleaned and cut, untrusted), first row, and last row. A Struct
    # record built with no arguments.
    class SymbolRequest < Struct.new(:languages, :asked_buffer, :asked_changes, :asked_closed, :sent_id, :language, :deadline, :buffer_id, :names, :starts, :ends, keyword_init: true)
      # @rbs @languages: Array[String]
      # @rbs @asked_buffer: Integer
      # @rbs @asked_changes: Integer
      # @rbs @asked_closed: Integer
      # @rbs @sent_id: Integer
      # @rbs @language: String
      # @rbs @deadline: Float
      # @rbs @buffer_id: Integer
      # @rbs @names: Array[String]
      # @rbs @starts: Array[Integer]
      # @rbs @ends: Array[Integer]

      #: () -> void
      def initialize
        super()
        self.languages = [""]
        languages.clear
        self.asked_buffer = 0
        self.asked_changes = -1
        self.asked_closed = -1
        self.sent_id = 0
        self.language = ""
        self.deadline = 0.0
        self.buffer_id = 0
        self.names = [""]
        names.clear
        self.starts = []
        self.ends = []
      end

      # Whether a running server of the language offers document symbols.
      #: (String) -> bool
      def offers?(name)
        languages.include?(name)
      end

      # Whether a request is in flight.
      #: () -> bool
      def waiting?
        sent_id != 0
      end

      # Whether the text of that buffer, at those change counts, was the
      # last asked.
      #: (Integer, Integer, Integer) -> bool
      def asked?(buffer, changes, closed)
        asked_buffer == buffer && asked_changes == changes && asked_closed == closed
      end

      # Records the text a request is sent for.
      #: (Integer, Integer, Integer) -> void
      def ask(buffer, changes, closed)
        self.asked_buffer = buffer
        self.asked_changes = changes
        self.asked_closed = closed
      end

      # Drops the held symbols and keeps the next ones for the buffer last
      # asked.
      #: () -> void
      def restart
        self.buffer_id = asked_buffer
        names.clear
        starts.clear
        ends.clear
      end

      # Keeps one symbol spanning the rows from first to last.
      #: (String, Integer, Integer) -> void
      def add(name, first, last)
        names << name
        starts << first
        ends << last
      end

      # The number of symbols held.
      #: () -> Integer
      def count
        names.length
      end

      # Whether the symbols held are the buffer's.
      #: (Integer) -> bool
      def held?(buffer)
        buffer_id != 0 && buffer_id == buffer
      end

      # Whether symbol i spans the row.
      #: (Integer, Integer) -> bool
      def spans?(index, row)
        starts[index] <= row && row <= ends[index]
      end

      #: (Integer) -> String
      def name_at(index)
        names[index]
      end
    end
  end
end
