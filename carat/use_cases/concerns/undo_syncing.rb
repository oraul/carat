module Carat
  module UseCases
    # The one sync an undo walk does among the keys :normal feeds, shared
    # by the history keys (u, Ctrl-R, g-, g+) and the undo ex commands
    # (:undo, :redo, :earlier, :later): the transaction holding the keys
    # before the walk is still open there, so it closes first, its edits
    # an undo state the walk can take back, as Vim's u_undo syncs the
    # undo first, and a new one opens for the keys after the walk.
    #
    # Readers the including class provides: none.
    module UndoSyncing
      # Runs the block, the walk, between the close and the reopen when
      # the keys :normal feeds hold an open transaction, and returns its
      # outcome.
      # @rbs skip
      def synced_walk(state)
        buffer = state.buffer
        synced = state.normal_depth > 0 && buffer.transaction_open?
        buffer.commit_transaction(state.cursor.position) if synced
        outcome = yield
        buffer.begin_transaction(state.cursor.position) if synced
        outcome
      end
    end
  end
end
