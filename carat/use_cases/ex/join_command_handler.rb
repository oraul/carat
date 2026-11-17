require_relative "../../domain/editor_state"
require_relative "../../domain/operators"
require_relative "../../domain/register_count"
require_relative "../outcome"
require_relative "line_command_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :[range]j[oin][!] [count]: joins the lines of the range, the cursor
    # line and the next without one, as Neovim's ex_join does: a count
    # joins count lines from the range's last line; one line given with
    # two addresses, or the last line, changes nothing but the cursor
    # line. Without a bang the joined lines lose their leading blanks and
    # follow one space, as J does; with one they are put together as they
    # are. The cursor goes to the first non-blank of the joined line. One
    # undo step: the edit joins the caller's transaction or is its own. A
    # bad range reports what ExRange gives, a bad count what RegisterCount
    # gives.
    class JoinCommandHandler < LineCommandHandler
      #: (spec: String) -> void
      def initialize(spec:)
        super(spec: spec)
      end

      # True: a bang joins without spaces.
      # @rbs skip
      def bang?
        true
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        lines = lines_of(state, command)
        return Outcome.failure(lines.error) unless lines.ok?
        args = Domain::RegisterCount.parse_count(command.args)
        return Outcome.failure(args.error) unless args.ok?
        buffer = state.buffer
        addresses = addresses_in(command.range)
        if args.count > 0
          lines = lines.counted(args.count, buffer.line_count)
          addresses += 1
        end
        first = lines.first
        last = lines.last
        if first == last
          return stay(state, first) if addresses >= 2 || last >= buffer.line_count - 1
          last += 1
        end
        opened = buffer.begin_transaction(state.cursor.position)
        Domain::Operators.join(buffer, first, last - first + 1, !command.bang)
        state.cursor.move_to(first, buffer.first_nonblank(first))
        buffer.commit_transaction(state.cursor.position) if opened
        Outcome.none
      end

      # Registers :join after :t, in the order of docs/compatibility.md,
      # which is its precedence; no core command shares its abbreviation.
      #: (ExTable) -> void
      def self.register(table)
        table.register(JoinCommandHandler.new(spec: "j[oin]"), "Join lines")
      end

      private

      # How many addresses the range text typed, as Neovim's addr_count:
      # none, one, or two for "%" or a comma.
      #: (String) -> Integer
      def addresses_in(text)
        return 0 if text.empty?
        text == "%" || text.include?(",") ? 2 : 1
      end

      # Nothing joined: the cursor goes to row, its column clamped, as
      # Neovim's ex_join sets the line before it returns.
      #: (Domain::EditorState, Integer) -> Outcome
      def stay(state, row)
        cursor = state.cursor
        cursor.row = row
        cursor.col = state.clamp_col(row, cursor.col)
        Outcome.none
      end
    end
  end
end
