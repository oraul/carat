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
    # It pumps the input controller exactly as MainLoop does. The plugins
    # are a parameter because the doubles may not require the registry;
    # default runs with none, with_plugins with the list given.
    class EditorHarness
      attr_reader :terminal #: FakeTerminal
      attr_reader :clock #: ManualClock
      attr_reader :files #: MemoryFiles
      attr_reader :assembly #: Adapters::EditorAssembly
      attr_reader :frame #: Domain::Frame

      #: (files: MemoryFiles, config: untyped, rows: Integer, cols: Integer, plugins: Array[untyped]) -> void
      def initialize(files:, config:, rows:, cols:, plugins:)
        @files = files
        @clock = ManualClock.new
        @terminal = FakeTerminal.new(@clock, rows, cols)
        @assembly = Adapters::EditorAssembly.new(terminal: @terminal, clock: @clock, files: @files, config: config, config_source: FixedConfig::SOURCE, plugin_list: plugins)
        @frame = Domain::Frame.new(rows, cols)
      end

      # A harness over the default configuration with the given files and
      # no plugins.
      #: (MemoryFiles, Integer, Integer) -> EditorHarness
      def self.default(files, rows, cols)
        new(files: files, config: FixedConfig.defaults, rows: rows, cols: cols, plugins: [])
      end

      # A harness over the default configuration with the given plugins.
      #: (MemoryFiles, Integer, Integer, Array[untyped]) -> EditorHarness
      def self.with_plugins(files, rows, cols, plugins)
        new(files: files, config: FixedConfig.defaults, rows: rows, cols: cols, plugins: plugins)
      end

      #: () -> UseCases::PluginHost
      def plugins
        @assembly.plugins
      end

      # Opens the file as bin/carat does and draws the first frame.
      #: (String) -> void
      def open(path)
        @assembly.screen_presenter.enter
        @assembly.open(path)
        render
      end

      # Types keys written in Vim notation, one terminal read per key, and
      # lets every wait the decoder needs expire in between. The frame is
      # drawn after every key, as the main loop draws after every read, so
      # a window command sees the layout the previous key left.
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
          render
          i += 1
        end
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

      # The number of windows in the current tab page.
      #: () -> Integer
      def window_count
        @assembly.state.window_count
      end

      # The 1-based number of the current window in layout order.
      #: () -> Integer
      def window_index
        tab = @assembly.state.tab
        tab.layout.number_of(tab.current)
      end

      #: () -> Integer
      def tab_count
        @assembly.state.tab_count
      end

      # The 1-based number of the current tab page.
      #: () -> Integer
      def tab_index
        @assembly.state.tab_index + 1
      end

      # Every window of the current tab page in layout order, each as
      # [row, col, text rows, columns, path or "", cursor row, cursor col].
      #: () -> Array[Array[untyped]]
      def windows
        layout = @assembly.state.tab.layout
        ids = layout.leaves
        out = []
        i = 0
        while i < ids.length
          w = layout.window_at(ids[i])
          path = w.buffer.path
          out << [w.row, w.col, w.height, w.width, path.nil? ? "" : path, w.cursor.row, w.cursor.col]
          i += 1
        end
        out
      end

      # The paths of the listed buffers, "" for an unnamed one.
      #: () -> Array[String]
      def buffer_paths
        s = @assembly.state
        out = []
        i = 0
        while i < s.buffer_count
          path = s.buffer_at(i).path
          out << (path.nil? ? "" : path)
          i += 1
        end
        out
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
