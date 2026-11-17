require_relative "../../domain/editor_state"
require_relative "../../domain/messages"
require_relative "../../domain/operators"
require_relative "../../domain/register_count"
require_relative "../outcome"
require_relative "line_command_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :[range]> [count] and :[range]< [count]: shift the lines of the
    # range, the cursor line without one, right or left by shiftwidth
    # once for each ">" or "<" typed, as Neovim's ex_operators and
    # op_shift do: a count shifts count lines from the range's last line;
    # an empty line stays empty. The cursor goes to the first non-blank
    # of the last line; above two lines the message is "N lines >ed M
    # times". One undo step: the edit joins the caller's transaction or
    # is its own. A bad range reports what ExRange gives, a bad count what
    # RegisterCount gives, a bang E477.
    class ShiftCommandHandler < LineCommandHandler
      #: (spec: String) -> void
      def initialize(spec:)
        super(spec: spec)
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        lines = lines_of(state, command)
        return Outcome.failure(lines.error) unless lines.ok?
        char = name.full
        text = command.args
        i = 0
        i += 1 while i < text.length && text[i, 1] == char
        args = Domain::RegisterCount.parse_count(text[i, text.length - i].to_s.strip)
        return Outcome.failure(args.error) unless args.ok?
        buffer = state.buffer
        lines = lines.counted(args.count, buffer.line_count) if args.count > 0
        amount = i + 1
        options = state.options
        opened = buffer.begin_transaction(state.cursor.position)
        Domain::Operators.shift(buffer, lines.first, lines.last, char == ">" ? amount : -amount, options.shiftwidth, options.tabstop, options.expandtab)
        state.cursor.move_to(lines.last, buffer.first_nonblank(lines.last))
        buffer.commit_transaction(state.cursor.position) if opened
        count = lines.last - lines.first + 1
        return Outcome.none if count <= Domain::Messages::REPORT
        Outcome.success("#{count} lines #{char}ed #{amount} #{amount == 1 ? "time" : "times"}")
      end

      # Registers :> and :< after :join, in the order of
      # docs/compatibility.md, which is their precedence.
      #: (ExTable) -> void
      def self.register(table)
        table.register(ShiftCommandHandler.new(spec: ">"), "Shift lines right")
        table.register(ShiftCommandHandler.new(spec: "<"), "Shift lines left")
      end
    end
  end
end
