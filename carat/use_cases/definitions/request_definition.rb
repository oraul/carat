require_relative "../../domain/editor_state"
require_relative "../../domain/definition_request"
require_relative "../outcome"

module Carat
  module UseCases
    # gd and the peek key in normal mode: records a definition ask at the
    # layout window's cursor in the DefinitionRequest the language
    # services share, which they send at the next idle tick. A buffer
    # without a path or a server offering definitions is refused with
    # Neovim's message for a method no server supports.
    class RequestDefinition
      UNSUPPORTED = "method textDocument/definition is not supported by any of the servers registered for the current buffer"
      private_constant :UNSUPPORTED

      attr_reader :definition #: Domain::DefinitionRequest

      #: (definition: Domain::DefinitionRequest) -> void
      def initialize(definition:)
        @definition = definition
      end

      #: (Domain::EditorState, bool) -> Outcome
      def call(state, peek)
        definition = @definition
        window = state.tab.layout_window
        buffer = window.buffer
        return Outcome.failure(UNSUPPORTED) if buffer.path_text.empty? || !definition.offers?(buffer.filetype)
        cursor = window.cursor
        definition.ask(window.id, buffer.id, cursor.row, cursor.col, peek)
        Outcome.none
      end
    end
  end
end
