require_relative "../../domain/editor_state"
require_relative "../../domain/hover_request"
require_relative "../outcome"

module Carat
  module UseCases
    # K in normal mode: while the documentation float shows, enters it, so
    # the window's own keys scroll it; otherwise records a hover ask at the
    # layout window's cursor in the HoverRequest the language services
    # share, which they send at the next idle tick. A buffer without a path
    # or a hovering server is refused.
    class RequestHover
      NO_PROVIDER = "No hover provider for this buffer"
      private_constant :NO_PROVIDER

      attr_reader :hover #: Domain::HoverRequest

      #: (hover: Domain::HoverRequest) -> void
      def initialize(hover:)
        @hover = hover
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        hover = @hover
        floats = state.tab.floats
        if hover.float_id != 0 && floats.index_of(hover.float_id) >= 0
          floats.enter(hover.float_id)
          return Outcome.none
        end
        window = state.tab.layout_window
        buffer = window.buffer
        return Outcome.failure(NO_PROVIDER) if buffer.path_text.empty? || !hover.hovers?(buffer.filetype)
        cursor = window.cursor
        hover.ask(window.id, buffer.id, cursor.row, cursor.col)
        Outcome.none
      end
    end
  end
end
