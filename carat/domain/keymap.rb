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
      def child!(code)
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

    # The result of looking up a key sequence: kind is :none (unbound and no
    # prefix), :prefix (more keys needed), :match (bound, nothing longer), or
    # :match_prefix (bound, and a longer binding exists). value is the bound
    # action name or remap sequence for :match and :match_prefix.
    # A Data value: equal by value and frozen.
    class KeymapMatch < Data.define(:kind, :value)
    end

    # One trie per mode from key sequences to action names or remap
    # sequences, built only from the JSON "keymaps" object. Every binding
    # records its owner: the plugin whose defaults added it, or "" for the
    # configuration, so a plugin's bindings can be removed with it and a
    # second plugin cannot take another's keys. A Struct record: the roots
    # fill as bindings are added, errors collect as they are found, and
    # conflicts between plugins collect as "mode.keys is already bound by
    # plugin name".
    class Keymap < Struct.new(:roots, :errors, :conflicts)
      ACTION_NAME = /\A[a-z0-9_]+(\.[a-z0-9_]+)+\z/

      # @rbs @roots: Hash[String, KeymapNode]
      # @rbs @errors: Array[String]
      # @rbs @conflicts: Array[String]

      # The empty literals are stored through the writers, not passed to
      # super: an empty array literal is typed Array[Integer] by default, and
      # only an assignment coerces it to the pinned member type.
      #: () -> void
      def initialize
        super()
        self.roots = {}
        self.errors = []
        self.conflicts = []
      end

      # Whether a keymap value names an action: one or more namespace
      # segments and the action, in lowercase letters, digits, and
      # underscores joined by dots, as plugin.hello.greet; anything else is
      # a key sequence to replay.
      #: (String) -> bool
      def self.action_name?(value)
        value.match?(ACTION_NAME)
      end

      # Builds a keymap from a "keymaps" object, expanding <leader> with
      # the given leader. Malformed entries are recorded in errors as
      # "mode.key: reason" and skipped.
      #: (untyped, String) -> Keymap
      def self.build(keymaps, leader)
        keymap = Keymap.new
        keymap.add_all(keymaps, leader)
        keymap
      end

      # Adds every binding of a "keymaps" object, in the same JSON shape as
      # the configuration, over the bindings already present: a later
      # binding of the same keys replaces an earlier one and null removes
      # it, which is how a plugin's defaults go in first and the
      # configuration last.
      #: (untyped, String) -> void
      def add_all(keymaps, leader)
        add_owned(keymaps, leader, "")
      end

      # Adds the bindings with their owner. A plugin's binding of keys
      # another plugin holds is not added and is recorded in conflicts; the
      # configuration (owner "") replaces any binding.
      #: (untyped, String, String) -> void
      def add_owned(keymaps, leader, owner)
        return unless keymaps.is_a?(Hash)
        keymaps.each do |mode_name, bindings|
          mode = Mode.from_name(mode_name.to_s)
          if mode.nil?
            errors << "#{mode_name}: unknown mode"
            next
          end
          next unless bindings.is_a?(Hash)
          bindings.each do |key, value|
            add_binding(mode, key.to_s, value, leader, owner)
          end
        end
      end

      # Adds one binding from its JSON form. A nil value unbinds.
      #: (Symbol, String, untyped, String) -> void
      def add(mode, key, value, leader)
        add_binding(mode, key, value, leader, "")
      end

      # Adds one binding from its JSON form for the owner.
      #: (Symbol, String, untyped, String, String) -> void
      def add_binding(mode, key, value, leader, owner)
        parsed = KeyNotation.parse(key, leader)
        unless parsed.ok?
          errors << "#{Mode.name_of(mode)}.#{key}: #{parsed.error}"
          return
        end
        if parsed.codes.empty?
          errors << "#{Mode.name_of(mode)}.#{key}: empty key"
          return
        end
        holder = holder_of(mode, parsed.codes)
        if !owner.empty? && !holder.empty? && holder != owner
          conflicts << "#{Mode.name_of(mode)}.#{key} is already bound by plugin #{holder}"
          return
        end
        if value.nil?
          bind_owned(mode, parsed.codes, nil, owner)
        elsif value.is_a?(String) && !value.empty?
          bind_owned(mode, parsed.codes, value, owner)
        else
          errors << "#{Mode.name_of(mode)}.#{key}: value must be an action name or a key sequence"
        end
      end

      #: (Symbol, Array[Integer], String?) -> void
      def bind(mode, codes, value)
        bind_owned(mode, codes, value, "")
      end

      #: (Symbol, Array[Integer], String?, String) -> void
      def bind_owned(mode, codes, value, owner)
        node = root(mode)
        i = 0
        while i < codes.length
          node = node.child!(codes[i])
          i += 1
        end
        node.value = value
        node.owner = value.nil? ? "" : owner
      end

      # The plugin that owns the binding of the keys, "" when the keys are
      # unbound or the configuration bound them.
      #: (Symbol, Array[Integer]) -> String
      def holder_of(mode, codes)
        node = root(mode)
        i = 0
        while i < codes.length
          return "" unless node.child?(codes[i])
          node = node.child!(codes[i])
          i += 1
        end
        node.value.nil? ? "" : node.owner
      end

      # Removes every binding the owner added, in every mode, and the
      # nodes left with neither a value nor children.
      #: (String) -> void
      def remove_owner(owner)
        return if owner.empty?
        tops = roots.values
        i = 0
        while i < tops.length
          clear_owner(tops[i], owner)
          i += 1
        end
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

      #: (KeymapNode, String) -> void
      def clear_owner(node, owner)
        if node.owner == owner
          node.value = nil
          node.owner = ""
        end
        keys = node.children.keys
        i = 0
        while i < keys.length
          child = node.child_named(keys[i])
          clear_owner(child, owner)
          node.children.delete(keys[i]) if child.value.nil? && child.leaf?
          i += 1
        end
      end

      #: (Symbol) -> KeymapNode
      def root(mode)
        name = Mode.name_of(mode)
        existing = roots[name]
        return existing unless existing.nil?
        node = KeymapNode.new
        roots[name] = node
        node
      end
    end
  end
end
