require_relative "plugin_entry"

module Carat
  module UseCases
    # The registered plugins in registration order, with an index from
    # name to position so finding one does not walk the list. A second
    # entry with a name already present is kept, disabled, but not
    # indexed: find answers the first.
    class PluginEntries
      # @rbs @entries: Array[untyped]
      # @rbs @index: Hash[String, Integer]

      #: () -> void
      def initialize
        @entries = []
        @index = {}
      end

      #: (PluginEntry) -> void
      def add(entry)
        @index[entry.name] = @entries.length unless @index.key?(entry.name)
        @entries << entry
        nil
      end

      #: (Integer) -> PluginEntry
      def entry(i)
        @entries[i]
      end

      #: () -> Integer
      def count
        @entries.length
      end

      #: (String) -> PluginEntry?
      def find(name)
        at = @index[name]
        return nil if at.nil?
        entry(at)
      end

      #: (String) -> bool
      def include?(name)
        @index.key?(name)
      end
    end
  end
end
