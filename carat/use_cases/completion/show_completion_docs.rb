require_relative "../../domain/editor_state"
require_relative "../../domain/completion_menu"
require_relative "../../domain/markdown_text"
require_relative "../../domain/display_width"
require_relative "../../domain/buffer"
require_relative "../../domain/window"
require_relative "../../domain/float_spec"
require_relative "../../domain/float_window"
require_relative "../../ports/completion_port"
require_relative "../windows/open_float"
require_relative "../windows/close_float"

module Carat
  module UseCases
    # Shows the completion popup's selected candidate's documentation in a
    # float beside the popup. ShowCompletion calls it whenever it leaves the
    # popup showing: after a typed character, after any key while the
    # popup shows (so after a selection moved), and at an idle tick when
    # the source's answer or documentation arrived. It asks the source for
    # the candidate's documentation, which also tells a source that asks a
    # server which candidate is picked; with none the float closes. When
    # the float shows that candidate's same text beside the same popup it
    # stays, so moving the selection costs one comparison. Otherwise the
    # float is replaced: the text read as plain rows (MarkdownText) at most
    # WIDTH cells wide, at most MAX_ROWS rows and the rows free on the
    # popup's side shown, at the popup's rows (from its first row below
    # the cursor, ending on the row above it above), on the popup's right,
    # or on its left when the right lacks the room and the left has it,
    # with no border, under the popup. CloseCompletion closes it with the
    # popup.
    class ShowCompletionDocs
      WIDTH = 60
      MAX_ROWS = 12
      OWNER = ":completion_docs"
      Z = 999
      private_constant :WIDTH, :MAX_ROWS, :OWNER, :Z

      attr_reader :menu #: Domain::CompletionMenu
      attr_reader :source #: Ports::CompletionPort
      attr_reader :open_float #: OpenFloat
      attr_reader :close_float #: CloseFloat

      #: (menu: Domain::CompletionMenu, source: Ports::CompletionPort, open_float: OpenFloat, close_float: CloseFloat) -> void
      def initialize(menu:, source:, open_float:, close_float:)
        @menu = menu
        @source = source
        @open_float = open_float
        @close_float = close_float
      end

      #: (Domain::EditorState) -> void
      def call(state)
        menu = @menu
        floats = state.tab.floats
        shown = floats.index_of(menu.float_id)
        if shown < 0 || menu.selected >= menu.matches.length
          close(state, menu)
          return
        end
        index = menu.chosen_index
        text = @source.documentation(menu.origin, index)
        if text.empty?
          close(state, menu)
          return
        end
        return if menu.docs_float_id != 0 && menu.docs_index == index && menu.docs_beside == menu.float_id && floats.index_of(menu.docs_float_id) >= 0 && menu.docs_text == text
        popup = floats.at(shown).spec
        close(state, menu)
        open_beside(state, menu, popup, index, text)
      end

      private

      # Closes the documentation float, if one shows.
      #: (Domain::EditorState, Domain::CompletionMenu) -> void
      def close(state, menu)
        @close_float.call(state, menu.docs_float_id) if menu.docs_float_id != 0
        menu.forget_docs
      end

      # Opens the float of the text beside the popup's spec.
      #: (Domain::EditorState, Domain::CompletionMenu, Domain::FloatSpec, Integer, String) -> void
      def open_beside(state, menu, popup, index, text)
        rows = Domain::MarkdownText.rows(text, WIDTH)
        return if rows.empty?
        window = state.tab.layout_window
        cursor = window.cursor
        screen_row = window.row + cursor.row - window.top
        below = popup.row > 0
        height = rows.length > MAX_ROWS ? MAX_ROWS : rows.length
        room = below ? state.screen_rows - 2 - screen_row : screen_row
        height = room if height > room
        return if height < 1
        width = 1
        i = 0
        while i < rows.length
          w = Domain::DisplayWidth.text_width(rows[i], 0)
          width = w if w > width
          i += 1
        end
        options = state.options
        cursor_col = window.col + window.gutter_width(options) + Domain::DisplayWidth.column(window.buffer.line(cursor.row), cursor.col, options.tab_width) - window.left
        col = popup.col + popup.width
        col = popup.col - width if cursor_col + col + width > state.screen_cols && cursor_col + popup.col - width >= 0
        spec = Domain::FloatSpec.new(anchor: "cursor", row: below ? 1 : -height, col: col, height: height, width: width, border: false, title: "", z: Z)
        buffer = Domain::Buffer.new(lines: rows, path: nil, line_ending: "\n")
        buffer.owner = OWNER
        float = Domain::FloatWindow.new(window: Domain::Window.new(buffer: buffer), spec: spec)
        return unless @open_float.call(state, float, false).ok
        menu.docs_float_id = float.id
        menu.docs_index = index
        menu.docs_text = text
        menu.docs_beside = menu.float_id
      end
    end
  end
end
