require_relative "rc_parse"
require_relative "rc_line"
require_relative "rc_parser"
require_relative "root_word"
require_relative "key"
require_relative "key_notation"

module Carat
  module Domain
    # The configuration: the setting lines of every file read, in load
    # order (the shipped defaults, the user's file, the project's), so a
    # reader that applies them in turn lets a later line win, and the
    # problems found in them, each kept with the order of its line so they
    # are reported in file order whichever reader found them. Reading a
    # file checks each line's form and scope and the language settings,
    # which no other reader checks yet; the options, keymap, and plugin
    # host check their own lines and note problems here. A Struct record.
    class Config < Struct.new(:settings, :problems, :orders, :files, :shipped, keyword_init: true)
      # The scopes a key may start with.
      SCOPES = ["option", "keymap", "plugin", "language"]

      # The settings of a language: the commands the language services
      # run, each a list of words; lsp.root is a root and the server
      # command for a working directory under it.
      LANGUAGE_SETTINGS = ["lsp", "lsp.root"]

      # The language setting whose first word is a root, so it holds at
      # least a root and a command word.
      ROOTED_SETTING = "lsp.root"

      # The settings of a language the roadmap plans but no service reads
      # yet (formatting, roadmap item 14): a line setting one is answered
      # and not kept.
      PLANNED_SETTINGS = ["formatter"]

      # The key of the directories whose language servers start on their
      # own: a language line, so only the defaults and the user file set it.
      TRUSTED_ROOTS = "language.trusted_roots"

      # The actions a project file may bind, in any mode: an entry ending
      # in a dot names a family, any other entry one action. Every other
      # action is refused, as a key the user types would run it: the
      # writes and quits (file.save, quit.*, window.quit), the command
      # line's own actions (cmdline.*), which run or recall an ex command,
      # every plugin action (plugin.explorer.delete deletes a file), and
      # any family added later until it is named here.
      PROJECT_BINDABLE = [
        "buffer.", "completion.", "cursor.", "definition.", "docs.", "float.",
        "fold.", "history.", "insert.", "jump.", "layout.", "message.", "mode.",
        "motion.", "operator.", "palette.", "register.", "scroll.", "search.",
        "substitute.", "tab.", "tabline.", "textobject.", "visual.",
        "window.close", "window.down", "window.equalize", "window.last_accessed",
        "window.left", "window.next", "window.only", "window.previous",
        "window.right", "window.split", "window.up", "window.vsplit"
      ]

      # The action that opens the command line: a project file may bind it,
      # but may not take it from the key the defaults or the user gave it.
      OPEN_COMMAND_LINE = "mode.cmdline"

      # The actions that open a prompt whose Enter runs what was typed, an
      # ex command or any action: a project file binds them only in
      # PROMPT_MODES, so a key typed while inserting text, such as <CR>,
      # does not turn the next line typed into a command.
      PROMPT_ACTIONS = ["mode.cmdline", "palette.open"]

      # The modes in which a project file may bind PROMPT_ACTIONS.
      PROMPT_MODES = ["normal", "visual", "visual_line", "visual_block"]

      # The modes in which keys enter text, the grammar reading none of
      # them: insert, replace, the command line, and the completion layer
      # over insert mode.
      TEXT_MODES = ["insert", "replace", "cmdline", "completion"]

      # The actions a project file may bind in TEXT_MODES, entries read as
      # PROJECT_BINDABLE's: the ones that keep the mode. Any other, a mode
      # action such as mode.normal or a search that opens its prompt, would
      # leave it, so a key typed while entering text, such as <CR>, would
      # turn the letters typed after it into normal-mode keys.
      TEXT_BINDABLE = ["completion.", "cursor.", "insert.", "palette.next", "palette.previous", "scroll."]

      # The keymap value that removes a binding.
      NONE = "none"

      # The keymap line that sets the leader, and Vim's mapleader when the
      # configuration names none.
      LEADER = "leader"
      DEFAULT_LEADER = "\\"

      # The keymap line that names a normal-mode prefix for the key hints
      # and binds nothing.
      GROUP = "group"

      # The settings stay Array[untyped]: Spinel pins an array only of a
      # builtin element type (docs/spinel-notes.md), so the lines are read
      # through line_at, typed RcLine, and counted by count, never through
      # the member from another file.
      # @rbs @settings: Array[untyped]
      # @rbs @problems: Array[String]
      # @rbs @orders: Array[Integer]
      # @rbs @files: Integer
      # @rbs @shipped: Integer

      # The empty literals are stored through the writers, not passed to
      # super, so they take the pinned member types.
      #: () -> void
      def initialize
        super()
        self.settings = []
        self.problems = []
        self.orders = []
        self.files = 0
        self.shipped = 0
      end

      # Reads the shipped defaults, trusted, and remembers that the files
      # read so far are the defaults: they name every compiled plugin, so a
      # build or a test with fewer plugins does not report the others.
      #: (String, String) -> void
      def read_defaults(source, text)
        read(source, text, true)
        self.shipped = files
      end

      # Whether the line comes from the shipped defaults.
      #: (RcLine) -> bool
      def shipped?(line)
        line.file < shipped
      end

      # Reads a file's text under its label. A line that does not read,
      # names an unknown scope, or is a setting it may not make is noted
      # and skipped. An untrusted file, the project's, may not set language
      # commands, which name programs to run, nor bind keys to a key
      # sequence to replay, which can run any ex command, nor take a key
      # from a binding it could not make itself (held_keys).
      #: (String, String, bool) -> void
      def read(source, text, trusted)
        file = files
        self.files = file + 1
        held = trusted ? Config.no_keys : held_keys
        at = trusted ? "" : leader
        n = text.bytesize
        start = 0
        number = 1
        while start < n
          stop = start
          stop += 1 while stop < n && text.getbyte(stop).to_i != RcParser::NEWLINE
          add(source, file, number, RcParser.parse_range(text, start, stop), trusted, held, at)
          start = stop + 1
          number += 1
        end
      end

      # Notes a file that exists but was not read, with the reason, as a
      # file of its own in load order: "source: reason".
      #: (String, String) -> void
      def refuse(source, reason)
        file = files
        self.files = file + 1
        note_at(RcLine.order_at(file, 0), "#{source}: #{reason}")
      end

      # The number of setting lines kept.
      #: () -> Integer
      def count
        settings.length
      end

      #: (Integer) -> RcLine
      def line_at(i)
        settings[i]
      end

      # The last line with the key, or nil.
      #: (String) -> RcLine?
      def last(key)
        i = settings.length - 1
        while i >= 0
          line = line_at(i)
          return line if line.key == key
          i -= 1
        end
        nil
      end

      # Records a problem with the line, reported as "file:line: message".
      #: (RcLine, String) -> void
      def note(line, message)
        note_at(line.order, line.problem(message))
      end

      # The leader: the value of the last keymap.leader line that is one
      # key in notation, Vim's backslash when there is none. The keymap
      # notes the lines that are not.
      #: () -> String
      def leader
        found = DEFAULT_LEADER
        i = 0
        while i < settings.length
          line = line_at(i)
          found = line.words[0].to_s if line.scope == "keymap" && line.name == LEADER && Config.leader_problem(line.words).empty?
          i += 1
        end
        found
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

      # An empty table typed as the keys an untrusted file may not take.
      #: () -> Hash[String, String]
      def self.no_keys
        table = { "" => "" }
        table.clear
        table
      end

      # Whether a project file may bind the action (PROJECT_BINDABLE).
      #: (String) -> bool
      def self.project_bindable?(action)
        Config.listed?(PROJECT_BINDABLE, action)
      end

      # Whether a project file may bind the action in the mode: an action
      # of PROJECT_BINDABLE; in TEXT_MODES one of TEXT_BINDABLE, elsewhere
      # one of PROMPT_ACTIONS only in PROMPT_MODES.
      #: (String, String) -> bool
      def self.project_bindable_in?(mode, action)
        return false unless Config.project_bindable?(action)
        return Config.listed?(TEXT_BINDABLE, action) if TEXT_MODES.include?(mode)
        !PROMPT_ACTIONS.include?(action) || PROMPT_MODES.include?(mode)
      end

      # Whether the list names the action: an entry ending in a dot names a
      # family, any other entry one action.
      #: (Array[String], String) -> bool
      def self.listed?(entries, action)
        i = 0
        while i < entries.length
          entry = entries[i]
          return true if entry.end_with?(".") ? action.start_with?(entry) : action == entry
          i += 1
        end
        false
      end

      # Every problem in file and line order, two of one line in the order
      # noted. Each reader notes in load order, so the orders are a few
      # ascending runs: a stable merge of the runs, pair by pair, sorts
      # them in time linear for that handful and n log n at worst, where
      # an insertion sort was quadratic on a hostile file of many lines.
      #: () -> Array[String]
      def report
        index = []
        starts = []
        i = 0
        while i < orders.length
          starts << i if i == 0 || orders[i] < orders[i - 1]
          index << i
          i += 1
        end
        starts << orders.length
        while starts.length > 2
          merged = []
          next_starts = []
          r = 0
          while r + 1 < starts.length
            mid = starts[r + 1]
            to = r + 2 < starts.length ? starts[r + 2] : mid
            next_starts << starts[r]
            merged = merge_runs(index, starts[r], mid, to, merged)
            r += 2
          end
          next_starts << orders.length
          index = merged
          starts = next_starts
        end
        out = []
        i = 0
        while i < index.length
          out << problems[index[i]]
          i += 1
        end
        out
      end

      private

      # Keeps the parsed line, or notes why not. held and leader are an
      # untrusted file's held_keys and the leader, empty for a trusted one.
      #: (String, Integer, Integer, RcParse, bool, Hash[String, String], String) -> void
      def add(source, file, number, parsed, trusted, held, leader)
        return if parsed.blank?
        unless parsed.ok?
          note_at(RcLine.order_at(file, number), RcLine.problem_at(source, number, parsed.error))
          return
        end
        line = RcLine.from_parse(source, file, number, parsed)
        # The scope goes through a local: on the pinned compiler,
        # SCOPES.include?(line.scope) answered false for a scope it holds.
        scope = line.scope
        unless SCOPES.include?(scope)
          note(line, "unknown setting #{line.key}")
          return
        end
        problem = ""
        problem = language_problem(line, trusted) if scope == "language"
        problem = binding_problem(line, held, leader) if scope == "keymap" && !trusted
        if problem.empty?
          settings << line
        else
          note(line, problem)
        end
      end

      # Why a language line may not be kept, or "": it is kept from a
      # trusted file, as language.<name>.<setting> with a known setting or
      # as language.trusted_roots, a root's command with a root (RootWord)
      # and a command word; a planned setting is not supported yet.
      #: (RcLine, bool) -> String
      def language_problem(line, trusted)
        return "language commands are not read from a project file" unless trusted
        name = line.name
        return "" if line.key == TRUSTED_ROOTS
        dot = name.index(".")
        return "unknown setting #{line.key}" if dot.nil?
        setting = name[dot + 1, name.length - dot - 1].to_s
        return "language setting #{setting} is not supported yet" if PLANNED_SETTINGS.include?(setting)
        return "unknown language setting #{setting}" unless LANGUAGE_SETTINGS.include?(setting)
        return "" unless setting == ROOTED_SETTING
        return "#{line.key} needs a root and a command" if line.words.length < 2
        root = line.words[0].to_s
        return "#{line.key} #{root} is not a root" unless RootWord.root?(root)
        ""
      end

      # Why an untrusted file's keymap line may not be kept, or "": one
      # whose value is an action name or none, or a group name, which binds
      # nothing, is kept. A key sequence to replay is refused, because a
      # replay types anything, :w with any path included, so a project file
      # could write any file the user can. So is an action outside
      # PROJECT_BINDABLE, in any mode, one outside TEXT_BINDABLE in
      # TEXT_MODES, and one of PROMPT_ACTIONS outside PROMPT_MODES or on
      # keys typed as text; a binding, none included, of keys held (held_keys),
      # which would take the command line, a write, or a quit from the
      # user; a binding but none of keys that start with held keys or begin
      # them, which would make the held keys a prefix or wait on them; and
      # a leader, which would move the defaults' and the user's <leader>
      # write and quit bindings onto keys such as d.
      #: (RcLine, Hash[String, String], String) -> String
      def binding_problem(line, held, leader)
        return "keymap.leader is not read from a project file" if line.name == LEADER
        words = line.words
        return "" if line.name == GROUP || words.length != 2
        keys = words[0].to_s
        value = words[1].to_s
        unless value == NONE
          return "key sequences are not read from a project file" unless RcParser.key?(value, 0, value.bytesize)
          return "#{value} is not bound from a project file" unless Config.project_bindable?(value)
          return "#{value} is not bound in #{line.name} mode from a project file" unless Config.project_bindable_in?(line.name, value)
          return "#{keys} is typed as text, so a project file may not bind it to #{value}" if PROMPT_ACTIONS.include?(value) && typed_as_text?(keys, leader)
        end
        key = held_key(line.name, keys, leader)
        action = held[key]
        return "#{keys} runs #{action}, which a project file may not unbind or rebind" unless action.nil?
        return "" if value == NONE
        overlap = held_overlap(held, key)
        return "" if overlap.empty?
        "#{keys} overlaps keys that run #{held[overlap]}, which a project file may not unbind or rebind"
      end

      # Whether every key of the keys, under the leader, is one typing text
      # sends: a printable character, Tab, Enter, or Backspace. Only such
      # keys fire while text is typed in normal mode by mistake; keys that
      # do not parse bind nothing, and the keymap notes them.
      #: (String, String) -> bool
      def typed_as_text?(keys, leader)
        parsed = KeyNotation.parse(keys, leader)
        return false unless parsed.ok?
        codes = parsed.codes
        return false if codes.empty?
        i = 0
        while i < codes.length
          code = codes[i].to_i
          return false unless Key.printable?(code) || code == Key::TAB || code == Key::CR || code == Key::NL || code == Key::BS || code == Key::CTRL_H
          i += 1
        end
        true
      end

      # The held key (held_keys) that the key starts with or begins, codes
      # compared whole, or "": unbinding either leaves the other, but
      # binding one would turn a held key into a prefix or wait on it.
      #: (Hash[String, String], String) -> String
      def held_overlap(held, key)
        names = held.keys
        i = 0
        while i < names.length
          name = names[i].to_s
          return name if key.start_with?("#{name} ") || name.start_with?("#{key} ")
          i += 1
        end
        ""
      end

      # The keys of the bindings in effect that a project file may not
      # take, each as held_key, to the action or key sequence they run:
      # a value it could not bind itself, and the key that opens the
      # command line. Read once before an untrusted file's lines.
      #: () -> Hash[String, String]
      def held_keys
        bound = Config.no_keys
        at = leader
        i = 0
        while i < settings.length
          line = line_at(i)
          words = line.words
          if line.scope == "keymap" && line.name != LEADER && line.name != GROUP && words.length == 2
            key = held_key(line.name, words[0].to_s, at)
            value = words[1].to_s
            if value == NONE || (value != OPEN_COMMAND_LINE && Config.project_bindable_in?(line.name, value))
              bound.delete(key)
            else
              bound[key] = value
            end
          end
          i += 1
        end
        bound
      end

      # The key of a binding in held_keys: the keymap line's name and the
      # codes its keys spell under the leader, so <leader>fs and <Space>fs
      # are one key; keys that do not parse are their text.
      #: (String, String, String) -> String
      def held_key(name, keys, leader)
        parsed = KeyNotation.parse(keys, leader)
        return "#{name} #{keys}" unless parsed.ok?
        "#{name} #{parsed.codes.join(" ")}"
      end

      # Appends the problems of index[from, mid - from] and
      # index[mid, to - mid], each in ascending order, to out in ascending
      # order, the first run's first on equal orders, and returns out.
      #: (Array[Integer], Integer, Integer, Integer, Array[Integer]) -> Array[Integer]
      def merge_runs(index, from, mid, to, out)
        a = from
        b = mid
        while a < mid && b < to
          if orders[index[b]] < orders[index[a]]
            out << index[b]
            b += 1
          else
            out << index[a]
            a += 1
          end
        end
        while a < mid
          out << index[a]
          a += 1
        end
        while b < to
          out << index[b]
          b += 1
        end
        out
      end

      #: (Integer, String) -> void
      def note_at(order, text)
        problems << text
        orders << order
      end
    end
  end
end
