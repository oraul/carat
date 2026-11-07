module Carat
  module Ports
    # Child processes with live pipes, as language servers run: a child's
    # output comes back as Domain::ServiceMessage values on the message
    # queue its driver was given, never through this port, so the editor
    # thread never waits on a child.
    class ProcessPort
      # Starts the command and answers its handle, a positive number, or 0
      # when it cannot start.
      # @rbs argv: Array[String]
      def spawn(argv)
        raise NotImplementedError, "ProcessPort#spawn"
      end

      # Queues bytes for the child's input and answers whether the child
      # still takes input.
      # @rbs handle: Integer
      # @rbs bytes: String
      def write(handle, bytes)
        raise NotImplementedError, "ProcessPort#write"
      end

      # Closes the child's input once what was queued is written, and
      # reaps the child when it ends, without waiting for it.
      #: (Integer) -> void
      def stop(handle)
        raise NotImplementedError, "ProcessPort#stop"
      end
    end
  end
end
