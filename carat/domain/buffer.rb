require_relative "position"
require_relative "range"
require_relative "line_splice"
require_relative "change_record"
require_relative "transaction"
require_relative "sign_layer"
require_relative "buffer_feed"

module Carat
  module Domain
    # The text of one file as an array of line strings without newlines,
    # plus path and line_ending. Every edit goes through the five
    # primitives insert, delete, replace, set_lines, and reload, which all
    # end in one private splice: it changes the line array in place through
    # LineSplice, counts one change in changes, and hands a ChangeRecord to
    # the open Transaction, or wraps it in a transaction of its own when
    # none is open. Nothing outside this file assigns or mutates lines; the
    # lint test enforces it. Lines are never mutated in place: every
    # primitive stores new strings, so records share them safely.
    #
    # modified is derived: the change counter differs from saved_change,
    # the counter at the last load, reload, or save. id is the stable
    # number the buffer list gives the buffer when it first enters it (0
    # until then). transaction is the open transaction, last_transaction
    # the last one closed with records, and closed_count how many have
    # closed: the hook the undo change consumes.
    #
    # A scratch buffer, one a plugin owns, has an owner (the plugin name,
    # empty for a file buffer), a title shown in place of the path, and a
    # keymap of its own that wins over the mode's keymap while the cursor
    # is in its window. Signs are kept per plugin in sign_layers, sorted by
    # the plugin's priority, each with one mark per line that the splice
    # moves with inserted and deleted lines. feed is the editor's buffer
    # feed while the buffer is listed (nil before): renames and closed
    # transactions are recorded there for the plugin host. A Struct
    # record: mutable, with a reader and a writer per member.
    class Buffer < Struct.new(:lines, :path, :line_ending, :saved_change, :owner, :title, :keymap, :sign_layers, :changes, :id, :transaction, :last_transaction, :closed_count, :feed)
      # @rbs @lines: Array[String]
      # @rbs @path: String?
      # @rbs @line_ending: String
      # @rbs @saved_change: Integer
      # @rbs @owner: String
      # @rbs @title: String
      # @rbs @keymap: Keymap?
      # @rbs @sign_layers: Array[untyped]
      # @rbs @changes: Integer
      # @rbs @id: Integer
      # @rbs @transaction: Transaction?
      # @rbs @last_transaction: Transaction?
      # @rbs @closed_count: Integer
      # @rbs @feed: BufferFeed?

      # The original members go through super and the later members
      # through the writers, so the empty sign list takes the pinned type.
      #: (Array[String], String?, String) -> void
      def initialize(lines, path, line_ending)
        lines << "" if lines.empty?
        super(lines, path, line_ending, 0)
        self.owner = ""
        self.title = ""
        self.keymap = nil
        self.sign_layers = []
        self.changes = 0
        self.id = 0
        self.transaction = nil
        self.last_transaction = nil
        self.closed_count = 0
        self.feed = nil
      end

      # Whether an edit changed the text since the last load, reload, or
      # save. Editing the text back does not clear it.
      #: () -> bool
      def modified?
        changes != saved_change
      end

      # The text now is the saved text: called by a write to the buffer's
      # own path and by reload.
      #: () -> void
      def mark_saved
        self.saved_change = changes
      end

      # No saved text matches the buffer any more, as when its file was
      # deleted: -1 is a number the change counter never reaches.
      #: () -> void
      def mark_unsaved
        self.saved_change = -1
      end

      # Whether a plugin owns the buffer: it is never written and never
      # counts as unsaved work.
      #: () -> bool
      def scratch?
        !owner.empty?
      end

      # The name the status line shows: the path, the scratch title, or
      # nil for an unnamed file buffer.
      #: () -> String?
      def display_name
        return path unless path.nil?
        title.empty? ? nil : title
      end

      # The path, or "" for a buffer without one.
      #: () -> String
      def path_text
        current = path
        current.nil? ? "" : current
      end

      # Gives the buffer a new path and records the rename in the feed,
      # with the old path, when the buffer is listed.
      #: (String) -> void
      def rename(new_path)
        old = path_text
        self.path = new_path
        sink = feed
        sink.note("rename", id, new_path, old) unless sink.nil? || old == new_path
      end

      # ------------------------------------------------------------- signs

      # Whether any sign is placed on the buffer.
      #: () -> bool
      def signs?
        !sign_layers.empty?
      end

      #: (Integer) -> SignLayer
      def layer_at(i)
        sign_layers[i]
      end

      # Places the glyph on the row in the owner's layer, which is made,
      # in priority order, when the owner has none yet. The row must be
      # inside the buffer.
      #: (String, Integer, Integer, String) -> void
      def place_sign(owner, priority, row, glyph)
        i = 0
        while i < sign_layers.length
          layer = layer_at(i)
          if layer.owner == owner
            layer.place(row, glyph)
            return
          end
          i += 1
        end
        fresh = SignLayer.new(owner, priority, lines.length)
        fresh.place(row, glyph)
        at = 0
        at += 1 while at < sign_layers.length && layer_at(at).priority <= priority
        sign_layers.insert(at, fresh)
        nil
      end

      # Removes the owner's signs and returns how many rows they marked.
      #: (String) -> Integer
      def clear_signs(owner)
        i = 0
        while i < sign_layers.length
          layer = layer_at(i)
          if layer.owner == owner
            count = layer.count
            sign_layers.delete_at(i)
            return count
          end
          i += 1
        end
        0
      end

      # The glyph shown on the row: the mark of the layer with the highest
      # priority that marks it, "" for none.
      #: (Integer) -> String
      def sign_at(row)
        i = 0
        while i < sign_layers.length
          glyph = layer_at(i).glyph_at(row)
          return glyph unless glyph.empty?
          i += 1
        end
        ""
      end

      # Splits file text into lines. The line ending is "\r\n" when the first
      # terminator is one, "\n" otherwise; a trailing terminator does not
      # produce an extra empty line.
      #: (String, String?) -> Buffer
      def self.from_text(text, path)
        first = text.index("\n")
        ending = "\n"
        ending = "\r\n" if !first.nil? && first > 0 && text[first - 1, 1] == "\r"
        body = ending == "\r\n" ? text.gsub("\r\n", "\n") : text
        lines = body.split("\n", -1)
        lines.pop if lines.length > 1 && lines.last == ""
        lines = [""] if lines.empty?
        new(lines, path, ending)
      end

      # The file text: every line followed by the line ending.
      #: () -> String
      def to_text
        lines.join(line_ending) + line_ending
      end

      #: () -> Integer
      def line_count
        lines.length
      end

      # The line at row, or an empty string outside the buffer.
      #: (Integer) -> String
      def line(row)
        l = lines[row]
        l.nil? ? "" : l
      end

      #: () -> Integer
      def byte_count
        to_text.bytesize
      end

      # The text of a charwise range, with "\n" between lines.
      #: (Range) -> String
      def text_of(range)
        r = range.normalized
        from = r.from
        to = r.to
        if from.row == to.row
          current = line(from.row)
          a = clamp_col(current, from.col)
          b = clamp_col(current, to.col)
          return b > a ? current[a, b - a] : ""
        end
        first = line(from.row)
        parts = [tail_of(first, clamp_col(first, from.col))]
        row = from.row + 1
        while row < to.row
          parts << line(row)
          row += 1
        end
        last = line(to.row)
        parts << last[0, clamp_col(last, to.col)]
        parts.join("\n")
      end

      # Copies of the lines from row from to row to, both inclusive.
      #: (Integer, Integer) -> Array[String]
      def lines_of(from, to)
        result = []
        row = from
        while row <= to
          result << line(row)
          row += 1
        end
        result
      end

      # The column of the first character of row that is not a space or a
      # tab, or the last column when the line is blank.
      #: (Integer) -> Integer
      def first_nonblank(row)
        text = line(row)
        i = 0
        i += 1 while i < text.length && (text[i, 1] == " " || text[i, 1] == "\t")
        i >= text.length ? (text.length > 0 ? text.length - 1 : 0) : i
      end

      # The leading spaces and tabs of row.
      #: (Integer) -> String
      def indent_of(row)
        text = line(row)
        i = 0
        i += 1 while i < text.length && (text[i, 1] == " " || text[i, 1] == "\t")
        text[0, i]
      end

      # Inserts text at pos; newlines in text split the line.
      #: (Position, String) -> void
      def insert(pos, text)
        return if text.empty?
        current = line(pos.row)
        col = clamp_col(current, pos.col)
        splice(pos.row, pos.row + 1, joined(current[0, col], text, tail_of(current, col)))
      end

      # Deletes a charwise range; a range spanning lines joins the remaining
      # head of the first line to the remaining tail of the last.
      #: (Range) -> void
      def delete(range)
        r = range.normalized
        from = r.from
        to = r.to
        first = line(from.row)
        last = line(to.row)
        head = first[0, clamp_col(first, from.col)]
        tail = tail_of(last, clamp_col(last, to.col))
        splice(from.row, to.row + 1, [head + tail])
      end

      # Replaces a charwise range with text in one step: one change, the
      # same text as deleting the range and inserting at its start.
      #: (Range, String) -> void
      def replace(range, text)
        r = range.normalized
        from = r.from
        to = r.to
        first = line(from.row)
        last = line(to.row)
        head = first[0, clamp_col(first, from.col)]
        tail = tail_of(last, clamp_col(last, to.col))
        splice(from.row, to.row + 1, joined(head, text, tail))
      end

      # Replaces the rows from..to (exclusive) with new_lines, keeping at
      # least one line in the buffer. The buffer takes new_lines over: the
      # caller passes an array built for the call and does not change it
      # afterwards.
      #: (Integer, Integer, Array[String]) -> void
      def set_lines(from, to, new_lines)
        splice(from, to, new_lines)
      end

      # Replaces the whole text with new_lines, as reading the file again
      # does: one change, after which the buffer is unmodified.
      #: (Array[String]) -> void
      def reload(new_lines)
        splice(0, lines.length, new_lines)
        mark_saved
      end

      # ------------------------------------------------------ transactions

      # Opens a transaction with the cursor position before the edits and
      # returns true, or returns false when one is already open: the caller
      # then joins it and must not close it.
      #: (Position) -> bool
      def begin_transaction(before)
        return false unless transaction.nil?
        self.transaction = Transaction.new(id, before)
        true
      end

      # Closes the open transaction with the cursor position after the
      # edits. One without records is dropped and not counted.
      #: (Position) -> void
      def commit_transaction(after)
        open = transaction
        return if open.nil?
        self.transaction = nil
        close(open, after) unless open.empty?
      end

      #: () -> bool
      def transaction_open?
        !transaction.nil?
      end

      # The number of records in the open transaction, 0 when none is open.
      #: () -> Integer
      def transaction_size
        open = transaction
        open.nil? ? 0 : open.size
      end

      # Undoes the records of the open transaction after the first count,
      # last first, without recording anything: the lines, the change
      # counter, and the signs return to how they were. The plugin host
      # uses it when applying a validated edit request still fails.
      #: (Integer) -> void
      def revert_to(count)
        open = transaction
        return if open.nil?
        i = open.size - 1
        while i >= count
          change = open.record_at(i)
          gone = change.inserted.length
          LineSplice.apply(lines, change.row, change.row + gone, change.removed)
          shift_signs(change.row, gone, change.removed.length)
          self.changes = changes - 1
          i -= 1
        end
        open.truncate(count)
      end

      private

      # The one place the line array changes. Clamps the rows into the
      # buffer, keeps at least one line, applies the splice in place,
      # counts the change, and records it. The record keeps new_lines
      # itself rather than a copy: every caller builds the array for the
      # call and never touches it afterwards.
      #: (Integer, Integer, Array[String]) -> void
      def splice(from, to, new_lines)
        count = lines.length
        a = from < 0 ? 0 : from
        a = count if a > count
        b = to > count ? count : to
        b = a if b < a
        inserted = new_lines
        inserted = [""] if inserted.empty? && a == 0 && b == count
        removed = lines[a, b - a]
        LineSplice.apply(lines, a, b, inserted)
        shift_signs(a, b - a, inserted.length)
        self.changes = changes + 1
        record(ChangeRecord.new(id, a, removed, inserted))
      end

      # Adds the record to the open transaction, or closes it in a
      # transaction of its own when none is open.
      #: (ChangeRecord) -> void
      def record(change)
        open = transaction
        unless open.nil?
          open.add(change, cause)
          return
        end
        at = Position.new(change.row, 0)
        single = Transaction.new(id, at)
        single.add(change, cause)
        close(single, at)
      end

      # The plugin whose call is running, "" for none or an unlisted
      # buffer.
      #: () -> String
      def cause
        sink = feed
        sink.nil? ? "" : sink.cause
      end

      # Keeps the closed transaction for the undo change and records its
      # span in the feed as a change.
      #: (Transaction, Position) -> void
      def close(done, after)
        done.after = after
        self.last_transaction = done
        self.closed_count = closed_count + 1
        sink = feed
        return if sink.nil?
        span = done.span
        notice = BufferNotice.new("change", id, path_text, "", done.cause)
        notice.row = span[0]
        notice.removed = span[1]
        notice.inserted = span[2]
        sink.push(notice)
      end

      # Moves every sign layer by an edit at row that replaced removed rows
      # with inserted ones.
      #: (Integer, Integer, Integer) -> void
      def shift_signs(row, removed, inserted)
        i = 0
        while i < sign_layers.length
          LineSplice.shift_marks(layer_at(i).marks, row, removed, inserted)
          i += 1
        end
      end

      # head, then text, then tail, split into lines at each newline of
      # text.
      #: (String, String, String) -> Array[String]
      def joined(head, text, tail)
        parts = text.split("\n", -1)
        return [head + text + tail] if parts.length <= 1
        result = [head + parts[0]]
        i = 1
        while i < parts.length - 1
          result << parts[i]
          i += 1
        end
        result << parts[parts.length - 1] + tail
        result
      end

      #: (String, Integer) -> Integer
      def clamp_col(text, col)
        return 0 if col < 0
        col > text.length ? text.length : col
      end

      #: (String, Integer) -> String
      def tail_of(text, col)
        col >= text.length ? "" : text[col, text.length - col]
      end
    end
  end
end
