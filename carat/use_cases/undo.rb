require_relative "../domain/editor_state"
require_relative "../domain/buffer"
require_relative "../domain/undo_tree"
require_relative "../domain/transaction"
require_relative "../ports/clock_port"
require_relative "outcome"

module Carat
  module UseCases
    # Moves the current buffer through its undo tree: u and Ctrl-R along
    # the current branch, :undo N to a numbered state, g-, g+, :earlier,
    # and :later in time order across branches, U on the last changed line,
    # and :undolist. Every walk runs inside one history transaction on the
    # buffer, which observers see as a change and which becomes no undo
    # state; the buffer is unmodified again when the walk ends on the state
    # of the last write. The cursor and the message follow Neovim's
    # u_undoredo and u_undo_end: the cursor goes to the first changed line,
    # at the position before the change when the change started there; the
    # message counts the lines put back and taken out and names the last
    # state undone ("before") or redone ("after") with how long ago it was
    # made.
    class Undo
      OLDEST = "Already at oldest change"
      NEWEST = "Already at newest change"
      FAR = 1 << 30
      LIST_TITLE = "number changes  when               saved"

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

      # u: count states back along the current branch.
      #: (Domain::EditorState, Integer) -> Outcome
      def undo(state, count)
        tree = state.buffer.undo
        return Outcome.success(OLDEST) if tree.undo_seq < 0
        start(state)
        seq = 0
        done = 0
        while done < count && tree.undo_seq >= 0
          seq = tree.current
          step(state, tree.undo_step, true)
          done += 1
        end
        finish(state, true, seq)
      end

      # Ctrl-R: count states forward along the current branch.
      #: (Domain::EditorState, Integer) -> Outcome
      def redo(state, count)
        tree = state.buffer.undo
        return Outcome.success(NEWEST) if tree.redo_seq < 0
        start(state)
        seq = 0
        done = 0
        while done < count && tree.redo_seq >= 0
          seq = tree.redo_seq
          step(state, tree.redo_to(seq), false)
          done += 1
        end
        finish(state, false, seq)
      end

      # :undo N: the text after state number, 0 for the original text.
      #: (Domain::EditorState, Integer) -> Outcome
      def to(state, number)
        tree = state.buffer.undo
        unless number == 0 || (number <= tree.last && tree.live?(number))
          return Outcome.failure("E830: Undo number #{number} not found")
        end
        walk(state, tree.path_to(number == 0 ? tree.root : number), true)
      end

      # g-, g+, :earlier, and :later: steps states back (negative) or
      # forward in the order they were made, across branches.
      #: (Domain::EditorState, Integer) -> Outcome
      def travel(state, steps)
        tree = state.buffer.undo
        if steps < 0
          return Outcome.success(OLDEST) if tree.current == tree.root
          target = tree.nearest(tree.current + steps, true)
        else
          return Outcome.success(NEWEST) if tree.current >= tree.last
          wanted = tree.current + steps
          wanted = tree.last if wanted > tree.last
          target = tree.nearest(wanted, false)
          return Outcome.success(NEWEST) if target < 0
        end
        walk(state, tree.path_to(target), false)
      end

      # U: the line saved before the latest run of changes on it is put
      # back, as a change of its own; the replaced text becomes the saved
      # one, so U undoes U. Nothing when no line is saved.
      #: (Domain::EditorState) -> Outcome
      def line(state)
        buffer = state.buffer
        tree = buffer.undo
        row = tree.line_row
        return Outcome.none if row < 0 || row >= buffer.line_count
        cursor = state.cursor
        old = buffer.line(row)
        col = tree.line_col
        buffer.set_lines(row, row + 1, [tree.line_text])
        tree.line_text = old
        tree.line_col = cursor.col if cursor.row == row
        cursor.move_to(row, clamp(state, row, col))
        Outcome.none
      end

      # :undolist: one line per state without later states on its branch.
      #: (Domain::EditorState) -> Outcome
      def list(state)
        tree = state.buffer.undo
        leaves = tree.leaves
        return Outcome.success("Nothing to undo") if leaves.empty?
        now = @clock.now
        text = LIST_TITLE
        i = 0
        while i < leaves.length
          seq = leaves[i]
          row = seq.to_s.rjust(6) + " " + (tree.depth_of(seq) - tree.root_depth).to_s.rjust(7) + "  " + ago(now - tree.time_of(seq))
          save = tree.save_of(seq)
          row = row.ljust(33) + "  " + save.to_s.rjust(3) if save > 0
          text = text + "\n" + row
          i += 1
        end
        Outcome.success(text)
      end

      private

      # Runs the steps of a path: negative undoes the current state,
      # positive redoes that state. For :undo N the message names the state
      # reached when the last step undid one.
      #: (Domain::EditorState, Array[Integer], bool) -> Outcome
      def walk(state, path, absolute)
        return Outcome.none if path.empty?
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
          state.cursor.move_to(row, clamp(state, row, before.col))
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
        Outcome.success("#{counted}; #{undid ? "before" : "after"} ##{seq}  #{ago(@clock.now - time)}")
      end

      # How long ago, in seconds, as Neovim writes it under 100 seconds.
      #: (Float) -> String
      def ago(seconds)
        whole = seconds.to_i
        whole = 0 if whole < 0
        whole == 1 ? "1 second ago" : "#{whole} seconds ago"
      end

      # Whether the buffer holds one empty line, which Neovim counts as no
      # line at all.
      #: (Domain::Buffer) -> bool
      def empty?(buffer)
        buffer.line_count == 1 && buffer.line(0).empty?
      end

      #: (Domain::EditorState, Integer, Integer) -> Integer
      def clamp(state, row, col)
        max = state.max_col(row)
        col > max ? max : col
      end
    end
  end
end
