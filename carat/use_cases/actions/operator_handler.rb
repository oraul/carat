require_relative "../../domain/mode"
require_relative "../../domain/operator_kind"
require_relative "../operate"
require_relative "../visual/delete_selection"
require_relative "../visual/yank_selection"
require_relative "../visual/change_selection"
require_relative "../visual/shift_selection"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The five pending operators d c y > <. In normal mode the grammar
    # holds the operator until its motion, text object, or doubled key
    # arrives, and the dispatcher runs this handler with the whole
    # command, which Operate carries out; in a visual mode the operator
    # acts on the selection at once, through the selection use case of
    # its operation.
    class OperatorHandler < ActionHandler
      # @rbs @operate: Operate
      # @rbs @delete_selection: DeleteSelection
      # @rbs @yank_selection: YankSelection
      # @rbs @change_selection: ChangeSelection
      # @rbs @shift_selection: ShiftSelection
      # @rbs @variant: Symbol

      #: (operate: Operate, delete_selection: DeleteSelection, yank_selection: YankSelection, change_selection: ChangeSelection, shift_selection: ShiftSelection, variant: Symbol) -> void
      def initialize(operate:, delete_selection:, yank_selection:, change_selection:, shift_selection:, variant:)
        super(kind: :operator, repeat: true)
        @operate = operate
        @delete_selection = delete_selection
        @yank_selection = yank_selection
        @change_selection = change_selection
        @shift_selection = shift_selection
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        return @operate.call(state, command) if command.operator?
        return Outcome.none unless Domain::Mode.visual?(state.mode)
        case @variant
        when :delete then @delete_selection.call(state, command, :selected)
        when :yank then @yank_selection.call(state, command, false)
        when :change then @change_selection.call(state, command, :selected)
        when :indent then @shift_selection.call(state, command, 1)
        else @shift_selection.call(state, command, -1)
        end
      end

      #: (ActionTable, operate: Operate, delete_selection: DeleteSelection, yank_selection: YankSelection, change_selection: ChangeSelection, shift_selection: ShiftSelection) -> void
      def self.register(table, operate:, delete_selection:, yank_selection:, change_selection:, shift_selection:)
        names = [Domain::OperatorKind::DELETE, Domain::OperatorKind::CHANGE, Domain::OperatorKind::YANK, Domain::OperatorKind::INDENT, Domain::OperatorKind::DEDENT]
        variants = [:delete, :change, :yank, :indent, :dedent]
        descriptions = ["Delete", "Change", "Yank", "Indent", "Dedent"]
        i = 0
        while i < names.length
          table.register(names[i], OperatorHandler.new(operate: operate, delete_selection: delete_selection, yank_selection: yank_selection, change_selection: change_selection, shift_selection: shift_selection, variant: variants[i]), descriptions[i])
          i += 1
        end
      end
    end
  end
end
