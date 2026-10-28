require_relative "../ports/terminal_port"
require_relative "../adapters/editor_assembly"
require_relative "signals"

module Carat
  module Drivers
    # The single editor thread. One iteration: present when something
    # changed or the terminal was resized, then pump one read through the
    # input controller. Ends when the state asks to quit or SIGTERM arrived.
    class MainLoop
      # @rbs @assembly: Adapters::EditorAssembly
      # @rbs @terminal: Ports::TerminalPort

      #: (Adapters::EditorAssembly, Ports::TerminalPort) -> void
      def initialize(assembly, terminal)
        @assembly = assembly
        @terminal = terminal
      end

      #: () -> void
      def run
        state = @assembly.state
        dirty = true
        until state.quit || Signals.terminated
          if dirty || Signals.resized
            Signals.resized = false
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
