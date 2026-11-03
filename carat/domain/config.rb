require_relative "rc_parse"
require_relative "rc_line"
require_relative "rc_parser"

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
      # run, each a list of words.
      LANGUAGE_SETTINGS = ["lsp", "formatter"]

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
      # names an unknown scope, or is a language setting it may not set
      # is noted and skipped. An untrusted file, the project's, may not
      # set language commands, which name programs to run.
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

      # Notes a file that exists but could not be read, as a file of its
      # own in load order.
      #: (String) -> void
      def unreadable(source)
        file = files
        self.files = file + 1
        note_at(file * RcLine::FILE_SPAN, "#{source}: cannot be read")
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

      # Every problem in file and line order.
      #: () -> Array[String]
      def report
        index = []
        i = 0
        while i < problems.length
          index << i
          i += 1
        end
        # An insertion sort keeps problems of the same order as noted.
        i = 1
        while i < index.length
          k = index[i]
          j = i - 1
          while j >= 0 && orders[index[j]] > orders[k]
            index[j + 1] = index[j]
            j -= 1
          end
          index[j + 1] = k
          i += 1
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
        settings << line
      end

      # Whether a language line may be kept: from a trusted file, as
      # language.<name>.<setting> with a known setting. Notes why not.
      #: (RcLine, bool) -> bool
      def language?(line, trusted)
        unless trusted
          note(line, "language commands are not read from a project file")
          return false
        end
        name = line.name
        dot = name.index(".")
        if dot.nil?
          note(line, "unknown setting #{line.key}")
          return false
        end
        setting = name[dot + 1, name.length - dot - 1].to_s
        unless LANGUAGE_SETTINGS.include?(setting)
          note(line, "unknown language setting #{setting}")
          return false
        end
        true
      end

      #: (Integer, String) -> void
      def note_at(order, text)
        problems << text
        orders << order
      end
    end
  end
end
