require_relative "../../domain/editor_state"
require_relative "../../domain/hover_request"
require_relative "../../domain/mode"
require_relative "../windows/close_float"

module Carat
  module UseCases
    # After every key while a documentation float is recorded (HandleKey
    # checks the id first, so no other key pays for it): forgets a float
    # another path closed (Esc, :q), keeps the float while it is entered,
    # and closes it when the layout window, its buffer, the cursor, or
    # normal mode moved from where K was typed.
    class FollowHover
      attr_reader :hover #: Domain::HoverRequest
      attr_reader :close_float #: CloseFloat

      #: (hover: Domain::HoverRequest, close_float: CloseFloat) -> void
      def initialize(hover:, close_float:)
        @hover = hover
        @close_float = close_float
      end

      #: (Domain::EditorState) -> void
      def call(state)
        hover = @hover
        id = hover.float_id
        floats = state.tab.floats
        if floats.index_of(id) >= 0
          return if floats.focused? && floats.focused.id == id
          window = state.tab.layout_window
          cursor = window.cursor
          return if state.mode == Domain::Mode::NORMAL && hover.at?(window.id, window.buffer.id, cursor.row, cursor.col)
        end
        @close_float.call(state, id)
        hover.float_id = 0
      end
    end
  end
end
