require_relative "control_text"

module Carat
  module Domain
    # The signature help ask the editor shares with the language
    # services while insert mode follows a call. The anchor is the window,
    # buffer, and row typed in, open_col, the byte column of the call's
    # "(" (-1 when no call is followed), and col, the cursor column asked
    # at. Each ask or stop takes a new serial, want; the gateway debounces
    # it (seen, the serial it scheduled; due, when it may be sent), sends it
    # once (sent, the serial it handled; sent_id, the request in flight, 0
    # for none; language, its server's; deadline, when it is cancelled
    # unanswered), and keeps the answer: label, the active signature
    # without controls or escape sequences and at most LABEL_LIMIT bytes
    # (untrusted, "" for none), mark_from and mark_to, the byte range of
    # its active parameter (-1 for none), and arrived for the editor to
    # show it. languages are those whose running server gives signature
    # help. float_id is the float the editor shows the label in, 0 for
    # none. A Struct record built with no arguments.
    class SignatureRequest < Struct.new(:window_id, :buffer_id, :row, :open_col, :col, :want, :seen, :due, :sent, :sent_id, :language, :deadline, :label, :mark_from, :mark_to, :arrived, :languages, :float_id, keyword_init: true)
      # @rbs @window_id: Integer
      # @rbs @buffer_id: Integer
      # @rbs @row: Integer
      # @rbs @open_col: Integer
      # @rbs @col: Integer
      # @rbs @want: Integer
      # @rbs @seen: Integer
      # @rbs @due: Float
      # @rbs @sent: Integer
      # @rbs @sent_id: Integer
      # @rbs @language: String
      # @rbs @deadline: Float
      # @rbs @label: String
      # @rbs @mark_from: Integer
      # @rbs @mark_to: Integer
      # @rbs @arrived: bool
      # @rbs @languages: Array[String]
      # @rbs @float_id: Integer

      # The owner of the scratch buffer the signature is shown in.
      OWNER = ":signature"
      # The most bytes of a label kept.
      LABEL_LIMIT = 1024
      # The most bytes scanned back from the cursor for the call's "(".
      SCAN_LIMIT = 1024

      #: () -> void
      def initialize
        super()
        self.window_id = 0
        self.buffer_id = 0
        self.row = -1
        self.open_col = -1
        self.col = -1
        self.want = 0
        self.seen = 0
        self.due = 0.0
        self.sent = 0
        self.sent_id = 0
        self.language = ""
        self.deadline = 0.0
        self.label = ""
        self.mark_from = -1
        self.mark_to = -1
        self.arrived = false
        self.languages = [""]
        languages.clear
        self.float_id = 0
      end

      # Whether a call is followed.
      #: () -> bool
      def active?
        open_col >= 0
      end

      # Records an ask for the call opened at paren, the cursor at at_col,
      # under a new serial; an answer not yet shown is dropped.
      #: (Integer, Integer, Integer, Integer, Integer) -> void
      def ask(window, buffer, at_row, paren, at_col)
        self.window_id = window
        self.buffer_id = buffer
        self.row = at_row
        self.open_col = paren
        self.col = at_col
        self.want = want + 1
        forget_answer
      end

      # Stops following the call under a new serial, so the request in
      # flight is cancelled and its answer dropped.
      #: () -> void
      def stop
        self.open_col = -1
        self.want = want + 1
        forget_answer
      end

      # Whether the followed call is in that window, buffer, and row.
      #: (Integer, Integer, Integer) -> bool
      def on?(window, buffer, at_row)
        active? && window_id == window && buffer_id == buffer && row == at_row
      end

      # Whether the ask is that window, buffer, row, and cursor column.
      #: (Integer, Integer, Integer, Integer) -> bool
      def at?(window, buffer, at_row, at_col)
        on?(window, buffer, at_row) && col == at_col
      end

      # Whether a running server of the language gives signature help.
      #: (String) -> bool
      def helps?(name)
        languages.include?(name)
      end

      # Whether the services owe a tick: an ask not yet sent or a request
      # in flight.
      #: () -> bool
      def waiting?
        sent != want || sent_id != 0
      end

      # Keeps an answer: the label as the three raw pieces around its
      # active parameter, each without escape sequences or controls, the
      # whole at most LABEL_LIMIT bytes; the parameter is marked when any of
      # it is kept. An empty parameter marks nothing.
      #: (String, String, String) -> void
      def keep(prefix, parameter, suffix)
        head = ControlText.plain(prefix, LABEL_LIMIT)
        middle = ControlText.plain(parameter, LABEL_LIMIT - head.bytesize)
        tail = ControlText.plain(suffix, LABEL_LIMIT - head.bytesize - middle.bytesize)
        self.label = head + middle + tail
        if middle.empty?
          self.mark_from = -1
          self.mark_to = -1
        else
          self.mark_from = head.bytesize
          self.mark_to = head.bytesize + middle.bytesize
        end
        self.arrived = true
      end

      # The byte column of the innermost "(" left open before col on the
      # line, scanning back at most SCAN_LIMIT bytes; -1 for none.
      #: (String, Integer) -> Integer
      def self.open_paren(line, col)
        i = col > line.bytesize ? line.bytesize : col
        stop = i - SCAN_LIMIT
        stop = 0 if stop < 0
        depth = 0
        while i > stop
          i -= 1
          b = line.getbyte(i).to_i
          if b == 41
            depth += 1
          elsif b == 40
            return i if depth == 0
            depth -= 1
          end
        end
        -1
      end

      private

      #: () -> void
      def forget_answer
        self.arrived = false
        self.label = ""
        self.mark_from = -1
        self.mark_to = -1
      end
    end
  end
end
