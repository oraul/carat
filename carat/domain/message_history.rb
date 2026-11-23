module Carat
  module Domain
    # What the message row and the notifications told the user, oldest
    # first, as Neovim's message history: each entry a text, the oldest
    # dropped past LIMIT. The texts are kept as given, never copied or
    # changed. INFO, WARNING, and ERROR are the levels of a message or a
    # notification, which the history itself does not keep. A Struct
    # record: mutable, with a reader and a writer per member.
    class MessageHistory < Struct.new(:texts, keyword_init: true)
      INFO = 0
      WARNING = 1
      ERROR = 2
      LIMIT = 500

      # @rbs @texts: Array[String]

      # An empty history.
      #: () -> void
      def initialize
        super()
        self.texts = []
      end

      # Keeps a non-empty text, dropping the oldest past LIMIT. A text
      # may have several lines, as the refusal of a quit over two buffers
      # does; the callers keep a listing out.
      #: (String) -> void
      def add(text)
        return if text.empty?
        texts << text
        texts.shift if texts.length > LIMIT
      end

      #: () -> Integer
      def count
        texts.length
      end

      #: (Integer) -> String
      def text_at(i)
        texts[i]
      end

      # Every text in order, one per line.
      #: () -> String
      def to_s
        texts.join("\n")
      end

      #: () -> void
      def clear
        texts.clear
      end
    end
  end
end
