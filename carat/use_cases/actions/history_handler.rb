require_relative "../history/undo_step"
require_relative "../history/redo_step"
require_relative "../history/restore_line"
require_relative "../history/travel_history"
require_relative "../repeat_last"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The history keys: u and Ctrl-R with counts through UndoStep and
    # RedoStep, U through RestoreLine, g- and g+ with counts through
    # TravelHistory, and the dot command through RepeatLast. None of them
    # is a change the dot command repeats.
    class HistoryHandler < ActionHandler
      # @rbs @undo_step: UndoStep
      # @rbs @redo_step: RedoStep
      # @rbs @restore_line: RestoreLine
      # @rbs @travel_history: TravelHistory
      # @rbs @repeat_last: RepeatLast
      # @rbs @variant: Symbol

      #: (undo_step: UndoStep, redo_step: RedoStep, restore_line: RestoreLine, travel_history: TravelHistory, repeat_last: RepeatLast, variant: Symbol) -> void
      def initialize(undo_step:, redo_step:, restore_line:, travel_history:, repeat_last:, variant:)
        super(kind: :action, repeat: false)
        @undo_step = undo_step
        @redo_step = redo_step
        @restore_line = restore_line
        @travel_history = travel_history
        @repeat_last = repeat_last
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        count = command.count_or(1)
        case @variant
        when :undo then @undo_step.call(state, count)
        when :redo then @redo_step.call(state, count)
        when :undo_line then @restore_line.call(state)
        when :older then @travel_history.call(state, -count)
        when :newer then @travel_history.call(state, count)
        else @repeat_last.call(state, command)
        end
      end

      #: (ActionTable, undo_step: UndoStep, redo_step: RedoStep, restore_line: RestoreLine, travel_history: TravelHistory, repeat_last: RepeatLast) -> void
      def self.register(table, undo_step:, redo_step:, restore_line:, travel_history:, repeat_last:)
        names = ["history.undo", "history.redo", "history.undo_line", "history.older", "history.newer", "history.repeat"]
        variants = [:undo, :redo, :undo_line, :older, :newer, :repeat]
        i = 0
        while i < names.length
          table.register(names[i], HistoryHandler.new(undo_step: undo_step, redo_step: redo_step, restore_line: restore_line, travel_history: travel_history, repeat_last: repeat_last, variant: variants[i]))
          i += 1
        end
      end
    end
  end
end
