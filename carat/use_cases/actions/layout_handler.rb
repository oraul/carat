require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../windows/toggle_slot"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # layout.toggle_sidebar, layout.toggle_right_sidebar, and
    # layout.toggle_panel: hide or show a slot of the tab page through
    # ToggleSlot.
    class LayoutHandler < ActionHandler
      # @rbs @toggle_slot: ToggleSlot
      # @rbs @side: Symbol

      #: (toggle_slot: ToggleSlot, side: Symbol) -> void
      def initialize(toggle_slot:, side:)
        super(kind: :action, repeat: false)
        @toggle_slot = toggle_slot
        @side = side
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        @toggle_slot.call(state, @side)
      end

      #: (ActionTable, toggle_slot: ToggleSlot) -> void
      def self.register(table, toggle_slot:)
        table.register("layout.toggle_sidebar", LayoutHandler.new(toggle_slot: toggle_slot, side: :left), "Toggle the left sidebar")
        table.register("layout.toggle_right_sidebar", LayoutHandler.new(toggle_slot: toggle_slot, side: :right), "Toggle the right sidebar")
        table.register("layout.toggle_panel", LayoutHandler.new(toggle_slot: toggle_slot, side: :bottom), "Toggle the bottom panel")
      end
    end
  end
end
