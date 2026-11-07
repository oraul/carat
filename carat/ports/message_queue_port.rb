module Carat
  module Ports
    # The one thing a service thread and the editor thread share: service
    # threads push, the editor pops without waiting.
    class MessageQueuePort
      #: (Domain::ServiceMessage) -> void
      def push(message)
        raise NotImplementedError, "MessageQueuePort#push"
      end

      # The oldest message, or nil at once when there is none.
      # @rbs skip
      def pop
        raise NotImplementedError, "MessageQueuePort#pop"
      end
    end
  end
end
