module Carat
  module Domain
    # The documentation of the candidates of the completion answer a
    # CompletionRequest holds, as the source and the language services
    # share it: one text per candidate (texts, untrusted, "" for none) and
    # its state (known: TO_RESOLVE, ASKED, or HELD); the candidate the
    # popup selects (index) under a serial (want) that changes only when
    # the index does; the gateway's debounce (seen, due); the serial it
    # handled (sent) and the resolve request in flight (sent_id, 0 for
    # none, for the candidate sent_index); and arrived, set when a
    # resolved text is held for the editor to refresh the float. A Struct
    # record built with no arguments.
    class CompletionDocs < Struct.new(:texts, :known, :index, :want, :seen, :due, :sent, :sent_id, :sent_index, :arrived, keyword_init: true)
      # @rbs @texts: Array[String]
      # @rbs @known: Array[Integer]
      # @rbs @index: Integer
      # @rbs @want: Integer
      # @rbs @seen: Integer
      # @rbs @due: Float
      # @rbs @sent: Integer
      # @rbs @sent_id: Integer
      # @rbs @sent_index: Integer
      # @rbs @arrived: bool

      TO_RESOLVE = 0
      ASKED = 1
      HELD = 2

      #: () -> void
      def initialize
        super()
        self.texts = [""]
        texts.clear
        self.known = [0]
        known.clear
        self.index = -1
        self.want = 0
        self.seen = 0
        self.due = 0.0
        self.sent = 0
        self.sent_id = 0
        self.sent_index = -1
        self.arrived = false
      end

      # Records the candidate the popup selects under a new serial when it
      # changed; a candidate with nothing to resolve marks the serial
      # handled, so the services owe it nothing.
      #: (Integer) -> void
      def pick(slot)
        return if slot == index
        self.index = slot
        self.want = want + 1
        self.sent = want unless to_resolve?(slot)
      end

      # Whether the candidate's documentation is still to resolve.
      #: (Integer) -> bool
      def to_resolve?(slot)
        slot >= 0 && slot < known.length && known[slot] == TO_RESOLVE
      end

      # The documentation held for the candidate, "" for none.
      #: (Integer) -> String
      def text_at(slot)
        return "" if slot < 0 || slot >= texts.length
        texts[slot]
      end

      # Adds the next candidate's documentation and its state.
      #: (String, Integer) -> void
      def add(text, state)
        texts << text
        known << state
        nil
      end

      # Whether the services owe a tick: a picked candidate not yet handled
      # or a resolve request in flight.
      #: () -> bool
      def waiting?
        sent != want || sent_id != 0
      end

      # Forgets the candidates for a new answer; the serials go on, and the
      # caller cancels the request in flight first.
      #: () -> void
      def clear
        texts.clear
        known.clear
        self.index = -1
        self.sent = want
        self.sent_index = -1
        self.arrived = false
      end
    end
  end
end
