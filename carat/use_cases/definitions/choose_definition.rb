require_relative "../../domain/editor_state"
require_relative "../../domain/definition_request"
require_relative "../outcome"
require_relative "../windows/close_float"
require_relative "visit_target"

module Carat
  module UseCases
    # Enter in the pick list: closes it and goes to, or peeks at, the
    # target of the row under its cursor, as the ask asked. Anywhere else
    # it does nothing.
    class ChooseDefinition
      attr_reader :definition #: Domain::DefinitionRequest
      attr_reader :close_float #: CloseFloat
      attr_reader :visit_target #: VisitTarget

      #: (definition: Domain::DefinitionRequest, close_float: CloseFloat, visit_target: VisitTarget) -> void
      def initialize(definition:, close_float:, visit_target:)
        @definition = definition
        @close_float = close_float
        @visit_target = visit_target
      end

      #: (Domain::EditorState) -> Outcome
      def call(state)
        definition = @definition
        id = definition.pick_id
        floats = state.tab.floats
        return Outcome.none unless id != 0 && floats.focused? && floats.focused.id == id
        row = floats.focused.cursor.row
        @close_float.call(state, id)
        definition.pick_id = 0
        @visit_target.call(state, row)
      end
    end
  end
end
