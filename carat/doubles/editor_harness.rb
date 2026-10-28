require_relative "../adapters/editor_assembly"
require_relative "../adapters/key_decoder"
require_relative "../domain/key_notation"
require_relative "fake_terminal"
require_relative "manual_clock"
require_relative "memory_files"
require_relative "fixed_config"

module Carat
  module Doubles
    # The whole editor over doubles: type keys in Vim notation, then read the
    # frame, the buffer, the cursor, the mode, the message, and the files.
    # It pumps the input controller exactly as MainLoop does.
    class EditorHarness
      attr_reader :terminal #: FakeTerminal
      attr_reader :clock #: ManualClock
      attr_reader :files #: MemoryFiles
      attr_reader :assembly #: Adapters::EditorAssembly
      attr_reader :frame #: Domain::Frame

      #: (MemoryFiles, untyped, Integer, Integer) -> void
      def initialize(files, config, rows, cols)
        @files = files
        @clock = ManualClock.new
        @terminal = FakeTerminal.new(@clock, rows, cols)
        @assembly = Adapters::EditorAssembly.new(@terminal, @clock, @files, config)
        @frame = Domain::Frame.new(rows, cols)
      end

      # A harness over the default configuration with the given files.
      #: (MemoryFiles, Integer, Integer) -> EditorHarness
      def self.default(files, rows, cols)
        new(files, FixedConfig.defaults, rows, cols)
      end

      # Opens the file as bin/carat does and draws the first frame.
      #: (String) -> void
      def open(path)
        @assembly.screen_presenter.enter
        @assembly.open(path)
        render
      end

      # Types keys written in Vim notation, one terminal read per key, and
      # lets every wait the decoder needs expire in between.
      #: (String) -> void
      def type(notation)
        parsed = Domain::KeyNotation.parse(notation, "")
        raise ArgumentError, parsed.error.to_s unless parsed.ok?
        codes = parsed.codes
        i = 0
        while i < codes.length
          @terminal.push(Adapters::KeyDecoder.encode(codes[i]))
          pump
          pump while @assembly.controller.decoder.pending?
          i += 1
        end
        render
      end

      # Pushes raw bytes as one read, as a terminal would deliver a sequence.
      #: (String) -> void
      def raw(bytes)
        @terminal.push(bytes)
        pump
        render
      end

      # Lets one timeout pass with no input: the keymap wait resolves and
      # the manual clock advances.
      #: () -> void
      def wait
        pump
        render
      end

      #: (Integer, Integer) -> void
      def resize(rows, cols)
        @terminal.rows = rows
        @terminal.cols = cols
        render
      end

      #: () -> Domain::EditorState
      def state
        @assembly.state
      end

      #: () -> Domain::Buffer
      def buffer
        @assembly.state.buffer
      end

      #: () -> Array[String]
      def lines
        @assembly.state.buffer.lines
      end

      #: () -> Array[Integer]
      def cursor
        @assembly.state.cursor.to_a
      end

      #: () -> Symbol
      def mode
        @assembly.state.mode
      end

      #: () -> String
      def message
        @assembly.state.message
      end

      #: () -> bool
      def quit?
        @assembly.state.quit
      end

      #: () -> Array[String]
      def screen
        @frame.text_rows
      end

      #: (Integer) -> String
      def row(index)
        @frame.row_text(index)
      end

      #: () -> String
      def message_row
        @frame.row_text(@frame.rows - 1)
      end

      #: () -> String
      def status_row
        @frame.row_text(@frame.rows - 2)
      end

      private

      #: () -> void
      def pump
        @assembly.controller.pump(@assembly.state)
      end

      #: () -> void
      def render
        @frame = @assembly.render(@terminal.rows, @terminal.cols)
      end
    end
  end
end
