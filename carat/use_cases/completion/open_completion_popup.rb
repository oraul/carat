require_relative "../../domain/editor_state"
require_relative "../../domain/completion_menu"
require_relative "../../domain/display_width"
require_relative "../../domain/icons"
require_relative "../../domain/buffer"
require_relative "../../domain/window"
require_relative "../../domain/float_spec"
require_relative "../../domain/float_window"
require_relative "../windows/open_float"
require_relative "../windows/close_float"
require_relative "close_completion"

module Carat
  module UseCases
    # Opens the completion popup's float under the word (above it when
    # there is more room there), replacing the one it shows: one row per
    # match of the menu, each the kind's icon, the label, and the detail
    # on the right, at most MAX_ROWS rows shown, the menu's selected row
    # selected and scrolled into view. typed_width is the display width of
    # the typed part, so the labels stand under the word. ShowCompletion
    # and CompleteWord call it; a float that cannot open closes the popup.
    class OpenCompletionPopup
      MAX_ROWS = 10
      LABEL_WIDTH = 40
      DETAIL_WIDTH = 30
      OWNER = ":completion"
      Z = 1000
      private_constant :MAX_ROWS, :LABEL_WIDTH, :DETAIL_WIDTH, :OWNER, :Z

      attr_reader :menu #: Domain::CompletionMenu
      attr_reader :open_float #: OpenFloat
      attr_reader :close_float #: CloseFloat
      attr_reader :close_completion #: CloseCompletion

      #: (menu: Domain::CompletionMenu, open_float: OpenFloat, close_float: CloseFloat, close_completion: CloseCompletion) -> void
      def initialize(menu:, open_float:, close_float:, close_completion:)
        @menu = menu
        @open_float = open_float
        @close_float = close_float
        @close_completion = close_completion
      end

      # Replaces the popup's float with one showing the matches.
      #: (Domain::EditorState, Integer) -> void
      def call(state, typed_width)
        menu = @menu
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
        selected = menu.selected
        float.selected = selected
        if @open_float.call(state, float, false).ok
          menu.float_id = float.id
          float.window.cursor.move_to(selected, 0) if selected > 0
        else
          @close_completion.call(state)
        end
      end

      private

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
          row << Domain::DisplayWidth.fit(item.label, label_width)
          if detail_width > 0
            row << "  "
            row << Domain::DisplayWidth.fit(item.detail, detail_width)
          end
          row << " "
          out << row
          i += 1
        end
        out
      end
    end
  end
end
