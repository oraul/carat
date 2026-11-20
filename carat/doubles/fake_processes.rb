require_relative "../ports/process_port"

module Carat
  module Doubles
    # Child processes that are never started: a command starts only when a
    # test installed it, so by default no language server runs; spawns
    # (the refused ones counted too), written bodies, and stops are
    # recorded for a test to read. A capture answers the output a test
    # scripted for the command, "" for an installed command with none,
    # and nil for one not installed or one a test made time out, after
    # which timed_out? is true until the next capture.
    class FakeProcesses < Ports::ProcessPort
      # @rbs @installed: Array[String]
      # @rbs @spawned: Array[String]
      # @rbs @bodies: Array[String]
      # @rbs @stopped: Array[Integer]
      # @rbs @broken: Array[Integer]
      # @rbs @scripted: Array[String]
      # @rbs @outputs: Array[String]
      # @rbs @captured: Array[String]
      # @rbs @environments: Array[String]
      # @rbs @slow: Array[String]
      # @rbs @timed_out: bool
      # @rbs @attempts: Integer

      attr_reader :spawned #: Array[String]
      attr_reader :bodies #: Array[String]
      attr_reader :stopped #: Array[Integer]
      attr_reader :captured #: Array[String]
      attr_reader :environments #: Array[String]
      # Every spawn asked for, one refused for a command not installed
      # included.
      attr_reader :attempts #: Integer

      #: () -> void
      def initialize
        @installed = []
        @spawned = []
        @bodies = []
        @stopped = []
        @broken = []
        @scripted = []
        @outputs = []
        @captured = []
        @environments = []
        @slow = []
        @timed_out = false
        @attempts = 0
      end

      # Gives the command, its words joined by spaces, the output a capture
      # answers, replacing an earlier one.
      #: (String, String) -> void
      def script(command, output)
        at = @scripted.index(command)
        if at.nil?
          @scripted << command
          @outputs << output
        else
          @outputs[at] = output
        end
      end

      # Makes a capture of the command, its words joined by spaces, run
      # past its deadline: recorded, answering nil, timed_out? true.
      #: (String) -> void
      def time_out(command)
        @slow << command
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
        @attempts += 1
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

      # Records the command and the variables added to its environment, as
      # NAME=value words in the order given, and answers its scripted
      # output.
      # @rbs argv: Array[String]
      # @rbs environment: Hash[String, String]
      def capture(argv, environment)
        @timed_out = false
        return nil if argv.empty? || !@installed.include?(argv[0])
        command = argv.join(" ")
        @captured << command
        words = []
        environment.each { |name, value| words << "#{name}=#{value}" }
        @environments << words.join(" ")
        if @slow.include?(command)
          @timed_out = true
          return nil
        end
        at = @scripted.index(command)
        at.nil? ? "" : @outputs[at]
      end

      # Whether the last capture was of a command made to time out; a
      # bool.
      # @rbs skip
      def timed_out?
        @timed_out
      end

      # The method names of the bodies written, in order.
      #: () -> Array[String]
      def methods_sent
        names = []
        @bodies.each do |body|
          value = Json.parse(body)
          names << (value.is_a?(Hash) && Json.field(value, "method").is_a?(String) ? Json.field(value, "method").to_s : "result")
        end
        names
      end
    end
  end
end
