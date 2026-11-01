module Carat
  module Domain
    # One node of a keymap trie. Children are keyed by the decimal string of
    # the key code, a form the compiler can type. owner is the plugin whose
    # default bindings put the value there, "" for the configuration. A
    # Struct record: mutable, with a reader and a writer per member.
    class KeymapNode < Struct.new(:value, :children, :owner)
      # @rbs @value: String?
      # @rbs @children: Hash[String, KeymapNode]
      # @rbs @owner: String

      #: () -> void
      def initialize
        super(nil, {}, "")
      end

      #: (Integer) -> bool
      def child?(code)
        children.key?(code.to_s)
      end

      #: (Integer) -> KeymapNode
      def child_for(code)
        key = code.to_s
        existing = children[key]
        return existing unless existing.nil?
        node = KeymapNode.new
        children[key] = node
        node
      end

      # The child under the decimal key, or a new empty node when there
      # is none, so the answer is never nil.
      #: (String) -> KeymapNode
      def child_named(key)
        existing = children[key]
        return existing unless existing.nil?
        KeymapNode.new
      end

      #: () -> bool
      def leaf?
        children.empty?
      end
    end
  end
end
