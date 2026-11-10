require_relative "../../domain/editor_state"
require_relative "../../domain/buffer_list"
require_relative "../../domain/jump_list"
require_relative "../../domain/messages"
require_relative "../../domain/options"
require_relative "../outcome"

module Carat
  module UseCases
    # Ctrl-O and Ctrl-I: moves through the current window's jump list by
    # steps, older for a negative count, showing the entry's buffer in
    # the window (E37 while the current file buffer is modified, the list
    # then put back as it was) with the cursor at the entry, clamped to
    # the text.
    # An entry whose buffer is gone is dropped; past either end, or while
    # a float such as the pick list has the focus, nothing happens. Under
    # option.jumptab replace an entry's file buffer with no tab takes the
    # tab of the buffer left (BufferList#hand_tab). The walk records no
    # jump of its own.
    class WalkJumps
      # @rbs @saved: Domain::JumpList

      attr_reader :buffers #: Domain::BufferList

      #: (buffers: Domain::BufferList) -> void
      def initialize(buffers:)
        @buffers = buffers
        @saved = Domain::JumpList.new
      end

      #: (Domain::EditorState, Integer) -> Outcome
      def call(state, steps)
        return Outcome.none if state.tab.floats.focused?
        window = state.window
        jumps = window.jumps
        current = window.buffer
        guarded = current.modified? && !current.scratch?
        @saved.restore_from(jumps) if guarded
        at = jumps.step(steps, current.id, window.cursor.row, window.cursor.col)
        return Outcome.none if at < 0
        target = @buffers.with_id(jumps.buffer_ids[at].to_i)
        if target.nil?
          jumps.remove_at(at)
          return Outcome.none
        end
        unless target.equal?(current)
          if guarded
            jumps.restore_from(@saved)
            return Outcome.failure(Domain::Messages::E37)
          end
          tabbed = !target.tabless?
          @buffers.load(target)
          @buffers.hand_tab(current, target) if !tabbed && state.options.jump_takes_tab?
        end
        window = state.window
        count = window.buffer.line_count
        row = jumps.rows[at].to_i
        row = count - 1 if row >= count
        row = 0 if row < 0
        col = jumps.cols[at].to_i
        col = 0 if col < 0
        col = state.clamp_col(row, col)
        window.cursor.move_to(row, col)
        Outcome.none
      end
    end
  end
end
