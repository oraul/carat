require_relative "../../domain/editor_state"
require_relative "../../domain/messages"
require_relative "../../ports/clock_port"
require_relative "../outcome"

module Carat
  module UseCases
    # :undolist: one line per state of the current buffer's undo tree
    # without later states on its branch, with its number, its changes,
    # how long ago it was made, and its write number.
    class ListUndo
      TITLE = "number changes  when               saved"
      private_constant :TITLE

      attr_reader :clock #: Ports::ClockPort

      #: (clock: Ports::ClockPort) -> void
      def initialize(clock:)
        @clock = clock
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        tree = state.buffer.undo
        leaves = tree.leaves
        return Outcome.success("Nothing to undo") if leaves.empty?
        now = @clock.now
        text = TITLE
        i = 0
        while i < leaves.length
          seq = leaves[i]
          row = seq.to_s.rjust(6) + " " + (tree.depth_of(seq) - tree.root_depth).to_s.rjust(7) + "  " + Domain::Messages.seconds_ago(now - tree.time_of(seq))
          save = tree.save_of(seq)
          row = row.ljust(33) + "  " + save.to_s.rjust(3) if save > 0
          text = text + "\n" + row
          i += 1
        end
        Outcome.success(text)
      end
    end
  end
end
