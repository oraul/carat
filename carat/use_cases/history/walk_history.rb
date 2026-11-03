require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/undo_tree"
require_relative "../../domain/transaction"
require_relative "../../domain/messages"
require_relative "../../ports/clock_port"
require_relative "../outcome"

module Carat
  module UseCases
    # Walks the current buffer along a path through its undo tree, the
    # replay every undo command shares: a negative step undoes the current
    # state, a positive one redoes that state. The walk runs inside one
    # history transaction on the buffer, which observers see as a change
    # and which becomes no undo state; the buffer is unmodified again when
    # the walk ends on the state of the last write. The cursor and the
    # message follow Neovim's u_undoredo and u_undo_end: the cursor goes
    # to the first changed line, at the position before the change when
    # the change started there; the message counts the lines put back and
    # taken out and names the last state undone ("before") or redone
    # ("after") with how long ago it was made, read from the clock. An
    # empty path is the end of the history: undoing says the oldest change
    # is reached, redoing the newest, and :undo N (absolute) nothing.
    class WalkHistory
      OLDEST = "Already at oldest change"
      NEWEST = "Already at newest change"
      FAR = 1 << 30
      private_constant :OLDEST, :NEWEST, :FAR

      attr_reader :clock #: Ports::ClockPort

      # @rbs @gone: Integer
      # @rbs @back: Integer
      # @rbs @empty_before: bool

      #: (clock: Ports::ClockPort) -> void
      def initialize(clock:)
        @clock = clock
        @gone = 0
        @back = 0
        @empty_before = false
      end

      # For :undo N (absolute) the message names the state reached when
      # the last step undid one.
      #: (Domain::EditorState, Array[Integer], bool, bool) -> Outcome
      def call(state, path, undoing, absolute)
        if path.empty?
          return Outcome.none if absolute
          return Outcome.success(undoing ? OLDEST : NEWEST)
        end
        tree = state.buffer.undo
        start(state)
        undid = false
        seq = 0
        i = 0
        while i < path.length
          target = path[i]
          if target < 0
            seq = tree.current
            step(state, tree.undo_step, true)
            undid = true
          else
            seq = target
            step(state, tree.redo_to(target), false)
            undid = false
          end
          i += 1
        end
        return finish(state, false, tree.current) if absolute && undid && tree.current != tree.root
        finish(state, undid, seq)
      end

      private

      # Opens the history transaction and clears the line counts.
      #: (Domain::EditorState) -> void
      def start(state)
        buffer = state.buffer
        @gone = 0
        @back = 0
        @empty_before = empty?(buffer)
        buffer.begin_history(state.cursor.position)
      end

      # Applies one state backwards (undo) or forwards and puts the cursor
      # where Neovim does: on the first changed line of the topmost record,
      # or at the cursor before the change when that falls inside the
      # record's lines; one line up when that leaves it just below the
      # cursor before the change; then the column before the change on the
      # line the change started, the first non-blank otherwise.
      #: (Domain::EditorState, Domain::Transaction, bool) -> void
      def step(state, done, undo)
        buffer = state.buffer
        if undo
          buffer.revert(done)
        else
          buffer.reapply(done)
        end
        before = done.before
        row = state.cursor.row
        best = FAR
        n = done.size
        k = 0
        while k < n
          change = done.record_at(undo ? n - 1 - k : k)
          now_lines = undo ? change.removed : change.inserted
          was = undo ? change.inserted : change.removed
          @gone += was.length
          @back += now_lines.length
          top = change.row
          size = now_lines.length
          if top < best
            if before.row >= top - 1 && before.row <= top + size
              row = before.row
              best = before.row
            else
              same = 0
              limit = size < was.length ? size : was.length
              same += 1 while same < limit && now_lines[same] == was[same]
              if same == size && best == FAR && k == n - 1
                row = top
                best = top
              elsif same < size
                row = top + same
                best = top + same
              end
            end
          end
          k += 1
        end
        row -= 1 if before.row + 1 == row && row > 0
        count = buffer.line_count
        if row >= count
          state.cursor.move_to(count - 1, 0)
        elsif before.row == row
          state.cursor.move_to(row, state.clamp_col(row, before.col))
        else
          state.cursor.move_to(row, buffer.first_nonblank(row))
        end
      end

      # Closes the history transaction, settles the modified flag, and
      # builds Neovim's message for the walk.
      #: (Domain::EditorState, bool, Integer) -> Outcome
      def finish(state, undid, seq)
        buffer = state.buffer
        buffer.commit_transaction(state.cursor.position)
        buffer.settle_saved
        gone = @gone
        back = @back
        gone -= 1 if @empty_before && gone > 0
        back -= 1 if empty?(buffer) && back > 0
        net = gone - back
        counted = ""
        if net == -1
          counted = "1 more line"
        elsif net < 0
          counted = "#{-net} more lines"
        elsif net == 1
          counted = "1 line less"
        elsif net > 1
          counted = "#{net} fewer lines"
        else
          counted = back == 1 ? "1 change" : "#{back} changes"
        end
        time = buffer.undo.time_of(seq)
        Outcome.success("#{counted}; #{undid ? "before" : "after"} ##{seq}  #{Domain::Messages.seconds_ago(@clock.now - time)}")
      end

      # Whether the buffer holds one empty line, which Neovim counts as no
      # line at all.
      #: (Domain::Buffer) -> bool
      def empty?(buffer)
        buffer.line_count == 1 && buffer.line(0).empty?
      end
    end
  end
end
