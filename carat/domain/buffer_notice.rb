module Carat
  module Domain
    # One thing that happened to a listed buffer, as the buffer feed
    # records it for the plugin host: kind is "open" (the buffer entered
    # the list), "close" (it left), "rename" (its path changed; detail is
    # the old path), or "change" (a transaction with records closed; row is
    # its first changed row, removed and inserted the rows it took out
    # there and put in their place). path is the buffer's path when it
    # happened, "" for none, and cause is the name of the plugin whose
    # request did it, "" for the editor and the user. A Struct record.
    class BufferNotice < Struct.new(:kind, :buffer_id, :row, :removed, :inserted, :path, :detail, :cause)
      # @rbs @kind: String
      # @rbs @buffer_id: Integer
      # @rbs @row: Integer
      # @rbs @removed: Integer
      # @rbs @inserted: Integer
      # @rbs @path: String
      # @rbs @detail: String
      # @rbs @cause: String

      #: (String, Integer, String, String, String) -> void
      def initialize(kind, buffer_id, path, detail, cause)
        super(kind, buffer_id, 0, 0, 0, path, detail, cause)
      end

      #: () -> bool
      def change?
        kind == "change"
      end
    end
  end
end
