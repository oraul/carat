require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../../domain/mode"
require_relative "../../domain/operator_kind"
require_relative "../operate"
require_relative "../windows/change_folds"
require_relative "../outcome"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The eight fold.* actions. fold.create (zf) is a pending operator in
    # normal mode, which Operate carries out with its motion or text
    # object, and folds the selection at once in a visual mode; the
    # others complete at once, each a ChangeFolds target. None repeats
    # with ".", as in Neovim.
    class FoldHandler < ActionHandler
      # @rbs @operate: Operate
      # @rbs @change_folds: ChangeFolds
      # @rbs @target: Symbol

      #: (operate: Operate, change_folds: ChangeFolds, target: Symbol) -> void
      def initialize(operate:, change_folds:, target:)
        super(kind: target == :create ? :operator : :action, repeat: false)
        @operate = operate
        @change_folds = change_folds
        @target = target
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        if @target == :create
          return @operate.call(state, command) if command.operator?
          return Outcome.none unless Domain::Mode.visual?(state.mode)
        end
        @change_folds.call(state, @target)
      end

      #: (ActionTable, operate: Operate, change_folds: ChangeFolds) -> void
      def self.register(table, operate:, change_folds:)
        names = [Domain::OperatorKind::FOLD, "fold.open", "fold.close", "fold.toggle", "fold.delete", "fold.delete_all", "fold.open_all", "fold.close_all"]
        targets = [:create, :open, :close, :toggle, :delete, :eliminate, :open_all, :close_all]
        descriptions = ["Create a fold", "Open a fold", "Close a fold", "Toggle a fold", "Delete a fold", "Delete every fold", "Open every fold", "Close every fold"]
        i = 0
        while i < names.length
          table.register(names[i], FoldHandler.new(operate: operate, change_folds: change_folds, target: targets[i]), descriptions[i])
          i += 1
        end
      end
    end
  end
end
