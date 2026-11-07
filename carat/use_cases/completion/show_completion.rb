require_relative "../../domain/editor_state"
require_relative "../../domain/completion_menu"
require_relative "../../domain/completion_list"
require_relative "../../domain/fuzzy_match"
require_relative "../../domain/display_width"
require_relative "../../domain/utf8"
require_relative "../../domain/icons"
require_relative "../../domain/buffer"
require_relative "../../domain/window"
require_relative "../../domain/float_spec"
require_relative "../../domain/float_window"
require_relative "../../domain/mode"
require_relative "../../ports/completion_port"
require_relative "../windows/open_float"
require_relative "../windows/close_float"
require_relative "close_completion"

module Carat
  module UseCases
    # Opens, filters, or closes the completion popup after a key in insert
    # mode. HandleKey calls it after a typed character (typed true) and
    # after any key while the popup shows. Without a popup it returns at
    # once unless a character was typed and the source is ready, so a
    # typed key costs no allocation otherwise. It reads the word before
    # the cursor, asks the source for its candidates when the word's
    # buffer, row, or start changed, and shows those matching the typed
    # part in a float under the word (above it when there is more room
    # there): each row the kind's icon, the label, and the detail on the
    # right, at most MAX_ROWS rows shown, the first selected. An unchanged
    # typed part keeps the popup and its selection; an empty word, no
    # match, or another mode closes it, and so does a key that is not
    # typed text and leaves the word, such as one moving to another row
    # or buffer: only a typed character asks the source again.
    class ShowCompletion
      MAX_ROWS = 10
      LABEL_WIDTH = 40
      DETAIL_WIDTH = 30
      OWNER = ":completion"
      Z = 1000
      private_constant :MAX_ROWS, :LABEL_WIDTH, :DETAIL_WIDTH, :OWNER, :Z

      attr_reader :menu #: Domain::CompletionMenu
      attr_reader :source #: Ports::CompletionPort
      attr_reader :open_float #: OpenFloat
      attr_reader :close_float #: CloseFloat
      attr_reader :close_completion #: CloseCompletion

      #: (menu: Domain::CompletionMenu, source: Ports::CompletionPort, open_float: OpenFloat, close_float: CloseFloat, close_completion: CloseCompletion) -> void
      def initialize(menu:, source:, open_float:, close_float:, close_completion:)
        @menu = menu
        @source = source
        @open_float = open_float
        @close_float = close_float
        @close_completion = close_completion
      end

      #: (Domain::EditorState, bool) -> void
      def call(state, typed)
        menu = @menu
        showing = menu.showing?
        return unless showing || (typed && @source.ready?(state.buffer))
        if state.mode != Domain::Mode::INSERT || (showing && state.tab.floats.index_of(menu.float_id) < 0)
          @close_completion.call(state)
          return
        end
        buffer = state.buffer
        cursor = state.cursor
        head = buffer.line(cursor.row)[0, cursor.col].to_s
        start = Domain::FuzzyMatch.word_start(head)
        prefix = head.byteslice(start, head.bytesize - start).to_s
        col = cursor.col - prefix.length
        if prefix.empty?
          @close_completion.call(state)
          return
        end
        if menu.for_word?(buffer.id, cursor.row, col)
          return if showing && prefix == menu.prefix
        else
          unless typed && @source.ready?(buffer)
            @close_completion.call(state)
            return
          end
          menu.fill(@source.candidates(buffer, cursor.row, col), buffer.id, cursor.row, col)
        end
        menu.prefix = prefix
        menu.matches = ranked(menu.candidates, prefix)
        if menu.matches.empty?
          @close_completion.call(state)
          return
        end
        menu.selected = 0
        reopen(state, menu, Domain::DisplayWidth.text_width(prefix, 0))
      end

      private

      # The indices of the candidates matching the prefix, the best score
      # first, equal scores in the source's order.
      #: (Domain::CompletionList, String) -> Array[Integer]
      def ranked(candidates, prefix)
        order = [0]
        order.clear
        scores = [0]
        scores.clear
        i = 0
        while i < candidates.count
          score = Domain::FuzzyMatch.score(prefix, candidates.at(i).label)
          if score >= 0
            j = scores.length
            j -= 1 while j > 0 && scores[j - 1] < score
            scores.insert(j, score)
            order.insert(j, i)
          end
          i += 1
        end
        order
      end

      # Replaces the popup's float with one showing the matches.
      #: (Domain::EditorState, Domain::CompletionMenu, Integer) -> void
      def reopen(state, menu, typed_width)
        @close_float.call(state, menu.float_id) if menu.showing?
        menu.float_id = 0
        set = state.options.icons
        lines = rows(menu, set)
        width = Domain::DisplayWidth.text_width(lines[0].to_s, 0)
        height = lines.length > MAX_ROWS ? MAX_ROWS : lines.length
        icon = Domain::DisplayWidth.text_width(Domain::Icons.glyph("kind_text", set), 0)
        spec = Domain::FloatSpec.new(anchor: "cursor", row: row_offset(state, height), col: -typed_width - icon - 2, height: height, width: width, border: false, title: "", z: Z)
        buffer = Domain::Buffer.new(lines: lines, path: nil, line_ending: "\n")
        buffer.owner = OWNER
        float = Domain::FloatWindow.new(window: Domain::Window.new(buffer: buffer), spec: spec)
        float.selected = 0
        if @open_float.call(state, float, false).ok
          menu.float_id = float.id
        else
          menu.clear
        end
      end

      # 1 for below the cursor's row, or minus the height for above it when
      # fewer rows are free below than the popup needs and more above.
      #: (Domain::EditorState, Integer) -> Integer
      def row_offset(state, height)
        window = state.tab.layout_window
        screen_row = window.row + window.cursor.row - window.top
        below = state.screen_rows - 2 - screen_row
        above = screen_row
        below < height && above > below ? -height : 1
      end

      # One row per match: " ", the kind's icon, " ", the label padded to
      # the label column, then two spaces and the detail padded to its
      # column when any match has a detail, and " ".
      #: (Domain::CompletionMenu, String) -> Array[String]
      def rows(menu, set)
        matches = menu.matches
        label_width = 0
        detail_width = 0
        i = 0
        while i < matches.length
          item = menu.candidates.at(matches[i])
          w = Domain::DisplayWidth.text_width(item.label, 0)
          label_width = w if w > label_width
          w = Domain::DisplayWidth.text_width(item.detail, 0)
          detail_width = w if w > detail_width
          i += 1
        end
        label_width = LABEL_WIDTH if label_width > LABEL_WIDTH
        detail_width = DETAIL_WIDTH if detail_width > DETAIL_WIDTH
        out = [""]
        out.clear
        i = 0
        while i < matches.length
          item = menu.candidates.at(matches[i])
          row = +" "
          row << Domain::Icons.glyph(item.icon_name, set)
          row << " "
          row << fit(item.label, label_width)
          if detail_width > 0
            row << "  "
            row << fit(item.detail, detail_width)
          end
          row << " "
          out << row
          i += 1
        end
        out
      end

      # The text cut at a character boundary to width cells and padded
      # with spaces to it.
      #: (String, Integer) -> String
      def fit(text, width)
        out = +""
        used = 0
        len = text.bytesize
        i = 0
        while i < len
          size = Domain::Utf8.size_at(text, i, len)
          w = Domain::DisplayWidth.text_width(text.byteslice(i, size).to_s, 0)
          break if used + w > width
          out << text.byteslice(i, size).to_s
          used += w
          i += size
        end
        out << " " * (width - used)
        out
      end
    end
  end
end
