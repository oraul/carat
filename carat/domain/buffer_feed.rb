require_relative "buffer_notice"

module Carat
  module Domain
    # The one sink of buffer events: the buffer list owns it and hands it
    # to every buffer that enters the list, the list records opens and
    # closes, a buffer records its renames and its closed transactions,
    # and the plugin host takes the notices to turn them into events. A
    # closed transaction is also reported to tabs, the tab list the buffer
    # list sets, which keeps the cursors on the buffer inside its text, so
    # the change records drive cursor clamping for every edit.
    # cause is the name of the plugin whose call is running, "" outside
    # any plugin call; a notice records the cause at the moment it is
    # made. The notices are Array[untyped], read through notice_at, which
    # declares their type. A Struct record.
    class BufferFeed < Struct.new(:cause, :notices, :tabs)
      # @rbs @cause: String
      # @rbs @notices: Array[untyped]
      # @rbs @tabs: TabList?

      # The empty list is stored through the writer, so it takes the
      # pinned type.
      #: () -> void
      def initialize
        super()
        self.cause = ""
        self.notices = []
        self.tabs = nil
      end

      # Records the notice; a change also clamps the cursors of the windows
      # showing its buffer from its first row on.
      #: (BufferNotice) -> void
      def push(notice)
        notices << notice
        keeper = tabs
        keeper.clamp_cursors(notice.buffer_id, notice.row) if !keeper.nil? && notice.change?
        nil
      end

      #: (Integer) -> BufferNotice
      def notice_at(i)
        notices[i]
      end

      #: () -> Integer
      def count
        notices.length
      end

      #: () -> void
      def clear
        self.notices = []
      end

      # Records that a buffer entered, left, or was renamed, with the
      # current cause.
      #: (String, Integer, String, String) -> void
      def note(kind, buffer_id, path, detail)
        push(BufferNotice.new(kind, buffer_id, path, detail, cause))
      end
    end
  end
end
