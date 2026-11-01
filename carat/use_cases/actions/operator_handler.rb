require_relative "../../domain/mode"
require_relative "../operate"
require_relative "../visual/operate_on_selection"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The five pending operators d c y > <. In normal mode the grammar
    # holds the operator until its motion, text object, or doubled key
    # arrives, and the dispatcher runs this handler with the whole
    # command, which Operate carries out; in a visual mode the operator
    # acts on the selection at once.
    class OperatorHandler < ActionHandler
      # @rbs @operate: Operate
      # @rbs @selection: OperateOnSelection
      # @rbs @variant: Symbol

      #: (operate: Operate, selection: OperateOnSelection, variant: Symbol) -> void
      def initialize(operate:, selection:, variant:)
        super(kind: :operator)
        @operate = operate
        @selection = selection
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        return @operate.call(state, command) if command.operator?
        return Outcome.none unless Domain::Mode.visual?(state.mode)
        case @variant
        when :delete then @selection.delete(state, command)
        when :yank then @selection.yank(state, command)
        when :change then @selection.change(state, command)
        when :indent then @selection.shift(state, command, 1)
        else @selection.shift(state, command, -1)
        end
      end

      #: (ActionTable, operate: Operate, selection: OperateOnSelection) -> void
      def self.register(table, operate:, selection:)
        table.register(Operate::DELETE, OperatorHandler.new(operate: operate, selection: selection, variant: :delete))
        table.register(Operate::CHANGE, OperatorHandler.new(operate: operate, selection: selection, variant: :change))
        table.register(Operate::YANK, OperatorHandler.new(operate: operate, selection: selection, variant: :yank))
        table.register(Operate::INDENT, OperatorHandler.new(operate: operate, selection: selection, variant: :indent))
        table.register(Operate::DEDENT, OperatorHandler.new(operate: operate, selection: selection, variant: :dedent))
      end
    end
  end
end
