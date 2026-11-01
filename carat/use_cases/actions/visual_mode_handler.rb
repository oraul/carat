require_relative "../../domain/mode"
require_relative "../visual/start_visual"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # v V <C-v> and gv, from normal mode and from a visual mode, through
    # StartVisual.
    class VisualModeHandler < ActionHandler
      # @rbs @start_visual: StartVisual
      # @rbs @variant: Symbol

      #: (start_visual: StartVisual, variant: Symbol) -> void
      def initialize(start_visual:, variant:)
        super(kind: :action, repeat: false)
        @start_visual = start_visual
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        case @variant
        when :charwise then @start_visual.toggle(state, Domain::Mode::VISUAL)
        when :linewise then @start_visual.toggle(state, Domain::Mode::VISUAL_LINE)
        when :blockwise then @start_visual.toggle(state, Domain::Mode::VISUAL_BLOCK)
        else @start_visual.reselect(state)
        end
      end

      #: (ActionTable, start_visual: StartVisual) -> void
      def self.register(table, start_visual:)
        table.register("mode.visual", VisualModeHandler.new(start_visual: start_visual, variant: :charwise))
        table.register("mode.visual_line", VisualModeHandler.new(start_visual: start_visual, variant: :linewise))
        table.register("mode.visual_block", VisualModeHandler.new(start_visual: start_visual, variant: :blockwise))
        table.register("visual.reselect", VisualModeHandler.new(start_visual: start_visual, variant: :reselect))
      end
    end
  end
end
