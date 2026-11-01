require_relative "../operate"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The normal-mode editing commands that complete at once: x s S C D Y
    # as an operator over a fixed motion, J, p, P, ~, and r, which reads
    # the replacement character, all through Operate.
    class EditHandler < ActionHandler
      # @rbs @operate: Operate
      # @rbs @variant: Symbol

      #: (operate: Operate, variant: Symbol, kind: Symbol) -> void
      def initialize(operate:, variant:, kind:)
        super(kind: kind, repeat: true)
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
        when :replace_char then operate.replace_chars(state, command)
        when :toggle_case then operate.toggle_case(state, command)
        else operate.put(state, command, false)
        end
      end

      #: (ActionTable, operate: Operate) -> void
      def self.register(table, operate:)
        table.register("operator.delete_char", EditHandler.new(operate: operate, variant: :delete_char, kind: :action))
        table.register("operator.substitute_char", EditHandler.new(operate: operate, variant: :substitute_char, kind: :action))
        table.register("operator.substitute_line", EditHandler.new(operate: operate, variant: :substitute_line, kind: :action))
        table.register("operator.change_to_end", EditHandler.new(operate: operate, variant: :change_to_end, kind: :action))
        table.register("operator.delete_to_end", EditHandler.new(operate: operate, variant: :delete_to_end, kind: :action))
        table.register("operator.yank_to_end", EditHandler.new(operate: operate, variant: :yank_to_end, kind: :action))
        table.register("operator.join", EditHandler.new(operate: operate, variant: :join, kind: :action))
        table.register("operator.put_after", EditHandler.new(operate: operate, variant: :put_after, kind: :action))
        table.register("operator.put_before", EditHandler.new(operate: operate, variant: :put_before, kind: :action))
        table.register("operator.replace_char", EditHandler.new(operate: operate, variant: :replace_char, kind: :char))
        table.register("operator.toggle_case", EditHandler.new(operate: operate, variant: :toggle_case, kind: :action))
      end
    end
  end
end
