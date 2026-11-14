require_relative "../../domain/editor_state"
require_relative "../../domain/hover_request"
require_relative "../../domain/docs_text"
require_relative "../../domain/display_width"
require_relative "../../domain/buffer"
require_relative "../../domain/window"
require_relative "../../domain/float_spec"
require_relative "../../domain/float_window"
require_relative "../../domain/mode"
require_relative "../windows/open_float"
require_relative "../windows/close_float"
require_relative "format_docs"

module Carat
  module UseCases
    # Shows a hover answer the language services marked arrived, at the
    # idle tick that reads it: dropped when the layout window, its buffer,
    # the cursor, or normal mode moved since K; "No information available"
    # for an empty one. Otherwise the text is read as rows with their
    # markup styles (FormatDocs) at most WIDTH cells wide and within the
    # screen, the styles kept on the float's buffer, and
    # shown in a bordered float at most MAX_ROWS rows high, below the
    # cursor, or above it when below lacks the rows and above has more;
    # its id is kept in the HoverRequest for FollowHover, RequestHover,
    # and PinHover.
    class ShowHover
      WIDTH = 80
      MAX_ROWS = 20
      Z = 50
      NO_INFORMATION = "No information available"
      private_constant :WIDTH, :MAX_ROWS, :Z, :NO_INFORMATION

      attr_reader :hover #: Domain::HoverRequest
      attr_reader :open_float #: OpenFloat
      attr_reader :close_float #: CloseFloat
      attr_reader :format_docs #: FormatDocs

      #: (hover: Domain::HoverRequest, open_float: OpenFloat, close_float: CloseFloat, format_docs: FormatDocs) -> void
      def initialize(hover:, open_float:, close_float:, format_docs:)
        @hover = hover
        @open_float = open_float
        @close_float = close_float
        @format_docs = format_docs
      end

      #: (Domain::EditorState) -> void
      def call(state)
        hover = @hover
        hover.arrived = false
        text = hover.text
        hover.text = ""
        window = state.tab.layout_window
        cursor = window.cursor
        return unless state.mode == Domain::Mode::NORMAL && hover.at?(window.id, window.buffer.id, cursor.row, cursor.col)
        if hover.float_id != 0
          @close_float.call(state, hover.float_id)
          hover.float_id = 0
        end
        width = Domain::FloatWindow.text_room(state.screen_cols, state.options.winborder)
        width = WIDTH if width > WIDTH
        return if width < 1
        docs = @format_docs.call(state, text, width)
        if docs.count == 0
          state.show(NO_INFORMATION, false)
          return
        end
        open(state, window, docs)
      end

      private

      # Opens the bordered float of the rows at the cursor.
      #: (Domain::EditorState, Domain::Window, Domain::DocsText) -> void
      def open(state, window, docs)
        rows = docs.texts
        screen_row = window.row + window.cursor.row - window.top
        wanted = rows.length > MAX_ROWS ? MAX_ROWS : rows.length
        below = state.screen_rows - 4 - screen_row
        above = screen_row - 2
        up = below < wanted && above > below
        height = up ? above : below
        height = wanted if height > wanted
        return if height < 1
        width = 1
        i = 0
        while i < rows.length
          w = Domain::DisplayWidth.text_width(rows[i], 0)
          width = w if w > width
          i += 1
        end
        spec = Domain::FloatSpec.new(anchor: "cursor", row: up ? -(height + 2) : 1, col: 0, height: height, width: width, border: true, title: "", z: Z)
        buffer = Domain::Buffer.new(lines: rows, path: nil, line_ending: "\n")
        buffer.owner = Domain::HoverRequest::OWNER
        buffer.styles = docs.styles
        float = Domain::FloatWindow.new(window: Domain::Window.new(buffer: buffer), spec: spec)
        @hover.float_id = float.id if @open_float.call(state, float, false).ok
      end
    end
  end
end
