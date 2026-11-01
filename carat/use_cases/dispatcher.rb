require_relative "../domain/editor_state"
require_relative "../domain/command"
require_relative "../domain/mode"
require_relative "../domain/buffer_feed"
require_relative "../domain/last_change"
require_relative "../domain/selection"
require_relative "../domain/position"
require_relative "../ports/clock_port"
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
    #
    # Before each command it gives the buffer feed the time, which the
    # undo states closed during the command carry. A command of a change
    # handler that starts outside insert and command-line mode and changes
    # the text or enters insert mode becomes the last change, which the
    # dot command repeats; the selection a visual one acts on is measured
    # before it runs.
    class Dispatcher
      include Reporting

      attr_reader :last_change #: Domain::LastChange
      attr_reader :clock #: Ports::ClockPort
      attr_reader :feed #: Domain::BufferFeed

      # @rbs @actions: ActionTable

      #: (actions: ActionTable, last_change: Domain::LastChange, clock: Ports::ClockPort, feed: Domain::BufferFeed) -> void
      def initialize(actions:, last_change:, clock:, feed:)
        @actions = actions
        @last_change = last_change
        @clock = clock
        @feed = feed
      end

      # Runs a command inside a transaction on the current buffer, so the
      # edits of one command are grouped: the transaction closes after the
      # command, unless the command left the editor in insert mode on the
      # same buffer, when it stays open as the insert session that
      # LeaveInsert closes. A command that runs while a transaction is
      # already open (an insert-mode action) joins it, except a motion,
      # which ends the session's undo state and starts a new one, as an
      # arrow key in Neovim's insert mode does. Outside insert mode an
      # open transaction is a session that ended without LeaveInsert, and
      # is closed first.
      #: (Domain::EditorState, Domain::Command) -> void
      def call(state, command)
        @feed.now = @clock.now
        name = command.operator? ? command.operator : command.action
        handler = @actions.find(name)
        if handler.nil?
          report(state, Outcome.success("Not implemented: #{name}"))
          return
        end
        buffer = state.buffer
        before = state.cursor.position
        mode = state.mode
        if mode == Domain::Mode::INSERT
          return split(state, handler, command) if handler.kind == :motion
        elsif buffer.transaction_open?
          buffer.commit_transaction(before)
        end
        opened = buffer.begin_transaction(before)
        change = handler.repeat && mode != Domain::Mode::INSERT && mode != Domain::Mode::CMDLINE
        if change
          measure(state)
          buffer.start_at(start_of(state.selection)) if Domain::Mode.visual?(mode)
        end
        report(state, handler.call(state, command))
        record(state, command, buffer) if change
        return unless opened
        same = state.buffer.equal?(buffer)
        return if same && state.mode == Domain::Mode::INSERT
        buffer.commit_transaction(same ? state.cursor.position : before)
      end

      private

      # A motion in insert mode: the insert session's undo state so far
      # closes, the cursor moves, and a new one opens, which text typed
      # next becomes a new change for the dot command.
      #: (Domain::EditorState, ActionHandler, Domain::Command) -> void
      def split(state, handler, command)
        buffer = state.buffer
        cursor = state.cursor
        col = cursor.col
        # Closing clamps the cursors on the buffer with normal-mode limits;
        # in insert mode the cursor may stand after the last character, and
        # closing changed no text, so its column is kept.
        buffer.commit_transaction(cursor.position)
        cursor.col = col
        @last_change.split
        report(state, handler.call(state, command))
        buffer.begin_transaction(state.cursor.position) if state.mode == Domain::Mode::INSERT && state.buffer.equal?(buffer)
      end

      # The size of the selection a visual command acts on, for the dot
      # command.
      #: (Domain::EditorState) -> void
      def measure(state)
        last = @last_change
        if Domain::Mode.visual?(state.mode)
          tabstop = state.options.tabstop > 0 ? state.options.tabstop : 8
          last.measure(state.selection, state.buffer, tabstop)
        else
          last.unmeasure
        end
      end

      # Where an operator on the selection starts: its first position, in
      # the left column of a block.
      #: (Domain::Selection) -> Domain::Position
      def start_of(selection)
        first = selection.start
        return first unless selection.kind == :blockwise
        left = selection.anchor.col < selection.head.col ? selection.anchor.col : selection.head.col
        Domain::Position.new(selection.top, left)
      end

      # Keeps the command as the last change when it changed the text or
      # entered insert mode, unless the dot command is running it.
      #: (Domain::EditorState, Domain::Command, Domain::Buffer) -> void
      def record(state, command, buffer)
        last = @last_change
        return if last.replaying
        entered = state.mode == Domain::Mode::INSERT
        return unless entered || buffer.transaction_size > 0
        last.start(command)
        last.begin_session if entered
      end
    end
  end
end
