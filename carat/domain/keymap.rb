module Carat
  module Domain
    # One node of a keymap trie. Children are keyed by the decimal string of
    # the key code, a form the compiler can type.
    class KeymapNode
      attr_accessor :value #: String?

      # @rbs @children: Hash[String, KeymapNode]

      #: () -> void
      def initialize
        @children = {}
        @value = nil
      end

      #: (Integer) -> bool
      def child?(code)
        @children.key?(code.to_s)
      end

      #: (Integer) -> KeymapNode
      def child!(code)
        key = code.to_s
        existing = @children[key]
        return existing unless existing.nil?
        node = KeymapNode.new
        @children[key] = node
        node
      end

      #: () -> bool
      def leaf?
        @children.empty?
      end
    end

    # The result of looking up a key sequence: kind is :none (unbound and no
    # prefix), :prefix (more keys needed), :match (bound, nothing longer), or
    # :match_prefix (bound, and a longer binding exists). value is the bound
    # action name or remap sequence for :match and :match_prefix.
    class KeymapMatch
      attr_reader :kind #: Symbol
      attr_reader :value #: String?

      #: (Symbol, String?) -> void
      def initialize(kind, value)
        @kind = kind
        @value = value
      end
    end

    # One trie per mode from key sequences to action names or remap
    # sequences, built only from the JSON "keymaps" object.
    class Keymap
      attr_reader :errors #: Array[String]

      # @rbs @roots: Hash[String, KeymapNode]

      #: () -> void
      def initialize
        @roots = {}
        @errors = []
      end

      # Builds the keymap from the "keymaps" object of the configuration,
      # expanding <leader> with the given leader. Malformed entries are
      # recorded in errors as "mode.key: reason" and skipped.
      #: (untyped, String) -> Keymap
      def self.build(keymaps, leader)
        keymap = Keymap.new
        return keymap unless keymaps.is_a?(Hash)
        keymaps.each do |mode_name, bindings|
          mode = Mode.from_name(mode_name.to_s)
          if mode.nil?
            keymap.errors << "#{mode_name}: unknown mode"
            next
          end
          next unless bindings.is_a?(Hash)
          bindings.each do |key, value|
            keymap.add(mode, key.to_s, value, leader)
          end
        end
        keymap
      end

      # Adds one binding from its JSON form. A nil value unbinds.
      #: (Symbol, String, untyped, String) -> void
      def add(mode, key, value, leader)
        parsed = KeyNotation.parse(key, leader)
        unless parsed.ok?
          @errors << "#{Mode.name_of(mode)}.#{key}: #{parsed.error}"
          return
        end
        if parsed.codes.empty?
          @errors << "#{Mode.name_of(mode)}.#{key}: empty key"
          return
        end
        if value.nil?
          bind(mode, parsed.codes, nil)
        elsif value.is_a?(String) && !value.empty?
          bind(mode, parsed.codes, value)
        else
          @errors << "#{Mode.name_of(mode)}.#{key}: value must be an action name or a key sequence"
        end
      end

      #: (Symbol, Array[Integer], String?) -> void
      def bind(mode, codes, value)
        node = root(mode)
        i = 0
        while i < codes.length
          node = node.child!(codes[i])
          i += 1
        end
        node.value = value
      end

      #: (Symbol, Array[Integer]) -> KeymapMatch
      def lookup(mode, codes)
        node = root(mode)
        i = 0
        while i < codes.length
          return KeymapMatch.new(:none, nil) unless node.child?(codes[i])
          node = node.child!(codes[i])
          i += 1
        end
        value = node.value
        if value.nil?
          return KeymapMatch.new(:none, nil) if node.leaf?
          KeymapMatch.new(:prefix, nil)
        elsif node.leaf?
          KeymapMatch.new(:match, value)
        else
          KeymapMatch.new(:match_prefix, value)
        end
      end

      private

      #: (Symbol) -> KeymapNode
      def root(mode)
        name = Mode.name_of(mode)
        existing = @roots[name]
        return existing unless existing.nil?
        node = KeymapNode.new
        @roots[name] = node
        node
      end
    end
  end
end
