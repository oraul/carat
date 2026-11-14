require_relative "../../domain/editor_state"
require_relative "../../domain/mode"
require_relative "../../domain/palette"
require_relative "../../domain/fuzzy_match"
require_relative "../../domain/display_width"
require_relative "../../domain/buffer"
require_relative "../../domain/syntax_line"
require_relative "../../domain/highlight"
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
    # the rows around the selection, each the name, the description, and
    # the key on the right in columns measured in cells, the description
    # in PmenuExtra and the matched characters of the field that ranked
    # the entry in PmenuMatch (their Sel forms on the selected row), "No
    # match" when nothing matches.
    class FollowPalette
      Z = 960
      MAX_ROWS = 15
      MAX_WIDTH = 90
      NAME_WIDTH = 30
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

      # Filters the entries for the text, best first, keeping which field
      # ranked each, and selects the first.
      #: (String) -> void
      def filter(text)
        palette = @palette
        query = bare(text)
        names = palette.names
        descriptions = palette.descriptions
        matches = []
        fields = []
        scores = []
        i = 0
        while i < names.length
          score = 0
          field = 0
          unless query.empty?
            a = Domain::FuzzyMatch.score(query, bare(names[i]))
            b = Domain::FuzzyMatch.score(query, descriptions[i])
            score = a >= b ? a : b
            field = a >= b ? 0 : 1
          end
          if score >= 0
            at = scores.length
            at -= 1 while at > 0 && scores[at - 1] < score
            scores.insert(at, score)
            matches.insert(at, i)
            fields.insert(at, field)
          end
          i += 1
        end
        palette.matches = matches
        palette.fields = fields
        palette.query = text
        palette.selected = 0
      end

      # The text without its leading colons.
      #: (String) -> String
      def bare(text)
        out = text
        out = out.byteslice(1, out.bytesize - 1).to_s while out.start_with?(":")
        out
      end

      #: (Domain::EditorState) -> void
      def show(state)
        palette = @palette
        room = state.screen_rows - 5
        return if room < 1 || state.screen_cols < 8
        width = Domain::FloatWindow.text_room(state.screen_cols, state.options.winborder)
        width = MAX_WIDTH if width > MAX_WIDTH
        matches = palette.matches
        height = matches.length
        height = MAX_ROWS if height > MAX_ROWS
        height = room if height > room
        height = 1 if height < 1
        top = palette.selected - height + 1
        top = 0 if top < 0
        styles = Array.new(0, nil)
        lines = rows(top, height, width, styles)
        spec = Domain::FloatSpec.new(anchor: "editor", row: 1, col: 0, height: height, width: width, border: true, title: TITLE, z: Z)
        buffer = Domain::Buffer.new(lines: lines, path: nil, line_ending: "\n")
        buffer.owner = Domain::Palette::OWNER
        buffer.styles = styles
        float = Domain::FloatWindow.new(window: Domain::Window.new(buffer: buffer), spec: spec)
        float.centered = true
        float.selected = matches.empty? ? -1 : palette.selected - top
        return unless @open_float.call(state, float, false).ok
        palette.float_id = float.id
        palette.shown_query = palette.query
        palette.shown_selected = palette.selected
      end

      # The rows of the matches from top, the name, the description, and
      # the key on the right in columns cut to the width, each row's style
      # added to styles: the description column, then the runs of matched
      # characters, in the Pmenu groups of the row.
      #: (Integer, Integer, Integer, Array[untyped]) -> Array[String]
      def rows(top, height, width, styles)
        palette = @palette
        matches = palette.matches
        lines = []
        if matches.empty?
          lines << EMPTY
          return lines
        end
        query = bare(palette.query)
        room = width - NAME_WIDTH - KEY_WIDTH
        r = top
        while r < top + height && r < matches.length
          entry = matches[r]
          selected = r == palette.selected
          name = palette.names[entry]
          description = palette.descriptions[entry]
          tokens = Array.new(0, 0)
          line = pad(name, NAME_WIDTH)
          from = chars(line, line.bytesize)
          if palette.fields[r] == 0
            skip = name.start_with?(":") ? 1 : 0
            mark(tokens, query, name, skip, 0, kept(name, NAME_WIDTH), selected)
          end
          if room >= 2
            cell = pad(description, room)
            line << cell
            tokens << from
            tokens << chars(cell, cell.bytesize)
            tokens << (selected ? Domain::Highlight::POPUP_MENU_EXTRA_SELECTED : Domain::Highlight::POPUP_MENU_EXTRA)
            mark(tokens, query, description, 0, from, kept(description, room), selected) if palette.fields[r] == 1
          end
          line << pad(palette.keys[entry], KEY_WIDTH)
          line = Domain::DisplayWidth.cut(line, width)
          lines << line
          styles << Domain::SyntaxLine.new(text: line, start: 0, tokens: tokens, end_state: 0)
          r += 1
        end
        lines
      end

      # Adds a token per run of the characters of text the query matched,
      # from skip bytes on, below limit characters, at column from of the
      # row, in PmenuMatch or on the selected row PmenuMatchSel.
      #: (Array[Integer], String, String, Integer, Integer, Integer, bool) -> void
      def mark(tokens, query, text, skip, from, limit, selected)
        return if query.empty?
        field = skip > 0 ? text.byteslice(skip, text.bytesize - skip).to_s : text
        found = Domain::FuzzyMatch.positions(query, field)
        group = selected ? Domain::Highlight::POPUP_MENU_MATCH_SELECTED : Domain::Highlight::POPUP_MENU_MATCH
        i = 0
        while i < found.length
          at = chars(text, found[i] + skip)
          break if at >= limit
          length = 1
          length += 1 while i + length < found.length && found[i + length] == found[i] + length && at + length < limit
          tokens << from + at
          tokens << length
          tokens << group
          i += length
        end
      end

      # The characters of text a column of width cells keeps.
      #: (String, Integer) -> Integer
      def kept(text, width)
        cut = Domain::DisplayWidth.cut(text, width - 1)
        chars(cut, cut.bytesize)
      end

      # The characters in the first bytes of text: the bytes that start one.
      #: (String, Integer) -> Integer
      def chars(text, bytes)
        count = 0
        i = 0
        while i < bytes
          count += 1 if (text.getbyte(i).to_i & 0xC0) != 0x80
          i += 1
        end
        count
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
