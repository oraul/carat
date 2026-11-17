require_relative "../../domain/editor_state"
require_relative "../../domain/messages"
require_relative "../outcome"
require_relative "line_command_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # :[range]co[py] {address} and its synonym :[range]t {address}: puts a
    # copy of the lines of the range, the cursor line without one, below
    # the line the address names (0 for above the first), as Neovim's
    # ex_copy does. The cursor goes to the last copied line at the wanted
    # column; above two lines the message is "N more lines". One undo
    # step: the edit joins the caller's transaction or is its own. A bad
    # range or address reports what ExRange gives, a bang E477.
    class CopyCommandHandler < LineCommandHandler
      #: (spec: String) -> void
      def initialize(spec:)
        super(spec: spec)
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        lines = lines_of(state, command)
        return Outcome.failure(lines.error) unless lines.ok?
        target = target_of(state, command)
        return Outcome.failure(target.error) unless target.ok?
        buffer = state.buffer
        at = target.first
        count = lines.last - lines.first + 1
        opened = buffer.begin_transaction(state.cursor.position)
        buffer.set_lines(at, at, buffer.lines_of(lines.first, lines.last))
        place_cursor(state, at + count - 1)
        buffer.commit_transaction(state.cursor.position) if opened
        return Outcome.success("#{count} more lines") if count > Domain::Messages::REPORT
        Outcome.none
      end

      # Registers :copy and :t in the order of docs/compatibility.md,
      # which is their precedence; no core command shares their
      # abbreviations.
      #: (ExTable) -> void
      def self.register(table)
        table.register(CopyCommandHandler.new(spec: "co[py]"), "Copy lines")
        table.register(CopyCommandHandler.new(spec: "t"), "Copy lines")
      end
    end
  end
end
