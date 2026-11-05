require_relative "position"
require_relative "buffer"
require_relative "buffer_feed"
require_relative "tab_list"

module Carat
  module Domain
    # The listed buffers in order, the id the next buffer to enter the
    # list receives, and the buffer feed, where the list records buffers
    # opening and closing and every listed buffer its renames and closed
    # transactions, for the plugin host. It holds the keep or release
    # policy: a file buffer stays listed, hidden when no window shows it,
    # until :bd deletes it, as Neovim keeps it with 'hidden' on, so no
    # edit is lost and the buffer keeps its number; a scratch buffer
    # leaves as soon as no window shows it. The feed
    # reports closed transactions to the tab list, which keeps the cursors
    # inside the text. A Struct record: mutable, with a reader and a writer
    # per member.
    class BufferList < Struct.new(:tabs, :buffers, :next_id, :feed, keyword_init: true)
      # @rbs @tabs: TabList
      # @rbs @buffers: Array[untyped]
      # @rbs @next_id: Integer
      # @rbs @feed: BufferFeed

      # An empty list over the tab list. The list is stored through the
      # writer, so it takes the pinned type.
      #: (tabs: TabList) -> void
      def initialize(tabs:)
        super()
        self.tabs = tabs
        self.buffers = []
        self.next_id = 1
        self.feed = BufferFeed.new
        feed.tabs = tabs
      end

      #: (Integer) -> Buffer
      def buffer_at(index)
        buffers[index]
      end

      #: () -> Integer
      def count
        buffers.length
      end

      # The position of a buffer in the list by identity, or -1. Identity,
      # not value: two unnamed empty buffers are equal by value.
      #: (Buffer) -> Integer
      def index_of(target)
        i = 0
        while i < buffers.length
          return i if buffer_at(i).equal?(target)
          i += 1
        end
        -1
      end

      # The 1-based list position of a buffer, or 0 when it is not listed.
      #: (Buffer) -> Integer
      def number_of(target)
        index_of(target) + 1
      end

      # The listed buffer with that path, or nil.
      #: (String) -> Buffer?
      def for_path(path)
        i = 0
        while i < buffers.length
          candidate = buffer_at(i)
          return candidate if candidate.path == path
          i += 1
        end
        nil
      end

      # The listed buffer with the id, or nil.
      #: (Integer) -> Buffer?
      def with_id(id)
        i = 0
        while i < buffers.length
          candidate = buffer_at(i)
          return candidate if candidate.id == id
          i += 1
        end
        nil
      end

      # The listed scratch buffer a plugin owns with that title, or nil.
      #: (String, String) -> Buffer?
      def scratch_for(owner, title)
        i = 0
        while i < buffers.length
          candidate = buffer_at(i)
          return candidate if candidate.owner == owner && candidate.title == title
          i += 1
        end
        nil
      end

      # The first modified buffer in the list, or nil. A scratch buffer is
      # never unsaved work, however its lines changed.
      #: () -> Buffer?
      def modified_buffer
        i = 0
        while i < buffers.length
          candidate = buffer_at(i)
          return candidate if candidate.modified? && !candidate.scratch?
          i += 1
        end
        nil
      end

      #: () -> bool
      def any_modified?
        !modified_buffer.nil?
      end

      # The first modified file buffer in Neovim's check_changed_any
      # order: the current buffer, those of the current tab page's
      # windows, those of the other tab pages, then the list; only the
      # buffers no window shows when hidden_only is true. Nil when none.
      #: (bool) -> Buffer?
      def first_unsaved(hidden_only)
        return hidden_modified if hidden_only
        shown = tabs.modified_in_windows
        return shown unless shown.nil?
        modified_buffer
      end

      # Shows target to the user: focuses the first window that shows it,
      # in its tab page, or shows it in the current window.
      #: (Buffer) -> void
      def bring(target)
        return if tabs.window.buffer.equal?(target)
        load(target) unless tabs.focus_buffer(target)
      end

      # The listed file buffer steps places after target, or before it
      # when steps is negative, wrapping and skipping scratch buffers;
      # target itself for 0 when it is a file buffer, else the next one.
      # Nil when the list holds no file buffer, as Neovim's do_buffer
      # answers E85.
      #: (Buffer, Integer) -> Buffer?
      def step_from(target, steps)
        n = buffers.length
        return nil if n == 0
        i = index_of(target)
        i = 0 if i < 0
        forward = steps >= 0
        count = forward ? steps : -steps
        files = file_count
        count = (count - 1) % files + 1 if files > 0 && count > files
        start = -1
        while count > 0 || buffer_at(i).scratch?
          start = i if start < 0
          i = forward ? (i + 1) % n : (i - 1 + n) % n
          unless buffer_at(i).scratch?
            count -= 1
            start = -1
          end
          return nil if i == start
        end
        buffer_at(i)
      end

      # How many file buffers the list holds, scratch buffers left out.
      #: () -> Integer
      def file_count
        total = 0
        i = 0
        while i < buffers.length
          total += 1 unless buffer_at(i).scratch?
          i += 1
        end
        total
      end

      # The listed file buffer after target in the list, or the last one
      # before it, which :bd shows in place of target; nil when target is
      # the only one.
      #: (Buffer) -> Buffer?
      def replacement_for(target)
        index = index_of(target)
        i = index + 1
        while i < buffers.length
          return buffer_at(i) unless buffer_at(i).scratch?
          i += 1
        end
        i = index - 1
        while i >= 0
          return buffer_at(i) unless buffer_at(i).scratch?
          i -= 1
        end
        nil
      end

      # The first modified buffer no window shows, or nil.
      #: () -> Buffer?
      def hidden_modified
        i = 0
        while i < buffers.length
          candidate = buffer_at(i)
          return candidate if candidate.modified? && !candidate.scratch? && !tabs.shown?(candidate)
          i += 1
        end
        nil
      end

      # Lists a buffer that is not listed yet. A buffer entering the list
      # for the first time receives the next id, which it keeps for as
      # long as the editor runs, also after leaving the list.
      #: (Buffer) -> void
      def add(target)
        return if index_of(target) >= 0
        if target.id == 0
          target.id = next_id
          self.next_id = next_id + 1
        end
        buffers << target
        target.feed = feed
        feed.note("open", target.id, target.path_text, "")
      end

      #: (Buffer) -> void
      def remove(target)
        index = index_of(target)
        return if index < 0
        buffers.delete_at(index)
        feed.note("close", target.id, target.path_text, "")
      end

      # Lets go of a buffer a window stopped showing: a scratch buffer no
      # window shows leaves the list; a file buffer stays, hidden.
      #: (Buffer) -> void
      def release(target)
        remove(target) if target.scratch? && !tabs.shown?(target)
      end

      # Shows a buffer in the current window, listing it if needed, with
      # the cursor where a window last left it. The buffer the window
      # showed remembers the cursor and stays listed, unless it is a
      # scratch buffer no window shows. A buffer never listed takes the
      # number of an unnamed, empty, unmodified buffer only this window
      # shows, which leaves the list first, as Neovim reuses it.
      #: (Buffer) -> void
      def load(target)
        current = tabs.window
        old = current.buffer
        return if old.equal?(target)
        remember(current)
        if target.id == 0 && reusable?(old)
          remove(old)
          target.id = old.id
        end
        add(target)
        current.show(target)
        restore(current)
        release(old)
      end

      # Removes window id from the tab page at index, closing the tab page
      # when it was the last window there, and lets go of the buffer it
      # showed. The caller has checked that another window exists
      # somewhere.
      #: (Integer, Integer) -> void
      def close_window(index, id)
        tab = tabs.tab_at(index)
        layout = tab.layout
        remember(layout.window_at(id))
        shown = layout.window_at(id).buffer
        if layout.leaf_count <= 1
          tabs.remove_tab(index)
        else
          taker = layout.close(id)
          tab.current = layout.first_leaf(taker) if id == tab.current
          tab.previous = -1 if tab.previous == id
        end
        release(shown)
      end

      # Removes the tab page at index and lets go of every buffer its
      # windows showed. The caller has checked that another tab page
      # exists.
      #: (Integer) -> void
      def close_tab(index)
        layout = tabs.tab_at(index).layout
        ids = layout.leaves
        held = []
        i = 0
        while i < ids.length
          remember(layout.window_at(ids[i]))
          held << layout.window_at(ids[i]).buffer
          i += 1
        end
        tabs.remove_tab(index)
        i = 0
        while i < held.length
          release(held[i])
          i += 1
        end
      end

      # Closes every window that shows target in every tab page but the
      # current window, a tab page closing with its last window; the walk
      # starts over after each close, since a tab page may go.
      #: (Buffer) -> void
      def close_windows_of(target)
        closed = true
        while closed
          closed = false
          t = 0
          while t < tabs.tab_count && !closed
            layout = tabs.tab_at(t).layout
            ids = layout.leaves
            i = 0
            while i < ids.length && !closed
              current = t == tabs.tab_index && ids[i] == tabs.tab.current
              if !current && layout.window_at(ids[i]).buffer.equal?(target)
                close_window(t, ids[i])
                closed = true
              end
              i += 1
            end
            t += 1
          end
        end
      end

      private

      # Records where the window's cursor is in the buffer it shows.
      #: (Window) -> void
      def remember(window)
        cursor = window.cursor
        window.buffer.last_cursor = Position.new(row: cursor.row, col: cursor.col)
      end

      # Puts the window's cursor where its buffer remembers, inside the
      # text: on the last line at most and on the line's last character.
      #: (Window) -> void
      def restore(window)
        target = window.buffer
        spot = target.last_cursor
        row = spot.row
        last = target.line_count - 1
        row = last if row > last
        max = target.line(row).length - 1
        max = 0 if max < 0
        col = spot.col > max ? max : spot.col
        window.cursor.move_to(row, col)
      end

      # Whether old is the unnamed, empty, unmodified file buffer of one
      # window, which a file opened over it replaces under its number.
      #: (Buffer) -> bool
      def reusable?(old)
        return false if !old.path.nil? || old.scratch? || old.modified? || old.id == 0
        old.line_count == 1 && old.line(0).empty? && tabs.windows_showing(old) <= 1
      end
    end
  end
end
