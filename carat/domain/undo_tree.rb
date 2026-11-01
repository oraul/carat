require_relative "transaction"

module Carat
  module Domain
    # The undo history of one buffer as Vim keeps it: a tree of text
    # states. Every closed transaction becomes a state with the next
    # sequence number (1, 2, ...), made on top of the state the text showed
    # then, its parent; numbers are never reused, so they are the time
    # order. The root stands for the text before the oldest state kept; it
    # is not a slot of the table, its number is root (0 until trimming
    # merges states into it).
    #
    # The table is flat, parallel arrays indexed by number - base, so every
    # walk is over integers: parents (the parent's number, -1 for a dropped
    # slot), heads (the child Ctrl-R follows, -1 for none), children (the
    # count of live children), depths (the changes from the original text),
    # saves (the write number, 0 for none), times (seconds when the state
    # closed), and transactions (Array[untyped], read through
    # transaction_at). current is the state the text shows, last the
    # highest number given, saved the state at the last write (-1 for none,
    # or last + 1 for a transaction still open at the write, which
    # pending_save numbers). live counts the states kept.
    #
    # It also keeps the line "U" restores: line_row (-1 for none), the text
    # it had before the latest run of changes on it, and the cursor column
    # then. A Struct record: mutable, with a reader and a writer per member.
    class UndoTree < Struct.new(:base, :parents, :heads, :children, :depths, :saves, :times, :transactions, :root, :root_head, :root_children, :root_depth, :current, :last, :saved, :pending_save, :save_count, :live, :line_row, :line_text, :line_col)
      # @rbs @base: Integer
      # @rbs @parents: Array[Integer]
      # @rbs @heads: Array[Integer]
      # @rbs @children: Array[Integer]
      # @rbs @depths: Array[Integer]
      # @rbs @saves: Array[Integer]
      # @rbs @times: Array[Float]
      # @rbs @transactions: Array[untyped]
      # @rbs @root: Integer
      # @rbs @root_head: Integer
      # @rbs @root_children: Integer
      # @rbs @root_depth: Integer
      # @rbs @current: Integer
      # @rbs @last: Integer
      # @rbs @saved: Integer
      # @rbs @pending_save: Integer
      # @rbs @save_count: Integer
      # @rbs @live: Integer
      # @rbs @line_row: Integer
      # @rbs @line_text: String
      # @rbs @line_col: Integer

      DROPPED = -1

      # An empty history: the text is the original, which counts as saved.
      # The lists are stored through the writers, so they take the pinned
      # types.
      #: () -> void
      def initialize
        super()
        self.base = 1
        self.parents = []
        self.heads = []
        self.children = []
        self.depths = []
        self.saves = []
        self.times = []
        self.transactions = []
        self.root = 0
        self.root_head = -1
        self.root_children = 0
        self.root_depth = 0
        self.current = 0
        self.last = 0
        self.saved = 0
        self.pending_save = 0
        self.save_count = 0
        self.live = 0
        self.line_row = -1
        self.line_text = ""
        self.line_col = 0
      end

      # ------------------------------------------------------------ states

      # The slot of a state's number, or -1 when it is the root, out of
      # the table, or dropped.
      #: (Integer) -> Integer
      def slot(seq)
        i = seq - base
        return -1 if i < 0 || i >= parents.length
        parents[i] == DROPPED ? -1 : i
      end

      # Whether the number names the root or a kept state.
      #: (Integer) -> bool
      def live?(seq)
        seq == root || slot(seq) >= 0
      end

      #: (Integer) -> Transaction
      def transaction_at(i)
        transactions[i]
      end

      # The parent of a kept state.
      #: (Integer) -> Integer
      def parent_of(seq)
        parents[seq - base]
      end

      # The child Ctrl-R follows from a state or the root, -1 for none.
      #: (Integer) -> Integer
      def head_of(seq)
        return root_head if seq == root
        i = slot(seq)
        i < 0 ? -1 : heads[i]
      end

      # The changes from the original text to the state.
      #: (Integer) -> Integer
      def depth_of(seq)
        return root_depth if seq == root
        depths[seq - base]
      end

      # When the state closed, 0.0 for the root.
      #: (Integer) -> Float
      def time_of(seq)
        i = slot(seq)
        i < 0 ? 0.0 : times[i]
      end

      # The write number of the state, 0 when it was not written.
      #: (Integer) -> Integer
      def save_of(seq)
        i = slot(seq)
        i < 0 ? 0 : saves[i]
      end

      # Whether the text shows the state of the last write.
      #: () -> bool
      def at_saved?
        current == saved
      end

      # ------------------------------------------------------------- edits

      # Keeps a closed transaction as the next state, on top of the
      # current one, made at now; then drops the oldest states while more
      # than levels are kept. The new state is current, its parent's head,
      # and the saved state when a write happened while it was open.
      #: (Transaction, Float, Integer) -> void
      def push(done, now, levels)
        seq = last + 1
        self.last = seq
        parent = current
        parents << parent
        heads << -1
        children << 0
        depths << depth_of(parent) + 1
        saves << pending_save
        times << now
        transactions << done
        self.pending_save = 0
        set_head(parent, seq)
        add_child(parent, 1)
        self.current = seq
        self.live = live + 1
        note_line(done)
        trim(levels)
      end

      # The state u would undo, -1 at the root.
      #: () -> Integer
      def undo_seq
        current == root ? -1 : current
      end

      # The state Ctrl-R would redo, -1 when there is none.
      #: () -> Integer
      def redo_seq
        head_of(current)
      end

      # Moves to the parent of the current state and returns the
      # transaction to revert; the parent's head stays on the undone state
      # so Ctrl-R comes back to it. The caller checks undo_seq first.
      #: () -> Transaction
      def undo_step
        i = slot(current)
        done = transaction_at(i)
        parent = parents[i]
        set_head(parent, current)
        self.current = parent
        done
      end

      # Moves to a child of the current state, which becomes its head, and
      # returns the transaction to apply again.
      #: (Integer) -> Transaction
      def redo_to(child)
        set_head(current, child)
        self.current = child
        transaction_at(slot(child))
      end

      # The steps from the current state to target: a negative number
      # undoes the current state, a positive one redoes that state. Both
      # ends walk up by their parents, the higher number first (a parent's
      # number is lower than its children's), until they meet.
      #: (Integer) -> Array[Integer]
      def path_to(target)
        a = current
        b = target
        ups = []
        downs = []
        while a != b
          if a > b
            ups << -a
            a = parent_of(a)
          else
            downs << b
            b = parent_of(b)
          end
        end
        i = downs.length - 1
        while i >= 0
          ups << downs[i]
          i -= 1
        end
        ups
      end

      # The kept state nearest to target: at or before it when older,
      # at or after it otherwise; the root when nothing older is kept, and
      # -1 when nothing newer is.
      #: (Integer, bool) -> Integer
      def nearest(target, older)
        return root if target <= root
        if older
          seq = target
          while seq > root
            return seq if live?(seq)
            seq -= 1
          end
          return root
        end
        seq = target
        while seq <= last
          return seq if live?(seq)
          seq += 1
        end
        -1
      end

      # The kept states without children, in number order.
      #: () -> Array[Integer]
      def leaves
        result = []
        i = 0
        while i < parents.length
          result << base + i if parents[i] != DROPPED && children[i] == 0
          i += 1
        end
        result
      end

      # ------------------------------------------------------------ writes

      # Records a write: the current state is the saved one, or, when
      # pending (the buffer's open transaction already has records), the
      # state that transaction will become when it closes.
      #: (bool) -> void
      def mark_saved(pending)
        self.save_count = save_count + 1
        if pending
          self.saved = last + 1
          self.pending_save = save_count
          return
        end
        self.saved = current
        self.pending_save = 0
        i = slot(current)
        saves[i] = save_count if i >= 0
      end

      # No state matches the file any more.
      #: () -> void
      def mark_unsaved
        self.saved = -1
        self.pending_save = 0
      end

      # ---------------------------------------------------------- the U line

      # Remembers the line "U" restores from a new state: when every record
      # replaces one line by one line on the same row, that row's line
      # before the change, unless the row is the one already saved; a
      # change that inserts or removes lines, or touches several rows,
      # forgets it.
      #: (Transaction) -> void
      def note_line(done)
        row = -1
        i = 0
        while i < done.size
          change = done.record_at(i)
          if change.removed.length != 1 || change.inserted.length != 1 || (row >= 0 && change.row != row)
            self.line_row = -1
            return
          end
          row = change.row
          i += 1
        end
        return if row < 0 || row == line_row
        self.line_row = row
        self.line_text = done.record_at(0).removed[0]
        before = done.before
        self.line_col = before.row == row ? before.col : 0
      end

      private

      #: (Integer, Integer) -> void
      def set_head(seq, child)
        if seq == root
          self.root_head = child
        else
          i = slot(seq)
          heads[i] = child if i >= 0
        end
      end

      #: (Integer, Integer) -> void
      def add_child(seq, delta)
        if seq == root
          self.root_children = root_children + delta
        else
          i = slot(seq)
          children[i] = children[i] + delta if i >= 0
        end
      end

      # Drops the oldest states while more than levels are kept: one on
      # the way to the current state merges into the root, any other is
      # dropped with every state made on it.
      #: (Integer) -> void
      def trim(levels)
        while live > levels && live > 0
          oldest = first_live
          if on_current_path?(oldest)
            merge(oldest)
          else
            drop(oldest)
          end
          compact
        end
      end

      # The number of the oldest kept state. The oldest is always a child
      # of the root.
      #: () -> Integer
      def first_live
        i = 0
        i += 1 while i < parents.length && parents[i] == DROPPED
        base + i
      end

      # Whether the current state is seq or made on top of it, for a child
      # of the root.
      #: (Integer) -> bool
      def on_current_path?(seq)
        return false if current == root
        return true if root_children == 1
        a = current
        a = parent_of(a) while parent_of(a) != root
        a == seq
      end

      # The child of the root on the way to the current state becomes the
      # root: the root's other children go with their states.
      #: (Integer) -> void
      def merge(seq)
        if root_children > 1
          i = 0
          while i < parents.length
            other = base + i
            drop(other) if parents[i] == root && other != seq
            i += 1
          end
        end
        i = seq - base
        self.root = seq
        self.root_head = heads[i]
        self.root_children = children[i]
        self.root_depth = depths[i]
        release(i)
      end

      # Drops a state and every state made on it; the parent counts one
      # child less and forgets it as its head.
      #: (Integer) -> void
      def drop(seq)
        parent = parent_of(seq)
        add_child(parent, -1)
        set_head(parent, -1) if head_of(parent) == seq
        start = seq - base
        release(start)
        i = start + 1
        while i < parents.length
          p = parents[i]
          release(i) if p != DROPPED && p != root && parents[p - base] == DROPPED
          i += 1
        end
      end

      # Marks a slot dropped and lets its transaction go.
      #: (Integer) -> void
      def release(i)
        parents[i] = DROPPED
        transactions[i] = nil
        self.live = live - 1
      end

      # Removes the dropped slots at the front of the table.
      #: () -> void
      def compact
        while !parents.empty? && parents[0] == DROPPED
          parents.shift
          heads.shift
          children.shift
          depths.shift
          saves.shift
          times.shift
          transactions.shift
          self.base = base + 1
        end
      end
    end
  end
end
