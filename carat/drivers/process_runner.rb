require_relative "../ports/process_port"

module Carat
  module Drivers
    # Starts language servers with Process.spawn, stdin and stdout on
    # IO.pipe pairs and stderr on the null device, and runs two threads
    # per child, the only threads Carat starts: a reader that frames the
    # child's output with Domain::RpcFramer and pushes each body on the
    # message queue, then "exit" at the end of the output or "overflow"
    # when the framer refuses it; and a writer that takes queued bytes
    # off an outbox, so a child that stops reading never blocks the editor
    # thread. Process.detach reaps a stopped child (Spinel compiles no
    # Process.wait(pid) or WNOHANG).
    class ProcessRunner < Ports::ProcessPort
      READ_SIZE = 65_536

      # @rbs @messages: Ports::MessageQueuePort
      # @rbs @pids: Array[Integer]
      # @rbs @outboxes: Array[untyped]
      # @rbs @open: Array[bool]

      #: (messages: Ports::MessageQueuePort) -> void
      def initialize(messages:)
        @messages = messages
        @pids = []
        @outboxes = []
        @open = []
      end

      # Starts the command; its handle is its place in the lists plus one.
      # @rbs argv: Array[String]
      def spawn(argv)
        return 0 if argv.empty?
        input = IO.pipe
        output = IO.pipe
        pid = start(argv, input[0], output[1])
        input[0].close
        output[1].close
        if pid == 0
          input[1].close
          output[0].close
          return 0
        end
        outbox = Queue.new
        @pids << pid
        @outboxes << outbox
        @open << true
        handle = @pids.length
        read_output(handle, output[0])
        write_input(input[1], outbox)
        handle
      end

      # @rbs handle: Integer
      # @rbs bytes: String
      def write(handle, bytes)
        return false unless open?(handle)
        @outboxes[handle - 1].push(bytes)
        true
      end

      #: (Integer) -> void
      def stop(handle)
        return unless open?(handle)
        @open[handle - 1] = false
        @outboxes[handle - 1].push(nil)
        Process.detach(@pids[handle - 1])
      end

      private

      #: (Integer) -> bool
      def open?(handle)
        handle > 0 && handle <= @open.length && @open[handle - 1]
      end

      # The child's pid, or 0 when the command cannot start.
      #: (Array[String], IO, IO) -> Integer
      def start(argv, input, output)
        Process.spawn([argv[0], argv[0]], *argv.drop(1), in: input, out: output, err: File::NULL)
      rescue SystemCallError
        0
      end

      #: (Integer, IO) -> void
      def read_output(handle, output)
        Thread.new { pump(handle, output) }
      end

      #: (IO, untyped) -> void
      def write_input(input, outbox)
        Thread.new { drain(input, outbox) }
      end

      # The reader thread: frames the output until it ends or is refused.
      #: (Integer, IO) -> void
      def pump(handle, output)
        framer = Domain::RpcFramer.new
        kind = "exit"
        while true
          chunk = read_chunk(output)
          break if chunk.nil?
          framer.feed(chunk)
          body = framer.next_body
          until body.nil?
            @messages.push(Domain::ServiceMessage.new(handle: handle, kind: "body", text: body))
            body = framer.next_body
          end
          if framer.refused?
            kind = "overflow"
            break
          end
        end
        output.close
        @messages.push(Domain::ServiceMessage.new(handle: handle, kind: kind, text: ""))
      end

      # The next bytes of the output as UTF-8, or nil at its end.
      #: (IO) -> String?
      def read_chunk(output)
        output.readpartial(READ_SIZE).force_encoding(Encoding::UTF_8)
      rescue EOFError, IOError, SystemCallError
        nil
      end

      # The writer thread: writes the outbox until a nil or a broken pipe,
      # then closes the child's input.
      #: (IO, untyped) -> void
      def drain(input, outbox)
        while true
          bytes = outbox.pop
          break if bytes.nil?
          break unless write_bytes(input, bytes)
        end
        input.close
      end

      #: (IO, String) -> bool
      def write_bytes(input, bytes)
        input.write(bytes)
        input.flush
        true
      rescue IOError, SystemCallError
        false
      end
    end
  end
end
