require_relative "editor_state"
require_relative "mode"

module Carat
  module Domain
    # The completion menu of the `:` prompt: matches, the texts <Tab>
    # inserts, with labels, what each row shows (a path's last name);
    # selected, the index into matches of the inserted one, -1 while the
    # typed text shows; start, the character index of the command line
    # the completed word starts at, and typed, that word as typed; line
    # and position, the command line and its cursor the last insert left,
    # which tell whether a later key changed them; and float_id, the
    # popup, 0 for none. A Struct record built with no arguments.
    class CmdlineMenu < Struct.new(:matches, :labels, :selected, :start, :typed, :line, :position, :float_id, keyword_init: true)
      # @rbs @matches: Array[String]
      # @rbs @labels: Array[String]
      # @rbs @selected: Integer
      # @rbs @start: Integer
      # @rbs @typed: String
      # @rbs @line: String
      # @rbs @position: Integer
      # @rbs @float_id: Integer

      # The owner of the scratch buffer the popup is shown in.
      OWNER = ":cmdline-menu"

      #: () -> void
      def initialize
        super()
        self.matches = []
        self.labels = []
        self.selected = -1
        self.start = 0
        self.typed = ""
        self.line = ""
        self.position = 0
        self.float_id = 0
      end

      # Whether the popup shows.
      #: () -> bool
      def showing?
        float_id != 0
      end

      # Whether the command line is still the one the last insert left:
      # command-line mode, the same text, the same cursor.
      #: (EditorState) -> bool
      def current?(state)
        state.mode == Mode::CMDLINE && state.cmdline == line && state.cmdline_position == position
      end

      # Forgets the matches and the popup, as before the first <Tab>.
      #: () -> void
      def clear
        self.matches = []
        self.labels = []
        self.selected = -1
        self.start = 0
        self.typed = ""
        self.line = ""
        self.position = 0
        self.float_id = 0
      end
    end
  end
end
