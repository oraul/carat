require_relative "../../domain/editor_state"
require_relative "../../domain/command"
require_relative "../outcome"
require_relative "../completion/select_completion"
require_relative "../completion/accept_completion"
require_relative "../completion/close_completion"
require_relative "action_handler"
require_relative "action_table"

module Carat
  module UseCases
    # The completion popup's actions, bound in keymap.completion and run
    # only while the popup shows: completion.next and completion.previous
    # through SelectCompletion, completion.insert and completion.replace
    # through AcceptCompletion, completion.close through CloseCompletion.
    class CompletionHandler < ActionHandler
      # @rbs @select_completion: SelectCompletion
      # @rbs @accept_completion: AcceptCompletion
      # @rbs @close_completion: CloseCompletion
      # @rbs @variant: Symbol

      #: (select_completion: SelectCompletion, accept_completion: AcceptCompletion, close_completion: CloseCompletion, variant: Symbol) -> void
      def initialize(select_completion:, accept_completion:, close_completion:, variant:)
        super(kind: :action, repeat: false)
        @select_completion = select_completion
        @accept_completion = accept_completion
        @close_completion = close_completion
        @variant = variant
      end

      # @rbs state: Domain::EditorState
      # @rbs command: Domain::Command
      def call(state, command)
        case @variant
        when :next then @select_completion.call(state, 1)
        when :previous then @select_completion.call(state, -1)
        when :insert then @accept_completion.call(state, false)
        when :replace then @accept_completion.call(state, true)
        else @close_completion.call(state)
        end
      end

      #: (ActionTable, select_completion: SelectCompletion, accept_completion: AcceptCompletion, close_completion: CloseCompletion) -> void
      def self.register(table, select_completion:, accept_completion:, close_completion:)
        table.register("completion.next", CompletionHandler.new(select_completion: select_completion, accept_completion: accept_completion, close_completion: close_completion, variant: :next), "Next completion")
        table.register("completion.previous", CompletionHandler.new(select_completion: select_completion, accept_completion: accept_completion, close_completion: close_completion, variant: :previous), "Previous completion")
        table.register("completion.insert", CompletionHandler.new(select_completion: select_completion, accept_completion: accept_completion, close_completion: close_completion, variant: :insert), "Insert the completion")
        table.register("completion.replace", CompletionHandler.new(select_completion: select_completion, accept_completion: accept_completion, close_completion: close_completion, variant: :replace), "Replace the word with completion")
        table.register("completion.close", CompletionHandler.new(select_completion: select_completion, accept_completion: accept_completion, close_completion: close_completion, variant: :close), "Close the completion popup")
      end
    end
  end
end
