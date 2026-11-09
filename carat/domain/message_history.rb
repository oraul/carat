module Carat
  module Domain
    # What the message row and the notifications told the user, oldest
    # first, as Neovim's message history: each entry a one-line text and
    # its level (INFO, WARNING, or ERROR), the oldest dropped past LIMIT.
    # The texts are kept as given, never copied or changed. A Struct
    # record: mutable, with a reader and a writer per member.
    class MessageHistory < Struct.new(:texts, :levels, keyword_init: true)
      INFO = 0
      WARNING = 1
      ERROR = 2
      LIMIT = 500

      # @rbs @texts: Array[String]
      # @rbs @levels: Array[Integer]

      # An empty history.
      #: () -> void
      def initialize
        super()
        self.texts = []
        self.levels = []
      end

      # Keeps a non-empty text of one line at a level, dropping the oldest
      # past LIMIT; a text with a line feed is a listing and is not kept.
      #: (String, Integer) -> void
      def add(text, level)
        return if text.empty? || text.include?("\n")
        texts << text
        levels << level
        return if texts.length <= LIMIT
        texts.shift
        levels.shift
      end

      #: () -> Integer
      def count
        texts.length
      end

      #: (Integer) -> String
      def text_at(i)
        texts[i]
      end

      #: (Integer) -> Integer
      def level_at(i)
        levels[i]
      end

      # Every text in order, one per line.
      #: () -> String
      def to_s
        texts.join("\n")
      end

      #: () -> void
      def clear
        texts.clear
        levels.clear
      end
    end
  end
end
