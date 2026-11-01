require_relative "buffer"
require_relative "buffer_feed"
require_relative "tab_list"

module Carat
  module Domain
    # The listed buffers in order, the id the next buffer to enter the
    # list receives, and the buffer feed, where the list records buffers
    # opening and closing and every listed buffer its renames and closed
    # transactions, for the plugin host. It holds the keep or release
    # policy: a buffer stays listed while a window of the tab list shows
    # it or it is modified, so a closed window's edits are never lost, and
    # a scratch buffer leaves as soon as no window shows it. The feed
    # reports closed transactions to the tab list, which keeps the cursors
    # inside the text. A Struct record: mutable, with a reader and a writer
    # per member.
    class BufferList < Struct.new(:tabs, :buffers, :next_id, :feed)
      # @rbs @tabs: TabList
      # @rbs @buffers: Array[untyped]
      # @rbs @next_id: Integer
      # @rbs @feed: BufferFeed

      # An empty list over the tab list. The list is stored through the
      # writer, so it takes the pinned type.
      #: (TabList) -> void
      def initialize(tabs)
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

      # Lets go of a buffer a window stopped showing: it leaves the list
      # when it is unmodified and no window shows it, and stays hidden in
      # the list otherwise, so no edit is lost. A scratch buffer leaves as
      # soon as no window shows it.
      #: (Buffer) -> void
      def release(target)
        remove(target) if (!target.modified? || target.scratch?) && !tabs.shown?(target)
      end

      # Shows a buffer in the current window, listing it if needed. The
      # buffer the window showed leaves the list when no window shows it any
      # more; the callers make sure it is unmodified or that its changes
      # were discarded on purpose.
      #: (Buffer) -> void
      def load(target)
        current = tabs.window
        old = current.buffer
        add(target)
        current.show(target)
        remove(old) unless old.equal?(target) || tabs.shown?(old)
      end
    end
  end
end
