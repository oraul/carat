require_relative "completion_list"

module Carat
  module Domain
    # The asynchronous completion ask a source shares with the language
    # services. The source records the wanted word (buffer id, row, and
    # start column) under a new serial, want; the gateway schedules it
    # (seen, due), sends it (sent, the request id in flight sent_id, 0 for
    # none, and its server's language), and keeps the answer of serial
    # answered in list, setting arrived for the editor to refresh the
    # popup. languages are those whose running server completes. A Struct
    # record built with no arguments.
    class CompletionRequest < Struct.new(:buffer_id, :row, :col, :want, :seen, :due, :sent, :sent_id, :language, :answered, :list, :arrived, :languages, keyword_init: true)
      # @rbs @buffer_id: Integer
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @want: Integer
      # @rbs @seen: Integer
      # @rbs @due: Float
      # @rbs @sent: Integer
      # @rbs @sent_id: Integer
      # @rbs @language: String
      # @rbs @answered: Integer
      # @rbs @list: CompletionList
      # @rbs @arrived: bool
      # @rbs @languages: Array[String]

      #: () -> void
      def initialize
        super()
        self.buffer_id = 0
        self.row = -1
        self.col = -1
        self.want = 0
        self.seen = 0
        self.due = 0.0
        self.sent = 0
        self.sent_id = 0
        self.language = ""
        self.answered = 0
        self.list = CompletionList.new
        self.arrived = false
        self.languages = [""]
        languages.clear
      end

      # Records the word as wanted under a new serial, unless it is the
      # word already wanted.
      #: (Integer, Integer, Integer) -> void
      def ask(id, at_row, at_col)
        return if wanted?(id, at_row, at_col)
        self.buffer_id = id
        self.row = at_row
        self.col = at_col
        self.want = want + 1
      end

      # Whether the word is the one wanted.
      #: (Integer, Integer, Integer) -> bool
      def wanted?(id, at_row, at_col)
        want > 0 && buffer_id == id && row == at_row && col == at_col
      end

      # Whether list holds the answer for the word, the one wanted.
      #: (Integer, Integer, Integer) -> bool
      def answer_for?(id, at_row, at_col)
        answered == want && wanted?(id, at_row, at_col)
      end

      # Whether a running server of the language completes.
      #: (String) -> bool
      def completes?(name)
        languages.include?(name)
      end

      # Whether the services owe a tick: a wanted word not yet sent or a
      # request in flight.
      #: () -> bool
      def waiting?
        sent != want || sent_id != 0
      end
    end
  end
end
