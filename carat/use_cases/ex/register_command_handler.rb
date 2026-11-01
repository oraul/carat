require_relative "../../domain/editor_state"
require_relative "../../domain/registers"
require_relative "../../domain/register_entry"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :reg[isters] and :di[splay]: Neovim's listing of the registers that
    # hold text, in the order unnamed, 0 to 9, a to z, -, ., :, %, under
    # the line "Type Name Content". Each line is two spaces, the kind (c,
    # l, or b), two spaces, the quote and the name, three spaces, and the
    # text with ^J for each line break and after linewise text, cut to the
    # screen width less 11 columns. Names given as the argument keep only
    # those registers.
    class RegisterCommandHandler < ExHandler
      TITLE = "Type Name Content"
      ORDER = "\"0123456789abcdefghijklmnopqrstuvwxyz-.:%"

      attr_reader :registers #: Domain::Registers

      #: (spec: String, registers: Domain::Registers) -> void
      def initialize(spec:, registers:)
        super(spec: spec)
        @registers = registers
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        wanted = command.args
        width = state.screen_cols > 0 ? state.screen_cols : 80
        path = state.buffer.path_text
        text = TITLE
        i = 0
        while i < ORDER.length
          name = ORDER[i, 1]
          if wanted.empty? || wanted.include?(name)
            entry = @registers.read_with_file(name, path)
            text = text + "\n" + RegisterCommandHandler.line(name, entry, width - 11) if !entry.nil?
          end
          i += 1
        end
        Outcome.success(text)
      end

      #: (ExTable, registers: Domain::Registers) -> void
      def self.register(table, registers:)
        table.register(RegisterCommandHandler.new(spec: "reg[isters]", registers: registers))
        table.register(RegisterCommandHandler.new(spec: "di[splay]", registers: registers))
      end

      # One line of the listing, its text cut to room columns.
      #: (String, Domain::RegisterEntry, Integer) -> String
      def self.line(name, entry, room)
        kind = entry.kind == :linewise ? "l" : (entry.kind == :blockwise ? "b" : "c")
        out = "  " + kind + "  \"" + name + "   "
        n = room
        parts = entry.text.split("\n", -1)
        parts = [""] if parts.empty?
        j = 0
        while j < parts.length && n > 1
          if j > 0
            out = out + "^J"
            n -= 2
          end
          part = parts[j]
          take = part.length < n ? part.length : (n > 0 ? n : 0)
          out = out + part[0, take]
          n -= part.length
          j += 1
        end
        out = out + "^J" if n > 1 && entry.kind == :linewise
        out
      end
    end
  end
end
