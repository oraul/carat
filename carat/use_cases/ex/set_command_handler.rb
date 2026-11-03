require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../outcome"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :se[t] for the two buffer options highlighting reads: filetype (ft)
    # and syntax (syn), each as name=value, name? or the bare name, which
    # shows "  name=value", several in one command. filetype=x sets the
    # filetype and the syntax with it; syntax=x sets the syntax alone,
    # OFF for none and ON for the filetype's. The rest of :set arrives with
    # the options change: an option Carat already has is answered with
    # Not implemented, any other name with E518.
    class SetCommandHandler < ExHandler
      # The options Carat has that :set does not handle yet.
      PENDING = ["number", "nu", "relativenumber", "rnu", "tabstop", "ts", "shiftwidth", "sw", "expandtab", "et", "autoindent", "ai", "scroll", "scr", "scrolloff", "so", "timeoutlen", "tm", "undolevels", "ul", "icons", "theme"]
      private_constant :PENDING

      #: (spec: String) -> void
      def initialize(spec:)
        super(spec: spec)
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
      #: (ExTable) -> void
      def self.register(table)
        table.register(SetCommandHandler.new(spec: "se[t]"))
      end

      private

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
