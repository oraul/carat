require_relative "../domain/editor_state"
require_relative "../domain/command"
require_relative "../domain/mode"
require_relative "outcome"
require_relative "concerns/reporting"
require_relative "actions/action_table"

module Carat
  module UseCases
    # Runs a command from the grammar: finds the handler the action table
    # registered for it (the pending operator's for an operator command,
    # the action's otherwise), runs it, and reports its outcome. It knows
    # no action name: each feature registers its handlers in the table,
    # whose kinds the grammar reads as well. A name no handler takes
    # answers "Not implemented: name".
    class Dispatcher
      include Reporting

      # @rbs @actions: ActionTable

      #: (actions: ActionTable) -> void
      def initialize(actions:)
        @actions = actions
      end

      # Runs a command inside a transaction on the current buffer, so the
      # edits of one command are grouped: the transaction closes after the
      # command, unless the command left the editor in insert mode on the
      # same buffer, when it stays open as the insert session that
      # LeaveInsert closes. A command that runs while a transaction is
      # already open (an insert-mode action) joins it. Outside insert
      # mode an open transaction is a session that ended without
      # LeaveInsert, and is closed first.
      #: (Domain::EditorState, Domain::Command) -> void
      def call(state, command)
        buffer = state.buffer
        before = state.cursor.position
        buffer.commit_transaction(before) if state.mode != Domain::Mode::INSERT && buffer.transaction_open?
        opened = buffer.begin_transaction(before)
        report(state, run(state, command))
        return unless opened
        same = state.buffer.equal?(buffer)
        return if same && state.mode == Domain::Mode::INSERT
        buffer.commit_transaction(same ? state.cursor.position : before)
      end

      private

      #: (Domain::EditorState, Domain::Command) -> Outcome
      def run(state, command)
        name = command.operator? ? command.operator : command.action
        handler = @actions.find(name)
        return Outcome.success("Not implemented: #{name}") if handler.nil?
        handler.call(state, command)
      end
    end
  end
end
