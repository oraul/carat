require_relative "../../domain/editor_state"
require_relative "../../domain/signature_request"
require_relative "../../domain/mode"
require_relative "../windows/close_float"

module Carat
  module UseCases
    # After every key while insert mode follows a call (HandleKey checks
    # SignatureRequest#active? first, so no other key pays for it): stops
    # following and closes the signature float when insert mode was left,
    # the layout window, its buffer, or the row changed, or no "(" is left
    # open before the cursor; asks again when the open "(" or the cursor
    # column moved, the float staying until the new answer replaces it;
    # forgets a float another path closed.
    class FollowSignature
      attr_reader :signature #: Domain::SignatureRequest
      attr_reader :close_float #: CloseFloat

      #: (signature: Domain::SignatureRequest, close_float: CloseFloat) -> void
      def initialize(signature:, close_float:)
        @signature = signature
        @close_float = close_float
      end

      #: (Domain::EditorState) -> void
      def call(state)
        signature = @signature
        id = signature.float_id
        signature.float_id = 0 if id != 0 && state.tab.floats.index_of(id) < 0
        window = state.tab.layout_window
        buffer = window.buffer
        cursor = window.cursor
        paren = -1
        if state.mode == Domain::Mode::INSERT && signature.on?(window.id, buffer.id, cursor.row)
          paren = Domain::SignatureRequest.open_paren(buffer.line(cursor.row), cursor.col)
        end
        if paren < 0
          close(state)
          signature.stop
          return
        end
        return if paren == signature.open_col && cursor.col == signature.col
        signature.ask(window.id, buffer.id, cursor.row, paren, cursor.col)
      end

      private

      #: (Domain::EditorState) -> void
      def close(state)
        signature = @signature
        return if signature.float_id == 0
        @close_float.call(state, signature.float_id)
        signature.float_id = 0
      end
    end
  end
end
