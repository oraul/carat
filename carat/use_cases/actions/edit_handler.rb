require_relative "../operate"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The normal-mode editing commands that complete at once: x s S C D Y
    # as an operator over a fixed motion, J, p, and P, all through Operate.
    class EditHandler < ActionHandler
      # @rbs @operate: Operate
      # @rbs @variant: Symbol

      #: (operate: Operate, variant: Symbol) -> void
      def initialize(operate:, variant:)
        super(kind: :action)
        @operate = operate
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        operate = @operate
        case @variant
        when :delete_char then operate.fixed(state, command, Operate::DELETE, "cursor.right", false)
        when :substitute_char then operate.fixed(state, command, Operate::CHANGE, "cursor.right", false)
        when :substitute_line then operate.fixed(state, command, Operate::CHANGE, "", true)
        when :change_to_end then operate.fixed(state, command, Operate::CHANGE, "cursor.line_end", false)
        when :delete_to_end then operate.fixed(state, command, Operate::DELETE, "cursor.line_end", false)
        when :yank_to_end then operate.fixed(state, command, Operate::YANK, "cursor.line_end", false)
        when :join then operate.join(state, command)
        when :put_after then operate.put(state, command, true)
        else operate.put(state, command, false)
        end
      end

      #: (ActionTable, operate: Operate) -> void
      def self.register(table, operate:)
        table.register("operator.delete_char", EditHandler.new(operate: operate, variant: :delete_char))
        table.register("operator.substitute_char", EditHandler.new(operate: operate, variant: :substitute_char))
        table.register("operator.substitute_line", EditHandler.new(operate: operate, variant: :substitute_line))
        table.register("operator.change_to_end", EditHandler.new(operate: operate, variant: :change_to_end))
        table.register("operator.delete_to_end", EditHandler.new(operate: operate, variant: :delete_to_end))
        table.register("operator.yank_to_end", EditHandler.new(operate: operate, variant: :yank_to_end))
        table.register("operator.join", EditHandler.new(operate: operate, variant: :join))
        table.register("operator.put_after", EditHandler.new(operate: operate, variant: :put_after))
        table.register("operator.put_before", EditHandler.new(operate: operate, variant: :put_before))
      end
    end
  end
end
