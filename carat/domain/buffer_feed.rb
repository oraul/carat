require_relative "buffer_notice"

module Carat
  module Domain
    # The one sink of buffer events: the editor state owns it and hands it
    # to every buffer that enters the list, the list records opens and
    # closes, a buffer records its renames and its closed transactions,
    # and the plugin host takes the notices to turn them into events.
    # cause is the name of the plugin whose call is running, "" outside
    # any plugin call; a notice records the cause at the moment it is
    # made. The notices are Array[untyped], read through notice_at, which
    # declares their type. A Struct record.
    class BufferFeed < Struct.new(:cause, :notices)
      # @rbs @cause: String
      # @rbs @notices: Array[untyped]

      # The empty list is stored through the writer, so it takes the
      # pinned type.
      #: () -> void
      def initialize
        super()
        self.cause = ""
        self.notices = []
      end

      #: (BufferNotice) -> void
      def push(notice)
        notices << notice
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
