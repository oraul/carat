require_relative "../../domain/editor_state"
require_relative "../../domain/signature_request"
require_relative "../../domain/display_width"
require_relative "../../domain/buffer"
require_relative "../../domain/window"
require_relative "../../domain/float_spec"
require_relative "../../domain/float_window"
require_relative "../../domain/mode"
require_relative "../windows/open_float"
require_relative "../windows/close_float"

module Carat
  module UseCases
    # Shows a signature answer the language services marked arrived, at
    # the idle tick that reads it: the previous signature float closes;
    # an answer for a call no longer followed in insert mode in the layout
    # window, its buffer, and its row is dropped; an empty label stops the
    # following. Otherwise the label shows in a bordered float of one row
    # above the cursor, or below it when the screen has no room above, as
    # wide as the label within the screen, its active parameter marked;
    # its id is kept in the SignatureRequest for FollowSignature.
    class ShowSignature
      Z = 900
      private_constant :Z

      attr_reader :signature #: Domain::SignatureRequest
      attr_reader :open_float #: OpenFloat
      attr_reader :close_float #: CloseFloat

      #: (signature: Domain::SignatureRequest, open_float: OpenFloat, close_float: CloseFloat) -> void
      def initialize(signature:, open_float:, close_float:)
        @signature = signature
        @open_float = open_float
        @close_float = close_float
      end

      #: (Domain::EditorState) -> void
      def call(state)
        signature = @signature
        signature.arrived = false
        if signature.float_id != 0
          @close_float.call(state, signature.float_id)
          signature.float_id = 0
        end
        window = state.tab.layout_window
        return unless state.mode == Domain::Mode::INSERT && signature.on?(window.id, window.buffer.id, window.cursor.row)
        label = signature.label
        if label.empty?
          signature.stop
          return
        end
        width = Domain::DisplayWidth.text_width(label, 0)
        width = state.screen_cols - 2 if width > state.screen_cols - 2
        return if width < 1
        open(state, window, label, width)
      end

      private

      # Opens the bordered float of the label at the cursor, its marked
      # parameter as display columns.
      #: (Domain::EditorState, Domain::Window, String, Integer) -> void
      def open(state, window, label, width)
        signature = @signature
        screen_row = window.row + window.cursor.row - window.top
        spec = Domain::FloatSpec.new(anchor: "cursor", row: screen_row >= 3 ? -3 : 1, col: 0, height: 1, width: width, border: true, title: "", z: Z)
        buffer = Domain::Buffer.new(lines: [label], path: nil, line_ending: "\n")
        buffer.owner = Domain::SignatureRequest::OWNER
        float = Domain::FloatWindow.new(window: Domain::Window.new(buffer: buffer), spec: spec)
        if signature.mark_from >= 0
          float.mark_from = Domain::DisplayWidth.text_width(label.byteslice(0, signature.mark_from).to_s, 0)
          float.mark_to = Domain::DisplayWidth.text_width(label.byteslice(0, signature.mark_to).to_s, 0)
        end
        signature.float_id = float.id if @open_float.call(state, float, false).ok
      end
    end
  end
end
