require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/jump_list"
require_relative "../../domain/messages"
require_relative "../outcome"

module Carat
  module UseCases
    # Ctrl-O and Ctrl-I: moves through the jump list by steps, older for
    # a negative count, showing the entry's buffer in the current window
    # (E37 while the current file buffer is modified) with the cursor at
    # the entry, clamped to the text. An entry whose buffer is gone is
    # dropped; past either end nothing happens.
    class WalkJumps
      attr_reader :jumps #: Domain::JumpList
      attr_reader :buffers #: Domain::BufferList

      #: (jumps: Domain::JumpList, buffers: Domain::BufferList) -> void
      def initialize(jumps:, buffers:)
        @jumps = jumps
        @buffers = buffers
      end

      #: (Domain::EditorState, Integer) -> Outcome
      def call(state, steps)
        jumps = @jumps
        window = state.window
        current = window.buffer
        at = jumps.step(steps, current.id, window.cursor.row, window.cursor.col)
        return Outcome.none if at < 0
        target = @buffers.with_id(jumps.buffer_ids[at].to_i)
        if target.nil?
          jumps.remove_at(at)
          return Outcome.none
        end
        unless target.equal?(current)
          return Outcome.failure(Domain::Messages::E37) if current.modified? && !current.scratch?
          @buffers.load(target)
        end
        window = state.window
        buffer = window.buffer
        count = buffer.line_count
        row = jumps.rows[at].to_i
        row = count - 1 if row >= count
        row = 0 if row < 0
        col = jumps.cols[at].to_i
        last = buffer.line(row).bytesize - 1
        col = last if col > last
        col = 0 if col < 0
        window.cursor.move_to(row, col)
        Outcome.none
      end
    end
  end
end
