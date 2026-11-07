require_relative "../ports/process_port"

module Carat
  module Doubles
    # Child processes that are never started: a command starts only when a
    # test installed it, so by default no language server runs; spawns,
    # written bodies, and stops are recorded for a test to read.
    class FakeProcesses < Ports::ProcessPort
      # @rbs @installed: Array[String]
      # @rbs @spawned: Array[String]
      # @rbs @bodies: Array[String]
      # @rbs @stopped: Array[Integer]
      # @rbs @broken: Array[Integer]

      attr_reader :spawned #: Array[String]
      attr_reader :bodies #: Array[String]
      attr_reader :stopped #: Array[Integer]

      #: () -> void
      def initialize
        @installed = []
        @spawned = []
        @bodies = []
        @stopped = []
        @broken = []
      end

      # Lets a command start.
      #: (String) -> void
      def install(command)
        @installed << command
      end

      # Makes a handle's input fail, as a broken pipe.
      #: (Integer) -> void
      def break_input(handle)
        @broken << handle
      end

      # The handle of the last spawn, the number of spawns so far.
      # @rbs argv: Array[String]
      def spawn(argv)
        return 0 if argv.empty? || !@installed.include?(argv[0])
        @spawned << argv.join(" ")
        @spawned.length
      end

      # Records the body of the frame, without its header.
      # @rbs handle: Integer
      # @rbs bytes: String
      def write(handle, bytes)
        return false if @broken.include?(handle) || @stopped.include?(handle)
        at = bytes.byteindex("\r\n\r\n").to_i
        @bodies << bytes.byteslice(at + 4, bytes.bytesize - at - 4).to_s
        true
      end

      #: (Integer) -> void
      def stop(handle)
        @stopped << handle
      end

      # The method names of the bodies written, in order.
      #: () -> Array[String]
      def methods_sent
        names = []
        @bodies.each do |body|
          value = Json.parse(body)
          names << (value.is_a?(Hash) && value["method"].is_a?(String) ? value["method"].to_s : "result")
        end
        names
      end
    end
  end
end
