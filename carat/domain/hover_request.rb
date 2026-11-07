module Carat
  module Domain
    # The hover documentation ask the editor shares with the language
    # services. K records the window, buffer, and cursor it was typed at
    # (the anchor) under a new serial, want; the gateway sends it once
    # (sent, the serial it handled; sent_id, the request in flight, 0 for
    # none; language, its server's; deadline, when it is cancelled
    # unanswered) and keeps the answer as one markdown text (untrusted,
    # "" for none), setting arrived for the editor to show it. languages
    # are those whose running server hovers. float_id is the float the
    # editor shows the answer in, 0 for none, anchored where it was
    # asked. A Struct record built with no arguments.
    class HoverRequest < Struct.new(:window_id, :buffer_id, :row, :col, :want, :sent, :sent_id, :language, :deadline, :text, :arrived, :languages, :float_id, keyword_init: true)
      # @rbs @window_id: Integer
      # @rbs @buffer_id: Integer
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @want: Integer
      # @rbs @sent: Integer
      # @rbs @sent_id: Integer
      # @rbs @language: String
      # @rbs @deadline: Float
      # @rbs @text: String
      # @rbs @arrived: bool
      # @rbs @languages: Array[String]
      # @rbs @float_id: Integer

      #: () -> void
      def initialize
        super()
        self.window_id = 0
        self.buffer_id = 0
        self.row = -1
        self.col = -1
        self.want = 0
        self.sent = 0
        self.sent_id = 0
        self.language = ""
        self.deadline = 0.0
        self.text = ""
        self.arrived = false
        self.languages = [""]
        languages.clear
        self.float_id = 0
      end

      # Records an ask at the anchor under a new serial; an answer not yet
      # shown is dropped.
      #: (Integer, Integer, Integer, Integer) -> void
      def ask(window, buffer, at_row, at_col)
        self.window_id = window
        self.buffer_id = buffer
        self.row = at_row
        self.col = at_col
        self.want = want + 1
        self.arrived = false
        self.text = ""
      end

      # Whether the anchor is that window, buffer, and cursor.
      #: (Integer, Integer, Integer, Integer) -> bool
      def at?(window, buffer, at_row, at_col)
        want > 0 && window_id == window && buffer_id == buffer && row == at_row && col == at_col
      end

      # Whether a running server of the language hovers.
      #: (String) -> bool
      def hovers?(name)
        languages.include?(name)
      end

      # Whether the services owe a tick: an ask not yet sent or a request
      # in flight.
      #: () -> bool
      def waiting?
        sent != want || sent_id != 0
      end
    end
  end
end
