require_relative "decoded_line"

module Carat
  module Domain
    # Decoded lines keyed by the identity of their text: open addressing
    # over String#object_id in an integer array, which costs a few
    # nanoseconds per lookup where a Hash keyed by String hashes and
    # compares the text and copies it on insert. A key that matches is
    # confirmed with equal? on the entry's text, which the entry keeps
    # alive, so a reused address can never match a dropped entry. The
    # table doubles when it is half full. A Struct record.
    class IdentityTable < Struct.new(:keys, :entries, :mask, :count)
      # @rbs @keys: Array[Integer]
      # @rbs @entries: Array[untyped]
      # @rbs @mask: Integer
      # @rbs @count: Integer

      #: (Integer) -> void
      def initialize(capacity)
        super()
        self.keys = Array.new(capacity, 0)
        self.entries = Array.new(capacity, nil)
        self.mask = capacity - 1
        self.count = 0
      end

      #: (Integer) -> DecodedLine
      def entry_at(i)
        entries[i]
      end

      # The entry for exactly this string object, or nil.
      #: (String) -> DecodedLine?
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

      #: (DecodedLine) -> void
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
