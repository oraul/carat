require_relative "window"
require_relative "tab_page"

module Carat
  module Domain
    # The tab pages of the editor in order, which one is current, and the
    # id the next window to enter a tab page receives. Every window gets
    # its id once, here, and keeps it for as long as the editor runs. The
    # tab list also keeps the cursors of the windows inside their text:
    # the buffer feed reports every closed transaction with its first
    # changed row, and the cursors on or below it are clamped. A Struct
    # record: mutable, with a reader and a writer per member.
    class TabList < Struct.new(:pages, :tab_index, :next_window_id)
      # @rbs @pages: Array[untyped]
      # @rbs @tab_index: Integer
      # @rbs @next_window_id: Integer

      # One tab page with the first window, which gets the first id. The
      # list is stored through the writer, so it takes the pinned type.
      #: (Window) -> void
      def initialize(first)
        super()
        self.pages = []
        self.next_window_id = 1
        adopt(first)
        pages << TabPage.new(first)
        self.tab_index = 0
      end

      # ------------------------------------------------------- current view

      #: () -> TabPage
      def tab
        tab_at(tab_index)
      end

      #: () -> Window
      def window
        tab.window
      end

      # --------------------------------------------------------- tab pages

      #: (Integer) -> TabPage
      def tab_at(index)
        pages[index]
      end

      #: () -> Integer
      def tab_count
        pages.length
      end

      # Inserts a tab page after the current one and makes it current.
      #: (TabPage) -> void
      def add_tab(page)
        adopt(page.window)
        pages.insert(tab_index + 1, page)
        self.tab_index = tab_index + 1
      end

      # Removes the tab page at index. When it was the current one, the one
      # after it becomes current, or the one before it when it was last, as
      # Neovim's alt_tabpage picks; otherwise the current one stays current.
      #: (Integer) -> void
      def remove_tab(index)
        pages.delete_at(index)
        self.tab_index = tab_index - 1 if index < tab_index
        self.tab_index = pages.length - 1 if tab_index > pages.length - 1
      end

      # Goes to tab page number n (1-based) when it exists; with 0, to the
      # next one, wrapping. Returns whether the current tab page changed.
      #: (Integer) -> bool
      def next_tab(n)
        if n == 0
          self.tab_index = (tab_index + 1) % pages.length
          return true
        end
        return false if n > pages.length
        self.tab_index = n - 1
        true
      end

      # Goes n tab pages back, wrapping; 0 counts as 1.
      #: (Integer) -> void
      def previous_tab(n)
        steps = n > 0 ? n : 1
        self.tab_index = (tab_index - steps) % pages.length
      end

      # ------------------------------------------------------------ windows

      # Gives a window that has none the next window id, which it keeps
      # for as long as the editor runs; no other window ever gets it.
      #: (Window) -> void
      def adopt(target)
        return unless target.id == 0
        target.id = next_window_id
        self.next_window_id = next_window_id + 1
      end

      # The index of the tab page holding the window with the id, or -1.
      #: (Integer) -> Integer
      def window_tab(id)
        t = 0
        while t < pages.length
          return t if tab_at(t).layout.leaf_of(id) >= 0
          t += 1
        end
        -1
      end

      # The number of windows over every tab page.
      #: () -> Integer
      def total_windows
        total = 0
        t = 0
        while t < pages.length
          total += tab_at(t).window_count
          t += 1
        end
        total
      end

      # Whether some window of some tab page shows the buffer.
      #: (Buffer) -> bool
      def shown?(target)
        t = 0
        while t < pages.length
          layout = tab_at(t).layout
          ids = layout.leaves
          i = 0
          while i < ids.length
            return true if layout.window_at(ids[i]).buffer.equal?(target)
            i += 1
          end
          t += 1
        end
        false
      end

      # Keeps the cursor of every window showing the buffer with the id
      # inside its text after a change from row on: a cursor on or below
      # that row moves onto the last line and the line's last character
      # when it is past them, and a scroll position past the end returns
      # to the top. Cursors above the row stay, since their lines did not
      # change. The buffer feed calls it for every closed transaction.
      #: (Integer, Integer) -> void
      def clamp_cursors(buffer_id, row)
        t = 0
        while t < pages.length
          layout = tab_at(t).layout
          ids = layout.leaves
          i = 0
          while i < ids.length
            current = layout.window_at(ids[i])
            target = current.buffer
            clamp_window(current, target) if target.id == buffer_id && current.cursor.row >= row
            i += 1
          end
          t += 1
        end
      end

      private

      #: (Window, Buffer) -> void
      def clamp_window(current, target)
        cursor = current.cursor
        last = target.line_count - 1
        cursor.row = last if cursor.row > last
        max = target.line(cursor.row).length
        max = max > 0 ? max - 1 : 0
        cursor.col = max if cursor.col > max
        current.top = 0 if current.top > last
      end
    end
  end
end
