require_relative "../ports/message_queue_port"

module Carat
  module Doubles
    # The message queue as an array: a test pushes what a server's reader
    # thread would, and the editor pops it.
    class MemoryQueue < Ports::MessageQueuePort
      # @rbs @items: Array[untyped]

      #: () -> void
      def initialize
        @items = []
      end

      #: (Domain::ServiceMessage) -> void
      def push(message)
        @items << message
      end

      # The oldest message, or nil when there is none.
      # @rbs skip
      def pop
        @items.shift
      end

      # Pushes one body from a server.
      #: (Integer, String) -> void
      def body(handle, text)
        push(Domain::ServiceMessage.new(handle: handle, kind: "body", text: text))
      end

      # How many messages wait.
      #: () -> Integer
      def count
        @items.length
      end
    end
  end
end
