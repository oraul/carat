module Carat
  module Domain
    # The lines entered at one kind of command-line prompt, oldest first,
    # without duplicates and at most MAX of them, with where a recall
    # stands: <Up> and <Down> walk the entries that start with the text
    # typed before the first recall, and walking past the newest gives
    # that text back. A Struct record: mutable, with a reader and a writer
    # per member.
    class History < Struct.new(:entries, :at, :prefix, :recalling, :recalled, :moved, keyword_init: true)
      # @rbs @entries: Array[String]
      # @rbs @at: Integer
      # @rbs @prefix: String
      # @rbs @recalling: bool
      # @rbs @recalled: String
      # @rbs @moved: bool

      # Vim's default 'history'.
      MAX = 50

      #: () -> void
      def initialize
        super()
        self.entries = [""]
        entries.clear
        self.at = 0
        self.prefix = ""
        self.recalling = false
        self.recalled = ""
        self.moved = false
      end

      # Adds a line as the newest entry, dropping an equal older one and
      # the oldest past MAX; an empty line is not kept.
      #: (String) -> void
      def add(text)
        return if text.empty?
        list = entries
        i = 0
        while i < list.length
          if list[i] == text
            list.delete_at(i)
          else
            i += 1
          end
        end
        list << text
        list.shift while list.length > MAX
        nil
      end

      # Forgets where a recall stood, as a new prompt opens.
      #: () -> void
      def restart
        self.recalling = false
        self.at = entries.length
        self.prefix = ""
      end

      # Moves to the next older entry starting with the prefix; recalled
      # holds it, and moved says whether there was one.
      #: (String) -> void
      def older(typed)
        self.moved = false
        unless recalling
          self.recalling = true
          self.prefix = typed
          self.at = entries.length
        end
        i = at - 1
        while i >= 0
          entry = entries[i]
          if entry.start_with?(prefix)
            self.at = i
            self.recalled = entry
            self.moved = true
            return
          end
          i -= 1
        end
      end

      # Moves to the next newer entry starting with the prefix, or past
      # the newest to the typed text; recalled holds it, and moved is
      # false before any recall.
      #: () -> void
      def newer
        self.moved = false
        return unless recalling
        i = at + 1
        while i < entries.length
          entry = entries[i]
          if entry.start_with?(prefix)
            self.at = i
            self.recalled = entry
            self.moved = true
            return
          end
          i += 1
        end
        self.at = entries.length
        self.recalled = prefix
        self.moved = true
      end
    end
  end
end
