require_relative "../ports/message_queue_port"

module Carat
  module Drivers
    # The message queue over the runtime's Queue, the only object a
    # service thread and the editor thread both hold. One consumer, the
    # editor thread, so a pop after empty? never waits.
    class RuntimeQueue < Ports::MessageQueuePort
      # @rbs @queue: Queue

      #: () -> void
      def initialize
        @queue = Queue.new
      end

      #: (Domain::ServiceMessage) -> void
      def push(message)
        @queue.push(message)
      end

      # The oldest message, or nil when there is none.
      # @rbs skip
      def pop
        return nil if @queue.empty?
        @queue.pop
      end
    end
  end
end
