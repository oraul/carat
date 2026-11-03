require_relative "../../domain/mode"
require_relative "../visual/start_visual"
require_relative "../visual/reselect_visual"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # v V <C-v> through StartVisual and gv through ReselectVisual, from
    # normal mode and from a visual mode.
    class VisualModeHandler < ActionHandler
      # @rbs @start_visual: StartVisual
      # @rbs @reselect_visual: ReselectVisual
      # @rbs @variant: Symbol

      #: (start_visual: StartVisual, reselect_visual: ReselectVisual, variant: Symbol) -> void
      def initialize(start_visual:, reselect_visual:, variant:)
        super(kind: :action, repeat: false)
        @start_visual = start_visual
        @reselect_visual = reselect_visual
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        case @variant
        when :charwise then @start_visual.call(state, Domain::Mode::VISUAL)
        when :linewise then @start_visual.call(state, Domain::Mode::VISUAL_LINE)
        when :blockwise then @start_visual.call(state, Domain::Mode::VISUAL_BLOCK)
        else @reselect_visual.call(state)
        end
      end

      #: (ActionTable, start_visual: StartVisual, reselect_visual: ReselectVisual) -> void
      def self.register(table, start_visual:, reselect_visual:)
        names = ["mode.visual", "mode.visual_line", "mode.visual_block", "visual.reselect"]
        variants = [:charwise, :linewise, :blockwise, :reselect]
        i = 0
        while i < names.length
          table.register(names[i], VisualModeHandler.new(start_visual: start_visual, reselect_visual: reselect_visual, variant: variants[i]))
          i += 1
        end
      end
    end
  end
end
