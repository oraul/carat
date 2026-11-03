require_relative "syntax_line"

module Carat
  module Domain
    # SyntaxLine values keyed by the identity of their text: the sibling of
    # IdentityTable for syntax entries, a separate class because Spinel
    # types an entry accessor once for the whole program. Open addressing
    # over String#object_id in an integer array; a key that matches is
    # confirmed with equal? on the entry's text, which the entry keeps
    # alive. The table doubles when it is half full. A Struct record.
    class SyntaxTable < Struct.new(:keys, :entries, :mask, :count, keyword_init: true)
      # @rbs @keys: Array[Integer]
      # @rbs @entries: Array[untyped]
      # @rbs @mask: Integer
      # @rbs @count: Integer

      #: (capacity: Integer) -> void
      def initialize(capacity:)
        super()
        self.keys = Array.new(capacity, 0)
        self.entries = Array.new(capacity, nil)
        self.mask = capacity - 1
        self.count = 0
      end

      #: (Integer) -> SyntaxLine
      def entry_at(i)
        entries[i]
      end

      # The entry for exactly this string object, or nil.
      #: (String) -> SyntaxLine?
      def find(text)
        id = text.object_id
        i = slot(id)
        while true
          key = keys[i]
          return nil if key == 0
          if key == id
            entry = entry_at(i)
            return entry.text.equal?(text) ? entry : nil
          end
          i = (i + 1) & mask
        end
        nil
      end

      # Stores the entry under its text, replacing one for the same text.
      #: (SyntaxLine) -> void
      def store(entry)
        grow if (count + 1) * 2 > mask + 1
        id = entry.text.object_id
        i = slot(id)
        while keys[i] != 0 && keys[i] != id
          i = (i + 1) & mask
        end
        self.count = count + 1 if keys[i] == 0
        keys[i] = id
        entries[i] = entry
      end

      #: () -> void
      def clear
        return if count == 0
        i = 0
        while i <= mask
          keys[i] = 0
          entries[i] = nil
          i += 1
        end
        self.count = 0
      end

      #: () -> Integer
      def size
        count
      end

      private

      #: (Integer) -> Integer
      def slot(id)
        ((id >> 4) ^ (id >> 13)) & mask
      end

      #: () -> void
      def grow
        old_keys = keys
        old_entries = entries
        capacity = (mask + 1) * 2
        self.keys = Array.new(capacity, 0)
        self.entries = Array.new(capacity, nil)
        self.mask = capacity - 1
        self.count = 0
        i = 0
        while i < old_keys.length
          store(old_entries[i]) if old_keys[i] != 0
          i += 1
        end
      end
    end
  end
end
