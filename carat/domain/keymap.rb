require_relative "keymap_node"
require_relative "keymap_match"
require_relative "config"
require_relative "rc_parser"
require_relative "rc_line"

module Carat
  module Domain
    # One trie per mode from key sequences to action names or remap
    # sequences, built only from keymap lines: a plugin's defaults, then
    # the configuration's. Every binding
    # records its owner: the plugin whose defaults added it, or "" for the
    # configuration, so a plugin's bindings can be removed with it and a
    # second plugin cannot take another's keys. A Struct record: the roots
    # fill as bindings are added, errors collect as they are found, and
    # conflicts between plugins collect as "mode.keys is already bound by
    # plugin name". The names keymap.group lines give normal-mode prefixes
    # are kept apart from the tries, keyed by the prefix's codes, so a
    # group line never changes what a key looks up.
    class Keymap < Struct.new(:roots, :errors, :conflicts, :groups, keyword_init: true)
      # @rbs @roots: Hash[String, KeymapNode]
      # @rbs @errors: Array[String]
      # @rbs @conflicts: Array[String]
      # @rbs @groups: Hash[String, String]

      # The empty literals are stored through the writers, not passed to
      # super: an empty array literal is typed Array[Integer] by default, and
      # only an assignment coerces it to the pinned member type.
      #: () -> void
      def initialize
        super()
        self.roots = {}
        self.errors = []
        self.conflicts = []
        self.groups = {}
      end

      # Whether a keymap value names an action: one or more namespace
      # segments and the action, in lowercase letters, digits, and
      # underscores joined by dots, as plugin.hello.greet; anything else is
      # a key sequence to replay. The check reads bytes, so a value that
      # is not UTF-8 is not an action name instead of raising, as a pattern
      # would.
      #: (String) -> bool
      def self.action_name?(value)
        RcParser.key?(value, 0, value.bytesize)
      end

      # Vim's mapleader when the configuration names none.
      DEFAULT_LEADER = "\\"

      # The action that removes a binding.
      NONE = "none"

      # The keymap line that names a normal-mode prefix for the key hints.
      GROUP = "group"

      # The keymap lines, keymap.pick <keys> <action>, that bind in normal
      # mode of a pick list's buffer, as the definition pick list's, and in
      # no editor mode.
      PICK = "pick"

      # The most keys one binding may hold: the trie is one node deep per
      # key, and removing a plugin's bindings walks it recursively, so a
      # hostile binding of a million keys would overflow the stack.
      MAX_KEYS = 64

      # The leader of a configuration: the value of its last keymap.leader
      # line that is one key in notation, Vim's backslash when there is
      # none. add_checked notes the lines that are not.
      #: (Config) -> String
      def self.leader_from(config)
        leader = DEFAULT_LEADER
        i = 0
        n = config.count
        while i < n
          line = config.line_at(i)
          leader = line.words[0].to_s if line.scope == "keymap" && line.name == "leader" && leader_problem(line.words).empty?
          i += 1
        end
        leader
      end

      # Why the words cannot be the leader, or "".
      #: (Array[String]) -> String
      def self.leader_problem(words)
        return "keymap.leader takes one key" unless words.length == 1
        parsed = KeyNotation.parse(words[0].to_s, "")
        return parsed.error.to_s unless parsed.ok?
        return "keymap.leader takes one key" if parsed.codes.empty?
        ""
      end

      # The keymap of a pick list's buffer: the configuration's
      # keymap.pick lines bound in normal mode, in order, so a later line
      # wins and "none" removes a binding, with <leader> from the
      # configuration. A line that does not bind is skipped here;
      # add_checked notes it.
      #: (Config) -> Keymap
      def self.pick_from(config)
        keymap = Keymap.new
        leader = leader_from(config)
        i = 0
        n = config.count
        while i < n
          line = config.line_at(i)
          words = line.words
          keymap.bind_text(Mode::NORMAL, words[0].to_s, words[1].to_s, leader, "") if line.scope == "keymap" && line.name == PICK && words.length == 2
          i += 1
        end
        keymap
      end

      # Builds a keymap from keymap lines, as a plugin gives them for its
      # scratch buffer, expanding <leader> with the given leader. Lines
      # that do not bind are recorded in errors as "line: reason".
      #: (untyped, String) -> Keymap
      def self.from_lines(lines, leader)
        keymap = Keymap.new
        keymap.add_lines(lines, leader, "")
        keymap
      end

      # Adds keymap lines, "keymap.<mode> <keys> <action>", with their
      # owner, over the bindings already present, which is how a plugin's
      # defaults go in before the configuration. A line that does not bind
      # is recorded in errors as "line: reason"; a plugin's binding of
      # keys another plugin holds is not added and is recorded in
      # conflicts. Anything but a list of strings adds nothing.
      #: (untyped, String, String) -> void
      def add_lines(lines, leader, owner)
        return unless lines.is_a?(Array)
        none = Keymap.no_actions
        lines.each do |item|
          text = item.to_s
          parsed = RcParser.parse(text)
          if !parsed.ok?
            errors << "#{text}: #{parsed.error}"
          elsif !parsed.blank?
            line = RcLine.from_parse("", 0, 0, parsed)
            problem = line.scope == "keymap" ? apply(line, leader, owner, none, false) : "not a keymap line"
            errors << "#{text}: #{problem}" unless problem.empty?
          end
        end
      end

      # Adds the configuration's keymap lines in order, so a later line
      # wins and "none" removes a binding, with <leader> from the
      # configuration. A line naming an unknown mode, without exactly keys
      # and an action, with keys that do not parse, or binding an action
      # name known does not hold is noted on the configuration as
      # "file:line: message" and skipped; the other lines still go in.
      #: (Config, Hash[String, bool]) -> void
      def add_checked(config, known)
        leader = Keymap.leader_from(config)
        i = 0
        n = config.count
        while i < n
          line = config.line_at(i)
          if line.scope == "keymap"
            problem = apply(line, leader, "", known, true)
            config.note(line, problem) unless problem.empty?
          end
          i += 1
        end
      end

      # Applies one keymap line for the owner and returns its problem, ""
      # when it bound or was a good leader line. Only the configuration
      # (owner "") may set the leader; with check, an action name known
      # does not hold is refused.
      #: (RcLine, String, String, Hash[String, bool], bool) -> String
      def apply(line, leader, owner, known, check)
        name = line.name
        words = line.words
        if name == "leader"
          return "a plugin cannot set keymap.leader" unless owner.empty?
          return Keymap.leader_problem(words)
        end
        return name_group(line, leader) if name == GROUP
        pick = name == PICK
        mode = pick ? Mode::NORMAL : Mode.from_name(name)
        return "unknown mode #{name}" if mode.nil?
        return "#{line.key} takes keys and an action" unless words.length == 2
        value = words[1].to_s
        return "unknown action #{value}" if check && Keymap.action_name?(value) && !known.key?(value)
        # A pick line is checked on a keymap of its own and bound only by
        # pick_from, never in an editor mode.
        return Keymap.new.bind_text(mode, words[0].to_s, value, leader, owner) if pick
        bind_text(mode, words[0].to_s, value, leader, owner)
      end

      # Binds keys in notation to an action name or a key sequence, or
      # unbinds them for "none", for the owner, and returns the problem, ""
      # when there is none, keys longer than MAX_KEYS included. A plugin's
      # binding of keys another plugin holds is recorded in conflicts
      # instead.
      #: (Symbol, String, String, String, String) -> String
      def bind_text(mode, keys, value, leader, owner)
        parsed = KeyNotation.parse(keys, leader)
        return parsed.error.to_s unless parsed.ok?
        return "empty key" if parsed.codes.empty?
        return "more than #{MAX_KEYS} keys" if parsed.codes.length > MAX_KEYS
        return "empty action" if value.empty?
        holder = holder_of(mode, parsed.codes)
        if !owner.empty? && !holder.empty? && holder != owner
          conflicts << "#{Mode.name_of(mode)}.#{keys} is already bound by plugin #{holder}"
          return ""
        end
        bind_owned(mode, parsed.codes, value == NONE ? nil : value, owner)
        ""
      end

      # An empty action table typed as the known actions are.
      #: () -> Hash[String, bool]
      def self.no_actions
        table = { "" => true }
        table.clear
        table
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
          node = node.child_for(codes[i])
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
          node = node.child_for(codes[i])
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

      # The node the keys lead to in the mode's trie, an empty node when
      # they lead nowhere, so the answer is never nil.
      #: (Symbol, Array[Integer]) -> KeymapNode
      def node_at(mode, codes)
        node = root(mode)
        i = 0
        while i < codes.length
          return KeymapNode.new unless node.child?(codes[i])
          node = node.child_for(codes[i])
          i += 1
        end
        node
      end

      # The name a keymap.group line gave the prefix the keys spell, "" for
      # none or a mode other than normal.
      #: (Symbol, Array[Integer]) -> String
      def group_of(mode, codes)
        return "" unless mode == Mode::NORMAL
        name = groups[group_key(codes)]
        name.nil? ? "" : name
      end

      #: (Symbol, Array[Integer]) -> KeymapMatch
      def lookup(mode, codes)
        node = root(mode)
        i = 0
        while i < codes.length
          return KeymapMatch.new(kind: :none, value: nil) unless node.child?(codes[i])
          node = node.child_for(codes[i])
          i += 1
        end
        value = node.value
        if value.nil?
          return KeymapMatch.new(kind: :none, value: nil) if node.leaf?
          KeymapMatch.new(kind: :prefix, value: nil)
        elsif node.leaf?
          KeymapMatch.new(kind: :match, value: value)
        else
          KeymapMatch.new(kind: :match_prefix, value: value)
        end
      end

      private

      # Names the normal-mode prefix of a keymap.group line, leaving the
      # tries as they are, and returns the problem, "" when there is none.
      #: (RcLine, String) -> String
      def name_group(line, leader)
        words = line.words
        return "#{line.key} takes keys and a name" unless words.length == 2
        parsed = KeyNotation.parse(words[0].to_s, leader)
        return parsed.error.to_s unless parsed.ok?
        return "empty key" if parsed.codes.empty?
        return "more than #{MAX_KEYS} keys" if parsed.codes.length > MAX_KEYS
        groups[group_key(parsed.codes)] = words[1].to_s
        ""
      end

      # The key of a prefix in groups: its codes in decimal, joined by
      # spaces.
      #: (Array[Integer]) -> String
      def group_key(codes)
        text = +""
        i = 0
        while i < codes.length
          text << " " if i > 0
          text << codes[i].to_s
          i += 1
        end
        text
      end

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
