require_relative "../../domain/editor_state"
require_relative "../../domain/signature_request"

module Carat
  module UseCases
    # After `(` or `,` is typed in insert mode (HandleKey compares the
    # code first, so no other character pays for it): when the buffer's
    # running server gives signature help, records a signature ask for the
    # innermost "(" left open before the cursor on its row, which the
    # gateway sends at an idle tick; nothing without such a "(".
    class RequestSignature
      attr_reader :signature #: Domain::SignatureRequest

      #: (signature: Domain::SignatureRequest) -> void
      def initialize(signature:)
        @signature = signature
      end

      #: (Domain::EditorState) -> void
      def call(state)
        signature = @signature
        window = state.tab.layout_window
        buffer = window.buffer
        return unless signature.helps?(buffer.filetype)
        cursor = window.cursor
        paren = Domain::SignatureRequest.open_paren(buffer.line(cursor.row), cursor.col)
        return if paren < 0
        signature.ask(window.id, buffer.id, cursor.row, paren, cursor.col)
      end
    end
  end
end
