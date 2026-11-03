require_relative "../../domain/command"
require_relative "../../domain/operator_kind"
require_relative "../operate"
require_relative "../replace_chars"
require_relative "../toggle_case"
require_relative "../put_register"
require_relative "../join_lines"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The normal-mode editing commands that complete at once: x s S C D Y
    # as an operator over a fixed motion through Operate, J through
    # JoinLines, p and P through PutRegister, ~ through ToggleCase, and r,
    # which reads the replacement character, through ReplaceChars.
    class EditHandler < ActionHandler
      # @rbs @operate: Operate
      # @rbs @replace_chars: ReplaceChars
      # @rbs @toggle_case: ToggleCase
      # @rbs @put_register: PutRegister
      # @rbs @join_lines: JoinLines
      # @rbs @variant: Symbol

      #: (operate: Operate, replace_chars: ReplaceChars, toggle_case: ToggleCase, put_register: PutRegister, join_lines: JoinLines, variant: Symbol, kind: Symbol) -> void
      def initialize(operate:, replace_chars:, toggle_case:, put_register:, join_lines:, variant:, kind:)
        super(kind: kind, repeat: true)
        @operate = operate
        @replace_chars = replace_chars
        @toggle_case = toggle_case
        @put_register = put_register
        @join_lines = join_lines
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        case @variant
        when :delete_char then fixed(state, command, Domain::OperatorKind::DELETE, "cursor.right", false)
        when :substitute_char then fixed(state, command, Domain::OperatorKind::CHANGE, "cursor.right", false)
        when :substitute_line then fixed(state, command, Domain::OperatorKind::CHANGE, "", true)
        when :change_to_end then fixed(state, command, Domain::OperatorKind::CHANGE, "cursor.line_end", false)
        when :delete_to_end then fixed(state, command, Domain::OperatorKind::DELETE, "cursor.line_end", false)
        when :yank_to_end then fixed(state, command, Domain::OperatorKind::YANK, "cursor.line_end", false)
        when :join then @join_lines.call(state, command)
        when :put_after then @put_register.call(state, command, true)
        when :replace_char then @replace_chars.call(state, command)
        when :toggle_case then @toggle_case.call(state, command)
        else @put_register.call(state, command, false)
        end
      end

      #: (ActionTable, operate: Operate, replace_chars: ReplaceChars, toggle_case: ToggleCase, put_register: PutRegister, join_lines: JoinLines) -> void
      def self.register(table, operate:, replace_chars:, toggle_case:, put_register:, join_lines:)
        names = ["operator.delete_char", "operator.substitute_char", "operator.substitute_line", "operator.change_to_end", "operator.delete_to_end", "operator.yank_to_end", "operator.join", "operator.put_after", "operator.put_before", "operator.replace_char", "operator.toggle_case"]
        variants = [:delete_char, :substitute_char, :substitute_line, :change_to_end, :delete_to_end, :yank_to_end, :join, :put_after, :put_before, :replace_char, :toggle_case]
        i = 0
        while i < names.length
          kind = variants[i] == :replace_char ? :char : :action
          table.register(names[i], EditHandler.new(operate: operate, replace_chars: replace_chars, toggle_case: toggle_case, put_register: put_register, join_lines: join_lines, variant: variants[i], kind: kind))
          i += 1
        end
      end

      private

      # x, s, S, C, D, and Y: the operator over a fixed motion, or over
      # count lines when linewise, with the command's register and count.
      #: (Domain::EditorState, Domain::Command, String, String, bool) -> Outcome
      def fixed(state, command, operator, motion, linewise)
        @operate.call(state, Domain::Command.new(register: command.register, count: command.count, operator: operator, action: motion, char: "", linewise: linewise, keys: command.keys))
      end
    end
  end
end
