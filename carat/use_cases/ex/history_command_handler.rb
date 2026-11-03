require_relative "../../domain/editor_state"
require_relative "../history/undo_step"
require_relative "../history/redo_step"
require_relative "../history/undo_to_state"
require_relative "../history/travel_history"
require_relative "../history/list_undo"
require_relative "ex_handler"
require_relative "ex_table"

module Carat
  module UseCases
    # The undo ex commands: :u[ndo] with an optional state number, :red[o],
    # :undol[ist], and :ea[rlier] and :lat[er] with a count of changes.
    # A time or file-write argument (10s, 5m, 1h, 1d, 2f) is not
    # implemented yet.
    class HistoryCommandHandler < ExHandler
      # @rbs @undo_step: UndoStep
      # @rbs @redo_step: RedoStep
      # @rbs @undo_to_state: UndoToState
      # @rbs @travel_history: TravelHistory
      # @rbs @list_undo: ListUndo
      # @rbs @variant: Symbol

      #: (spec: String, undo_step: UndoStep, redo_step: RedoStep, undo_to_state: UndoToState, travel_history: TravelHistory, list_undo: ListUndo, variant: Symbol) -> void
      def initialize(spec:, undo_step:, redo_step:, undo_to_state:, travel_history:, list_undo:, variant:)
        super(spec: spec)
        @undo_step = undo_step
        @redo_step = redo_step
        @undo_to_state = undo_to_state
        @travel_history = travel_history
        @list_undo = list_undo
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::ExCommand
      def call(state, command)
        args = command.args
        case @variant
        when :undo
          return @undo_step.call(state, 1) if args.empty?
          return Outcome.failure("E474: Invalid argument") unless HistoryCommandHandler.digits?(args)
          @undo_to_state.call(state, args.to_i)
        when :redo then @redo_step.call(state, 1)
        when :list then @list_undo.call(state)
        when :earlier then travel(state, args, -1, "earlier")
        else travel(state, args, 1, "later")
        end
      end

      # Registers the undo commands after the window and tab commands.
      #: (ExTable, undo_step: UndoStep, redo_step: RedoStep, undo_to_state: UndoToState, travel_history: TravelHistory, list_undo: ListUndo) -> void
      def self.register(table, undo_step:, redo_step:, undo_to_state:, travel_history:, list_undo:)
        specs = ["u[ndo]", "red[o]", "undol[ist]", "ea[rlier]", "lat[er]"]
        variants = [:undo, :redo, :list, :earlier, :later]
        i = 0
        while i < specs.length
          table.register(HistoryCommandHandler.new(spec: specs[i], undo_step: undo_step, redo_step: redo_step, undo_to_state: undo_to_state, travel_history: travel_history, list_undo: list_undo, variant: variants[i]))
          i += 1
        end
      end

      # Whether text is one or more decimal digits.
      #: (String) -> bool
      def self.digits?(text)
        text.match?(/\A[0-9]+\z/)
      end

      private

      # :earlier and :later: a count of changes, one when none is given.
      #: (Domain::EditorState, String, Integer, String) -> Outcome
      def travel(state, args, direction, name)
        return @travel_history.call(state, direction) if args.empty?
        return @travel_history.call(state, direction * args.to_i) if HistoryCommandHandler.digits?(args)
        return Outcome.success("Not implemented: :#{name} #{args}") if args.match?(/\A[0-9]+[smhdf]\z/)
        Outcome.failure("E475: Invalid argument: #{args}")
      end
    end
  end
end
