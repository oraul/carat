require_relative "../../domain/editor_state"
require_relative "../../domain/ex_range"
require_relative "../../domain/messages"
require_relative "ex_handler"

module Carat
  module UseCases
    # The base of the line commands (:d, :m, :co, :t, :j, :>, :<): each
    # takes a range, the cursor line without one, and shares the prelude
    # that refuses a bang the command does not take with E477 and resolves
    # the range, the target address of :m and :co, and the cursor placed
    # at the wanted column.
    class LineCommandHandler < ExHandler
      #: (spec: String) -> void
      def initialize(spec:)
        super(spec: spec)
      end

      # True: the range is the lines the command works on.
      # @rbs skip
      def ranged?
        true
      end

      # Whether the command takes a bang: false here, so lines_of answers
      # E477; :j takes one.
      # @rbs skip
      def bang?
        false
      end

      private

      # The rows of the command's range, or E477 for a bang the command
      # does not take, or what ExRange answers for the range.
      #: (Domain::EditorState, Domain::ExCommand) -> Domain::ExRange
      def lines_of(state, command)
        return Domain::ExRange.refused(Domain::Messages::E477) if command.bang && !bang?
        Domain::ExRange.resolve(command.range, state.cursor.row, state.buffer.line_count, state.window.last_selection)
      end

      # The row the lines go to for the command's address argument, as
      # ExRange.target answers it.
      #: (Domain::EditorState, Domain::ExCommand) -> Domain::ExRange
      def target_of(state, command)
        Domain::ExRange.target(command.args, state.cursor.row, state.buffer.line_count, state.window.last_selection)
      end

      # The cursor on row at the wanted column, clamped by
      # EditorState#clamp_col (the end of the line for a wanted column
      # past it, -1), the wanted column kept, as Neovim's
      # beginline(BL_SOL | BL_FIX) does under nostartofline.
      #: (Domain::EditorState, Integer) -> void
      def place_cursor(state, row)
        cursor = state.cursor
        want = cursor.want_col
        col = want < 0 ? state.max_col(row) : state.clamp_col(row, want)
        cursor.row = row
        cursor.col = col
      end
    end
  end
end
