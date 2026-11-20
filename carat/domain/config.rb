require_relative "rc_parse"
require_relative "rc_line"
require_relative "rc_parser"
require_relative "root_word"

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

      # The actions that write the buffer or quit, which a project file
      # may not bind in any mode, as a key the user types would run them.
      PROJECT_REFUSED = ["file.save", "quit.all", "quit.write_all", "window.quit"]

      # The prefix of the command line's actions, which run or recall an
      # ex command, so a project file may not bind them in any mode.
      COMMAND_LINE = "cmdline."

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
      # sequence to replay, which can run any ex command.
      #: (String, String, bool) -> void
      def read(source, text, trusted)
        file = files
        self.files = file + 1
        n = text.bytesize
        start = 0
        number = 1
        while start < n
          stop = start
          stop += 1 while stop < n && text.getbyte(stop).to_i != RcParser::NEWLINE
          add(source, file, number, RcParser.parse_range(text, start, stop), trusted)
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
        note_at(file * RcLine::FILE_SPAN, "#{source}: #{reason}")
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

      #: (String, Integer, Integer, RcParse, bool) -> void
      def add(source, file, number, parsed, trusted)
        return if parsed.blank?
        unless parsed.ok?
          note_at(file * RcLine::FILE_SPAN + number, "#{source}:#{number}: #{parsed.error}")
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
        return if scope == "language" && !language?(line, trusted)
        return if scope == "keymap" && !trusted && !binding?(line)
        settings << line
      end

      # Whether a language line may be kept: from a trusted file, as
      # language.<name>.<setting> with a known setting or as
      # language.trusted_roots, a root's command with a root (RootWord)
      # and a command word. Notes why not, a planned setting as not
      # supported yet.
      #: (RcLine, bool) -> bool
      def language?(line, trusted)
        unless trusted
          note(line, "language commands are not read from a project file")
          return false
        end
        name = line.name
        return true if line.key == TRUSTED_ROOTS
        dot = name.index(".")
        if dot.nil?
          note(line, "unknown setting #{line.key}")
          return false
        end
        setting = name[dot + 1, name.length - dot - 1].to_s
        if PLANNED_SETTINGS.include?(setting)
          note(line, "language setting #{setting} is not supported yet")
          return false
        end
        unless LANGUAGE_SETTINGS.include?(setting)
          note(line, "unknown language setting #{setting}")
          return false
        end
        if setting == ROOTED_SETTING && line.words.length < 2
          note(line, "#{line.key} needs a root and a command")
          return false
        end
        if setting == ROOTED_SETTING
          root = line.words[0].to_s
          unless RootWord.root?(root)
            note(line, "#{line.key} #{root} is not a root")
            return false
          end
        end
        true
      end

      # Whether an untrusted file's keymap line may be kept: one whose
      # value is an action name or none, or a group name, which binds
      # nothing. A key sequence to replay is noted
      # and refused, because a replay types anything, :w with any path
      # included, so a project file could write any file the user can. So
      # is an action that writes, quits, or runs the command line, in any
      # mode (PROJECT_REFUSED, COMMAND_LINE).
      #: (RcLine) -> bool
      def binding?(line)
        words = line.words
        return true if line.name == "leader" || line.name == "group" || words.length != 2
        value = words[1].to_s
        return true if value == "none"
        unless RcParser.key?(value, 0, value.bytesize)
          note(line, "key sequences are not read from a project file")
          return false
        end
        return true unless PROJECT_REFUSED.include?(value) || value.start_with?(COMMAND_LINE)
        note(line, "write, quit, and command-line actions are not bound from a project file")
        false
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
