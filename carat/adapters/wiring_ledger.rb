module Carat
  module Adapters
    # What EditorAssembly handed each holder: one entry per holder and
    # slot, the slot a constructor keyword, the object the one it passed.
    # The shared-instance test reads it in place of a public reader on the
    # holder, comparing each object with the shared one by identity. The
    # objects are of many classes, so only equal? is ever called on them.
    # Written while the assembly is built, never on a key.
    class WiringLedger
      # @rbs @holders: Array[String]
      # @rbs @slots: Array[String]
      # @rbs @objects: Array[untyped]
      # @rbs @index: Hash[String, Integer]

      #: () -> void
      def initialize
        @holders = []
        @slots = []
        @objects = []
        @index = {}
      end

      # Records the object handed to the holder's slot; a second record of
      # the same pair replaces the object and keeps the pair's place.
      #: (String, String, untyped) -> void
      def record(holder, slot, object)
        key = "#{holder}.#{slot}"
        at = @index[key]
        if at.nil?
          @index[key] = @holders.length
          @holders << holder
          @slots << slot
          @objects << object
        else
          @objects[at] = object
        end
        nil
      end

      # The object recorded for the holder's slot, nil for a pair never
      # recorded, which the test's identity check then reports.
      #: (String, String) -> untyped
      def held(holder, slot)
        at = @index["#{holder}.#{slot}"]
        return nil if at.nil?
        @objects[at]
      end

      # The holder's slot names in the order they were recorded.
      #: (String) -> Array[String]
      def slots(holder)
        out = []
        i = 0
        while i < @holders.length
          out << @slots[i] if @holders[i] == holder
          i += 1
        end
        out
      end
    end
  end
end
