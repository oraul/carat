require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/options"
require_relative "../../domain/last_search"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :se[t] for the two buffer options highlighting reads: filetype (ft)
    # and syntax (syn), each as name=value, name? or the bare name, which
    # shows "  name=value", several in one command. filetype=x sets the
    # filetype and the syntax with it; syntax=x sets the syntax alone,
    # OFF for none and ON for the filetype's. The four search options
    # ignorecase (ic), smartcase (scs), hlsearch (hls), and incsearch (is)
    # take Vim's boolean forms: name, noname, invname, name!, and name?,
    # which shows "  name" or "noname"; a value is E474. Changing the case
    # options compiles the last pattern again, and setting hlsearch shows
    # its matches again after :noh. The rest of :set arrives with the
    # options change: an option Carat already has is answered with Not
    # implemented, any other name with E518.
    class SetCommandHandler < ExHandler
      attr_reader :last_search #: Domain::LastSearch

      # The options Carat has that :set does not handle yet.
      PENDING = ["number", "nu", "relativenumber", "rnu", "tabstop", "ts", "shiftwidth", "sw", "expandtab", "et", "autoindent", "ai", "scroll", "scr", "scrolloff", "so", "timeoutlen", "tm", "undolevels", "ul", "icons", "theme", "background", "bg", "startscreen", "reducedmotion"]
      private_constant :PENDING

      #: (spec: String, last_search: Domain::LastSearch) -> void
      def initialize(spec:, last_search:)
        super(spec: spec)
        @last_search = last_search
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        words = command.args.split(" ")
        return Outcome.success("Not implemented: :set") if words.empty?
        shown = []
        i = 0
        while i < words.length
          word = words[i]
          flag = boolean_name(word)
          unless flag.empty?
            return Outcome.failure("E474: Invalid argument: #{word}") if word.include?("=")
            if word.end_with?("?")
              shown << (on?(state.options, flag) ? "  #{flag}" : "no#{flag}")
            else
              set_boolean(state.options, word, flag)
            end
            i += 1
            next
          end
          equals = word.index("=")
          name = equals.nil? ? word.delete_suffix("?") : word[0, equals]
          value = equals.nil? ? "" : word[equals + 1, word.length - equals - 1]
          option = full_name(name)
          if option.empty?
            return Outcome.success("Not implemented: :set #{word}") if PENDING.include?(name.delete_prefix("no").delete_prefix("inv")) || PENDING.include?(name)
            return Outcome.failure("E518: Unknown option: #{name}")
          end
          buffer = state.buffer
          if equals.nil?
            shown << "  #{option}=#{option == "filetype" ? buffer.filetype : buffer.syntax}"
          elsif option == "filetype"
            buffer.assign_filetype(value)
          else
            buffer.syntax = syntax_value(buffer, value)
          end
          i += 1
        end
        shown.empty? ? Outcome.none : Outcome.success(shown.join("\n"))
      end

      # Registers :set after :syntax.
      #: (ExTable, last_search: Domain::LastSearch) -> void
      def self.register(table, last_search:)
        table.register(SetCommandHandler.new(spec: "se[t]", last_search: last_search))
      end

      private

      # The full name of the search option a word sets, with or without
      # no, inv, a trailing ! or ?, or a value; "" for another word.
      #: (String) -> String
      def boolean_name(word)
        equals = word.index("=")
        base = equals.nil? ? word : word[0, equals].to_s
        base = base.delete_suffix("?").delete_suffix("!")
        full = full_boolean(base)
        return full unless full.empty?
        return full_boolean(base.delete_prefix("no")) if base.start_with?("no")
        return full_boolean(base.delete_prefix("inv")) if base.start_with?("inv")
        ""
      end

      #: (String) -> String
      def full_boolean(name)
        return "ignorecase" if name == "ignorecase" || name == "ic"
        return "smartcase" if name == "smartcase" || name == "scs"
        return "hlsearch" if name == "hlsearch" || name == "hls"
        return "incsearch" if name == "incsearch" || name == "is"
        ""
      end

      # Sets a search option as the word asks: on, off with no, or
      # switched with inv or a trailing !.
      #: (Domain::Options, String, String) -> void
      def set_boolean(options, word, name)
        current = on?(options, name)
        value = true
        value = false if word.start_with?("no") && full_boolean(word) != name
        value = !current if word.start_with?("inv") || word.end_with?("!")
        case name
        when "ignorecase" then options.ignorecase = value
        when "smartcase" then options.smartcase = value
        when "hlsearch" then options.hlsearch = value
        else options.incsearch = value
        end
        @last_search.recompile(options) if name == "ignorecase" || name == "smartcase"
        @last_search.show if name == "hlsearch" && value
      end

      #: (Domain::Options, String) -> bool
      def on?(options, name)
        case name
        when "ignorecase" then options.ignorecase
        when "smartcase" then options.smartcase
        when "hlsearch" then options.hlsearch
        else options.incsearch
        end
      end

      # The full name of a handled option, "" for another name.
      #: (String) -> String
      def full_name(name)
        return "filetype" if name == "filetype" || name == "ft"
        return "syntax" if name == "syntax" || name == "syn"
        ""
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
