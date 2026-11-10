require_relative "../../domain/editor_state"
require_relative "../../domain/definition_request"
require_relative "../../domain/mode"
require_relative "../windows/close_float"

module Carat
  module UseCases
    # After a key while the peek float or the pick list is recorded:
    # forgets one another path closed, closes the peek float once normal
    # mode or the cursor left where it was asked, and closes the pick list
    # once it is no longer the current window.
    class FollowDefinition
      attr_reader :definition #: Domain::DefinitionRequest
      attr_reader :close_float #: CloseFloat

      #: (definition: Domain::DefinitionRequest, close_float: CloseFloat) -> void
      def initialize(definition:, close_float:)
        @definition = definition
        @close_float = close_float
      end

      #: (Domain::EditorState) -> void
      def call(state)
        definition = @definition
        floats = state.tab.floats
        peek = definition.float_id
        if peek != 0
          if floats.index_of(peek) < 0
            definition.float_id = 0
          else
            window = state.tab.layout_window
            cursor = window.cursor
            unless state.mode == Domain::Mode::NORMAL && definition.at?(window.id, window.buffer.id, cursor.row, cursor.col)
              @close_float.call(state, peek)
              definition.float_id = 0
            end
          end
        end
        pick = definition.pick_id
        return if pick == 0
        if floats.index_of(pick) < 0
          definition.pick_id = 0
        elsif !floats.focused? || floats.focused.id != pick
          @close_float.call(state, pick)
          definition.pick_id = 0
        end
      end
    end
  end
end
