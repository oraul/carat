require_relative "message_history"

module Carat
  module Domain
    # The notifications shown at the top right, oldest first, at most
    # LIMIT: each a one-line text, its level (MessageHistory::INFO,
    # WARNING, or ERROR), the clock time it leaves at, LIFETIMES seconds
    # by level after it came, and a serial that tells a new notice from an
    # old one at the same place. Each is also kept in the message history.
    # A Struct record: mutable, with a reader and a writer per member.
    class Notices < Struct.new(:history, :texts, :levels, :deadlines, :serials, :serial, keyword_init: true)
      LIMIT = 3
      LIFETIMES = [3.0, 5.0, 8.0]

      # @rbs @history: MessageHistory
      # @rbs @texts: Array[String]
      # @rbs @levels: Array[Integer]
      # @rbs @deadlines: Array[Float]
      # @rbs @serials: Array[Integer]
      # @rbs @serial: Integer

      #: (history: MessageHistory) -> void
      def initialize(history:)
        super()
        self.history = history
        self.texts = []
        self.levels = []
        self.deadlines = []
        self.serials = []
        self.serial = 0
      end

      # Shows a text at a level from the clock time now, replacing the
      # oldest when LIMIT show, and keeps it in the history.
      #: (String, Integer, Float) -> void
      def add(text, level, now)
        level = MessageHistory::INFO if level < MessageHistory::INFO || level > MessageHistory::ERROR
        history.add(text, level)
        drop(0) if texts.length >= LIMIT
        self.serial = serial + 1
        texts << text
        levels << level
        deadlines << now + LIFETIMES[level]
        serials << serial
      end

      # Drops each notice whose time has come; answers whether any went.
      #: (Float) -> bool
      def expire(now)
        gone = false
        i = 0
        while i < texts.length
          if deadlines[i] <= now
            drop(i)
            gone = true
          else
            i += 1
          end
        end
        gone
      end

      # The seconds from now until the next notice leaves, 0.0 when one is
      # due, and LIFETIMES' longest when none shows.
      #: (Float) -> Float
      def wait(now)
        soonest = now + LIFETIMES[MessageHistory::ERROR]
        i = 0
        while i < deadlines.length
          soonest = deadlines[i] if deadlines[i] < soonest
          i += 1
        end
        soonest > now ? soonest - now : 0.0
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

      #: (Integer) -> Integer
      def serial_at(i)
        serials[i]
      end

      private

      #: (Integer) -> void
      def drop(i)
        texts.delete_at(i)
        levels.delete_at(i)
        deadlines.delete_at(i)
        serials.delete_at(i)
      end
    end
  end
end
