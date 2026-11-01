require_relative "../ports/terminal_port"
require_relative "../ports/signal_port"
require_relative "../adapters/editor_assembly"

module Carat
  module Drivers
    # The single editor thread. One iteration: present when something
    # changed or the signal port reports a resize, then pump one read
    # through the input controller. Ends when the state asks to quit or
    # the signal port reports a request to end.
    class MainLoop
      attr_reader :assembly #: Adapters::EditorAssembly
      attr_reader :terminal #: Ports::TerminalPort
      attr_reader :signals #: Ports::SignalPort

      #: (assembly: Adapters::EditorAssembly, terminal: Ports::TerminalPort, signals: Ports::SignalPort) -> void
      def initialize(assembly:, terminal:, signals:)
        @assembly = assembly
        @terminal = terminal
        @signals = signals
      end

      #: () -> void
      def run
        state = @assembly.state
        signals = @signals
        dirty = true
        until state.quit || signals.terminated?
          if dirty || signals.resized?
            signals.acknowledge_resize
            size = @terminal.size
            @assembly.render(size[0], size[1])
            dirty = false
          end
          dirty = @assembly.controller.pump(state)
        end
      end
    end
  end
end
