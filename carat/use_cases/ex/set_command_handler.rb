require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/buffer_feed"
require_relative "../../domain/options"
require_relative "../../domain/rc_value"
require_relative "../../domain/last_search"
require_relative "../../domain/last_substitute"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :se[t] for the options of NAMES, by full or short name, as Neovim
    # takes them. The two buffer options highlighting reads, filetype (ft)
    # and syntax (syn), take name=value: filetype=x sets the filetype and
    # the syntax with it; syntax=x sets the syntax alone, OFF for none and
    # ON for the filetype's. A flag takes Vim's boolean forms: name,
    # noname, invname, name!, and name?, which shows "  name" or
    # "noname". A number takes name=N, name+=N, name-=N, and name^=N
    # (multiply), a word name=value, a backslash keeping a blank; name?
    # and the bare name show "  name=value", and name& resets the option
    # to its shipped default. Every value is checked by Options#problem,
    # the rule of its configuration line, so :set never stores one a line
    # would refuse: E521 for a number that does not parse, E474 for any
    # other refused value or form. A bare :set lists the options that
    # differ from the shipped defaults, :set all every option. Changing
    # the case options compiles the last pattern again, setting hlsearch
    # shows its matches again after :noh, and undolevels reaches the feed
    # the buffers record their undo states through. startscreen, read
    # only at startup, is not changed live; theme and background answer
    # Not implemented, any other name E518.
    class SetCommandHandler < ExHandler
      attr_reader :last_search #: Domain::LastSearch
      attr_reader :last_substitute #: Domain::LastSubstitute
      attr_reader :shipped #: Domain::Options
      attr_reader :feed #: Domain::BufferFeed

      # The options :set handles, by full name in the order the listings
      # show them, and their short names, "" for none.
      NAMES = ["autoindent", "breadcrumbs", "cursorline", "expandtab", "filetype", "hlsearch", "icons", "ignorecase", "incsearch", "list", "listchars", "number", "reducedmotion", "relativenumber", "scroll", "scrolloff", "shiftwidth", "showtabline", "smartcase", "startscreen", "syntax", "tabstop", "timeoutlen", "undolevels", "winborder"]
      SHORT_NAMES = ["ai", "", "cul", "et", "ft", "hls", "", "ic", "is", "", "lcs", "nu", "", "rnu", "scr", "so", "sw", "stal", "scs", "", "syn", "ts", "tm", "ul", ""]
      # The options Carat has that :set does not handle yet.
      PENDING = ["theme", "background", "bg"]
      private_constant :NAMES, :SHORT_NAMES, :PENDING

      #: (spec: String, last_search: Domain::LastSearch, last_substitute: Domain::LastSubstitute, shipped: Domain::Options, feed: Domain::BufferFeed) -> void
      def initialize(spec:, last_search:, last_substitute:, shipped:, feed:)
        super(spec: spec)
        @last_search = last_search
        @last_substitute = last_substitute
        @shipped = shipped
        @feed = feed
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        words = arguments(command.args)
        return Outcome.success(listing(state, false)) if words.empty?
        shown = []
        i = 0
        while i < words.length
          word = words[i]
          if word == "all"
            shown << listing(state, true)
          else
            stop = set_word(state, word, shown)
            return stop.start_with?("E") ? Outcome.failure(stop) : Outcome.success(stop) unless stop.empty?
          end
          i += 1
        end
        shown.empty? ? Outcome.none : Outcome.success(shown.join("\n"))
      end

      # Registers :set after :syntax.
      #: (ExTable, last_search: Domain::LastSearch, last_substitute: Domain::LastSubstitute, shipped: Domain::Options, feed: Domain::BufferFeed) -> void
      def self.register(table, last_search:, last_substitute:, shipped:, feed:)
        table.register(SetCommandHandler.new(spec: "se[t]", last_search: last_search, last_substitute: last_substitute, shipped: shipped, feed: feed), "Set an option")
      end

      private

      # The arguments of :set, split at blanks; a backslash before a blank
      # or a backslash keeps that character in the argument.
      #: (String) -> Array[String]
      def arguments(text)
        words = []
        word = +""
        n = text.bytesize
        run = 0
        i = 0
        while i < n
          byte = text.getbyte(i)
          if byte == 92 && i + 1 < n && escaped?(text.getbyte(i + 1))
            word << text.byteslice(run, i - run).to_s
            run = i + 1
            i += 2
          elsif byte == 32 || byte == 9
            word << text.byteslice(run, i - run).to_s
            words << word unless word.empty?
            word = +""
            i += 1
            run = i
          else
            i += 1
          end
        end
        word << text.byteslice(run, n - run).to_s
        words << word unless word.empty?
        words
      end

      # Whether a backslash keeps the byte after it: a blank or itself.
      #: (Integer) -> bool
      def escaped?(byte)
        byte == 32 || byte == 9 || byte == 92
      end

      # Applies one argument, adding what it shows to shown; "" when it
      # went on, else the message that stops the command, an error when it
      # starts with E.
      #: (Domain::EditorState, String, Array[String]) -> String
      def set_word(state, word, shown)
        return "Not implemented: :set #{word}" if word == "all&"
        op = operator(word)
        name = name_part(word, op)
        option = full_name(name)
        prefix = ""
        if option.empty?
          prefix = "no" if name.start_with?("no")
          prefix = "inv" if name.start_with?("inv")
          option = full_name(name.delete_prefix(prefix)) unless prefix.empty?
        end
        if option.empty?
          return "Not implemented: :set #{word}" if PENDING.include?(name) || PENDING.include?(name.delete_prefix(prefix))
          return "E518: Unknown option: #{name}"
        end
        value = value_part(word, op)
        options = state.options
        kind = Domain::Options::KINDS[option].to_s
        return set_flag(options, option, prefix, op, word, shown) if kind == "bool" && option != "filetype" && option != "syntax"
        return "E474: Invalid argument: #{word}" unless prefix.empty? && op != "!"
        return set_buffer_option(state.buffer, option, op, value, word, shown) if option == "filetype" || option == "syntax"
        if op.empty? || op == "?"
          shown << "  #{option}=#{options.value_of(option)}"
          return ""
        end
        return store(options, option, @shipped.value_of(option)) if op == "&"
        target = value
        if kind == "integer"
          return "E521: Number required after =: #{word}" unless number_word?(value)
          target = number_result(options.value_of(option).to_i, op, value.to_i).to_s
        elsif op != "="
          return "Not implemented: :set #{word}"
        end
        return "E474: Invalid argument: #{word}" unless Domain::RcValue.valid?([target], kind) && options.problem(option, option, target).empty?
        store(options, option, target)
      end

      # A flag in Vim's boolean forms: on, off with no, switched with inv
      # or a trailing !, shown with ?, reset with &; a value is E474.
      #: (Domain::Options, String, String, String, String, Array[String]) -> String
      def set_flag(options, option, prefix, op, word, shown)
        return "E474: Invalid argument: #{word}" unless op.empty? || op == "?" || op == "!" || op == "&"
        on = options.value_of(option) == "true"
        if op == "?"
          shown << (on ? "  #{option}" : "no#{option}")
          return ""
        end
        return store(options, option, @shipped.value_of(option)) if op == "&"
        value = prefix != "no"
        value = !on if prefix == "inv" || op == "!"
        store(options, option, value ? "true" : "false")
      end

      # filetype and syntax: shown bare or with ?, set with =; another
      # form is not implemented.
      #: (Domain::Buffer, String, String, String, String, Array[String]) -> String
      def set_buffer_option(buffer, option, op, value, word, shown)
        if op.empty? || op == "?"
          shown << "  #{option}=#{option == "filetype" ? buffer.filetype : buffer.syntax}"
        elsif op == "="
          if option == "filetype"
            buffer.assign_filetype(value)
          else
            buffer.syntax = syntax_value(buffer, value)
          end
        else
          return "Not implemented: :set #{word}"
        end
        ""
      end

      # Stores a value problem accepted and runs what the option's change
      # starts; startscreen, read only at startup, is not changed.
      #: (Domain::Options, String, String) -> String
      def store(options, option, word)
        return "Not implemented: :set #{option} live" if option == "startscreen"
        options.assign(option, word)
        @last_search.recompile(options, @last_substitute) if option == "ignorecase" || option == "smartcase"
        @last_search.show if option == "hlsearch" && options.hlsearch
        @feed.undolevels = options.undolevels if option == "undolevels"
        ""
      end

      # The operator of an argument: "=", "+=", "-=", "^=", or a trailing
      # "?", "&", or "!", "" for none.
      #: (String) -> String
      def operator(word)
        equals = word.index("=")
        unless equals.nil?
          before = equals > 0 ? word.getbyte(equals - 1) : 0
          return "+=" if before == 43
          return "-=" if before == 45
          return "^=" if before == 94
          return "="
        end
        return "?" if word.end_with?("?")
        return "&" if word.end_with?("&")
        return "!" if word.end_with?("!")
        ""
      end

      # The option name an argument starts with, before its operator.
      #: (String, String) -> String
      def name_part(word, op)
        return word if op.empty?
        equals = word.index("=")
        return word.byteslice(0, word.bytesize - 1).to_s if equals.nil?
        word.byteslice(0, equals - op.bytesize + 1).to_s
      end

      # The value after an argument's =, "" without one.
      #: (String, String) -> String
      def value_part(word, op)
        equals = word.index("=")
        return "" if equals.nil?
        word.byteslice(equals + 1, word.bytesize - equals - 1).to_s
      end

      # The full name of a handled option by its full or short name, ""
      # for another name.
      #: (String) -> String
      def full_name(name)
        return "" if name.empty?
        i = 0
        while i < NAMES.length
          full = NAMES[i]
          return full if name == full || name == SHORT_NAMES[i]
          i += 1
        end
        ""
      end

      # Whether a value reads as a number: an optional minus and one to
      # nine digits, so a product of two stays within an Integer.
      #: (String) -> bool
      def number_word?(value)
        digits = value.start_with?("-") ? value.delete_prefix("-") : value
        Domain::RcValue.number?(digits)
      end

      # The number an operator makes of the current value and the typed
      # one: set, added, subtracted, or multiplied.
      #: (Integer, String, Integer) -> Integer
      def number_result(current, op, typed)
        return current + typed if op == "+="
        return current - typed if op == "-="
        return current * typed if op == "^="
        typed
      end

      # Every option :set handles, or only those that differ from the
      # shipped defaults and a set filetype and syntax, under Neovim's
      # heading, one per line as name? shows it.
      #: (Domain::EditorState, bool) -> String
      def listing(state, all)
        options = state.options
        buffer = state.buffer
        lines = ["--- Options ---"]
        i = 0
        while i < NAMES.length
          name = NAMES[i]
          if name == "filetype" || name == "syntax"
            value = name == "filetype" ? buffer.filetype : buffer.syntax
            lines << "  #{name}=#{value}" if all || !value.empty?
          else
            value = options.value_of(name)
            lines << shown_value(name, value) if all || value != @shipped.value_of(name)
          end
          i += 1
        end
        lines.join("\n")
      end

      # An option as name? shows it: "  name" or "noname" for a flag,
      # "  name=value" for another.
      #: (String, String) -> String
      def shown_value(name, value)
        return "  #{name}=#{value}" unless Domain::Options::KINDS[name].to_s == "bool"
        value == "true" ? "  #{name}" : "no#{name}"
      end

      # What syntax=value stores: "" for OFF, the filetype for ON.
      #: (Domain::Buffer, String) -> String
      def syntax_value(buffer, value)
        return "" if value == "OFF" || value == "off"
        return buffer.filetype if value == "ON" || value == "on"
        value
      end
    end
  end
end
