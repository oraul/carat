require_relative "../../domain/editor_state"
require_relative "../../domain/buffer"
require_relative "../../domain/display_width"
require_relative "../../domain/float_spec"
require_relative "../../domain/float_window"
require_relative "../../domain/window"
require_relative "../windows/open_float"

module Carat
  module UseCases
    # Opens a bordered float over a buffer at the layout window's cursor,
    # for the peek float and the pick list: below the cursor, or above
    # when there is more room there, as tall as the buffer within the
    # room and as wide as its widest line or its title, at most WIDTH
    # columns. Answers the float's id, 0 when it does not fit or the layer
    # is full.
    class OpenDefinitionFloat
      WIDTH = 80
      Z = 50
      private_constant :WIDTH, :Z

      attr_reader :open_float #: OpenFloat

      #: (open_float: OpenFloat) -> void
      def initialize(open_float:)
        @open_float = open_float
      end

      #: (Domain::EditorState, Domain::Buffer, String, bool) -> Integer
      def call(state, buffer, title, enter)
        window = state.tab.layout_window
        screen_row = window.row + window.cursor.row - window.top
        wanted = buffer.line_count
        below = state.screen_rows - 4 - screen_row
        above = screen_row - 2
        up = below < wanted && above > below
        height = up ? above : below
        height = wanted if height > wanted
        return 0 if height < 1
        limit = Domain::FloatWindow.text_room(state.screen_cols, true, state.options.winborder)
        limit = WIDTH if limit > WIDTH
        return 0 if limit < 1
        width = Domain::DisplayWidth.text_width(title, 0)
        i = 0
        while i < buffer.line_count
          w = Domain::DisplayWidth.text_width(buffer.line(i), 0)
          width = w if w > width
          i += 1
        end
        width = limit if width > limit
        width = 1 if width < 1
        spec = Domain::FloatSpec.new(anchor: "cursor", row: up ? -(height + 2) : 1, col: 0, height: height, width: width, border: true, title: title, z: Z)
        float = Domain::FloatWindow.new(window: Domain::Window.new(buffer: buffer), spec: spec)
        return 0 unless @open_float.call(state, float, enter).ok
        float.id
      end
    end
  end
end
