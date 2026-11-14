require_relative "../../domain/editor_state"
require_relative "../../domain/mode"
require_relative "../../domain/palette"
require_relative "../../domain/fuzzy_match"
require_relative "../../domain/display_width"
require_relative "../../domain/buffer"
require_relative "../../domain/window"
require_relative "../../domain/float_spec"
require_relative "../../domain/float_window"
require_relative "../windows/open_float"
require_relative "../windows/close_float"

module Carat
  module UseCases
    # Keeps the command palette's float in step after each key while the
    # palette follows: once the mode left the command line (Enter, Esc)
    # the palette closes with its float; otherwise a changed text filters
    # the entries again through FuzzyMatch (the better of the name's and
    # the description's score, a leading ":" of the text dropped, equal
    # scores in the table's order, every entry for an empty text) and
    # selects the first, and a changed text or selection reopens the
    # float: a bordered menu titled "Commands" near the top of the editor,
    # the rows around the selection, each the name, the key, and the
    # description in columns measured in cells, "No match" when nothing
    # matches.
    class FollowPalette
      Z = 960
      MAX_ROWS = 15
      MAX_WIDTH = 90
      NAME_WIDTH = 28
      KEY_WIDTH = 12
      TITLE = "Commands"
      EMPTY = "No match"
      private_constant :Z, :MAX_ROWS, :MAX_WIDTH, :NAME_WIDTH, :KEY_WIDTH, :TITLE, :EMPTY

      attr_reader :palette #: Domain::Palette
      attr_reader :open_float #: OpenFloat
      attr_reader :close_float #: CloseFloat

      #: (palette: Domain::Palette, open_float: OpenFloat, close_float: CloseFloat) -> void
      def initialize(palette:, open_float:, close_float:)
        @palette = palette
        @open_float = open_float
        @close_float = close_float
      end

      #: (Domain::EditorState) -> void
      def call(state)
        palette = @palette
        unless palette.active && state.mode == Domain::Mode::CMDLINE
          palette.active = false
          close(state)
          return
        end
        text = state.cmdline
        filter(text) if palette.shown_selected < 0 || text != palette.query
        return if palette.float_id != 0 && palette.shown_query == text && palette.shown_selected == palette.selected
        close(state)
        show(state)
      end

      private

      #: (Domain::EditorState) -> void
      def close(state)
        palette = @palette
        return if palette.float_id == 0
        @close_float.call(state, palette.float_id)
        palette.float_id = 0
      end

      # Filters the entries for the text, best first, and selects the
      # first.
      #: (String) -> void
      def filter(text)
        palette = @palette
        query = text
        query = query.byteslice(1, query.bytesize - 1).to_s while query.start_with?(":")
        names = palette.names
        descriptions = palette.descriptions
        matches = []
        scores = []
        i = 0
        while i < names.length
          score = query.empty? ? 0 : score_of(query, names[i], descriptions[i])
          if score >= 0
            at = scores.length
            at -= 1 while at > 0 && scores[at - 1] < score
            scores.insert(at, score)
            matches.insert(at, i)
          end
          i += 1
        end
        palette.matches = matches
        palette.query = text
        palette.selected = 0
      end

      # The better of the name's and the description's score, a leading
      # ":" of the name dropped.
      #: (String, String, String) -> Integer
      def score_of(query, name, description)
        bare = name.start_with?(":") ? name.byteslice(1, name.bytesize - 1).to_s : name
        a = Domain::FuzzyMatch.score(query, bare)
        b = Domain::FuzzyMatch.score(query, description)
        a > b ? a : b
      end

      #: (Domain::EditorState) -> void
      def show(state)
        palette = @palette
        room = state.screen_rows - 5
        return if room < 1 || state.screen_cols < 8
        width = Domain::FloatWindow.text_room(state.screen_cols, true, state.options.winborder)
        width = MAX_WIDTH if width > MAX_WIDTH
        matches = palette.matches
        height = matches.length
        height = MAX_ROWS if height > MAX_ROWS
        height = room if height > room
        height = 1 if height < 1
        top = palette.selected - height + 1
        top = 0 if top < 0
        lines = rows(top, height, width)
        spec = Domain::FloatSpec.new(anchor: "editor", row: 1, col: (state.screen_cols - width - Domain::FloatWindow.frame_width(1)) / 2, height: height, width: width, border: true, title: TITLE, z: Z)
        buffer = Domain::Buffer.new(lines: lines, path: nil, line_ending: "\n")
        buffer.owner = Domain::Palette::OWNER
        float = Domain::FloatWindow.new(window: Domain::Window.new(buffer: buffer), spec: spec)
        float.selected = matches.empty? ? -1 : palette.selected - top
        return unless @open_float.call(state, float, false).ok
        palette.float_id = float.id
        palette.shown_query = palette.query
        palette.shown_selected = palette.selected
      end

      # The rows of the matches from top, the name, key, and description
      # of each in columns cut to the width.
      #: (Integer, Integer, Integer) -> Array[String]
      def rows(top, height, width)
        palette = @palette
        matches = palette.matches
        lines = []
        if matches.empty?
          lines << EMPTY
          return lines
        end
        r = top
        while r < top + height && r < matches.length
          entry = matches[r]
          line = +""
          line << pad(palette.names[entry], NAME_WIDTH)
          line << pad(palette.keys[entry], KEY_WIDTH)
          line << palette.descriptions[entry]
          lines << Domain::DisplayWidth.cut(line, width)
          r += 1
        end
        lines
      end

      # The text cut to the width less one in cells, then padded with
      # spaces to the width, so at least one space follows it.
      #: (String, Integer) -> String
      def pad(text, width)
        cell = Domain::DisplayWidth.fit(text, width - 1)
        cell << " "
        cell
      end
    end
  end
end
