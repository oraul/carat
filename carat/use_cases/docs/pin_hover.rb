require_relative "../../domain/editor_state"
require_relative "../../domain/hover_request"
require_relative "../../domain/buffer"
require_relative "../../domain/buffer_list"
require_relative "../outcome"
require_relative "../windows/split_window"
require_relative "../windows/close_float"

module Carat
  module UseCases
    # <leader>dp: splits the layout window as :split does, at the
    # documentation's rows up to MAX_HEIGHT, shows a scratch buffer
    # (TITLE) holding the documentation float's rows and their styles in
    # the new window, which keeps the focus, and closes the float; the
    # split stays when the float would have closed. With no documentation float it is
    # refused, and a refused split keeps the float.
    class PinHover
      MAX_HEIGHT = 10
      TITLE = "[docs]"
      NOTHING = "No documentation to pin"
      private_constant :MAX_HEIGHT, :TITLE, :NOTHING

      attr_reader :hover #: Domain::HoverRequest
      attr_reader :split_window #: SplitWindow
      attr_reader :buffers #: Domain::BufferList
      attr_reader :close_float #: CloseFloat

      #: (hover: Domain::HoverRequest, split_window: SplitWindow, buffers: Domain::BufferList, close_float: CloseFloat) -> void
      def initialize(hover:, split_window:, buffers:, close_float:)
        @hover = hover
        @split_window = split_window
        @buffers = buffers
        @close_float = close_float
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        hover = @hover
        id = hover.float_id
        floats = state.tab.floats
        shown = id == 0 ? -1 : floats.index_of(id)
        return Outcome.failure(NOTHING) if shown < 0
        source = floats.at(shown).window.buffer
        count = source.line_count
        lines = [""]
        lines.clear
        i = 0
        while i < count
          lines << source.line(i)
          i += 1
        end
        outcome = @split_window.call(state, false, count > MAX_HEIGHT ? MAX_HEIGHT : count, "", false)
        return outcome unless outcome.ok
        buffer = Domain::Buffer.new(lines: lines, path: nil, line_ending: "\n")
        buffer.owner = Domain::HoverRequest::OWNER
        buffer.title = TITLE
        buffer.styles = source.styles
        @buffers.load(buffer)
        @close_float.call(state, id)
        hover.float_id = 0
        Outcome.none
      end
    end
  end
end
