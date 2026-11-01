require_relative "../../domain/mode"
require_relative "../../domain/text_objects"
require_relative "../visual/extend_visual"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # Every text object. After an operator the dispatcher runs the
    # operator's handler, which reads the object from the command; in a
    # visual mode the object selects or extends through ExtendVisual. The
    # grammar never completes a text object on its own in normal mode.
    class TextObjectHandler < ActionHandler
      # @rbs @extend_visual: ExtendVisual

      #: (extend_visual: ExtendVisual) -> void
      def initialize(extend_visual:)
        super(kind: :text_object, repeat: false)
        @extend_visual = extend_visual
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        return Outcome.none unless Domain::Mode.visual?(state.mode)
        @extend_visual.text_object(state, command)
      end

      # Registers Domain::TextObjects::NAMES with the kind :text_object.
      #: (ActionTable, extend_visual: ExtendVisual) -> void
      def self.register(table, extend_visual:)
        handler = TextObjectHandler.new(extend_visual: extend_visual)
        names = Domain::TextObjects::NAMES
        i = 0
        while i < names.length
          table.register(names[i], handler)
          i += 1
        end
      end
    end
  end
end
