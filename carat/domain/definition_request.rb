module Carat
  module Domain
    # The definition ask the editor shares with the language services. gd
    # and the peek key record the window, buffer, and cursor they were
    # typed at (the anchor) and whether to peek, under a new serial, want;
    # the gateway sends it once (sent, the serial it handled; sent_id, the
    # request in flight, 0 for none; language, its server's; deadline,
    # when it is cancelled unanswered) and keeps the answer's file targets
    # as parallel target_paths, target_rows, and target_characters
    # (UTF-16 code units, as the protocol counts them), setting arrived
    # for the editor to use them.
    # languages are those whose running server offers definitions.
    # float_id is the peek float and pick_id the pick list, 0 for none. A
    # Struct record built with no arguments.
    class DefinitionRequest < Struct.new(:window_id, :buffer_id, :row, :col, :peek, :want, :sent, :sent_id, :language, :deadline, :arrived, :languages, :target_paths, :target_rows, :target_characters, :float_id, :pick_id, keyword_init: true)
      # @rbs @window_id: Integer
      # @rbs @buffer_id: Integer
      # @rbs @row: Integer
      # @rbs @col: Integer
      # @rbs @peek: bool
      # @rbs @want: Integer
      # @rbs @sent: Integer
      # @rbs @sent_id: Integer
      # @rbs @language: String
      # @rbs @deadline: Float
      # @rbs @arrived: bool
      # @rbs @languages: Array[String]
      # @rbs @target_paths: Array[String]
      # @rbs @target_rows: Array[Integer]
      # @rbs @target_characters: Array[Integer]
      # @rbs @float_id: Integer
      # @rbs @pick_id: Integer

      # The owner of the scratch buffers of the peek float, the pick list,
      # and the read-only views of files outside the project.
      OWNER = ":definitions"

      # The most targets read from one answer.
      LIMIT = 50

      #: () -> void
      def initialize
        super()
        self.window_id = 0
        self.buffer_id = 0
        self.row = -1
        self.col = -1
        self.peek = false
        self.want = 0
        self.sent = 0
        self.sent_id = 0
        self.language = ""
        self.deadline = 0.0
        self.arrived = false
        self.languages = [""]
        languages.clear
        self.target_paths = [""]
        target_paths.clear
        self.target_rows = []
        self.target_characters = []
        self.float_id = 0
        self.pick_id = 0
      end

      # Records an ask at the anchor under a new serial; targets not yet
      # used are dropped.
      #: (Integer, Integer, Integer, Integer, bool) -> void
      def ask(window, buffer, at_row, at_col, peeking)
        self.window_id = window
        self.buffer_id = buffer
        self.row = at_row
        self.col = at_col
        self.peek = peeking
        self.want = want + 1
        self.arrived = false
        clear_targets
      end

      # Whether the anchor is that window, buffer, and cursor.
      #: (Integer, Integer, Integer, Integer) -> bool
      def at?(window, buffer, at_row, at_col)
        want > 0 && window_id == window && buffer_id == buffer && row == at_row && col == at_col
      end

      # Whether a running server of the language offers definitions.
      #: (String) -> bool
      def offers?(name)
        languages.include?(name)
      end

      # Whether the services owe a tick: an ask not yet sent or a request
      # in flight.
      #: () -> bool
      def waiting?
        sent != want || sent_id != 0
      end

      # Whether HandleKey must follow a float after a key.
      #: () -> bool
      def following?
        float_id != 0 || pick_id != 0
      end

      #: () -> void
      def clear_targets
        target_paths.clear
        target_rows.clear
        target_characters.clear
      end

      # Adds a target unless LIMIT are kept.
      #: (String, Integer, Integer) -> void
      def add_target(path, line, character)
        return if target_paths.length >= LIMIT
        target_paths << path
        target_rows << line
        target_characters << character
      end

      #: () -> Integer
      def target_count
        target_paths.length
      end
    end
  end
end
