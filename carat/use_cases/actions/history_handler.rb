require_relative "../undo"
require_relative "../repeat_last"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The history keys: u and Ctrl-R with counts, U, g- and g+ with
    # counts through Undo, and the dot command through RepeatLast. None
    # of them is a change the dot command repeats.
    class HistoryHandler < ActionHandler
      # @rbs @undo: Undo
      # @rbs @repeat_last: RepeatLast
      # @rbs @variant: Symbol

      #: (undo: Undo, repeat_last: RepeatLast, variant: Symbol) -> void
      def initialize(undo:, repeat_last:, variant:)
        super(kind: :action, repeat: false)
        @undo = undo
        @repeat_last = repeat_last
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        count = command.count_or(1)
        case @variant
        when :undo then @undo.undo(state, count)
        when :redo then @undo.redo(state, count)
        when :undo_line then @undo.line(state)
        when :older then @undo.travel(state, -count)
        when :newer then @undo.travel(state, count)
        else @repeat_last.call(state, command)
        end
      end

      #: (ActionTable, undo: Undo, repeat_last: RepeatLast) -> void
      def self.register(table, undo:, repeat_last:)
        table.register("history.undo", HistoryHandler.new(undo: undo, repeat_last: repeat_last, variant: :undo))
        table.register("history.redo", HistoryHandler.new(undo: undo, repeat_last: repeat_last, variant: :redo))
        table.register("history.undo_line", HistoryHandler.new(undo: undo, repeat_last: repeat_last, variant: :undo_line))
        table.register("history.older", HistoryHandler.new(undo: undo, repeat_last: repeat_last, variant: :older))
        table.register("history.newer", HistoryHandler.new(undo: undo, repeat_last: repeat_last, variant: :newer))
        table.register("history.repeat", HistoryHandler.new(undo: undo, repeat_last: repeat_last, variant: :repeat))
      end
    end
  end
end
